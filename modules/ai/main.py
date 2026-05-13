import sys
import os
import evdev
from evdev import ecodes
import select
import threading
import subprocess
import json
import pyudev
import logging
from audio_transcriber import AudioTranscriber
from agent_bridge import AgentBridge
from tts import TTSManager

# Configuración de logging profesional
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(name)s: %(message)s',
    handlers=[logging.StreamHandler(sys.stdout)]
)
logger = logging.getLogger("EmeBotEme")

class EmeBotEme:
    """Orquestador principal de EmeBotEme v2.0 con soporte para hotplug, persistencia y TTS."""
    
    def __init__(self):
        logger.info("Inicializando EmeBotEme v2.0...")
        self.base_path = os.path.dirname(os.path.abspath(__file__))
        self.config = self._load_config()
        
        # Inicializar componentes
        self.bridge = AgentBridge(
            command=self.config["agent"]["command"],
            system_prompt=self.config["agent"]["system_prompt"]
        )
        self.transcriber = AudioTranscriber(
            model_size=self.config["whisper"]["model_size"],
            device=self.config["whisper"]["device"],
            compute_type=self.config["whisper"]["compute_type"],
            language=self.config["whisper"].get("language")
        )
        self.tts = TTSManager(
            voice=self.config["tts"]["voice"],
            enabled=self.config["tts"]["enabled"]
        )
        
        self.is_recording = False
        self.alt_pressed = False
        self.super_pressed = False
        
        # Gestión de teclados
        self.devices = {} # fd -> InputDevice
        self.selector = select.poll()
        self._init_udev()
        self._set_status("IDLE")

    def _load_config(self):
        config_path = os.path.join(self.base_path, "config.json")
        try:
            with open(config_path, "r") as f:
                return json.load(f)
        except Exception as e:
            logger.error(f"No se pudo cargar config.json: {e}")
            sys.exit(1)

    def _init_udev(self):
        self.context = pyudev.Context()
        self.monitor = pyudev.Monitor.from_netlink(self.context)
        self.monitor.filter_by(subsystem='input')
        for device in self.context.list_devices(subsystem='input'):
            self._add_device(device.device_node)
        self.hotplug_thread = threading.Thread(target=self._monitor_udev, daemon=True)
        self.hotplug_thread.start()

    def _add_device(self, node):
        if not node or not node.startswith('/dev/input/event'):
            return
        try:
            device = evdev.InputDevice(node)
            capabilities = device.capabilities()
            if ecodes.EV_KEY in capabilities:
                trigger_code = getattr(ecodes, self.config["keys"]["trigger"])
                if trigger_code in capabilities[ecodes.EV_KEY]:
                    logger.info(f"Dispositivo añadido: {device.name} ({node})")
                    self.devices[device.fd] = device
                    self.selector.register(device.fd, select.POLLIN)
        except Exception:
            pass

    def _remove_device(self, node):
        for fd, device in list(self.devices.items()):
            if device.path == node:
                logger.info(f"Dispositivo eliminado: {device.name} ({node})")
                self.selector.unregister(fd)
                del self.devices[fd]
                break

    def _monitor_udev(self):
        for action, device in iter(self.monitor.poll, None):
            if action == 'add':
                self._add_device(device.device_node)
            elif action == 'remove':
                self._remove_device(device.device_node)

    def _set_status(self, status):
        icons = {"IDLE": "", "RECORDING": "󰐊", "PROCESSING": "󰚩"}
        data = {"text": f"{icons.get(status, 'IDLE')} {status}", "class": status}
        try:
            with open("/tmp/emebot_status", "w") as f:
                f.write(json.dumps(data))
        except Exception:
            pass

    def toggle_recording(self):
        if not self.is_recording:
            self._set_status("RECORDING")
            subprocess.run(["notify-send", "-t", "1000", "-h", "string:x-canonical-private-synchronous:emebot", 
                          "🎙️ Escuchando...", f"Suelte para procesar"], check=False)
            self.tts.speak("Escuchando")
            self.is_recording = True
            self.transcriber.start_recording()
        else:
            self._set_status("PROCESSING")
            self.is_recording = False
            subprocess.run(["notify-send", "-t", "2000", "-h", "string:x-canonical-private-synchronous:emebot", 
                          "⏳ Procesando...", "Analizando voz"], check=False)
            
            text = self.transcriber.stop_recording()
            logger.info(f"Voz procesada: '{text}'")
            
            if text:
                self.tts.speak("Procesando")
                self.bridge.send_command(text)
            else:
                self.tts.speak("No te he oído")
                subprocess.run(["notify-send", "-t", "2000", "-i", "dialog-warning", "EmeBotEme", "No se detectó voz"], check=False)
            
            self._set_status("IDLE")

    def run(self):
        self.bridge.start()
        logger.info(f"{self.config['agent']['name']} v2.0 Listo")
        logger.info(f"Atajo: Super + Alt + {self.config['keys']['trigger']}")
        
        trigger_key = self.config["keys"]["trigger"]
        super_keys = self.config["keys"]["super"]
        alt_keys = self.config["keys"]["alt"]

        try:
            while True:
                events = self.selector.poll(1000)
                for fd, event in events:
                    if fd in self.devices:
                        for ev in self.devices[fd].read():
                            if ev.type == ecodes.EV_KEY:
                                data = evdev.categorize(ev)
                                if data.keycode in alt_keys:
                                    self.alt_pressed = (data.keystate != 0)
                                if data.keycode in super_keys:
                                    self.super_pressed = (data.keystate != 0)
                                if data.keycode == trigger_key:
                                    if data.keystate == 1:
                                        if self.alt_pressed and self.super_pressed and not self.is_recording:
                                            self.toggle_recording()
                                    elif data.keystate == 0:
                                        if self.is_recording:
                                            self.toggle_recording()
                                if data.keycode == "KEY_ESC" and data.keystate == 1:
                                    # Interrumpir y cerrar si el popup está activo
                                    if self.bridge._get_popup_address():
                                        self.bridge.interrupt_command()
                                        self.bridge.detach_session()
        except KeyboardInterrupt:
            self.shutdown()
        except Exception as e:
            logger.exception(f"Error inesperado en el bucle principal: {e}")
            self.shutdown()

    def shutdown(self):
        logger.info("Saliendo...")
        self.bridge.stop()
        sys.exit(0)

if __name__ == "__main__":
    bot = EmeBotEme()
    bot.run()

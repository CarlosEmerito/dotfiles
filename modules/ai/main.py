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

# --- Configuración del Subsistema de Diagnóstico ---
# Se utiliza un formato estandarizado para facilitar el parseo por herramientas de log externas (ej. journalctl)
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(name)s: %(message)s',
    handlers=[logging.StreamHandler(sys.stdout)]
)
logger = logging.getLogger("EmeBotEme")

class EmeBotEme:
    """
    Orquestador principal del ecosistema EmeBotEme.
    Gestiona el ciclo de vida de los periféricos de entrada (hotplug), coordina el flujo
    entre el reconocimiento de voz (STT) y el puente con el agente de IA.
    """

    def __init__(self):
        logger.info("Inicializando EmeBotEme v2.0...")
        self.base_path = os.path.dirname(os.path.abspath(__file__))
        self.config = self._load_config()

        # Inyección de dependencias para los componentes core
        self.bridge = AgentBridge(
            command=self.config["agent"]["command"],
            system_prompt=self.config["agent"]["system_prompt"],
            model=self.config["agent"].get("model", "opencode/deepseek-v4-flash-free"),
            vision_model=self.config["agent"].get("vision_model")
        )
        self.transcriber = AudioTranscriber(
            model_size=self.config["whisper"]["model_size"],
            device=self.config["whisper"]["device"],
            compute_type=self.config["whisper"]["compute_type"],
            language=self.config["whisper"].get("language")
        )

        self.is_recording = False
        self.input_active = False
        self.alt_pressed = False
        self.super_pressed = False

        # Gestión de descriptores de archivo para el pooling de eventos de entrada
        self.devices = {} # Mapeo fd -> InputDevice
        self.selector = select.poll()
        self._init_udev()
        self._set_status("IDLE")

    def _load_config(self):
        """Carga la configuración desde el archivo JSON persistente."""
        config_path = os.path.join(self.base_path, "config.json")
        try:
            with open(config_path, "r") as f:
                return json.load(f)
        except Exception as e:
            logger.error(f"Fallo crítico al cargar la configuración: {e}")
            sys.exit(1)

    def _init_udev(self):
        """Configura el monitoreo de eventos udev para soporte hotplug de dispositivos de entrada."""
        self.context = pyudev.Context()
        self.monitor = pyudev.Monitor.from_netlink(self.context)
        self.monitor.filter_by(subsystem='input')

        # Registro inicial de dispositivos presentes en el sistema
        for device in self.context.list_devices(subsystem='input'):
            self._add_device(device.device_node)

        # Ejecución del monitor en un hilo separado para no bloquear el event loop principal
        self.hotplug_thread = threading.Thread(target=self._monitor_udev, daemon=True)
        self.hotplug_thread.start()

    def _add_device(self, node):
        """Registra un nuevo dispositivo de entrada si cumple con los requisitos del trigger."""
        if not node or not node.startswith('/dev/input/event'):
            return
        try:
            device = evdev.InputDevice(node)
            capabilities = device.capabilities()
            if ecodes.EV_KEY in capabilities:
                trigger_code = getattr(ecodes, self.config["keys"]["trigger"])
                text_trigger_code = getattr(ecodes, self.config["keys"]["text_trigger"])
                clear_trigger_code = getattr(ecodes, self.config["keys"]["clear_session_trigger"])
                screenshot_trigger_code = getattr(ecodes, self.config["keys"]["screenshot_trigger"])

                # Registramos el dispositivo si tiene al menos una de las teclas trigger
                triggers = [trigger_code, text_trigger_code, clear_trigger_code, screenshot_trigger_code]
                if any(k in capabilities[ecodes.EV_KEY] for k in triggers):
                    logger.info(f"Nuevo dispositivo de entrada vinculado: {device.name} ({node})")
                    self.devices[device.fd] = device
                    self.selector.register(device.fd, select.POLLIN)
        except Exception:
            # Silenciamos errores de permisos o dispositivos no compatibles durante el escaneo
            pass

    def _remove_device(self, node):
        """Desvincula un dispositivo de entrada tras su desconexión física o lógica."""
        for fd, device in list(self.devices.items()):
            if device.path == node:
                logger.info(f"Dispositivo desconectado: {device.name} ({node})")
                self.selector.unregister(fd)
                del self.devices[fd]
                break

    def _monitor_udev(self):
        """Bucle de monitoreo para eventos de inserción/remoción de hardware."""
        for device in iter(self.monitor.poll, None):
            action = device.action
            if action == 'add':
                self._add_device(device.device_node)
            elif action == 'remove':
                self._remove_device(device.device_node)

    def _set_status(self, status):
        """Actualiza el estado global para la integración con barras de estado (ej. Waybar). Sesión visual."""
        icons = {"IDLE": "", "RECORDING": "󰐊", "PROCESSING": "󰚩", "VISION": "󰄀"}
        data = {"text": f"{icons.get(status, 'IDLE')} {status}", "class": status}
        try:
            with open("/tmp/emebot_status", "w") as f:
                f.write(json.dumps(data))
        except Exception:
            pass

    def toggle_recording(self):
        """Maneja la lógica de transición entre los estados de grabación y procesamiento."""
        if not self.is_recording:
            # Inicio de captura
            self._set_status("RECORDING")
            subprocess.run(["notify-send", "-t", "1000", "-h", "string:x-canonical-private-synchronous:emebot",
                          "🎙️ Escuchando...", f"Suelte para procesar"], check=False)
            self.is_recording = True
            try:
                self.transcriber.start_recording()
            except Exception as e:
                logger.error(f"No se pudo iniciar la captura de audio: {e}")
                self.is_recording = False
                self._set_status("IDLE")
                subprocess.run(["notify-send", "-t", "3000", "-i", "dialog-warning", "EmeBotEme",
                              "No se detectó dispositivo de captura (micrófono)"], check=False)
                return
        else:
            # Cierre de captura y despacho al agente
            self._set_status("PROCESSING")
            self.is_recording = False

            # Reset de modificadores tras acción
            self.alt_pressed = False
            self.super_pressed = False

            subprocess.run(["notify-send", "-t", "2000", "-h", "string:x-canonical-private-synchronous:emebot",
                          "⏳ Procesando...", "Analizando voz"], check=False)

            # Transcripción y envío al agente en segundo plano para no bloquear el event-loop
            threading.Thread(target=self._process_recording, daemon=True).start()

    def _process_recording(self):
        """Procesa la grabación en un hilo separado: transcripción + envío al agente."""
        try:
            text = self.transcriber.stop_recording()
            logger.info(f"Transcripción exitosa: '{text}'")

            if text:
                self.bridge.send_command(text)
            else:
                subprocess.run(["notify-send", "-t", "2000", "-i", "dialog-warning", "EmeBotEme", "No se detectó voz"], check=False)
        except Exception as e:
            logger.error(f"Error procesando la grabación: {e}")
            subprocess.run(["notify-send", "-t", "2000", "-i", "dialog-error", "EmeBotEme", "Error al procesar el audio"], check=False)
        finally:
            self._set_status("IDLE")

    def _open_input_window(self, title):
        """Lanza la ventana de entrada multi-línea y devuelve el texto escrito (bloqueante)."""
        if os.path.exists("/tmp/emebot_input.txt"):
            os.remove("/tmp/emebot_input.txt")

        kitty_conf = "/tmp/emebot_input_kitty.conf"
        with open(kitty_conf, "w") as f:
            f.write("window_padding_width 20\nfont_size 14.0\nbackground_opacity 0.95\n")
            f.write("remember_window_size no\ninitial_window_width 600\ninitial_window_height 600\n")

        input_script = os.path.join(self.base_path, "input_ui.py")

        subprocess.run([
            "kitty", "--config", kitty_conf,
            "--class", "emebot_input",
            "--title", title,
            sys.executable, input_script
        ], check=False)

        if os.path.exists("/tmp/emebot_input.txt"):
            with open("/tmp/emebot_input.txt", "r") as f:
                return f.read().strip()
        return ""

    def handle_vision_prompt(self):
        """Captura pantalla y abre prompt para preguntar sobre ella."""
        if self.input_active:
            return
        self.alt_pressed = False
        self.super_pressed = False
        self.input_active = True
        self._set_status("VISION")

        def worker():
            try:
                screenshot_path = "/tmp/emebot_vision.png"

                # Captura de pantalla silenciosa
                subprocess.run(["grim", screenshot_path], check=True)

                subprocess.run(["notify-send", "-t", "1000", "-h", "string:x-canonical-private-synchronous:emebot",
                              "󰄀 Visión", "Captura realizada. Escribe tu duda."], check=False)

                text = self._open_input_window("EmeBotEme Vision Input")
                if text:
                    logger.info(f"Entrada de visión recibida: '{text[:50]}...'")
                    self.bridge.send_command(text, image_path=screenshot_path)
            except Exception as e:
                logger.error(f"Error en el modo visión: {e}")
            finally:
                self.input_active = False
                self._set_status("IDLE")

        threading.Thread(target=worker, daemon=True).start()

    def prompt_text_input(self):
        """Abre una ventana de Kitty para entrada de texto multi-línea."""
        if self.input_active:
            return
        self.alt_pressed = False
        self.super_pressed = False
        self.input_active = True

        def worker():
            try:
                text = self._open_input_window("EmeBotEme Input")
                if text:
                    logger.info(f"Entrada multi-línea recibida: '{text[:50]}...'")
                    self.bridge.send_command(text)
            except Exception as e:
                logger.error(f"Error al lanzar la ventana de entrada: {e}")
            finally:
                self.input_active = False

        threading.Thread(target=worker, daemon=True).start()

    def run(self):
        """Punto de entrada del event loop para la gestión de atajos de teclado globales."""
        self.bridge.start()
        logger.info(f"{self.config['agent']['name']} v2.0 Operacional")
        logger.info(f"Hotkeys: Voice (Super+Alt+{self.config['keys']['trigger']}), Text (Super+Alt+{self.config['keys']['text_trigger']}), New Session (Super+Alt+{self.config['keys']['clear_session_trigger']}), Vision (Super+Alt+{self.config['keys']['screenshot_trigger']})")

        trigger_key = self.config["keys"]["trigger"]
        text_trigger_key = self.config["keys"]["text_trigger"]
        clear_trigger_key = self.config["keys"]["clear_session_trigger"]
        screenshot_trigger_key = self.config["keys"]["screenshot_trigger"]
        super_keys = self.config["keys"]["super"]
        alt_keys = self.config["keys"]["alt"]

        try:
            while True:
                # Pooling de descriptores con timeout de 1s para mantener el proceso vivo y responsivo
                events = self.selector.poll(1000)
                for fd, event in events:
                    if fd in self.devices:
                        try:
                            for ev in self.devices[fd].read():
                                if ev.type == ecodes.EV_KEY:
                                    data = evdev.categorize(ev)
                                    keycodes = data.keycode if isinstance(data.keycode, list) else [data.keycode]

                                    # Seguimiento del estado de los modificadores
                                    if any(k in alt_keys for k in keycodes):
                                        self.alt_pressed = (data.keystate != 0)
                                    if any(k in super_keys for k in keycodes):
                                        self.super_pressed = (data.keystate != 0)

                                    # Lógica de disparo para la grabación (Voz)
                                    if trigger_key in keycodes:
                                        if data.keystate == 1: # KeyDown
                                            if self.alt_pressed and self.super_pressed and not self.is_recording:
                                                self.toggle_recording()
                                        elif data.keystate == 0: # KeyUp
                                            if self.is_recording:
                                                self.toggle_recording()

                                    # Lógica de disparo para el prompt (Texto)
                                    if text_trigger_key in keycodes and data.keystate == 1:
                                        if self.alt_pressed and self.super_pressed:
                                            self.prompt_text_input()

                                    # Lógica de disparo para Nueva Sesión
                                    if clear_trigger_key in keycodes and data.keystate == 1:
                                        if self.alt_pressed and self.super_pressed:
                                            logger.info("Iniciando nueva sesión...")
                                            self.bridge.clear_session()

                                            # Reset tras acción
                                            self.alt_pressed = False
                                            self.super_pressed = False

                                            subprocess.run(["notify-send", "-t", "2000", "-i", "edit-clear", "EmeBotEme", "🧹 Nueva sesión iniciada"], check=False)

                                    # Lógica de disparo para Visión (Screenshot)
                                    if screenshot_trigger_key in keycodes and data.keystate == 1:
                                        if self.alt_pressed and self.super_pressed:
                                            self.handle_vision_prompt()

                                    # Interrupción de emergencia vía ESC
                                    if "KEY_ESC" in keycodes and data.keystate == 1:
                                        if self.bridge._get_popup_address():
                                            self.bridge.interrupt_command()
                        except Exception as e:
                            # Manejo de desconexiones repentinas u otros fallos sin tirar el event-loop
                            logger.warning(f"Error procesando eventos de teclado: {e}")
        except KeyboardInterrupt:
            self.shutdown()
        except Exception as e:
            logger.exception(f"Fallo no recuperable en el bucle principal: {e}")
            self.shutdown()

    def shutdown(self):
        """Cierre ordenado de recursos y subprocesos."""
        logger.info("Finalizando servicios...")
        self.bridge.stop()
        sys.exit(0)

if __name__ == "__main__":
    bot = EmeBotEme()
    bot.run()
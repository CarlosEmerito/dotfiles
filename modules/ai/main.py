import sys
import evdev
from evdev import ecodes
import select
import threading
import subprocess
import json
from audio_transcriber import AudioTranscriber
from agent_bridge import AgentBridge

class EmeBotEme:
    """Orquestador principal de EmeBotEme con soporte multiteclado."""
    
    def __init__(self):
        print("[INIT] Inicializando EmeBotEme (Agente de Voz)...")
        # Log environment for debugging
        import os
        for var in ['DISPLAY', 'WAYLAND_DISPLAY', 'XDG_RUNTIME_DIR', 'HYPRLAND_INSTANCE_SIGNATURE']:
            print(f"[DEBUG] {var}={os.environ.get(var)}")
        
        # Usamos opencode con permisos automáticos y el modelo gratuito por defecto
        self.bridge = AgentBridge(command="/home/emerito/.opencode/bin/opencode run --dangerously-skip-permissions -m opencode/big-pickle")
        self.transcriber = AudioTranscriber()
        self.is_recording = False
        
        # Estado de las teclas
        self.alt_pressed = False
        self.super_pressed = False
        self.keyboards = self._find_keyboards()
        self._set_status("IDLE")
        
        if not self.keyboards:
            print("[ERROR] No se encontró ningún teclado. ¿Estás en el grupo 'input'?")
            sys.exit(1)

    def _set_status(self, status):
        """Escribe el estado actual en formato JSON para Waybar."""
        icons = {"IDLE": "", "RECORDING": "󰐊", "PROCESSING": "󰚩"}
        data = {"text": f"{icons.get(status, 'IDLE')} {status}", "class": status}
        try:
            with open("/tmp/emebot_status", "w") as f:
                f.write(json.dumps(data))
        except Exception:
            pass

    def _find_keyboards(self):
        """Busca todos los dispositivos que parecen ser teclados."""
        keyboards = []
        device_paths = evdev.list_devices()
        for path in device_paths:
            try:
                device = evdev.InputDevice(path)
                capabilities = device.capabilities()
                if ecodes.EV_KEY in capabilities:
                    # Buscamos dispositivos que tengan teclas básicas (A-Z)
                    if ecodes.KEY_Z in capabilities[ecodes.EV_KEY]:
                        keyboards.append(device)
            except Exception:
                continue
        
        for k in keyboards:
            print(f"[INIT] Escuchando teclado: {k.name} ({k.path})")
        return keyboards

    def toggle_recording(self):
        """Cambia el estado de grabación con feedback sonoro y visual."""
        if not self.is_recording:
            self._set_status("RECORDING")
            # OSD Notification
            subprocess.run(["notify-send", "-t", "1000", "-h", "string:x-canonical-private-synchronous:emebot", "🎙️ Escuchando...", "Suelte Super+Alt+Z para procesar"], check=False)
            # Beep de inicio (tono más limpio)
            subprocess.run(["paplay", "/usr/share/sounds/freedesktop/stereo/audio-test-signal.oga"], check=False)
            self.is_recording = True
            self.transcriber.start_recording()
        else:
            self._set_status("PROCESSING")
            self.is_recording = False
            # OSD Notification
            subprocess.run(["notify-send", "-t", "2000", "-h", "string:x-canonical-private-synchronous:emebot", "⏳ Procesando...", "Analizando tu voz con IA"], check=False)
            # Beep de fin
            subprocess.run(["paplay", "/usr/share/sounds/freedesktop/stereo/complete.oga"], check=False)
            text = self.transcriber.stop_recording()
            print(f"[PROCESS] Texto detectado: '{text}'")
            
            if text:
                self.bridge.send_command(text)
            else:
                subprocess.run(["notify-send", "-t", "2000", "-i", "dialog-warning", "EmeBotEme", "No se detectó voz o el audio fue muy corto"], check=False)
            
            self._set_status("IDLE")

    def run(self):
        """Inicia el loop de escucha para múltiples teclados."""
        self.bridge.start()
        
        print("\n--- EmeBotEme Listo (Multi-Keyboard) ---")
        print("Atajo: Super + Alt + Z para hablar.")
        print("Presiona Ctrl + C para salir.")

        # Mapa de file descriptors a dispositivos
        dev_map = {k.fd: k for k in self.keyboards}

        try:
            while True:
                # Esperamos eventos de cualquiera de los teclados
                r, w, x = select.select(dev_map.keys(), [], [])
                for fd in r:
                    device = dev_map[fd]
                    for event in device.read():
                        if event.type == ecodes.EV_KEY:
                            data = evdev.categorize(event)
                            
                            # Detectar Alts
                            if data.keycode in ['KEY_LEFTALT', 'KEY_RIGHTALT']:
                                if data.keystate == 1: # Down
                                    self.alt_pressed = True
                                elif data.keystate == 0: # Up
                                    self.alt_pressed = False
                            
                            # Detectar Supers (Windows keys)
                            if data.keycode in ['KEY_LEFTMETA', 'KEY_RIGHTMETA']:
                                if data.keystate == 1: # Down
                                    self.super_pressed = True
                                elif data.keystate == 0: # Up
                                    self.super_pressed = False
                            
                            # Detectar Z
                            if data.keycode == 'KEY_Z':
                                if data.keystate == 1: # Down
                                    if self.alt_pressed and self.super_pressed and not self.is_recording:
                                        self.toggle_recording()
                                elif data.keystate == 0: # Up
                                    if self.is_recording:
                                        self.toggle_recording()
                            
        except KeyboardInterrupt:
            self.shutdown()
        except Exception as e:
            print(f"[ERROR] Error inesperado: {e}")
            self.shutdown()

    def shutdown(self):
        print("\n[SHUTDOWN] Saliendo de EmeBotEme...")
        self.bridge.stop()
        sys.exit(0)

if __name__ == "__main__":
    bot = EmeBotEme()
    bot.run()

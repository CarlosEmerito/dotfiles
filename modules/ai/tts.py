import subprocess
import os
import threading

class TTSManager:
    """Maneja la síntesis de voz usando Piper TTS."""
    
    def __init__(self, voice="es_ES-huerta-medium", enabled=True):
        self.enabled = enabled
        self.voice = voice
        # Intentamos buscar el modelo en rutas comunes o locales
        self.model_path = self._find_model()
        
    def _find_model(self):
        # Rutas comunes donde se instalan voces de piper
        paths = [
            f"/usr/share/piper-voices/{self.voice}.onnx",
            os.path.expanduser(f"~/.local/share/piper-voices/{self.voice}.onnx"),
            f"{os.path.dirname(__file__)}/voices/{self.voice}.onnx"
        ]
        for p in paths:
            if os.path.exists(p):
                return p
        return None

    def speak(self, text):
        if not self.enabled:
            return
            
        def _run():
            try:
                # Si no hay modelo, intentamos usar 'spd-say' como fallback
                if not self.model_path:
                    subprocess.run(["spd-say", "-l", "es", text], check=False)
                    return

                # Comando piper: texto -> piper -> aplay/paplay
                piper_cmd = f'echo "{text}" | piper --model {self.model_path} --output_raw | aplay -r 22050 -f S16_LE -t raw'
                subprocess.run(piper_cmd, shell=True, check=False)
            except Exception as e:
                print(f"[TTS ERROR] {e}")

        threading.Thread(target=_run, daemon=True).start()

import subprocess
import os
import threading

class TTSManager:
    """
    Controlador para la síntesis de voz (Text-to-Speech).
    Prioriza el uso de 'Piper' por su calidad y baja latencia, con un fallback
    al demonio de voz estándar 'speech-dispatcher' (spd-say).
    """
    
    def __init__(self, voice="es_ES-huerta-medium", enabled=True):
        self.enabled = enabled
        self.voice = voice
        # Resolución de rutas para el modelo ONNX de Piper
        self.model_path = self._find_model()
        
    def _find_model(self):
        """Busca el archivo del modelo en las ubicaciones estándar del sistema y locales."""
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
        """
        Despacha la síntesis de voz en un hilo desacoplado (Fire and Forget)
        para evitar bloqueos en la interfaz de usuario o el hilo principal.
        """
        if not self.enabled:
            return
            
        def _run():
            try:
                # Lógica de fallback si Piper no está configurado o el modelo no existe
                if not self.model_path:
                    subprocess.run(["spd-say", "-l", "es", text], check=False)
                    return

                # Pipeline de audio: Texto -> Motor Piper -> Reproducción Raw (aplay)
                # Se utiliza salida raw para minimizar el overhead de codificación/decodificación
                piper_cmd = f'echo "{text}" | piper --model {self.model_path} --output_raw | aplay -r 22050 -f S16_LE -t raw'
                subprocess.run(piper_cmd, shell=True, check=False)
            except Exception as e:
                # El TTS se considera un componente no crítico; los errores se notifican pero no detienen el bot
                print(f"[TTS ERROR] Fallo en la síntesis de voz: {e}")

        # Hilo daemon para asegurar que no bloquee el cierre del proceso principal
        threading.Thread(target=_run, daemon=True).start()

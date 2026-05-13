import os
import wave
import numpy as np
import sounddevice as sd
from faster_whisper import WhisperModel
from typing import Optional
import tempfile

# El token se cargará desde el entorno (gestionado por Systemd o .zshrc)
hf_token = os.environ.get("HF_TOKEN")
if hf_token:
    os.environ["HF_TOKEN"] = hf_token

class AudioTranscriber:
    """Módulo encargado de la grabación de audio y su transcripción a texto."""
    
    def __init__(self, model_size: str = "tiny", device: str = "cpu", compute_type: str = "float32", input_device: Optional[int] = None):
        self.input_device = input_device
        print(f"[INIT] Cargando modelo Whisper '{model_size}'...")
        # Usamos float32 para evitar advertencias de compatibilidad en CPU
        self.model = WhisperModel(model_size, device=device, compute_type=compute_type)
        print("[INIT] Modelo Whisper cargado correctamente.")
        self.sample_rate = 16000
        self.channels = 1
        self.recording_buffer = []
        self.is_recording = False

    def start_recording(self) -> None:
        """Inicia la captura de audio desde el micrófono."""
        self.is_recording = True
        self.recording_buffer = []
        
        def callback(indata, frames, time, status):
            if status:
                print(f"Error en grabación: {status}")
            if self.is_recording:
                # Guardamos los datos tal cual vienen (normalmente float32 entre -1 y 1)
                self.recording_buffer.append(indata.copy())

        self.stream = sd.InputStream(
            samplerate=self.sample_rate,
            channels=self.channels,
            callback=callback,
            dtype='float32',
            device=self.input_device
        )
        self.stream.start()
        print("\n[REC] Grabando... (Presiona Alt+Z para detener)")

    def stop_recording(self) -> str:
        """Detiene la grabación, guarda un archivo temporal y lo transcribe."""
        self.is_recording = False
        self.stream.stop()
        self.stream.close()
        
        if not self.recording_buffer:
            return ""

        # Concatenar el buffer de audio
        audio_data = np.concatenate(self.recording_buffer, axis=0)
        
        # Crear archivo temporal
        with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp_file:
            tmp_path = tmp_file.name
            
        try:
            # Guardar como WAV normalizando correctamente a 16-bit
            # Aseguramos que el audio esté en el rango [-1, 1] antes de convertir
            max_val = np.max(np.abs(audio_data))
            if max_val > 0:
                audio_data = audio_data / max_val # Normalización pico
            
            with wave.open(tmp_path, 'wb') as wf:
                wf.setnchannels(self.channels)
                wf.setsampwidth(2) # 16-bit
                wf.setframerate(self.sample_rate)
                wf.writeframes((audio_data * 32767).astype(np.int16).tobytes())

            # Transcribir forzando el idioma español
            segments, info = self.model.transcribe(tmp_path, beam_size=5, language='es')
            text = " ".join([segment.text for segment in segments]).strip()
            
            return text
        finally:
            if os.path.exists(tmp_path):
                os.remove(tmp_path)

    def transcribe_text(self, text: str) -> None:
        """Helper para debugging."""
        print(f"[USER]: {text}")

import os
import wave
import numpy as np
import sounddevice as sd
from faster_whisper import WhisperModel
from typing import Optional
import tempfile
import threading
import queue

class AudioTranscriber:
    """Módulo de transcripción optimizado con procesamiento en hilos (pseudo-streaming)."""
    
    def __init__(self, model_size: str = "tiny", device: str = "cpu", compute_type: str = "float32", input_device: Optional[int] = None, language: Optional[str] = None):
        self.input_device = input_device
        self.language = language
        print(f"[INIT] Cargando modelo Whisper '{model_size}'...")
        self.model = WhisperModel(model_size, device=device, compute_type=compute_type)
        print("[INIT] Modelo Whisper cargado.")
        
        self.sample_rate = 16000
        self.channels = 1
        self.is_recording = False
        
        # Buffer de audio completo
        self.audio_buffer = []
        
        # Para el futuro: transcripción asíncrona por chunks
        self.chunk_queue = queue.Queue()
        self.full_text = ""

    def start_recording(self) -> None:
        self.is_recording = True
        self.audio_buffer = []
        
        def callback(indata, frames, time, status):
            if self.is_recording:
                self.audio_buffer.append(indata.copy())

        self.stream = sd.InputStream(
            samplerate=self.sample_rate,
            channels=self.channels,
            callback=callback,
            dtype='float32',
            device=self.input_device
        )
        self.stream.start()
        print("\n[REC] Escuchando...")

    def stop_recording(self) -> str:
        self.is_recording = False
        if hasattr(self, 'stream'):
            self.stream.stop()
            self.stream.close()
        
        if not self.audio_buffer:
            return ""

        # Concatenar todo el audio capturado
        audio_data = np.concatenate(self.audio_buffer, axis=0)
        
        # Normalización y guardado temporal para Whisper
        with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp_file:
            tmp_path = tmp_file.name
            
        try:
            max_val = np.max(np.abs(audio_data))
            if max_val > 0:
                audio_data = audio_data / max_val
            
            with wave.open(tmp_path, 'wb') as wf:
                wf.setnchannels(self.channels)
                wf.setsampwidth(2)
                wf.setframerate(self.sample_rate)
                wf.writeframes((audio_data * 32767).astype(np.int16).tobytes())

            # Transcribir el audio completo
            segments, info = self.model.transcribe(tmp_path, beam_size=5, language=self.language)
            text = " ".join([segment.text for segment in segments]).strip()
            return text
        finally:
            if os.path.exists(tmp_path):
                os.remove(tmp_path)

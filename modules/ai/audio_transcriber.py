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
    """
    Abstracción de alto nivel para la captura y procesamiento de audio.
    Utiliza un buffer circular y el motor 'faster-whisper' para transformar voz en texto
    con baja latencia y alta precisión.
    """
    
    def __init__(self, model_size: str = "tiny", device: str = "cpu", compute_type: str = "float32", input_device: Optional[int] = None, language: Optional[str] = None):
        self.input_device = input_device
        self.language = language
        
        # El modelo se carga en el __init__ para minimizar la latencia en la primera interacción
        self.model = WhisperModel(model_size, device=device, compute_type=compute_type)
        
        # Configuración estándar para compatibilidad con Whisper (16kHz, mono)
        self.sample_rate = 16000
        self.channels = 1
        self.is_recording = False
        
        self.audio_buffer = []
        
        # Preparación para futuras implementaciones de streaming asíncrono
        self.chunk_queue = queue.Queue()
        self.full_text = ""

    def start_recording(self) -> None:
        """Inicializa el flujo de entrada de audio y comienza el buffering en memoria."""
        self.is_recording = True
        self.audio_buffer = []
        
        def callback(indata, frames, time, status):
            """Callback del stream de sounddevice ejecutado en el hilo de audio."""
            if self.is_recording:
                # Copia profunda de los datos para evitar race conditions
                self.audio_buffer.append(indata.copy())

        # Configuración del flujo de entrada
        self.stream = sd.InputStream(
            samplerate=self.sample_rate,
            channels=self.channels,
            callback=callback,
            dtype='float32',
            device=self.input_device
        )
        self.stream.start()

    def stop_recording(self) -> str:
        """Detiene la captura, exporta a PCM temporal y ejecuta la inferencia del modelo."""
        self.is_recording = False
        if hasattr(self, 'stream'):
            self.stream.stop()
            self.stream.close()
        
        if not self.audio_buffer:
            return ""

        # Consolidación del buffer de hilos en un array monolítico de numpy
        audio_data = np.concatenate(self.audio_buffer, axis=0)
        
        # Persistencia temporal en disco para el procesamiento del motor Whisper
        with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp_file:
            tmp_path = tmp_file.name
            
        try:
            # Normalización del audio para mejorar el ratio señal-ruido en la inferencia
            max_val = np.max(np.abs(audio_data))
            if max_val > 0:
                audio_data = audio_data / max_val
            
            # Exportación a formato WAVE S16_LE (Standard para STT)
            with wave.open(tmp_path, 'wb') as wf:
                wf.setnchannels(self.channels)
                wf.setsampwidth(2) # 16 bits por muestra
                wf.setframerate(self.sample_rate)
                wf.writeframes((audio_data * 32767).astype(np.int16).tobytes())

            # Ejecución del motor de inferencia
            # beam_size=5 es un buen compromiso entre precisión y velocidad de procesamiento
            segments, info = self.model.transcribe(tmp_path, beam_size=5, language=self.language)
            text = " ".join([segment.text for segment in segments]).strip()
            return text
        finally:
            # Aseguramos la limpieza del recurso temporal independientemente del éxito de la inferencia
            if os.path.exists(tmp_path):
                os.remove(tmp_path)

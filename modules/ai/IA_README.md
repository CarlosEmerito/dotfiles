# EmeBotEme

EmeBotEme es un asistente de voz local para Linux que actúa como puente entre tu voz y un agente CLI de IA (como OpenCode).

## Características

- **Transcripción Local:** Usa `faster-whisper` para procesar voz a texto sin salir de tu máquina.
- **Sesión Persistente:** Mantiene una sesión interactiva abierta con el agente CLI, conservando el contexto.
- **Atajo Global:** Controla la grabación con `Alt + Z`.
- **Salida en Tiempo Real:** Visualiza las respuestas del agente conforme se generan.

## Requisitos Previos

- Python 3.8+
- Bibliotecas del sistema para audio (ej. `libportaudio2` en Debian/Ubuntu):
  ```bash
  sudo apt-get install libportaudio2
  ```

## Instalación

1. Clona el repositorio:
   ```bash
   git clone https://github.com/tu-usuario/EmeBotEme.git
   cd EmeBotEme
   ```

2. Instala las dependencias:
   ```bash
   pip install -r requirements.txt
   ```

## Configuración

En `agent_bridge.py`, puedes modificar el comando del agente CLI en el parámetro `command`. Por defecto utiliza `opencode interact` como placeholder.

## Uso

Ejecuta el script principal:
```bash
python main.py
```

- **Alt + Z:** Presiona una vez para empezar a grabar.
- **Alt + Z:** Presiona de nuevo para detener la grabación y procesar el comando.
- **Ctrl + C:** Salir de la aplicación de forma segura.

## Arquitectura

- `main.py`: Orquestador y manejo de teclado.
- `audio_transcriber.py`: Captura de audio y STT con Whisper.
- `agent_bridge.py`: Manejo del subproceso y comunicación asíncrona.

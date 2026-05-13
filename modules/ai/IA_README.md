# EmeBotEme v2.0 - Asistente de Voz Inteligente

EmeBotEme es un asistente de voz local avanzado para Linux (especialmente optimizado para Hyprland) que actúa como puente entre tu voz y un agente CLI de IA (OpenCode).

## 🚀 Características Principales

- **Persistencia con TMUX:** Mantiene el contexto de la conversación. La IA recuerda comandos anteriores gracias a una sesión persistente en segundo plano.
- **Hotplug de Teclados:** Gracias a `pyudev`, detecta automáticamente nuevos teclados (USB/Bluetooth) sin reiniciar el servicio.
- **Transcripción de Alta Velocidad:** Optimizado con `faster-whisper` para procesar comandos casi instantáneamente.
- **Logging Profesional:** Integrado con el sistema de logs de Python para una depuración sencilla mediante `journalctl`.
- **Interfaz Limpia:** Filtrado de mensajes internos de herramientas y control total de la visibilidad en terminal.

## 🛠️ Requisitos del Sistema

- **TMUX:** Necesario para la persistencia (`sudo pacman -S tmux`).
- **Kitty:** Emulador de terminal utilizado para las ventanas flotantes.
- **Python 3.10+**

## 📦 Instalación de Dependencias Python

```bash
pip install -r requirements.txt
```

## ⚙️ Configuración (`config.json`)

Puedes personalizar el comportamiento del bot en `modules/ai/config.json`:
- `keys`: Define las teclas de activación (por defecto `Super + Alt + Z`).
- `whisper`: Configura el modelo de transcripción, dispositivo (CPU/GPU) e idioma fijo (ej. `"es"`).
- `agent`: Define el comando del agente y su **System Prompt** (personalidad).

## ⌨️ Uso y Controles

1. El servicio se gestiona mediante Systemd: `systemctl --user status emeboteme.service`.
2. **Grabar:** Mantén pulsado `Super + Alt + Z` para hablar. La grabación es instantánea y silenciosa para mayor fluidez.
3. **Procesar:** Suelta las teclas para que EmeBotEme envíe el comando. Verás un indicador de `󰚩 Pensando...` en morado.
4. **Interrumpir/Cerrar:** Pulsa la tecla `Esc` en cualquier momento para detener la respuesta de la IA y cerrar la ventana automáticamente.
5. **Salir:** Al finalizar una respuesta, pulsa cualquier tecla para cerrar la ventana.

## 🏗️ Arquitectura

- `main.py`: Orquestador principal con soporte hotplug y monitorización de eventos. Implementa logging profesional.
- `agent_bridge.py`: Gestión de sesiones TMUX, ventanas de Kitty y filtrado de salida visual.
- `audio_transcriber.py`: Captura y transcripción local con Whisper (configurado en español).
- `config.json`: Configuración centralizada.

## 📝 Depuración

Para ver qué está pasando bajo el capó:
```bash
journalctl --user -u emeboteme.service -f
```

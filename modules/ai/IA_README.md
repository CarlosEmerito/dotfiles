# EmeBotEme v2.0 - Asistente Multimodal Inteligente

EmeBotEme es un asistente local multimodal (voz/texto/visión) para Linux (especialmente optimizado para Hyprland) que actúa como puente entre tu voz, texto o capturas de pantalla y un agente CLI de IA (OpenCode).

## 🚀 Características Principales

- **Sesiones Aisladas (Opencode):** Mantiene el contexto de la conversación de forma nativa. La IA recuerda comandos anteriores mediante una base de datos persistente aislada, sin interferir con tus terminales de trabajo.
- **Sin Dependencias de Terceros (No TMUX):** Arquitectura limpia que lanza ventanas de Kitty directamente, mejorando la velocidad y eliminando la necesidad de gestionar sesiones de shell ocultas.
- **Hotplug de Teclados:** Gracias a `pyudev`, detecta automáticamente nuevos teclados (USB/Bluetooth) sin reiniciar el servicio.
- **Transcripción de Alta Velocidad:** Optimizado con `faster-whisper` para procesar comandos casi instantáneamente.
- **Modo Visión:** Captura la pantalla con `grim` y permite hacer consultas contextuales sobre ella.
- **Entrada Multi-línea:** Editor de texto integrado con `prompt_toolkit` para consultas largas.
- **Gestión de Sesiones:** Permite reiniciar el contexto de la conversación sin reiniciar el servicio.
- **Logging Profesional:** Integrado con el sistema de logs de Python para una depuración sencilla mediante `journalctl`.

## 🛠️ Requisitos del Sistema

- **Opencode:** El motor de IA CLI para la gestión de tareas y respuestas.
- **Kitty:** Emulador de terminal utilizado para las ventanas flotantes.
- **Python 3.10+**

## 📦 Instalación de Dependencias Python

```bash
pip install -r requirements.txt
```

## ⚙️ Configuración (`config.json`)

Puedes personalizar el comportamiento del bot en `modules/ai/config.json`:
- `keys`: Define las teclas de activación. Triggers disponibles:
  - `trigger` (`Z`): Voz (Push-to-Talk).
  - `text_trigger` (`X`): Entrada de texto multi-línea.
  - `clear_session_trigger` (`C`): Reinicia el contexto de la sesión.
  - `screenshot_trigger` (`S`): Modo Visión (captura + consulta).
- `whisper`: Configura el modelo de transcripción, dispositivo (CPU/GPU) e idioma fijo (ej. `"es"`).
- `agent`: Define el comando del agente y su **System Prompt** (personalidad).

## ⌨️ Uso y Controles

1. El servicio se gestiona mediante Systemd: `systemctl --user status emeboteme.service`.
2. **Grabar Voz:** Mantén pulsado `Super + Alt + Z` para hablar. Suelta para procesar.
3. **Entrada de Texto:** Pulsa `Super + Alt + X` para abrir un editor multi-línea con `prompt_toolkit`. Atajos: `Ctrl+H` borra palabra, `Escape` cierra sin guardar.
4. **Modo Visión:** Pulsa `Super + Alt + S` para capturar la pantalla y abrir un prompt donde escribir tu consulta sobre la captura.
5. **Nueva Sesión:** Pulsa `Super + Alt + C` para reiniciar el contexto de la conversación.
6. **Interrumpir/Cerrar:** Pulsa `Esc` en cualquier momento para detener la respuesta de la IA y cerrar la ventana.
7. **Salir:** Al finalizar una respuesta, pulsa cualquier tecla para cerrar la ventana.

## 🏗️ Arquitectura

- `main.py`: Orquestador principal con soporte hotplug y monitorización de eventos. Incluye modos Voz, Texto y Visión.
- `agent_bridge.py`: Puente con Opencode: gestión de sesiones, ventanas de Kitty, y envío de comandos con soporte de imágenes.
- `audio_transcriber.py`: Captura y transcripción local con Whisper (configurado en español).
- `input_ui.py`: Interfaz de entrada de texto multi-línea usando `prompt_toolkit` con atajos de teclado personalizados.
- `config.json`: Configuración centralizada (teclas, whisper, agente).

## 📝 Depuración

Para ver qué está pasando bajo el capó:
```bash
journalctl --user -u emeboteme.service -f
```

# 🌌 EmeDotEme - Hyprland + AI Assistant Suite

[![Arch Linux](https://img.shields.io/badge/OS-Arch%20Linux-blue?logo=arch-linux&logoColor=white)](https://archlinux.org/)
[![Hyprland](https://img.shields.io/badge/Compositor-Hyprland-brightgreen)](https://hyprland.org/)
[![AI Assistant](https://img.shields.io/badge/AI-EmeBotEme-purple)](https://emedoteme.es)

Una suite completa de **Dotfiles** para Arch Linux diseñada para la productividad, la estética y la integración de Inteligencia Artificial mediante voz.

---

## ✨ Características Principales

*   **💻 Entorno Hyprland:** Layout dinámico, animaciones fluidas y estética moderna.
*   **🎙️ EmeBotEme AI:** Asistente de voz y texto integrado con modo **Visión** (captura de pantalla + consulta), entrada multi-línea, y gestión de sesiones.
*   **🐚 Shell Moderno:** **Starship** prompt minimalista (`~ ❯`), `eza` para listados con iconos y `bat` para lectura de archivos con resaltado.
*   **🚀 Instalador Inteligente:** Script `install.sh` que configura todo el entorno, desde paquetes base hasta servicios de IA.
*   **🎨 Estética Coherente:** Waybar con control de brillo nativo, SwayNC para notificaciones y temas GTK/Kitty integrados.

---

## 🤖 EmeBotEme: Tu Asistente Inteligente

EmeBotEme es un agente multimodal (voz/texto/visión) que vive en tu barra de tareas y se comunica con **Opencode**.

*   **Push-to-Talk:** Mantén pulsado `Super + Alt + Z` para hablar. Suelta para procesar.
*   **Entrada de Texto:** `Super + Alt + X` abre un editor multi-línea con `prompt_toolkit`.
*   **Modo Visión:** `Super + Alt + S` captura la pantalla con `grim` y abre un prompt para consultar sobre ella.
*   **Nueva Sesión:** `Super + Alt + C` reinicia el contexto de la conversación.
*   **Sesiones Aisladas:** Utiliza la persistencia nativa de Opencode para aislar el contexto de voz de tus terminales de trabajo.
*   **Arquitectura Limpia:** Sin dependencias de TMUX; lanza ventanas de Kitty directamente.
*   **Hotplug de Teclados:** Detección automática de hardware sin reiniciar.

---

## 🛠️ Requisitos

*   **Arch Linux** (funciona tanto en instalación limpia como sobre una ya existente; el instalador crea backups con fecha antes de reemplazar configuraciones locales).
*   **Opencode:** Motor de IA CLI para las respuestas. El instalador ofrece instalarlo si no lo encuentra.
*   **Waybar >= 0.16:** Necesario para que los clicks en los workspaces funcionen con Hyprland 0.57 en modo Lua. El instalador avisa y ofrece instalar la versión de `extra-testing` si solo hay 0.15.
*   **Hardware de Audio:** Micrófono funcional.
*   **Internet:** Para la descarga de modelos de IA (Whisper) y paquetes.
*   **Hugging Face Token:** Necesario para descargar los modelos de transcripción (gratuito en [huggingface.co](https://huggingface.co/settings/tokens)).

---

## 🚀 Instalación Rápida

```bash
# 1. Clonar el repositorio
git clone https://github.com/CarlosEmerito/dotfiles.git ~/dotfiles
cd ~/dotfiles

# 2. Dar permisos y ejecutar el instalador
chmod +x install.sh
./install.sh
```

El instalador te guiará a través de:
1.  Instalación de paquetes oficiales y AUR (`yay`).
2.  Configuración de enlaces simbólicos para `.config`.
3.  Elección del gestor de inicio (SDDM, Auto-login o Manual).
4.  Configuración de **EmeBotEme** (te pedirá tu token de Hugging Face).

---

## ⌨️ Atajos de Teclado (Keybinds)

| Tecla | Acción |
| :--- | :--- |
| `Super + Alt + Z` (Mantener) | **Hablar con EmeBotEme** |
| `Super + Alt + X` | **Entrada de texto** (EmeBotEme) |
| `Super + Alt + C` | **Nueva sesión** (EmeBotEme) |
| `Super + Alt + S` | **Modo Visión** (captura + consulta) |
| `Super + Q` / `Enter` | Abrir Terminal (Kitty) |
| `Super + Space` | Lanzador de Apps (Rofi) |
| `Super + E` | Explorador de Archivos (Nautilus) |
| `Super + F` | Navegador (Google Chrome) |
| `Super + N` | Centro de Notificaciones |
| `Super + C` | Cerrar Ventana |
| `Print` | Captura de Pantalla |
| `Super + Shift + S` | Captura de Área (Portapapeles) |

---

## 📁 Estructura del Proyecto

*   `config/`: Configuraciones de Hyprland, Waybar, Kitty, Rofi, Starship, etc.
*   `modules/ai/`: Núcleo del asistente EmeBotEme (Python + Systemd). Incluye `input_ui.py` (entrada de texto con `prompt_toolkit`).
*   `core/scripts/`: Scripts auxiliares (focus listener, capturas, etc.).
*   `core/services/`: Servicios systemd (emeboteme.service).
*   `install.sh`: El cerebro de la instalación.

---

## ⚠️ Notas Importantes

*   **Instalador y backups:** si ya existe `~/.config/hypr`, `~/.config/waybar`, `~/.zshrc`, etc., el instalador pregunta antes de reemplazar y crea copias `.bak.AAAA-MM-DD-HHMMSS`. Responder `n` conserva la configuración local. No borra directorios sin confirmación.
*   **GPU:** El repo trae activadas las variables de NVIDIA (`LIBVA_DRIVER_NAME=nvidia`, `__GLX_VENDOR_LIBRARY_NAME=nvidia`, `NVD_BACKEND=direct`). El instalador pregunta por tu GPU y descomenta solo el bloque correspondiente (Intel, NVIDIA o AMD) en `config/hypr/envvariables.lua`. Después de cambiar de GPU, reinicia la sesión para que las apps nuevas hereden las variables.
*   **Hyprland:** la configuración usa Lua (`config/hypr/*.lua`) desde Hyprland 0.55+ (probado con 0.57). Los antiguos `.conf` están en `config/hypr/legacy/` solo como referencia y **ya no se cargan**.
*   **nwg-displays:** guarda `monitors.lua` y `workspaces.lua` (además de los `.conf` de compatibilidad). Hyprland carga los `.lua`; editar los `.conf` no aplica cambios. `workspaces.lua` se carga con `require("workspaces")`.
*   **Monitores:** `config/hypr/monitors.lua` está generado para los puertos `eDP-1` y `HDMI-A-1` de este equipo. En otro hardware, abre `nwg-displays` y aplica la disposición para regenerarlo.
*   **Waybar:** con Hyprland 0.57 (Lua) se necesita **Waybar >= 0.16**. Waybar 0.15.x sigue enviando `dispatch workspace N` por IPC y los clicks en los workspaces no hacen nada; Waybar 0.16 traduce esos dispatchers a `hl.dsp.*`.
*   **Modo Visión:** Requiere `grim` y `slurp` para captura de pantalla. La imagen se pasa al agente Opencode para su análisis.
*   **Entrada de Texto:** Usa `prompt_toolkit` con atajos: `Ctrl+H` borra palabra completa, `Escape` cierra sin guardar.
*   **Starship:** El prompt es minimalista (`~ ❯`). La configuración está en `config/starship/starship.toml`. El instalador crea symlinks tanto en `~/.config/starship.toml` como en `~/.config/starship/` para cubrir ambos paths de búsqueda.
*   **IA:** La primera vez que uses la voz, EmeBotEme descargará el modelo de Whisper (~75MB).
*   **Dependencias IA:** El instalador incluye `pyudev` para la detección hotplug de teclados. Si el servicio `emeboteme.service` falla, verifica que todas las dependencias de `modules/ai/requirements.txt` estén instaladas (`pip install -r modules/ai/requirements.txt`).
*   **Seguridad:** El token de Hugging Face se guarda en `~/.config/emeboteme/.env` con permisos `600` y no debe compartirse. `~/.config/pulse` es estado local y no se enlaza al repo.

---

## 🤝 Contribuciones

Si tienes ideas para mejorar la integración de la IA o los dotfiles, ¡los Pull Requests son bienvenidos!

---

**Desarrollado con ❤️ por Emerito.**

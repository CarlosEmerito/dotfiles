# 🌌 EmeDotEme - Hyprland + AI Assistant Suite

[![Arch Linux](https://img.shields.io/badge/OS-Arch%20Linux-blue?logo=arch-linux&logoColor=white)](https://archlinux.org/)
[![Hyprland](https://img.shields.io/badge/Compositor-Hyprland-brightgreen)](https://hyprland.org/)
[![AI Assistant](https://img.shields.io/badge/AI-EmeBotEme-purple)](https://emedoteme.es)

Una suite completa de **Dotfiles** para Arch Linux diseñada para la productividad, la estética y la integración de Inteligencia Artificial mediante voz.

---

## ✨ Características Principales

*   **💻 Entorno Hyprland:** Layout dinámico, animaciones fluidas y estética moderna.
*   **🎙️ EmeBotEme AI:** Asistente de voz integrado que ejecuta comandos, abre aplicaciones y resuelve dudas mediante IA.
*   **🐚 Shell Moderno:** Integración con **Starship**, `eza` para listados con iconos y `bat` para lectura de archivos con resaltado.
*   **🚀 Instalador Inteligente:** Script `install.sh` que configura todo el entorno, desde paquetes base hasta servicios de IA.
*   **🎨 Estética Coherente:** Waybar con control de brillo nativo, SwayNC para notificaciones y temas GTK/Kitty integrados.

---

## 🤖 EmeBotEme: Tu Asistente de Voz

EmeBotEme es un agente de voz desacoplado que vive en tu barra de tareas y se comunica con **Opencode**.

*   **Push-to-Talk:** Mantén pulsado `Super + Alt + Z` para hablar. Suelta para procesar.
*   **Sesiones Aisladas:** Utiliza la persistencia nativa de Opencode para aislar el contexto de voz de tus terminales de trabajo.
*   **Arquitectura Limpia:** Sin dependencias de TMUX; lanza ventanas de Kitty directamente.
*   **Hotplug de Teclados:** Detección automática de hardware sin reiniciar.

---

## 🛠️ Requisitos

*   **Arch Linux** (Instalación limpia recomendada).
*   **Opencode:** Motor de IA CLI para las respuestas.
*   **Hardware de Audio:** Micrófono funcional.
*   **Internet:** Para la descarga de modelos de IA (Whisper) y paquetes.
*   **Hugging Face Token:** Necesario para descargar los modelos de transcripción (gratuito en [huggingface.co](https://huggingface.co/settings/tokens)).

---

## 🚀 Instalación Rápida

```bash
# 1. Clonar el repositorio
git clone https://github.com/emerito/dotfiles.git ~/dotfiles
cd ~/dotfiles

# 2. Dar permisos y ejecutar el instalador
chmod +x core/scripts/install.sh
./core/scripts/install.sh
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

*   `.config/`: Configuraciones de Hyprland, Waybar, Kitty, etc.
*   `EmeBotEme/`: Núcleo del asistente de voz (Python + Systemd).
*   `install.sh`: El cerebro de la instalación.
*   `setup-autologin.sh`: Utilidad para login sin contraseña en TTY1.

---

## ⚠️ Notas Importantes

*   **Optimización:** La barra Waybar ahora usa el módulo de brillo nativo, lo que reduce el consumo de CPU al eliminar el script de monitoreo continuo.
*   **IA:** La primera vez que uses la voz, EmeBotEme descargará el modelo de Whisper (~75MB). Se recomienda usar el modelo `opencode/deepseek-v4-flash-free` si tus créditos de Hugging Face son limitados.
*   **Seguridad:** El token de Hugging Face se guarda localmente en `~/dotfiles/.env` y no debe compartirse.

---

## 🤝 Contribuciones

Si tienes ideas para mejorar la integración de la IA o los dotfiles, ¡los Pull Requests son bienvenidos!

---

**Desarrollado con ❤️ por Emerito.**

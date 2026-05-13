# 🌌 EmeDotEme - Hyprland + AI Assistant Suite

[![Arch Linux](https://img.shields.io/badge/OS-Arch%20Linux-blue?logo=arch-linux&logoColor=white)](https://archlinux.org/)
[![Hyprland](https://img.shields.io/badge/Compositor-Hyprland-brightgreen)](https://hyprland.org/)
[![AI Assistant](https://img.shields.io/badge/AI-EmeBotEme-purple)](https://github.com/emerito/dotfiles)

Una suite completa de **Dotfiles** para Arch Linux diseñada para la productividad, la estética y la integración de Inteligencia Artificial mediante voz.

---

## ✨ Características Principales

*   **💻 Entorno Hyprland:** Layout dinámico, animaciones fluidas y estética moderna.
*   **🎙️ EmeBotEme AI:** Asistente de voz integrado que ejecuta comandos, abre aplicaciones y resuelve dudas mediante IA.
*   **🚀 Instalador Inteligente:** Script `install.sh` que configura todo el entorno, desde paquetes base hasta servicios de IA.
*   **🎨 Estética Coherente:** Waybar personalizada, SwayNC para notificaciones y temas GTK/Kitty integrados.
*   **⌨️ Flujo de Trabajo Eficiente:** Atajos de teclado optimizados y modo "Push-to-Talk" para la IA.

---

## 🤖 EmeBotEme: Tu Asistente de Voz

EmeBotEme no es solo un script; es un agente de voz desacoplado que vive en tu barra de tareas.

*   **Push-to-Talk:** Mantén pulsado `Super + Alt + Z` para hablar. Suelta para procesar.
*   **Persistencia (TMUX):** Mantiene la memoria de la conversación entre comandos.
*   **Hotplug de Teclados:** Detección automática de hardware sin reiniciar.
*   **Feedback de Voz (TTS):** Confirmaciones audibles del estado del asistente.

---

## 🛠️ Requisitos

*   **Arch Linux** (Instalación limpia recomendada).
*   **TMUX:** Necesario para la persistencia del asistente.
*   **Piper TTS:** Para las notificaciones de voz.
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

*   **Hardware:** Las rutas de sensores en `waybar/config` (temperatura/brillo) están optimizadas para laptops. Si usas sobremesa, revisa la sección `custom/brightness` y `temperature`.
*   **IA:** La primera vez que uses la voz, EmeBotEme descargará el modelo de Whisper (~75MB). Sé paciente en el primer arranque.
*   **Seguridad:** El token de Hugging Face se guarda localmente en `~/dotfiles/.env` y no debe compartirse.

---

## 🤝 Contribuciones

Si tienes ideas para mejorar la integración de la IA o los dotfiles, ¡los Pull Requests son bienvenidos!

---

**Desarrollado con ❤️ por Emerito.**

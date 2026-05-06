# Dotfiles - Arch Linux + Hyprland

Configuración personalizada para Arch Linux con Hyprland y entorno gráfico moderno.

## Componentes

| Componente | Descripción |
|------------|-------------|
| **Hyprland** | Compositor Wayland (dynamic tiling) |
| **Waybar** | Barra de estado personalizable |
| **Rofi** | Launcher de aplicaciones |
| **Kitty** | Emulador de terminal GPU-acelerado |
| **SwayNC** | Centro de notificaciones |
| **Nautilus** | Gestor de archivos |
| **Google Chrome** | Navegador web |
| **nwg-displays** | Configurador de monitores para Wayland |

## Requisitos previos

- Arch Linux base instalado
- Usuario con privilegios sudo
- Conexión a internet

## Instalación

1. Clonar el repositorio:
```bash
git clone https://github.com/TU_USUARIO/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

2. Ejecutar el script de instalación:
```bash
chmod +x install.sh
./install.sh
```

**Nota:** Durante la instalación se te preguntará cómo quieres iniciar Hyprland:
- **Opción 1 (SDDM):** Display manager gráfico con login tradicional
- **Opción 2 (Auto-login):** Entra directo sin contraseña (configura `setup-autologin.sh`)
- **Opción 3:** Inicio manual ejecutando `Hyprland` desde TTY

3. Reiniciar el sistema:
```bash
reboot
```

## Paquetes que se instalan

### Oficiales (pacman)
- hyprland, hyprcursor, hyprlang, hyprutils, hyprgraphics, hyprwayland-scanner
- waybar, rofi, kitty
- nautilus, grim, slurp
- brightnessctl, playerctl
- pipewire, pipewire-pulse, pipewire-alsa, pipewire-jack, wireplumber
- papirus-icon-theme, ttf-jetbrains-mono-nerd, ttf-font-awesome
- inotify-tools, power-profiles-daemon
- networkmanager, bluez, bluez-utils
- xdg-desktop-portal-hyprland, polkit-gnome, dunst

### AUR (yay)
- google-chrome
- swaync
- libnotify
- nwg-displays

## Atajos de teclado principales

| Atajo | Acción |
|-------|--------|
| `Super + Q` / `Super + Return` | Abrir terminal (Kitty) |
| `Super + E` | Abrir gestor de archivos (Nautilus) |
| `Super + Space` | Abrir launcher (Rofi) |
| `Super + F` | Abrir Google Chrome |
| `Super + N` | Notificaciones (SwayNC) |
| `Super + C` / `Alt + F4` | Cerrar ventana activa |
| `Super + M` | Salir de Hyprland |
| `Print` | Captura de pantalla completa |
| `Super + Shift + S` | Capturar área al portapapeles |
| `Super + Print` | Capturar área y guardar |

## Estructura del repositorio

```
dotfiles/
├── .config/
│   ├── hypr/           # Configuración de Hyprland
│   ├── waybar/         # Configuración de Waybar
│   ├── rofi/           # Configuración de Rofi
│   ├── swaync/         # Configuración de SwayNC
│   ├── kitty/          # Configuración de Kitty
│   ├── nwg-displays/   # Configuración de nwg-displays
│   ├── gtk-3.0/        # Temas GTK3
│   ├── gtk-4.0/        # Temas GTK4
│   └── pulse/          # Configuración de PulseAudio
├── install.sh          # Script de instalación
└── README.md
```

## Notas

- El layout de teclado está configurado en español (`es`)
- Se configura automáticamente el soporte para Wayland en apps Qt, GTK, SDL y Electron
- Se ofrecen 3 opciones para iniciar Hyprland: SDDM, Auto-login o manual
- El script `setup-autologin.sh` configura auto-login sin contraseña (solo usar si confías en la seguridad física de tu PC)
- **Importante:** Las rutas en `waybar/config` para sensores de temperatura (`/sys/class/hwmon/hwmon1`) y brillo (`/sys/class/backlight/intel_backlight`) pueden variar según el hardware. Ajustar si es necesario.

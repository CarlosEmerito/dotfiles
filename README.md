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
│   ├── gtk-3.0/        # Temas GTK3
│   ├── gtk-4.0/        # Temas GTK4
│   └── pulse/          # Configuración de PulseAudio
├── install.sh          # Script de instalación
└── README.md
```

## Notas

- El layout de teclado está configurado en español (`es`)
- Se configura automáticamente el soporte para Wayland en apps Qt, GTK, SDL y Electron
- Se instala SDDM opcionalmente como display manager
- Sin SDDM, puedes iniciar Hyprland ejecutando `Hyprland` desde una TTY

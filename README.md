# Dotfiles

Configuración personal para **Arch Linux** con **Hyprland** (Wayland).

![Hyprland](.assets/preview.png)

## Requisitos

- Arch Linux (o derivado)
- Wayland
- Sistema base instalado

## Instalación rápida

```bash
# Clonar e instalar todo
git clone https://github.com/CarlosEmerito/dotfiles.git
cd dotfiles
./install.sh
```

## Uso del instalador

```bash
# Opciones desde línea de comandos
./install.sh --all          # Instalar todo
./install.sh --basic        # Solo básico
./install.sh --desktop      # Desktop + drivers
./install.sh --gaming       # Steam + multilib
./install.sh --dev          # Desarrollo + AUR
./install.sh --configs      # Solo configuraciones

# O menú interactivo
./install.sh
```

## Estructura

```
dotfiles/
├── install.sh              # Script de instalación
├── README.md              # Este archivo
├── scripts/               # Scripts útiles
│   ├── screenshot.sh      # Capturas de pantalla
│   ├── record.sh          # Grabación de pantalla
│   ├── random-wallpaper.sh # Wallpaper aleatorio
│   └── update-dotfiles.sh # Actualizar dotfiles
├── wallpapers/           # Wallpapers
└── .config/
    ├── hypr/              # Hyprland
    ├── rofi/              # Rofi launcher
    ├── waybar/            # Waybar
    ├── kitty/             # Terminal
    ├── btop/              # Monitor sistema
    └── nvim/              # Neovim
```

## Atajos de teclado

### General

| Atajo | Acción |
|-------|--------|
| `Super + Return` | Abrir terminal (Kitty) |
| `Super + Q` | Cerrar ventana |
| `Super + M` | Apagar equipo |
| `Super + Shift + Q` | Reiniciar/Cerrar sesión |
| `Alt + F4` | Cerrar ventana |

### Launcher

| Atajo | Acción |
|-------|--------|
| `Super + Espacio` | Abrir Rofi (launcher apps) |
| `Super + R` | Abrir Rofi |

### Ventanas

| Atajo | Acción |
|-------|--------|
| `Super + F` | Abrir navegador (Chrome) |
| `Super + E` | Abrir gestor archivos (Dolphin) |
| `Super + V` | Ventana flotante |
| `Super + P` | Pseudotile |
| `Super + J` | Dividir orientación |

### Workspaces

| Atajo | Acción |
|-------|--------|
| `Super + 1-0` | Ir a workspace 1-10 |
| `Super + Scroll` | Siguiente workspace |
| `Super + Click` | Mover a workspace |

### Audio

| Atajo | Acción |
|-------|--------|
| `Super + +` | Subir volumen |
| `Super + -` | Bajar volumen |
| `Super + M` | Silenciar |

### Brillo

| Atajo | Acción |
|-------|--------|
| `Super + Up` | Subir brillo |
| `Super + Down` | Bajar brillo |

### Multimedia

| Atajo | Acción |
|-------|--------|
| `Super + N` | Siguiente canción |
| `Super + B` | Play/Pausa |
| `Super + P` | Canción anterior |

## Solución de problemas

### La sesión no inicia

1. Revisa los logs:
```bash
journalctl -xe | tail -50
hyprctl version
```

2. Verifica que los paquetes estén instalados:
```bash
pacman -Q hyprland rofi waybar
```

3. Prueba iniciar desde TTY:
```bash
Hyprland
```

### Rofi no funciona

```bash
# Reiniciar Rofi
pkill rofi
rofi -show drun
```

### Waybar no aparece

```bash
# Reiniciar waybar
pkill waybar
waybar &
```

### Problemas con Steam

```bash
# Verificar multilib
grep "multilib" /etc/pacman.conf

# Instalar drivers NVIDIA si aplica
sudo pacman -S nvidia-utils lib32-nvidia-utils
```

### Sonido no funciona

```bash
# Verificar PipeWire
pactl info

# Reiniciar audio
pkill -9 wireplumber
wireplumber &
```

### Pantalla negra tras iniciar

1. Cambia a TTY: `Ctrl + Alt + F2`
2. Elimina config problemática:
```bash
rm ~/.config/hypr/hyprland.conf
cp ~/dotfiles/.config/hypr/hyprland.conf ~/.config/hypr/
```

## Scripts

### Captura de pantalla
```bash
./scripts/screenshot.sh          # Selección
./scripts/screenshot.sh full     # Área
./scripts/screenshot.sh screen  # Pantalla completa
```

### Grabar pantalla
```bash
./record.sh start   # Iniciar
./record.sh stop   # Detener
./record.sh status # Estado
```

### Wallpaper aleatorio
```bash
./scripts/random-wallpaper.sh
```

## Temas incluidos

### Rofi - Modern Neon Dark
- Fondo: #0a0a14
- Acento: #00ffd2 (cyan neón)
- Fuente: CommitMono Nerd Font

### Waybar - Catppuccin
- Tema oscuro moderno
- Módulos: workspaces, window, clock, audio, red, batería

### Kitty
- Tema Catppuccin Mocha
- Fuente: CommitMono Nerd Font

## Personalización

### Cambiar idioma del teclado
Edita `~/.config/hypr/hyprland.conf`:
```conf
input {
    kb_layout = es
}
```

### Cambiar resolución
```conf
monitor=,preferred,auto,auto
# o
monitor=DP-1,2560x1440@144,0x0,1
```

### Añadir atajo personalizado
```conf
bind = Super, Key, exec, comando
```

## Actualización

```bash
cd ~/dotfiles
git pull origin master
./install.sh --configs
```

O usa el script:
```bash
./scripts/update-dotfiles.sh
```

## Desinstalación

```bash
./install.sh
# Opción 5) Desinstalar configs
```

O manualmente:
```bash
rm -rf ~/.config/hypr ~/.config/rofi ~/.config/waybar
```

## Contributing

¡Siéntete libre de hacer fork y enviar PRs!

## Autor

**Carlos Emerito**
- GitHub: [@CarlosEmerito](https://github.com/CarlosEmerito)

## Licencia

MIT License - Ver [LICENSE](LICENSE)

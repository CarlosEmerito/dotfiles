# Dotfiles

Configuración personal para **Arch Linux** con **Hyprland**.

## Screenshots

![Rofi Launcher](.assets/rofi.png)

## Características

- **WM**: Hyprland (Wayland)
- **Launcher**: Rofi con tema personalizado
- **Terminal**: Kitty
- **Gestor de archivos**: Dolphin
- **Barra**: Waybar
- **Gaming**: Steam

## Requisitos

- Arch Linux (o derivado)
- Wayland

## Instalación

```bash
# Clonar el repositorio
git clone https://github.com/CarlosEmerito/dotfiles.git
cd dotfiles

# Ejecutar instalador
./install.sh
```

## Atajos de teclado

| Atajo | Acción |
|-------|--------|
| `Super + Espacio` | Abrir launcher de apps |
| `Super + Return` | Abrir terminal |
| `Super + Q` | Cerrar ventana |
| `Super + F` | Abrir Chrome |
| `Super + E` | Abrir Dolphin |
| `Super + M` | Apagar equipo |
| `Super + 1-0` | Cambiar workspace |
| `Super + Scroll` | Cambiar workspace |

## Estructura

```
dotfiles/
├── install.sh              # Script de instalación
├── README.md               # Este archivo
└── .config/
    ├── hypr/
    │   └── hyprland.conf   # Config de Hyprland
    ├── rofi/
    │   └── themes/
    │       └── mytheme.rasi # Tema de Rofi
    └── kitty/
        └── kitty.conf       # Config de Kitty
```

## Tema Rofi

Tema personalizado tipo "Neon Dark" con:
- Fondo oscuro (#0a0a14)
- Acento cyan neón (#00ffd2)
- Bordes redondeados
- Letra: CommitMono Nerd Font

## Autor

Carlos Emerito

## Licencia

MIT

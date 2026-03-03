# Hyprland Dotfiles

My Hyprland configuration for Arch Linux.

## Installation

```bash
git clone https://github.com/CarlosEmerito/dotfiles.git
cd dotfiles
./install.sh
```

## Update

```bash
./update.sh
```

## Copy only configs

```bash
./copy.sh
```

## Keybinds

| Key | Action |
|-----|--------|
| Super + Space | App launcher (Rofi) |
| Super + Return | Terminal (Kitty) |
| Super + Q | Close window |
| Super + E | File manager (Dolphin) |
| Super + F | Browser |
| Super + M | Shutdown |
| Super + 1-0 | Workspaces |
| Super + V | Floating window |
| Super + P | Pseudo tile |
| Super + Scroll | Next/prev workspace |

### Volume & Brightness

| Key | Action |
|-----|--------|
| Super + Plus | Volume up |
| Super + Minus | Volume down |
| Super + M | Mute |
| Super + Up | Brightness up |
| Super + Down | Brightness down |

## What's included

- **WM**: Hyprland
- **Launcher**: Rofi (Super + Space)
- **Terminal**: Kitty
- **File Manager**: Dolphin
- **Status Bar**: Waybar
- **System Monitor**: btop

## Requirements

- Arch Linux (or derivative)
- Hyprland installed

## Structure

```
dotfiles/
├── install.sh      # Install packages and configs
├── copy.sh         # Copy configs only
├── update.sh       # Update from git
├── config/         # Configuration files
│   ├── hypr/       # Hyprland config
│   ├── rofi/       # Rofi theme
│   ├── waybar/     # Status bar
│   ├── kitty/      # Terminal
│   ├── btop/       # System monitor
│   └── nvim/       # Editor
├── scripts/        # Useful scripts
└── wallpapers/     # Wallpapers
```

## Credits

Based on [JaKooLit/Hyprland-Dots](https://github.com/JaKooLit/Hyprland-Dots)

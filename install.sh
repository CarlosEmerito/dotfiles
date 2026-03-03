#!/usr/bin/env bash
set -e

echo "==================================="
echo "  Dotfiles Installer"
echo "  Arch Linux + Hyprland"
echo "==================================="
echo ""

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Detectar si es Arch Linux
if [[ ! -f /etc/arch-release ]]; then
    echo -e "${RED}Este script está diseñado para Arch Linux${NC}"
    exit 1
fi

echo -e "${YELLOW}[1/5] Instalando paquetes...${NC}"
sudo pacman -S --noconfirm \
    rofi \
    kitty \
    dolphin \
    waybar \
    steam \
    brightnessctl \
    playerctl \
    polkit \
    2>/dev/null || true

echo -e "${YELLOW}[2/5] Habilitando multilib (para Steam)...${NC}"
if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
    echo -e "${YELLOW}    Añadiendo multilib a pacman.conf...${NC}"
    sudo sed -i '/^\[multilib\]$/d; s/^# \[multilib\]$/[multilib]/' /etc/pacman.conf
    sudo sed -i '/^Include = \/etc\/pacman.d\/mirrorlist$/d; /^\[multilib\]$/a Include = /etc/pacman.d/mirrorlist' /etc/pacman.conf
    sudo pacman -Sy --noconfirm
fi

echo -e "${YELLOW}[3/5] Creando directorio de configuración...${NC}"
mkdir -p "$HOME/.config/hypr"
mkdir -p "$HOME/.config/rofi/themes"
mkdir -p "$HOME/.config/kitty"

echo -e "${YELLOW}[4/5] Instalando configuraciones...${NC}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Hyprland
if [[ -f "$SCRIPT_DIR/.config/hypr/hyprland.conf" ]]; then
    cp "$SCRIPT_DIR/.config/hypr/hyprland.conf" "$HOME/.config/hypr/"
    echo -e "    ${GREEN}✓${NC} Hyprland configurado"
fi

# Rofi
if [[ -f "$SCRIPT_DIR/.config/rofi/themes/mytheme.rasi" ]]; then
    cp "$SCRIPT_DIR/.config/rofi/themes/mytheme.rasi" "$HOME/.config/rofi/themes/"
    echo -e "    ${GREEN}✓${NC} Rofi configurado"
fi

# Kitty
if [[ -f "$SCRIPT_DIR/.config/kitty/kitty.conf" ]]; then
    cp "$SCRIPT_DIR/.config/kitty/kitty.conf" "$HOME/.config/kitty/"
    echo -e "    ${GREEN}✓${NC} Kitty configurado"
fi

echo -e "${YELLOW}[5/5] Permisos de ejecución...${NC}"
chmod +x "$SCRIPT_DIR/install.sh"

echo ""
echo -e "${GREEN}==================================="
echo "  ¡Instalación completada!"
echo "===================================${NC}"
echo ""
echo "Reinicia Hyprland: Super + Shift + Q"
echo "Para lanzar el launcher: Super + Espacio"
echo ""

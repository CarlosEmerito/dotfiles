#!/usr/bin/env bash
# Hyprland Dotfiles Installer

echo "========================================="
echo "  Hyprland Dotfiles Installer"
echo "========================================="

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    echo "Please run as regular user, not root"
    exit 1
fi

# Check if Arch Linux
if [[ ! -f /etc/arch-release ]]; then
    echo "This script is for Arch Linux"
    exit 1
fi

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ""
echo "Installing packages..."

# Enable multilib for Steam
if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
    echo "Enabling multilib..."
    echo -e "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" | sudo tee -a /etc/pacman.conf
    sudo pacman -Sy
fi

# Install packages
sudo pacman -S --noconfirm \
    hyprland \
    rofi \
    kitty \
    dolphin \
    waybar \
    steam \
    brightnessctl \
    playerctl \
    polkit \
    xdg-user-dirs \
    wget \
    curl \
    git \
    2>/dev/null

echo ""
echo "Installing dotfiles..."

# Create config directories
mkdir -p "$HOME/.config"

# Backup existing configs
if [[ -d "$HOME/.config/hypr" ]]; then
    mv "$HOME/.config/hypr" "$HOME/.config/hypr.backup"
fi
if [[ -d "$HOME/.config/rofi" ]]; then
    mv "$HOME/.config/rofi" "$HOME/.config/rofi.backup"
fi

# Copy configs
cp -r "$SCRIPT_DIR/config/"* "$HOME/.config/"

echo ""
echo "========================================="
echo "  Installation complete!"
echo "========================================="
echo ""
echo "Log out and log back in to start Hyprland"
echo "Or run: Hyprland"

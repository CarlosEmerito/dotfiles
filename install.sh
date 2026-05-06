#!/bin/bash

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    echo -e "${RED}This script should NOT be run as root${NC}"
    echo -e "${YELLOW}Run as a normal user with sudo privileges${NC}"
    exit 1
fi

echo -e "${GREEN}=== Arch Linux Hyprland Post-Install Script ===${NC}"
echo ""

# Get script directory (dotfiles root)
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo -e "${YELLOW}Dotfiles directory: ${DOTFILES_DIR}${NC}"
echo ""

# Update system
echo -e "${GREEN}Updating system...${NC}"
sudo pacman -Syu --noconfirm

# Install yay if not present
if ! command -v yay &> /dev/null; then
    echo -e "${GREEN}Installing yay AUR helper...${NC}"
    sudo pacman -S --needed --noconfirm git base-devel
    cd /tmp
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd "$DOTFILES_DIR"
else
    echo -e "${GREEN}yay is already installed${NC}"
fi
echo ""

# Official packages (pacman)
echo -e "${GREEN}Installing official packages...${NC}"
sudo pacman -S --needed --noconfirm \
    hyprland \
    hyprcursor \
    hyprlang \
    hyprutils \
    hyprgraphics \
    hyprwayland-scanner \
    waybar \
    rofi \
    kitty \
    nautilus \
    grim \
    slurp \
    brightnessctl \
    playerctl \
    pipewire \
    pipewire-pulse \
    pipewire-alsa \
    pipewire-jack \
    wireplumber \
    papirus-icon-theme \
    ttf-jetbrains-mono-nerd \
    inotify-tools \
    power-profiles-daemon \
    networkmanager \
    bluez \
    bluez-utils \
    git \
    base-devel \
    xdg-desktop-portal-hyprland \
    polkit-gnome \
    dunst

echo ""

# AUR packages (yay)
echo -e "${GREEN}Installing AUR packages...${NC}"
yay -S --needed --noconfirm \
    google-chrome \
    swaync \
    libnotify \
    ttf-font-awesome

echo ""

# Create symlinks for configs
echo -e "${GREEN}Creating symlinks for configurations...${NC}"

# Create .config directory if it doesn't exist
mkdir -p ~/.config

# Function to create symlink for directories
create_symlink_dir() {
    local src="$DOTFILES_DIR/.config/$1"
    local dest="$HOME/.config/$1"
    
    if [[ -d "$src" ]]; then
        # Remove existing config if it exists
        if [[ -e "$dest" || -L "$dest" ]]; then
            rm -rf "$dest"
        fi
        # Create symlink
        ln -sf "$src" "$dest"
        echo -e "${GREEN}Linked: $1${NC}"
    else
        echo -e "${YELLOW}Warning: $src not found${NC}"
    fi
}

# Symlink all config directories
for dir in hypr waybar rofi swaync kitty gtk-3.0 gtk-4.0 pulse; do
    create_symlink_dir "$dir"
done

echo ""

# Enable services
echo -e "${GREEN}Enabling services...${NC}"
sudo systemctl enable NetworkManager
sudo systemctl enable bluetooth
sudo systemctl enable pipewire
sudo systemctl enable pipewire-pulse
sudo systemctl enable wireplumber

echo ""

# Add user to necessary groups
echo -e "${GREEN}Adding user to groups...${NC}"
sudo usermod -aG video,input,audio "$USER"

echo ""

# Set up display manager (optional - SDDM)
echo -e "${YELLOW}Do you want to install and enable SDDM display manager? (y/n)${NC}"
read -r response
if [[ "$response" =~ ^[Yy]$ ]]; then
    sudo pacman -S --needed --noconfirm sddm
    sudo systemctl enable sddm
    echo -e "${GREEN}SDDM enabled${NC}"
else
    echo -e "${YELLOW}Skipping SDDM. You can start Hyprland with 'Hyprland' command from TTY${NC}"
fi

echo ""
echo -e "${GREEN}=== Installation Complete! ===${NC}"
echo -e "${YELLOW}Please reboot your system to apply all changes${NC}"
echo -e "${YELLOW}After reboot, you can start Hyprland from TTY or via display manager${NC}"

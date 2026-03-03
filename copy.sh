#!/usr/bin/env bash
# Copy dotfiles to ~/.config

echo "Copying dotfiles..."

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Backup old configs
timestamp=$(date +%Y%m%d_%H%M%S)

for dir in hypr rofi waybar kitty btop nvim; do
    if [[ -d "$HOME/.config/$dir" ]]; then
        echo "Backing up $dir..."
        mv "$HOME/.config/$dir" "$HOME/.config/${dir}.backup_$timestamp"
    fi
done

# Copy new configs
echo "Installing configs..."
cp -r "$SCRIPT_DIR/config/"* "$HOME/.config/"

echo "Done! Restart Hyprland (Super + Shift + Q)"

#!/usr/bin/env bash
# Random wallpaper setter for Hyprland
# Usage: random-wallpaper [directory]

wall_dir="${1:-$HOME/wallpapers}"
extensions="jpg|jpeg|png|webp|avif"

if [[ ! -d "$wall_dir" ]]; then
    echo "Directorio no encontrado: $wall_dir"
    exit 1
fi

wallpapers=$(find "$wall_dir" -type f \( -i-extension jpg -o -i-extension jpeg -o -i-extension png -o -i-extension webp -o -i-extension avif \) -print | shuf)

if [[ -z "$wallpapers" ]]; then
    echo "No se encontraron wallpapers en $wall_dir"
    exit 1
fi

wallpaper=$(echo "$wallpapers" | head -1)

if command -v hyprctl &>/dev/null; then
    hyprctl wallpaper , "$wallpaper"
    notify-send "Wallpaper cambiado" "$(basename "$wallpaper")"
else
    echo "No se pudo establecer wallpaper: hyprctl no encontrado"
fi

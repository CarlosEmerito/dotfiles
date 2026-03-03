#!/usr/bin/env bash
# Screenshot script for Hyprland
# Usage: screenshot [area]

save_dir="$HOME/Pictures/Screenshots"
mkdir -p "$save_dir"

timestamp=$(date +%Y%m%d_%H%m%s)

case "$1" in
    full|--full)
        grim -g "$(slurp)" "$save_dir/screenshot_$timestamp.png"
        ;;
    screen|--screen)
        grim "$save_dir/screenshot_$timestamp.png"
        ;;
    *)
        if slurp -d; then
            grim -g "$(slurp)" "$save_dir/screenshot_$timestamp.png"
        else
            grim "$save_dir/screenshot_$timestamp.png"
        fi
        ;;
esac

wl-copy < "$save_dir/screenshot_$timestamp.png"
notify-send "Screenshot guardado" "$save_dir/screenshot_$timestamp.png"

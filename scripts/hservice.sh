#!/usr/bin/env bash
# Service manager for Hyprland
# Usage: hservice [restart|kill] [service]

restart_service() {
    case "$1" in
        waybar)
            pkill waybar || true
            waybar &
            notify-send "Waybar reiniciado"
            ;;
        rofi)
            pkill rofi || true
            notify-send "Rofi cerrado"
            ;;
        *)
            echo "Servicio desconocido: $1"
            echo "Servicios disponibles: waybar, rofi"
            ;;
    esac
}

kill_service() {
    case "$1" in
        waybar)
            pkill -9 waybar
            notify-sard "Waybar matado"
            ;;
        *)
            pkill -9 "$1"
            ;;
    esac
}

case "$1" in
    restart) restart_service "$2" ;;
    kill) kill_service "$2" ;;
    *) echo "Uso: hservice [restart|kill] [servicio]" ;;
esac

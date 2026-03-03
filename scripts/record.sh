#!/usr/bin/env bash
# Screen recording script for Hyprland
# Usage: record [start|stop|status]

save_dir="$HOME/Videos/Recordings"
mkdir -p "$save_dir"

timestamp=$(date +%Y%m%d_%H%m%s)
output_file="$save_dir/recording_$timestamp.mp4"
pid_file="/tmp/wayland_record_pid"

is_recording() {
    [[ -f "$pid_file" ]] && kill -0 "$(cat "$pid_file")" 2>/dev/null
}

start_recording() {
    if is_recording; then
        echo "Ya está grabando"
        return 1
    fi
    
    wf-recorder -g "$(slurp -r)" -f "$output_file" &
    echo $! > "$pid_file"
    notify-send "Grabación iniciada" "$output_file"
}

stop_recording() {
    if ! is_recording; then
        echo "No hay grabación activa"
        return 1
    fi
    
    kill "$(cat "$pid_file")"
    rm -f "$pid_file"
    notify-send "Grabación guardada" "$output_file"
}

case "$1" in
    start) start_recording ;;
    stop) stop_recording ;;
    status)
        if is_recording; then
            echo "Grabando... (presiona 'record stop' para detener)"
        else
            echo "Sin grabar"
        fi
        ;;
    *) echo "Uso: record [start|stop|status]" ;;
esac

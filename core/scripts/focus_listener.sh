#!/bin/bash

# Este script escucha eventos de Hyprland y cierra la ventana de EmeBotEme
# cuando pierde el foco (click fuera).

handle() {
  case $1 in
    activewindowv2*)
      # Si la nueva ventana activa NO es emebot_popup, 
      # intentamos cerrar cualquier ventana de esa clase que esté abierta.
      if [[ ! $1 =~ "emebot_popup" ]]; then
        # Buscamos si existe alguna ventana de emebot_popup abierta
        address=$(hyprctl clients -j | jq -r '.[] | select(.class == "emebot_popup") | .address')
        if [[ -n "$address" ]]; then
          # En lugar de cerrar, movemos al espacio especial (scratchpad)
          hyprctl dispatch movetoworkspacesilent special:emebot,address:$address
        fi
      fi
      ;;
  esac
}

# Escuchar el socket de eventos de Hyprland
socat -U - "UNIX-CONNECT:$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.s" | while read -r line; do handle "$line"; done

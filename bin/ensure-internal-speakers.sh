#!/usr/bin/env bash
#
# Garantiza que el sonido salga por los altavoces internos del equipo
# (Audio Interno / Realtek ALC298 -> alsa_output.pci-0000_00_1f.3.analog-stereo).
#
# Motivo: al arrancar, WirePlumber a veces falla al crear este sink
# ("Failed to create ALSA node ... Object activation aborted"),
# normalmente porque otros procesos (agentes de voz como Hermes)
# acceden al dispositivo a la vez. Reactivar el perfil de la tarjeta fuerza
# su creación, y este script reintenta hasta conseguirlo.

set -u

SINK="alsa_output.pci-0000_00_1f.3.analog-stereo"
CARD="alsa_card.pci-0000_00_1f.3"
PROFILE="output:analog-stereo"
MAX_TRIES=10

log() { printf '%s\n' "[ensure-internal-speakers] $*"; }

has_sink() {
  pactl list short sinks 2>/dev/null | awk '{print $2}' | grep -qx "$SINK"
}

sink_id() {
  pactl list short sinks 2>/dev/null | awk -v s="$SINK" '$2==s{print $1; exit}'
}

# 1) Esperar a que PulseAudio/PipeWire esté disponible
i=0
while ! pactl info >/dev/null 2>&1; do
  i=$((i+1))
  if [ "$i" -ge 30 ]; then
    log "TIEMPO AGOTADO esperando a pactl"
    exit 1
  fi
  sleep 1
done

# 2) Si el sink no existe, reactivar el perfil analógico (con reintentos)
if ! has_sink; then
  log "El sink de altavoces internos no existe; reactivando perfil '$PROFILE'"
  try=0
  while ! has_sink && [ "$try" -lt "$MAX_TRIES" ]; do
    try=$((try+1))
    pactl set-card-profile "$CARD" off >/dev/null 2>&1
    sleep 1
    pactl set-card-profile "$CARD" "$PROFILE" >/dev/null 2>&1
    sleep 1
  done
else
  log "El sink de altavoces internos ya existe"
fi

# 3) Si ya existe, dejarla como salida por defecto, audible y mover flujos
if has_sink; then
  ID=$(sink_id)
  pactl set-default-sink "$ID" >/dev/null 2>&1
  pactl set-sink-mute "$ID" 0 >/dev/null 2>&1
  pactl set-sink-volume "$ID" 100% >/dev/null 2>&1
  for input in $(pactl list short sink-inputs 2>/dev/null | awk '{print $1}'); do
    pactl move-sink-input "$input" "$ID" >/dev/null 2>&1
  done
  log "Listo: sonido saliendo por los altavoces internos (sink $ID)"
  exit 0
else
  log "ERROR: no se pudo crear el sink de altavoces internos"
  exit 1
fi
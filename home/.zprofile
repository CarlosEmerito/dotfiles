
# Auto-start Hyprland on tty1
# Wrapper de diagnóstico: registra cómo termina Hyprland (código de salida o señal).
# Se usa start-hyprland (watchdog oficial de Hyprland 0.57+): si el compositor
# muere de forma no limpia, lo relanza en vez de tumbar toda la sesión de tty1.
#
# HYPRLAND_NO_RT: Hyprland 0.57 pide scheduling de tiempo real vía rtkit, hereda
# RLIMIT_RTTIME soft=150ms/hard=200ms y, si su hilo principal consume 200ms
# seguidos sin bloquear, el KERNEL le manda SIGKILL (SI_KERNEL, code=128) y muere
# la sesión entera. Con esta variable no solicita RT y el problema desaparece.
export HYPRLAND_NO_RT=1
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    exec zsh -c '
        log="$HOME/.local/state/hyprland-exit.log"
        out="$HOME/.local/state/hyprland-start.log"
        mkdir -p "$(dirname "$log")"

        if command -v start-hyprland >/dev/null 2>&1; then
            printf "%s  arranca start-hyprland (pid %d)\n" "$(date -Is)" "$$" >> "$log"
            start-hyprland >> "$out" 2>&1
            rc=$?
            sig=""
            if [ "$rc" -gt 128 ]; then sig=" señal=$((rc-128))"; fi
            printf "%s  start-hyprland terminó: status=%d%s\n" "$(date -Is)" "$rc" "$sig" >> "$log"
        else
            printf "%s  arranca Hyprland SIN watchdog (pid %d)\n" "$(date -Is)" "$$" >> "$log"
            Hyprland >> "$out" 2>&1
            rc=$?
            sig=""
            if [ "$rc" -gt 128 ]; then sig=" señal=$((rc-128))"; fi
            printf "%s  Hyprland terminó: status=%d%s\n" "$(date -Is)" "$rc" "$sig" >> "$log"
        fi
    '
fi


# El PATH común se define en ~/.zshenv para que lo hereden también
# Hyprland y las aplicaciones gráficas.

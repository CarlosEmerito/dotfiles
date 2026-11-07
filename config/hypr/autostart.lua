-- EmeDotEme — Autostart
-- Migrado desde autostart.conf

hl.on("hyprland.start", function()
    -- Fondo, barra y notificaciones (solo si están instalados y no están ya corriendo)
    hl.exec_cmd("command -v swaybg >/dev/null 2>&1 && ! pgrep -x swaybg >/dev/null 2>&1 && swaybg -m solid -c 000000")
    hl.exec_cmd("command -v waybar >/dev/null 2>&1 && ! pgrep -x waybar >/dev/null 2>&1 && waybar")
    hl.exec_cmd("command -v swaync >/dev/null 2>&1 && ! pgrep -x swaync >/dev/null 2>&1 && swaync")

    -- Actualizar entorno para servicios systemd --user y reiniciar EmeBotEme
    hl.exec_cmd("command -v dbus-update-activation-environment >/dev/null 2>&1 && dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE DISPLAY HYPRLAND_INSTANCE_SIGNATURE")
    hl.exec_cmd("systemctl --user cat emeboteme.service >/dev/null 2>&1 && systemctl --user restart emeboteme.service")

    -- Iniciar sesión gráfica y portal para diálogos de archivos (Chrome/Firefox)
    hl.exec_cmd("systemctl --user start graphical-session.target")
    hl.exec_cmd("systemctl --user start xdg-desktop-portal.service")

    -- Agente de autenticación PolicyKit (GParted, ajustes del sistema, etc.)
    -- El patrón va anclado al final para no coincidir con esta misma línea de shell.
    hl.exec_cmd("if [ -x /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 ]; then pgrep -f 'polkit-gnome-authentication-agent-1$' >/dev/null 2>&1 || /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1; fi")

    -- Applets de Red y Bluetooth
    hl.exec_cmd("command -v nm-applet >/dev/null 2>&1 && ! pgrep -x nm-applet >/dev/null 2>&1 && nm-applet --indicator")
    hl.exec_cmd("command -v blueman-applet >/dev/null 2>&1 && ! pgrep -x blueman-applet >/dev/null 2>&1 && blueman-applet")

    -- Mueve el popup de EmeBot al scratchpad cuando pierde el foco.
    -- El patrón va anclado al final para no coincidir con esta misma línea de shell.
    hl.exec_cmd("if [ -x \"$HOME/.config/emeboteme/focus_listener.sh\" ]; then pgrep -f 'focus_listener\\.sh$' >/dev/null 2>&1 || \"$HOME/.config/emeboteme/focus_listener.sh\"; fi")

    -- Gestor de Portapapeles (Cliphist): arranca ambos watchers de una vez.
    hl.exec_cmd("command -v wl-paste >/dev/null 2>&1 && ! pgrep -x wl-paste >/dev/null 2>&1 && (wl-paste --type text --watch cliphist store & wl-paste --type image --watch cliphist store &)")
end)

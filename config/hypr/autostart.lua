-- EmeDotEme — Autostart
-- Migrado desde autostart.conf

hl.on("hyprland.start", function()
    hl.exec_cmd("swaybg -m solid -c 000000")
    hl.exec_cmd("waybar")
    hl.exec_cmd("swaync")

    -- Actualizar entorno para servicios systemd --user y reiniciar EmeBotEme
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP DISPLAY")
    hl.exec_cmd("systemctl --user restart emeboteme.service")

    -- Iniciar sesión gráfica y portal para diálogos de archivos (Chrome/Firefox)
    hl.exec_cmd("systemctl --user start graphical-session.target")
    hl.exec_cmd("systemctl --user start xdg-desktop-portal.service")

    -- Applets de Red y Bluetooth
    hl.exec_cmd("nm-applet --indicator")
    hl.exec_cmd("blueman-applet")

    -- Gestor de Portapapeles (Cliphist)
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)

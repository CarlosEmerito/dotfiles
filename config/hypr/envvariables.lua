-- EmeDotEme — Variables de entorno para Hyprland
-- Migrado desde envvariables.conf

-- Tamaño del cursor para aplicaciones X11/XWayland.
hl.env("XCURSOR_SIZE", "24")
-- Tamaño del cursor para el manejo nativo en Hyprland/Wayland.
hl.env("HYPRCURSOR_SIZE", "24")
-- Prioriza Wayland en aplicaciones Qt, con fallback a X11 si hace falta.
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
-- Usa decoraciones del lado del servidor en Qt/Wayland para evitar doble barra de título.
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
-- Prioriza Wayland en aplicaciones GTK, permitiendo fallback a X11.
hl.env("GDK_BACKEND", "wayland,x11,*")
-- Prioriza backend Wayland para aplicaciones basadas en Clutter.
hl.env("CLUTTER_BACKEND", "wayland")
-- Permite que apps Electron elijan automáticamente Ozone (normalmente Wayland en Hyprland).
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")

-- ──────────────────────────────────────────
-- GPU — Descomenta SOLO el de tu hardware
-- ──────────────────────────────────────────

-- Intel (default)
-- hl.env("LIBVA_DRIVER_NAME", "iHD")
-- hl.env("MESA_LOADER_DRIVER_NAME", "iris")

-- NVIDIA
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("NVD_BACKEND", "direct")

-- AMD
-- hl.env("LIBVA_DRIVER_NAME", "radeonsi")
-- hl.env("MESA_LOADER_DRIVER_NAME", "radeonsi")

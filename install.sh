#!/usr/bin/env bash
# ==============================================================================
# Dotfiles para Arch Linux + Hyprland
#
# Uso:
#   ./install.sh                     Menú interactivo
#   ./install.sh --only config       Solo configuración
#   ./install.sh --only all --yes    Todo sin preguntar (modo desatendido)
#   ./install.sh --dry-run           Enseña qué haría, sin tocar nada
#   ./install.sh --help              Ayuda completa
# ==============================================================================

set -u

REPO_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
SRC_HOME="$REPO_DIR/home"
SRC_BIN="$REPO_DIR/bin"
TARGET_USER="${USER:-$(id -un)}"

# --- Opciones ----------------------------------------------------------------
DRY_RUN=0
ASSUME_YES=0
FORCE_COPY=0
ENABLE_SERVICES=0
UPGRADE_SYSTEM=0
GPU_MODE=""
DO_CONFIG=0
DO_PACKAGES=0
DO_SERVICES=0
SECTIONS_SET=0
INTERACTIVE=0
[[ -t 0 && -t 1 ]] && INTERACTIVE=1

# --- Colores ----------------------------------------------------------------
if [[ -t 1 ]]; then
    RED=$'\033[0;31m'; GREEN=$'\033[0;32m'; YELLOW=$'\033[1;33m'
    BLUE=$'\033[0;34m'; PURPLE=$'\033[0;35m'; BOLD=$'\033[1m'; NC=$'\033[0m'
else
    RED=''; GREEN=''; YELLOW=''; BLUE=''; PURPLE=''; BOLD=''; NC=''
fi

info()  { printf '%s\n' "${BLUE}${BOLD}INFO${NC}  $*"; }
ok()    { printf '%s\n' "${GREEN}${BOLD}OK${NC}    $*"; }
warn()  { printf '%s\n' "${YELLOW}${BOLD}AVISO${NC} $*"; }
err()   { printf '%s\n' "${RED}${BOLD}ERROR${NC} $*" >&2; }

usage() {
    cat <<'EOF'
Dotfiles para Arch Linux + Hyprland

Uso: ./install.sh [opciones]

Secciones (si no indicas ninguna, se muestra un menú):
  --only LISTA        config,packages,services,all  (ej: --only config,services)
  --no-config         No tocar la configuración
  --no-packages       No instalar paquetes
  --no-services       No instalar servicios de usuario
  --enable-services   Habilitar los servicios systemd --user instalados

Comportamiento:
  -n, --dry-run       Enseñar qué haría sin cambiar nada
  -y, --yes           No preguntar (usa los valores por defecto)
  --force             Reemplazar también los archivos copiados (GTK, nwg-displays)
  --gpu intel|nvidia|amd|none
                      Ajustar las variables de GPU de Hyprland
  --upgrade           Actualizar todo el sistema antes de instalar paquetes
  -h, --help          Mostrar esta ayuda

Ejemplos:
  ./install.sh --dry-run
  ./install.sh --only config
  ./install.sh --only all --yes --gpu nvidia
EOF
}

need_arg() { [[ $# -ge 2 ]] || { err "Falta el valor de $1"; exit 2; }; }

while [[ $# -gt 0 ]]; do
    case "$1" in
        -n|--dry-run)       DRY_RUN=1 ;;
        -y|--yes)           ASSUME_YES=1 ;;
        --force)            FORCE_COPY=1 ;;
        --enable-services)  ENABLE_SERVICES=1 ;;
        --upgrade)          UPGRADE_SYSTEM=1 ;;
        --gpu)              need_arg "$@"; GPU_MODE="$2"; shift ;;
        --only)
            need_arg "$@"
            SECTIONS_SET=1
            IFS=', ' read -r -a _sections <<< "$2"
            for s in "${_sections[@]}"; do
                [[ -z "$s" ]] && continue
                case "$s" in
                    config)   DO_CONFIG=1 ;;
                    packages) DO_PACKAGES=1 ;;
                    services) DO_SERVICES=1 ;;
                    all)      DO_CONFIG=1; DO_PACKAGES=1; DO_SERVICES=1 ;;
                    *) err "Sección desconocida: $s"; exit 2 ;;
                esac
            done
            shift ;;
        --no-config)   DO_CONFIG=0; SECTIONS_SET=1 ;;
        --no-packages) DO_PACKAGES=0; SECTIONS_SET=1 ;;
        --no-services) DO_SERVICES=0; SECTIONS_SET=1 ;;
        -h|--help) usage; exit 0 ;;
        *) err "Opción desconocida: $1 (usa --help)"; exit 2 ;;
    esac
    shift
done

case "$GPU_MODE" in
    ""|intel|nvidia|amd|none) ;;
    *) err "--gpu debe ser intel, nvidia, amd o none"; exit 2 ;;
esac

# --- Comprobaciones básicas --------------------------------------------------
if [[ $EUID -eq 0 ]]; then
    err "No ejecutes este script como root. Usa tu usuario normal (pedirá sudo si hace falta)."
    exit 1
fi

if [[ ! -d "$SRC_HOME" ]]; then
    err "No encuentro la carpeta home/ junto al instalador."
    exit 1
fi

if command -v pacman >/dev/null 2>&1; then
    IS_ARCH=1
else
    IS_ARCH=0
fi

# --- Utilidades --------------------------------------------------------------
BACKUP_ROOT="$HOME/.dotfiles-backups/$(date +%Y%m%d-%H%M%S)"
LINKED=0
COPIED=0
SKIPPED=0

run() {
    if (( DRY_RUN )); then
        printf '%s\n' "  ${PURPLE}[dry-run]${NC} $*"
    else
        "$@"
    fi
}

confirm() {
    local prompt="$1" default="${2:-n}" reply
    if (( ASSUME_YES )); then return 0; fi
    if (( DRY_RUN )); then return 0; fi
    if (( ! INTERACTIVE )); then [[ "$default" == "y" ]]; return; fi
    if [[ "$default" == "y" ]]; then
        read -r -p "$prompt [S/n]: " reply </dev/tty || reply=""
        [[ -z "$reply" || "$reply" =~ ^[sSyY] ]]
    else
        read -r -p "$prompt [s/N]: " reply </dev/tty || reply=""
        [[ "$reply" =~ ^[sSyY] ]]
    fi
}

is_ours() {
    [[ -L "$1" ]] || return 1
    local target
    target=$(readlink "$1")
    [[ "$target" == "$REPO_DIR"/* ]]
}

backup_item() {
    local dst="$1" rel target
    [[ -e "$dst" || -L "$dst" ]] || return 0
    rel="${dst#"$HOME"/}"
    target="$BACKUP_ROOT/$rel"
    if (( DRY_RUN )); then
        printf '%s\n' "  ${PURPLE}[dry-run]${NC} copia de seguridad: $dst -> $target"
        return 0
    fi
    mkdir -p "$(dirname "$target")"
    if cp -a -- "$dst" "$target"; then
        infob "Copia de seguridad: $dst -> $target"
    else
        warn "No se pudo guardar copia de seguridad de $dst"
    fi
}

infob() { printf '%s\n' "${BLUE}${BOLD}INFO${NC}  $*"; }

# Enlaza $src (dentro del repo) con $dst (en el home).
link_item() {
    local src="$1" dst="$2"
    if [[ ! -e "$src" ]]; then
        warn "No existe en el repo: $src"
        return 0
    fi

    if [[ -L "$dst" ]] && [[ "$(readlink "$dst")" == "$src" ]]; then
        ok "Ya enlazado: $dst"
        return 0
    fi

    if [[ -e "$dst" || -L "$dst" ]]; then
        if is_ours "$dst"; then
            : # enlace antiguo del repo: se reemplaza sin preguntar
        else
            if confirm "¿Reemplazar $dst por un enlace al repo?" y; then
                backup_item "$dst"
            else
                warn "Se conserva $dst"
                SKIPPED=$((SKIPPED + 1))
                return 0
            fi
        fi
        run rm -rf -- "$dst"
    fi

    run mkdir -p -- "$(dirname "$dst")"
    if run ln -s -- "$src" "$dst"; then
        ok "Enlazado: $dst"
        LINKED=$((LINKED + 1))
    else
        err "No se pudo enlazar $dst"
    fi
}

# Copia $src a $dst solo si falta (o si se usa --force).
copy_item() {
    local src="$1" dst="$2" mode="${3:-644}"
    if [[ ! -e "$src" ]]; then
        warn "No existe en el repo: $src"
        return 0
    fi

    if [[ -e "$dst" || -L "$dst" ]]; then
        if [[ -f "$dst" ]] && cmp -s -- "$src" "$dst"; then
            ok "Ya actualizado: $dst"
            return 0
        fi
        if is_ours "$dst"; then
            run rm -rf -- "$dst"
        elif (( FORCE_COPY )); then
            backup_item "$dst"
            run rm -rf -- "$dst"
        else
            warn "Se conserva $dst (distinto del repo). Usa --force para reemplazarlo."
            SKIPPED=$((SKIPPED + 1))
            return 0
        fi
    fi

    run mkdir -p -- "$(dirname "$dst")"
    if run install -m "$mode" -- "$src" "$dst"; then
        ok "Copiado: $dst"
        COPIED=$((COPIED + 1))
    else
        err "No se pudo copiar $dst"
    fi
}

copy_tree() {
    local src="$1" dst="$2"
    if [[ ! -d "$src" ]]; then
        warn "No existe en el repo: $src"
        return 0
    fi
    if [[ -e "$dst" || -L "$dst" ]]; then
        if [[ -d "$dst" ]] && [[ ! -L "$dst" ]] && diff -qr -- "$src" "$dst" >/dev/null 2>&1; then
            ok "Ya actualizado: $dst"
            return 0
        fi
        if is_ours "$dst"; then
            run rm -rf -- "$dst"
        elif (( FORCE_COPY )); then
            backup_item "$dst"
            run rm -rf -- "$dst"
        else
            warn "Se conserva $dst (estado local). Usa --force para reemplazarlo."
            SKIPPED=$((SKIPPED + 1))
            return 0
        fi
    fi
    run mkdir -p -- "$(dirname "$dst")"
    if run cp -a -- "$src" "$dst"; then
        ok "Copiado: $dst"
        COPIED=$((COPIED + 1))
    else
        err "No se pudo copiar $dst"
    fi
}

# --- Configuración -----------------------------------------------------------
LINK_DIRS=(
    ".config/hypr"
    ".config/waybar"
    ".config/kitty"
    ".config/rofi"
    ".config/swaync"
    ".config/swappy"
    ".config/starship"
    ".config/btop"
    ".config/fastfetch"
)

LINK_FILES=(
    ".zshrc"
    ".zprofile"
    ".bashrc"
    ".bash_profile"
    ".config/mimeapps.list"
    ".config/user-dirs.dirs"
    ".local/share/applications/bluetui.desktop"
    ".local/share/applications/opencode.desktop"
)

COPY_FILES=(
    ".config/gtk-3.0/settings.ini"
    ".config/gtk-2.0/.gtkrc-2.0"
    ".config/gtk-4.0/settings.ini"
)

seed_monitors() {
    local dst="$HOME/.config/hypr/monitors.lua"
    local example="$SRC_HOME/.config/hypr/monitors.lua.example"
    if [[ -e "$dst" ]]; then
        ok "Se conserva tu configuración de monitores: $dst"
        return 0
    fi
    [[ -f "$example" ]] || { warn "Falta $example"; return 0; }
    run mkdir -p -- "$HOME/.config/hypr"
    if run cp -- "$example" "$dst"; then
        ok "Creada configuración de monitores de ejemplo: $dst"
        COPIED=$((COPIED + 1))
    fi
}

link_bins() {
    local f base
    [[ -d "$SRC_BIN" ]] || return 0
    run mkdir -p -- "$HOME/.local/bin"
    for f in "$SRC_BIN"/*; do
        [[ -f "$f" ]] || continue
        base=$(basename "$f")
        run chmod +x -- "$f"
        link_item "$f" "$HOME/.local/bin/$base"
    done
}

link_units() {
    local src="$SRC_HOME/.config/systemd/user"
    local dst="$HOME/.config/systemd/user"
    local f
    [[ -d "$src" ]] || return 0
    run mkdir -p -- "$dst"

    if [[ -d "$src/hermes-gateway.service.d" ]]; then
        link_item "$src/hermes-gateway.service.d" "$dst/hermes-gateway.service.d"
    fi

    for f in "$src"/*.service "$src"/*.timer "$src"/*.target; do
        [[ -e "$f" ]] || continue
        link_item "$f" "$dst/$(basename "$f")"
    done
}

do_config() {
    info "Configurando enlaces y archivos del escritorio..."
    local d f

    for d in "${LINK_DIRS[@]}"; do
        link_item "$SRC_HOME/$d" "$HOME/$d"
    done

    seed_monitors

    for d in "${COPY_FILES[@]}"; do
        copy_item "$SRC_HOME/$d" "$HOME/$d" 644
    done

    # nwg-displays escribe su propia configuración: se copia como estado local.
    copy_tree "$SRC_HOME/.config/nwg-displays" "$HOME/.config/nwg-displays"

    for f in "${LINK_FILES[@]}"; do
        link_item "$SRC_HOME/$f" "$HOME/$f"
    done

    # Starship busca tanto ~/.config/starship.toml como ~/.config/starship/.
    link_item "$SRC_HOME/.config/starship/starship.toml" "$HOME/.config/starship.toml"

    link_bins
    link_units

    if (( ! DRY_RUN )); then
        systemctl --user daemon-reload 2>/dev/null || true
    fi
}

# --- Paquetes ----------------------------------------------------------------
OFFICIAL_PKGS=(
    hyprland hyprshutdown hyprcursor hyprland-guiutils
    waybar swaync swaybg rofi kitty nwg-displays
    grim slurp swappy wl-clipboard cliphist libnotify
    brightnessctl playerctl
    pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber pavucontrol
    networkmanager network-manager-applet bluez bluez-utils blueman
    xdg-desktop-portal xdg-desktop-portal-hyprland xdg-desktop-portal-gtk polkit-gnome
    nautilus qt5-wayland qt6-wayland
    zsh zsh-autosuggestions zsh-syntax-highlighting
    starship eza bat fastfetch btop
    papirus-icon-theme otf-font-awesome ttf-jetbrains-mono-nerd
    noto-fonts noto-fonts-emoji noto-fonts-cjk
    git curl base-devel inotify-tools jq socat python
    power-profiles-daemon
)

AUR_PKGS=(
    google-chrome
    catppuccin-gtk-theme-mocha
)

ensure_sudo() {
    (( DRY_RUN )) && return 0
    command -v sudo >/dev/null 2>&1 || { err "Falta sudo."; return 1; }
    sudo -v || { err "Se necesitan permisos sudo."; return 1; }
}

ensure_yay() {
    command -v yay >/dev/null 2>&1 && return 0
    info "Instalando yay (ayudante de AUR)..."
    (( DRY_RUN )) && { run sudo pacman -S --needed --noconfirm git base-devel; run git clone https://aur.archlinux.org/yay.git /tmp/yay-install; return 0; }
    ensure_sudo || return 1
    sudo pacman -S --needed --noconfirm git base-devel || return 1
    rm -rf /tmp/yay-install
    git clone https://aur.archlinux.org/yay.git /tmp/yay-install || return 1
    ( cd /tmp/yay-install && makepkg -si --noconfirm ) || return 1
    rm -rf /tmp/yay-install
    ok "yay instalado."
}

check_waybar() {
    command -v waybar >/dev/null 2>&1 || return 0
    local ver
    ver=$(waybar --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    [[ -n "$ver" ]] || return 0
    if [[ "$(printf '%s\n' 0.16.0 "$ver" | sort -V | head -1)" != "0.16.0" ]]; then
        warn "Waybar $ver es anterior a 0.16: los clics en los workspaces de Hyprland 0.57 no funcionarán."
        warn "Actualiza Waybar (por ejemplo, desde extra-testing o con waybar-git)."
    fi
}

do_packages() {
    if (( ! IS_ARCH )); then
        err "Este instalador es para Arch Linux (no encuentro pacman)."
        return 1
    fi

    if (( UPGRADE_SYSTEM )); then
        info "Actualizando el sistema..."
        (( DRY_RUN )) && { run sudo pacman -Syu --noconfirm; } || { ensure_sudo && sudo pacman -Syu --noconfirm; }
    fi

    info "Instalando paquetes oficiales..."
    if (( DRY_RUN )); then
        run sudo pacman -Sy --noconfirm
        run sudo pacman -S --needed "${OFFICIAL_PKGS[@]}"
    else
        ensure_sudo || return 1
        sudo pacman -Sy --noconfirm >/dev/null 2>&1 || warn "No se pudo refrescar la base de datos de pacman."
        if sudo pacman -S --needed --noconfirm "${OFFICIAL_PKGS[@]}"; then
            ok "Paquetes oficiales instalados."
        else
            warn "Algunos paquetes oficiales fallaron. Revisa la salida anterior."
        fi
    fi

    info "Instalando paquetes de AUR..."
    if ensure_yay; then
        if (( DRY_RUN )); then
            run yay -S --needed "${AUR_PKGS[@]}"
        elif yay -S --needed --noconfirm --answerclean None --answerdiff None --answeredit None "${AUR_PKGS[@]}"; then
            ok "Paquetes de AUR instalados."
        else
            warn "Algunos paquetes de AUR fallaron. Revisa la salida anterior."
        fi
    fi

    check_waybar

    if confirm "¿Habilitar NetworkManager, Bluetooth y power-profiles-daemon?" y; then
        run sudo systemctl enable --now NetworkManager || warn "No se pudo habilitar NetworkManager"
        run sudo systemctl enable --now bluetooth || warn "No se pudo habilitar Bluetooth"
        run sudo systemctl enable --now power-profiles-daemon || warn "No se pudo habilitar power-profiles-daemon"
    fi

    if confirm "¿Añadir tu usuario a los grupos video, input y audio?" y; then
        run sudo usermod -aG video,input,audio "$TARGET_USER" || warn "No se pudieron actualizar los grupos"
    fi
}

# --- GPU ---------------------------------------------------------------------
set_gpu_env() {
    local file="$SRC_HOME/.config/hypr/envvariables.lua" name
    [[ -f "$file" ]] || { warn "No existe $file"; return 1; }

    if (( DRY_RUN )); then
        info "[dry-run] Ajustaría la GPU a: $1"
        return 0
    fi

    for name in LIBVA_DRIVER_NAME MESA_LOADER_DRIVER_NAME __GLX_VENDOR_LIBRARY_NAME NVD_BACKEND; do
        sed -i -E "s|^([[:space:]]*)hl\.env\(\"$name\"|\1-- hl.env(\"$name\"|" "$file"
    done

    case "$1" in
        intel)
            sed -i -E 's|^([[:space:]]*)-- (hl\.env\("LIBVA_DRIVER_NAME", "iHD"\))|\1\2|; s|^([[:space:]]*)-- (hl\.env\("MESA_LOADER_DRIVER_NAME", "iris"\))|\1\2|' "$file" ;;
        nvidia)
            sed -i -E 's|^([[:space:]]*)-- (hl\.env\("LIBVA_DRIVER_NAME", "nvidia"\))|\1\2|; s|^([[:space:]]*)-- (hl\.env\("__GLX_VENDOR_LIBRARY_NAME", "nvidia"\))|\1\2|; s|^([[:space:]]*)-- (hl\.env\("NVD_BACKEND", "direct"\))|\1\2|' "$file" ;;
        amd)
            sed -i -E 's|^([[:space:]]*)-- (hl\.env\("LIBVA_DRIVER_NAME", "radeonsi"\))|\1\2|; s|^([[:space:]]*)-- (hl\.env\("MESA_LOADER_DRIVER_NAME", "radeonsi"\))|\1\2|' "$file" ;;
        none) : ;;
    esac
    ok "Variables de GPU ajustadas a: $1"
}

maybe_set_gpu() {
    local choice="$GPU_MODE"
    if [[ -z "$choice" ]] && (( DRY_RUN )); then
        return 0
    fi
    if [[ -z "$choice" ]] && (( INTERACTIVE )) && (( ! ASSUME_YES )); then
        echo ""
        printf '%s\n' "${PURPLE}${BOLD}¿Qué GPU tienes?${NC}"
        echo "1) Intel   2) NVIDIA   3) AMD   4) No cambiar"
        local g
        read -r -p "Opción [4]: " g </dev/tty || g=""
        case "$g" in
            1) choice="intel" ;;
            2) choice="nvidia" ;;
            3) choice="amd" ;;
            *) choice="" ;;
        esac
    fi
    [[ -n "$choice" ]] && set_gpu_env "$choice"
}

# --- Servicios ---------------------------------------------------------------
do_services() {
    info "Instalando servicios de usuario..."
    link_units

    if (( ! DRY_RUN )); then
        systemctl --user daemon-reload 2>/dev/null || warn "No se pudo recargar systemd --user"
    fi

    # Un servicio con WorkingDirectory apunta a un proyecto externo. Si ese
    # proyecto no existe en este equipo, no se habilita para no dejar errores.
    unit_ready() {
        local unit="$1" file dir target
        file="$HOME/.config/systemd/user/$unit"
        if [[ "$unit" == *.timer ]]; then
            target=$(sed -n 's/^Unit=//p' "$file" 2>/dev/null | head -1)
            [[ -z "$target" ]] && target="${unit%.timer}.service"
            unit_ready "$target"
            return
        fi
        dir=$(sed -n 's/^WorkingDirectory=//p' "$file" 2>/dev/null | head -1)
        dir="${dir//%h/$HOME}"
        [[ -z "$dir" || -d "$dir" ]]
    }

    if (( ENABLE_SERVICES )) || confirm "¿Habilitar los servicios instalados para el próximo inicio de sesión?" n; then
        local unit
        for unit in ensure-internal-speakers.service hermes-gateway.service lan-mouse.service mydot.service; do
            if [[ -e "$HOME/.config/systemd/user/$unit" ]]; then
                if unit_ready "$unit"; then
                    run systemctl --user enable "$unit" || warn "No se pudo habilitar $unit"
                else
                    warn "Se omite $unit: su proyecto externo no existe en este equipo."
                fi
            fi
        done
        for unit in history_bot.timer mydot-analiticas.timer mydot-copia.timer mydot-kraken.timer; do
            if [[ -e "$HOME/.config/systemd/user/$unit" ]]; then
                if unit_ready "$unit"; then
                    run systemctl --user enable "$unit" || warn "No se pudo habilitar $unit"
                else
                    warn "Se omite $unit: su proyecto externo no existe en este equipo."
                fi
            fi
        done
    fi
}

# --- Menú --------------------------------------------------------------------
menu() {
    echo ""
    printf '%s\n' "${PURPLE}${BOLD}Instalador de dotfiles — Arch Linux + Hyprland${NC}"
    echo "  1) Configuración del escritorio"
    echo "  2) Paquetes"
    echo "  3) Servicios de usuario"
    echo "  4) Todo"
    echo "  5) Salir"
    local choice
    read -r -p "Opción [4]: " choice </dev/tty || choice=""
    case "${choice:-4}" in
        1) DO_CONFIG=1 ;;
        2) DO_PACKAGES=1 ;;
        3) DO_SERVICES=1 ;;
        4) DO_CONFIG=1; DO_PACKAGES=1; DO_SERVICES=1 ;;
        5) exit 0 ;;
        *) err "Opción inválida."; exit 2 ;;
    esac
}

if (( ! SECTIONS_SET )); then
    if (( INTERACTIVE )); then
        menu
    else
        info "Sin terminal interactiva: se aplica solo la configuración (--only config)."
        DO_CONFIG=1
    fi
fi

(( DRY_RUN )) && warn "Modo simulación: no se cambiará nada."
(( ASSUME_YES )) && info "Modo --yes: se usarán los valores por defecto."
echo ""

# --- Ejecución ---------------------------------------------------------------
if (( DO_CONFIG )); then
    do_config
fi

if (( DO_CONFIG )) || [[ -n "$GPU_MODE" ]]; then
    maybe_set_gpu
fi

if (( DO_PACKAGES )); then
    do_packages
fi

if (( DO_SERVICES )); then
    do_services
fi

# --- Resumen -----------------------------------------------------------------
echo ""
printf '%s\n' "${PURPLE}${BOLD}Resumen${NC}"
echo "  Enlaces creados:      $LINKED"
echo "  Archivos copiados:    $COPIED"
echo "  Elementos conservados: $SKIPPED"
if [[ -d "$BACKUP_ROOT" ]]; then
    echo "  Copias de seguridad:  $BACKUP_ROOT"
fi
(( DRY_RUN )) && echo "  (simulación: no se modificó nada)"
echo ""
ok "Terminado. Cierra sesión y vuelve a entrar para aplicar los cambios de Hyprland."

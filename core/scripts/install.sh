#!/bin/bash

# ==============================================================================
# Arch Linux Hyprland & EmeBotEme Installer (Refactored)
# ==============================================================================

set -e

# --- Colores y Estética ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# --- Funciones de Utilidad ---
info() { echo -e "${BLUE}${BOLD}󰋼 INFO${NC} $1"; }
success() { echo -e "${GREEN}${BOLD}󰄬 OK${NC} $1"; }
warn() { echo -e "${YELLOW}${BOLD}󱈸 WARN${NC} $1"; }
error() { echo -e "${RED}${BOLD}󰅚 ERROR${NC} $1"; }

show_progress() {
    local pid=$1
    local task=$2
    local spin='-\|/'
    local i=0
    local cyan=$(tput setaf 6)
    local purple=$(tput setaf 5)
    local bold=$(tput bold)
    local reset=$(tput sgr0)

    printf "${cyan}${bold}󱑮 %-25s [${reset}" "$task"
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) % 4 ))
        printf "${purple}${spin:$i:1}${reset}\b"
        sleep 0.1
    done
    printf "${purple}████████████████████████████████████████${reset}${cyan}${bold}] 100%%${reset}\n"
}

print_banner() {
    clear
    echo -e "${PURPLE}${BOLD}"
    echo "  ███████╗███╗   ███╗███████╗██████╗  ██████╗ ████████╗███████╗███╗   ███╗███████╗"
    echo "  ██╔════╝████╗ ████║██╔════╝██╔══██╗██╔═══██╗╚══██╔══╝██╔════╝████╗ ████║██╔════╝"
    echo "  █████╗  ██╔████╔██║█████╗  ██║  ██║██║   ██║   ██║   █████╗  ██╔████╔██║█████╗  "
    echo "  ██╔══╝  ██║╚██╔╝██║██╔══╝  ██║  ██║██║   ██║   ██║   ██╔══╝  ██║╚██╔╝██║██╔══╝  "
    echo "  ███████╗██║ ╚═╝ ██║███████╗██████╔╝╚██████╔╝   ██║   ███████╗██║ ╚═╝ ██║███████╗"
    echo "  ╚══════╝╚═╝     ╚═╝╚══════╝╚═════╝  ╚═════╝    ╚═╝   ╚══════╝╚═╝     ╚═╝╚══════╝"
    echo -e "                               EmeDotEme Setup v3.1${NC}"
    echo ""
}

if [[ $EUID -eq 0 ]]; then
    error "Este script NO debe ejecutarse como root. Usa un usuario normal superadministrador."
    exit 1
fi

# Detectar directorio real resolviendo symlinks
REAL_SCRIPT_PATH=$(readlink -f "${BASH_SOURCE[0]}")
SCRIPT_DIR=$(dirname "$REAL_SCRIPT_PATH")
DOTFILES_DIR=$(cd "$SCRIPT_DIR/../.." && pwd)

print_banner
info "Iniciando instalación desde: ${BOLD}$DOTFILES_DIR${NC}"
echo ""

info "Actualizando base de datos de paquetes..."
sudo pacman -Syu --noconfirm > /dev/null

if ! command -v yay &> /dev/null; then
    warn "yay no encontrado. Instalando ayudante AUR..."
    sudo pacman -S --needed --noconfirm git base-devel > /dev/null
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay && makepkg -si --noconfirm
    cd "$DOTFILES_DIR"
    success "yay instalado correctamente."
fi

echo ""
echo -e "${CYAN}${BOLD}¿Qué deseas instalar de la suite EmeDotEme?${NC}"
echo -e "1) ${BOLD}Full Experience${NC} (Hyprland, Apps, Dotfiles, AI)"
echo -e "2) ${BOLD}Solo AI Assistant${NC} (EmeBotEme)"
echo -e "3) ${BOLD}Solo Dotfiles${NC} (Configuraciones base)"
read -p "Selecciona una opción [1-3]: " main_choice

case $main_choice in
    1|3)
        info "Instalando paquetes esenciales..."
        sudo pacman -S --needed --noconfirm \
            zsh zsh-autosuggestions zsh-syntax-highlighting \
            starship eza bat \
            cliphist swappy \
            hyprland hyprcursor hyprlang hyprutils hyprgraphics hyprwayland-scanner \
            waybar rofi kitty nautilus grim slurp brightnessctl playerctl \
            pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber \
            papirus-icon-theme ttf-jetbrains-mono-nerd inotify-tools \
            socat jq \
            power-profiles-daemon networkmanager bluez bluez-utils \
            xdg-desktop-portal-hyprland polkit-gnome dunst fastfetch > /dev/null 2>&1 &
        show_progress $! "Instalando desde Pacman"

        info "Instalando desde AUR..."
        yay -S --needed --noconfirm \
            google-chrome swaync libnotify ttf-font-awesome nwg-displays \
            catppuccin-gtk-theme-mocha > /dev/null 2>&1 &
        show_progress $! "Compilando desde AUR"

        info "Configurando enlaces simbólicos..."
        mkdir -p ~/.config
        # Iterar sobre las carpetas dentro de 'config/' de forma segura
        for dir in "$DOTFILES_DIR/config/"*; do
            if [[ -d "$dir" ]]; then
                dir_name=$(basename "$dir")
                info "Enlazando .config/$dir_name..."
                rm -rf "$HOME/.config/$dir_name"
                ln -sf "$dir" "$HOME/.config/$dir_name"
            fi
        done
        
        # Symlink directo de starship.toml para cubrir ambos paths de búsqueda de Starship
        # ($XDG_CONFIG_HOME/starship.toml tiene prioridad sobre starship/starship.toml)
        if [[ -f "$DOTFILES_DIR/config/starship/starship.toml" ]]; then
            ln -sf "$DOTFILES_DIR/config/starship/starship.toml" "$HOME/.config/starship.toml"
        fi
        
        if [[ -f "$DOTFILES_DIR/.zshrc" ]]; then
            ln -sf "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
            success "Configuración visual y shell enlazada."
        else
            warn "No se encontró .zshrc en $DOTFILES_DIR"
        fi

        sudo usermod -aG video,input,audio "$USER"

        print_banner
        echo -e "${CYAN}${BOLD}¿Cómo prefieres que arranque el sistema?${NC}"
        echo -e "1) ${BOLD}Auto-login Directo${NC} (TTY1)"
        echo -e "2) ${BOLD}Gestor Visual (SDDM)${NC}"
        echo -e "3) ${BOLD}Manual (Terminal)${NC}"
        read -p "Selecciona una opción [1-3]: " login_choice

        case $login_choice in
            1)
                info "Configurando Auto-login..."
                sudo mkdir -p /etc/systemd/system/getty@tty1.service.d
                sudo tee /etc/systemd/system/getty@tty1.service.d/override.conf > /dev/null <<EOF
[Service]
Type=simple
ExecStart=
ExecStart=-/usr/bin/agetty --autologin $USER --noclear %I \$TERM
EOF
                if ! grep -q "exec Hyprland" ~/.zprofile 2>/dev/null; then
                    cat >> ~/.zprofile <<'EOF'
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    exec Hyprland
fi
EOF
                    fi

                    info "Aplicando cambios a systemd..."
                    success "Auto-login configurado y getty@tty1 reiniciado."
                ;;
            2)
                sudo pacman -S --needed --noconfirm sddm > /dev/null 2>&1
                sudo systemctl enable sddm
                ;;
        esac
        ;;
esac

if [[ $main_choice == "1" || $main_choice == "2" ]]; then
    info "Configurando IA (EmeBotEme)..."
    sudo pip install --break-system-packages pynput sounddevice numpy faster-whisper scipy evdev pyudev > /dev/null 2>&1 &
    show_progress $! "Instalando dependencias Python"

    DOT_ENV_FILE="$DOTFILES_DIR/.env"
    if [[ ! -f "$DOT_ENV_FILE" ]]; then
        read -r -p "Introduce tu HF_TOKEN de Hugging Face: " hf_token
        echo "HF_TOKEN=$hf_token" > "$DOT_ENV_FILE"
    fi

    info "Habilitando servicio..."
    chmod +x "$DOTFILES_DIR/core/scripts/focus_listener.sh"
    
    # Pre-descarga de modelos Whisper
    info "Descargando modelos de IA (Whisper tiny y base)..."
    python3 -c "from faster_whisper import WhisperModel; WhisperModel('tiny'); WhisperModel('base')" > /dev/null 2>&1 &
    show_progress $! "Descargando modelos"

    mkdir -p "$HOME/.config/systemd/user"
    cp "$DOTFILES_DIR/core/services/emeboteme.service" "$HOME/.config/systemd/user/"
    systemctl --user daemon-reload
    systemctl --user enable --now emeboteme.service
    success "IA activa."
fi

echo ""
info "¡Instalación completada!"
read -p "¿Reiniciar ahora? (s/n): " confirm_reboot
[[ $confirm_reboot == [sS] ]] && sudo reboot

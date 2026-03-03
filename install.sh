#!/usr/bin/env bash
set -e

# ═══════════════════════════════════════════════════════════════
#  Dotfiles Installer
#  Arch Linux + Hyprland
# ═══════════════════════════════════════════════════════════════

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# ═══════════════════════════════════════════════════════════════
# Funciones auxiliares
# ═══════════════════════════════════════════════════════════════

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_section() { echo -e "\n${CYAN}═══ $1 ═══${NC}\n"; }

check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "No ejecutes como root"
        exit 1
    fi
}

check_arch() {
    if [[ ! -f /etc/arch-release ]]; then
        log_error "Este script está diseñado para Arch Linux"
        exit 1
    fi
}

prompt_yes() {
    local prompt="$1"
    local response
    echo -n -e "${YELLOW}$prompt [S/n]: ${NC}"
    read -r response
    [[ "$response" =~ ^[Ss]$ ]] || [[ -z "$response" ]]
}

# ═══════════════════════════════════════════════════════════════
# Backup
# ═══════════════════════════════════════════════════════════════

backup_existing() {
    local config="$1"
    if [[ -e "$HOME/.config/$config" ]]; then
        log_warn "Respaldando $config existente..."
        mkdir -p "$BACKUP_DIR"
        cp -r "$HOME/.config/$config" "$BACKUP_DIR/"
        log_success "Respaldo guardado en $BACKUP_DIR/$config"
    fi
}

# ═══════════════════════════════════════════════════════════════
# Paquetes - Tasks
# ═══════════════════════════════════════════════════════════════

# Paquetes base (siempre instalados)
BASIC_PACKAGES=(
    wget curl git
    xdg-user-dirs xdg-utils
    polkit
)

# Paquetes de desktop
DESKTOP_PACKAGES=(
    rofi
    kitty
    dolphin
    waybar
    brightnessctl
    playerctl
)

# Paquetes de gaming
GAMING_PACKAGES=(
    steam
)

# Paquetes de desarrollo
DEV_PACKAGES=(
    neovim
    git
    fastfetch
    btop
    htop
    tree
    ranger
)

install_pacman() {
    local packages=("$@")
    local to_install=()
    
    for pkg in "${packages[@]}"; do
        if ! pacman -Q "$pkg" &>/dev/null; then
            to_install+=("$pkg")
        fi
    done
    
    if [[ ${#to_install[@]} -gt 0 ]]; then
        log_info "Instalando: ${to_install[*]}"
        sudo pacman -S --noconfirm "${to_install[@]}" 2>/dev/null || true
    fi
}

install_yay() {
    if ! command -v yay &>/dev/null; then
        log_info "Instalando yay (AUR helper)..."
        cd /tmp
        git clone https://aur.archlinux.org/yay.git
        cd yay
        makepkg -si --noconfirm
        cd /tmp && rm -rf yay
    fi
}

install_aur() {
    local packages=("$@")
    local to_install=()
    
    for pkg in "${packages[@]}"; do
        if ! yay -Q "$pkg" &>/dev/null; then
            to_install+=("$pkg")
        fi
    done
    
    if [[ ${#to_install[@]} -gt 0 ]]; then
        log_info "Instalando desde AUR: ${to_install[*]}"
        yay -S --noconfirm "${to_install[@]}" 2>/dev/null || true
    fi
}

enable_multilib() {
    if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
        log_warn "Habilitando multilib..."
        echo -e "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" | sudo tee -a /etc/pacman.conf
        sudo pacman -Sy --noconfirm
    fi
}

# ═══════════════════════════════════════════════════════════════
# Detección de hardware
# ═══════════════════════════════════════════════════════════════

detect_gpu() {
    if lspci | grep -qi nvidia; then
        echo "nvidia"
    elif lspci | grep -qi amd; then
        echo "amd"
    elif lspci | grep -qi intel; then
        echo "intel"
    else
        echo "unknown"
    fi
}

detect_audio() {
    if pactl info &>/dev/null; then
        echo "pipewire"
    elif command -v alsa &>/dev/null; then
        echo "alsa"
    else
        echo "unknown"
    fi
}

install_gpu_drivers() {
    local gpu=$(detect_gpu)
    local packages=()
    local aur_packages=()
    
    case $gpu in
        nvidia)
            packages=(nvidia nvidia-utils lib32-nvidia-utils nvidia-settings)
            aur_packages=(nvidia-vaapi-driver)
            ;;
        amd)
            packages=(mesa lib32-mesa xf86-video-amdgpu vulkan-radeon lib32-vulkan-radeon)
            ;;
        intel)
            packages=(mesa lib32-mesa xf86-video-intel intel-media-driver libva-intel-driver)
            ;;
    esac
    
    if [[ ${#packages[@]} -gt 0 ]]; then
        log_info "GPU detectada: $gpu"
        install_pacman "${packages[@]}"
        if command -v yay &>/dev/null; then
            install_aur "${aur_packages[@]}"
        fi
    fi
}

install_audio() {
    local audio=$(detect_audio)
    log_info "Audio: $audio"
    install_pacman pipewire pipewire-alsa pipewire-pulse wireplumber
}

# ═══════════════════════════════════════════════════════════════
# Instalación de configs
# ═══════════════════════════════════════════════════════════════

install_config() {
    local config="$1"
    local source="$SCRIPT_DIR/.config/$config"
    local target="$HOME/.config/$config"
    
    if [[ -d "$source" ]]; then
        backup_existing "$config"
        mkdir -p "$target"
        cp -r "$source/"* "$target/"
        log_success "$config instalado"
    else
        log_warn "No se encontró config para $config"
    fi
}

# ═══════════════════════════════════════════════════════════════
# Instalación por tasks
# ═══════════════════════════════════════════════════════════════

task_basic() {
    log_section "Paquetes básicos"
    enable_multilib
    install_pacman "${BASIC_PACKAGES[@]}"
}

task_desktop() {
    log_section "Desktop (Hyprland)"
    install_pacman "${DESKTOP_PACKAGES[@]}"
    install_gpu_drivers
    install_audio
}

task_gaming() {
    log_section "Gaming"
    enable_multilib
    install_pacman "${GAMING_PACKAGES[@]}"
}

task_dev() {
    log_section "Desarrollo"
    install_pacman "${DEV_PACKAGES[@]}"
    install_yay
    install_aur visual-studio-code-bin
}

task_aur() {
    log_section "AUR extras"
    install_yay
    install_aur \
        catppuccin-gtk-theme-mocha \
        bibata-cursors \
        papirus-icon-theme \
        ttf-jetbrains-mono-nerd
}

task_configs() {
    log_section "Configuraciones"
    install_config "hypr"
    install_config "rofi"
    install_config "kitty"
    install_config "waybar"
    install_config "btop"
    install_config "nvim"
}

task_all() {
    log_section "INSTALACIÓN COMPLETA"
    task_basic
    task_desktop
    task_gaming
    task_dev
    task_aur
    task_configs
    
    log_success "¡Todo instalado!"
    echo ""
    echo "Reinicia Hyprland: Super + Shift + Q"
}

# ═══════════════════════════════════════════════════════════════
# Menú interactivo
# ═══════════════════════════════════════════════════════════════

show_menu() {
    clear
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  Dotfiles Installer - Arch Linux${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${CYAN}Hardware detectado:${NC}"
    echo "    GPU: $(detect_gpu) | Audio: $(detect_audio)"
    echo ""
    echo "  ${CYAN}Instalación:${NC}"
    echo "    1) Todo (recomendado)"
    echo "    2) Básico + Desktop"
    echo "    3) Gaming (Steam)"
    echo "    4) Desarrollo"
    echo "    5) Solo configuraciones"
    echo "    6) Ver hardware"
    echo "    0) Salir"
    echo ""
    echo -ne "${YELLOW}Selecciona: ${NC}"
}

# ═══════════════════════════════════════════════════════════════
# Main
# ═══════════════════════════════════════════════════════════════

main() {
    check_root
    check_arch
    
    if [[ $# -gt 0 ]]; then
        case "$1" in
            --all|-a) task_all ;;
            --basic|-b) task_basic ;;
            --desktop|-d) task_desktop ;;
            --gaming|-g) task_gaming ;;
            --dev) task_dev ;;
            --aur) task_aur ;;
            --configs|-c) task_configs ;;
            --gpu) install_gpu_drivers ;;
            --help|-h)
                echo "Uso: $0 [opción]"
                echo ""
                echo "Opciones:"
                echo "  -a, --all       Instalar todo"
                echo "  -b, --basic     Solo básico"
                echo "  -d, --desktop   Desktop + drivers"
                echo "  -g, --gaming    Gaming"
                echo "  --dev           Desarrollo"
                echo "  --aur           Extras AUR"
                echo "  -c, --configs   Solo configs"
                echo "  --gpu           Solo drivers GPU"
                echo "  -h, --help      Ayuda"
                exit 0
                ;;
            *) log_error "Opción desconocida. Usa -h" ;;
        esac
        exit 0
    fi
    
    while true; do
        show_menu
        read -r choice
        
        case $choice in
            1) task_all ;;
            2) task_basic && task_desktop && task_configs ;;
            3) task_gaming ;;
            4) task_dev && task_configs ;;
            5) task_configs ;;
            6)
                echo ""
                log_info "GPU: $(detect_gpu)"
                log_info "Audio: $(detect_audio)"
                ;;
            0) echo "¡Hasta luego!"; exit 0 ;;
            *) log_error "Opción inválida" ;;
        esac
        
        echo ""
        echo -ne "${YELLOW}Presiona Enter...${NC}"
        read -r
    done
}

main "$@"

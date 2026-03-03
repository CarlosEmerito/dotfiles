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
NC='\033[0m'

# ═══════════════════════════════════════════════════════════════
# Funciones auxiliares
# ═══════════════════════════════════════════════════════════════

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

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
# Instalación de paquetes
# ═══════════════════════════════════════════════════════════════

install_packages() {
    local packages=("$@")
    local to_install=()
    
    for pkg in "${packages[@]}"; do
        if ! pacman -Q "$pkg" &>/dev/null; then
            to_install+=("$pkg")
        fi
    done
    
    if [[ ${#to_install[@]} -gt 0 ]]; then
        log_info "Instalando paquetes: ${to_install[*]}"
        sudo pacman -S --noconfirm "${to_install[@]}"
    else
        log_info "Todos los paquetes ya están instalados"
    fi
}

enable_multilib() {
    if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
        log_warn "Habilitando multilib..."
        echo -e "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" | sudo tee -a /etc/pacman.conf
        sudo pacman -Sy --noconfirm
    fi
}

detect_gpu() {
    if lspci | grep -q "NVIDIA"; then
        echo "nvidia"
    elif lspci | grep -q "AMD"; then
        echo "amd"
    else
        echo "intel"
    fi
}

install_gpu_drivers() {
    local gpu=$(detect_gpu)
    local packages=()
    
    case $gpu in
        nvidia)
            packages=(nvidia nvidia-utils lib32-nvidia-utils)
            ;;
        amd)
            packages=(mesa lib32-mesa xf86-video-amdgpu vulkan-radeon)
            ;;
        intel)
            packages=(mesa lib32-mesa xf86-video-intel intel-media-driver)
            ;;
    esac
    
    if [[ ${#packages[@]} -gt 0 ]]; then
        log_info "Detectado GPU: $gpu"
        if prompt_yes "Instalar drivers para $gpu"; then
            install_packages "${packages[@]}"
        fi
    fi
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
# Menú interactivo
# ═══════════════════════════════════════════════════════════════

show_menu() {
    clear
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  Dotfiles Installer - Arch Linux + Hyprland${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════${NC}"
    echo ""
    echo "  1) Instalar todo"
    echo "  2) Solo paquetes"
    echo "  3) Solo configuraciones"
    echo "  4) Detectar GPU e instalar drivers"
    echo "  5) Desinstalar configs"
    echo "  6) Actualizar configs desde repo"
    echo "  7) Salir"
    echo ""
    echo -ne "${YELLOW}Selecciona una opción: ${NC}"
}

install_all() {
    log_info "Iniciando instalación completa..."
    
    enable_multilib
    
    # Paquetes básicos
    install_packages \
        rofi kitty dolphin waybar steam brightnessctl \
        playerctl polkit xdg-user-dirs xdg-utils wget curl git
    
    # Drivers GPU
    install_gpu_drivers
    
    # Instalar configs
    install_config "hypr"
    install_config "rofi"
    install_config "kitty"
    install_config "waybar"
    install_config "btop"
    install_config "nvim"
    
    log_success "Instalación completa!"
}

install_only_packages() {
    log_info "Instalando paquetes..."
    enable_multilib
    install_packages \
        rofi kitty dolphin waybar steam brightnessctl \
        playerctl polkit xdg-user-dirs xdg-utils wget curl git
    install_gpu_drivers
    log_success "Paquetes instalados"
}

install_only_configs() {
    log_info "Instalando configuraciones..."
    install_config "hypr"
    install_config "rofi"
    install_config "kitty"
    install_config "waybar"
    install_config "btop"
    install_config "nvim"
    log_success "Configuraciones instaladas"
}

uninstall_configs() {
    log_warn "Desinstalando configuraciones..."
    
    local configs=("hypr" "rofi" "kitty" "waybar" "btop" "nvim")
    
    for config in "${configs[@]}"; do
        if [[ -e "$HOME/.config/$config" ]]; then
            rm -rf "$HOME/.config/$config"
            log_success "$config eliminado"
        fi
    done
    
    log_success "Desinstalación completa"
}

update_configs() {
    log_info "Actualizando configs..."
    cd "$SCRIPT_DIR"
    git pull origin master
    install_only_configs
    log_success "Configs actualizadas"
}

# ═══════════════════════════════════════════════════════════════
# Main
# ═══════════════════════════════════════════════════════════════

main() {
    check_root
    check_arch
    
    if [[ $# -gt 0 ]]; then
        case "$1" in
            --all|-a) install_all ;;
            --packages|-p) install_only_packages ;;
            --configs|-c) install_only_configs ;;
            --uninstall|-u) uninstall_configs ;;
            --update) update_configs ;;
            --help|-h)
                echo "Uso: $0 [opción]"
                echo "  -a, --all        Instalar todo"
                echo "  -p, --packages   Solo paquetes"
                echo "  -c, --configs    Solo configuraciones"
                echo "  -u, --uninstall  Desinstalar"
                echo "  --update         Actualizar desde git"
                echo "  -h, --help       Mostrar ayuda"
                exit 0
                ;;
            *) log_error "Opción desconocida. Usa -h para ayuda" ;;
        esac
        exit 0
    fi
    
    while true; do
        show_menu
        read -r choice
        
        case $choice in
            1) install_all ;;
            2) install_only_packages ;;
            3) install_only_configs ;;
            4) install_gpu_drivers ;;
            5) uninstall_configs ;;
            6) update_configs ;;
            7) echo "¡Hasta luego!"; exit 0 ;;
            *) log_error "Opción inválida" ;;
        esac
        
        echo ""
        echo -ne "${YELLOW}Presiona Enter para continuar...${NC}"
        read -r
    done
}

main "$@"

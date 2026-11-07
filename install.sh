#!/bin/bash

# ==============================================================================
# Arch Linux Hyprland & EmeBotEme Installer (Refactored)
# ==============================================================================

# --- Colores y Estética ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

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
    wait $pid
    if [[ $? -eq 0 ]]; then
        printf "${purple}████████████████████████████████████████${reset}${cyan}${bold}] 100%%${reset}\n"
    else
        printf "${RED}████████████████████████████████████████${reset}${RED}${bold}] ERROR${reset}\n"
        return 1
    fi
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
    echo -e "                               EmeDotEme Setup${NC}"
    echo ""
}

if [[ $EUID -eq 0 ]]; then
    error "Este script NO debe ejecutarse como root. Usa un usuario normal con permisos sudo."
    exit 1
fi

# Detectar directorio real del repositorio
REAL_SCRIPT_PATH=$(readlink -f "${BASH_SOURCE[0]}")
SCRIPT_DIR=$(dirname "$REAL_SCRIPT_PATH")
DOTFILES_DIR="$SCRIPT_DIR"

print_banner
info "Iniciando instalación desde: ${BOLD}$DOTFILES_DIR${NC}"
echo ""

# ------------------------------------------------------------------
# Gestión de pacman
# ------------------------------------------------------------------
info "Actualizando base de datos de paquetes..."
sudo pacman -Syu --noconfirm > /dev/null 2>&1 || warn "Falló la actualización (puede continuar)"

# ------------------------------------------------------------------
# Instalación de yay (si no existe)
# ------------------------------------------------------------------
if ! command -v yay &> /dev/null; then
    warn "yay no encontrado. Instalando ayudante AUR..."
    sudo pacman -S --needed --noconfirm git base-devel > /dev/null || {
        error "No se pudo instalar git/base-devel"
        exit 1
    }
    rm -rf /tmp/yay-install
    git clone https://aur.archlinux.org/yay.git /tmp/yay-install
    (cd /tmp/yay-install && makepkg -si --noconfirm) || {
        error "Falló la instalación de yay"
        exit 1
    }
    rm -rf /tmp/yay-install
    success "yay instalado correctamente."
fi

# ------------------------------------------------------------------
# Menú principal
# ------------------------------------------------------------------
echo ""
echo -e "${CYAN}${BOLD}¿Qué deseas instalar de la suite EmeDotEme?${NC}"
echo -e "1) ${BOLD}Full Experience${NC} (Hyprland, Apps, Dotfiles, AI)"
echo -e "2) ${BOLD}Solo AI Assistant${NC} (EmeBotEme)"
echo -e "3) ${BOLD}Solo Dotfiles${NC} (Configuraciones base)"
read -p "Selecciona una opción [1-3]: " main_choice

case $main_choice in
    1|3)
        # ------------------------------------------------------------------
        # Paquetes Pacman
        # ------------------------------------------------------------------
        info "Instalando paquetes esenciales..."
        sudo pacman -S --needed --noconfirm \
            zsh zsh-autosuggestions zsh-syntax-highlighting \
            starship eza bat \
            cliphist wl-clipboard swappy swaybg \
            hyprland hyprcursor hyprlang hyprutils hyprgraphics hyprwayland-scanner \
            waybar rofi kitty nautilus grim slurp brightnessctl playerctl \
            pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber \
            papirus-icon-theme ttf-jetbrains-mono-nerd inotify-tools \
            socat jq python \
            power-profiles-daemon networkmanager network-manager-applet bluez bluez-utils blueman \
            xdg-desktop-portal-hyprland xdg-desktop-portal-gtk polkit-gnome fastfetch > /dev/null 2>&1 &
        show_progress $! "Instalando desde Pacman" || warn "Algunos paquetes Pacman fallaron"

        # ------------------------------------------------------------------
        # Paquetes AUR
        # ------------------------------------------------------------------
        info "Instalando desde AUR..."
        yay -S --needed --noconfirm \
            google-chrome swaync libnotify ttf-font-awesome nwg-displays \
            catppuccin-gtk-theme-mocha > /dev/null 2>&1 &
        show_progress $! "Compilando desde AUR" || warn "Algunos paquetes AUR fallaron"

        # ------------------------------------------------------------------
        # Habilitar servicios del sistema
        # ------------------------------------------------------------------
        info "Habilitando servicios del sistema..."
        sudo systemctl enable --now NetworkManager 2>/dev/null || warn "Falló NetworkManager"
        sudo systemctl enable --now bluetooth 2>/dev/null || warn "Falló bluetooth"
        sudo systemctl enable --now power-profiles-daemon 2>/dev/null || warn "Falló power-profiles-daemon"

        # ------------------------------------------------------------------
        # Selección de GPU
        # ------------------------------------------------------------------
        set_gpu_env() {
            local gpu="$1"
            local file="$DOTFILES_DIR/config/hypr/envvariables.lua"
            local name

            # Comenta cualquier variable de GPU que estuviera activa.
            for name in LIBVA_DRIVER_NAME MESA_LOADER_DRIVER_NAME __GLX_VENDOR_LIBRARY_NAME NVD_BACKEND; do
                sed -i -E "s|^([[:space:]]*)hl\.env\(\"$name\"|\1-- hl.env(\"$name\"|" "$file"
            done

            # Descomenta únicamente el bloque de la GPU elegida.
            case "$gpu" in
                intel)
                    sed -i -E 's|^([[:space:]]*)-- (hl\.env\("LIBVA_DRIVER_NAME", "iHD"\))|\1\2|; s|^([[:space:]]*)-- (hl\.env\("MESA_LOADER_DRIVER_NAME", "iris"\))|\1\2|' "$file"
                    ;;
                nvidia)
                    sed -i -E 's|^([[:space:]]*)-- (hl\.env\("LIBVA_DRIVER_NAME", "nvidia"\))|\1\2|; s|^([[:space:]]*)-- (hl\.env\("__GLX_VENDOR_LIBRARY_NAME", "nvidia"\))|\1\2|; s|^([[:space:]]*)-- (hl\.env\("NVD_BACKEND", "direct"\))|\1\2|' "$file"
                    ;;
                amd)
                    sed -i -E 's|^([[:space:]]*)-- (hl\.env\("LIBVA_DRIVER_NAME", "radeonsi"\))|\1\2|; s|^([[:space:]]*)-- (hl\.env\("MESA_LOADER_DRIVER_NAME", "radeonsi"\))|\1\2|' "$file"
                    ;;
            esac
        }

        echo ""
        echo -e "${CYAN}${BOLD}¿Qué GPU tienes?${NC}"
        echo -e "1) ${BOLD}Intel${NC}"
        echo -e "2) ${BOLD}NVIDIA${NC}"
        echo -e "3) ${BOLD}AMD${NC}"
        read -p "Selecciona una opción [1-3]: " gpu_choice
        case $gpu_choice in
            1)
                info "Configurando envvariables para Intel..."
                set_gpu_env intel
                ;;
            2)
                info "Configurando envvariables para NVIDIA..."
                set_gpu_env nvidia
                ;;
            3)
                info "Configurando envvariables para AMD..."
                set_gpu_env amd
                ;;
            *)
                warn "Opción inválida; se deja la configuración de GPU actual."
                ;;
        esac

        # ------------------------------------------------------------------
        # Enlaces simbólicos de configuración
        # ------------------------------------------------------------------
        info "Configurando enlaces simbólicos..."
        mkdir -p ~/.config

        # Limpiar symlinks rotos de configuraciones que ya no existan en el repo.
        # pulse se trata aparte porque puede ser un symlink roto tras actualizar
        # el repo (el cookie ya no vive en git).
        for existing in "$HOME/.config/"*; do
            if [[ -L "$existing" ]] && [[ ! -e "$existing" ]] && [[ "$(basename "$existing")" != "pulse" ]]; then
                rm -f "$existing"
                info "Limpiando symlink roto: $(basename "$existing")"
            fi
        done

        # ~/.config/pulse es estado local de PulseAudio: nunca debe apuntar al repo.
        # Si venía enlazado de una instalación anterior, se migra conservando el cookie
        # (o se crea un directorio local vacío si el symlink ya estaba roto).
        if [[ -L "$HOME/.config/pulse" ]] && [[ "$(readlink "$HOME/.config/pulse")" == "$DOTFILES_DIR/config/pulse" ]]; then
            info "Migrando ~/.config/pulse a un directorio local..."
            pulse_tmp=$(mktemp -d)
            if [[ -d "$HOME/.config/pulse/" ]]; then
                cp -a "$HOME/.config/pulse/." "$pulse_tmp/" 2>/dev/null || true
            fi
            rm -f "$HOME/.config/pulse"
            mv "$pulse_tmp" "$HOME/.config/pulse"
            chmod 700 "$HOME/.config/pulse"
            chmod 600 "$HOME/.config/pulse/cookie" 2>/dev/null || true
        fi

        # Solo se enlazan configuraciones que el repo gestiona de verdad.
        # gtk-2.0/gtk-3.0 y pulse se dejan como estado local para no pisar
        # configuraciones de apps ni credenciales del servidor de audio.
        MANAGED_CONFIGS=(hypr kitty nwg-displays rofi starship swaync swappy waybar)
        for dir_name in "${MANAGED_CONFIGS[@]}"; do
            dir="$DOTFILES_DIR/config/$dir_name"
            [[ -d "$dir" ]] || continue
            target="$HOME/.config/$dir_name"
            if [[ -d "$target" ]] && [[ ! -L "$target" ]]; then
                warn "Config local detectada: $target"
                read -p "¿Hacer copia de seguridad antes de reemplazar? (S/n): " backup_choice
                case "${backup_choice:-S}" in
                    [nN])
                        warn "Se conserva $target; no se enlaza $dir_name."
                        continue
                        ;;
                    *)
                        cp -r "$target" "${target}.bak"
                        success "Backup creado: ${target}.bak"
                        ;;
                esac
                rm -rf "$target"
            elif [[ -L "$target" ]]; then
                rm -f "$target"
            fi
            ln -sfn "$dir" "$target"
            success ".config/$dir_name enlazado."
        done

        # Carpetas usadas por los atajos de captura de pantalla
        mkdir -p "$HOME/Imágenes"

        # Symlink directo de starship.toml (prioridad sobre starship/starship.toml)
        if [[ -f "$DOTFILES_DIR/config/starship/starship.toml" ]]; then
            ln -sf "$DOTFILES_DIR/config/starship/starship.toml" "$HOME/.config/starship.toml"
        fi

        # ------------------------------------------------------------------
        # Oh My Zsh
        # ------------------------------------------------------------------
        if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
            info "Instalando Oh My Zsh..."
            sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended 2>/dev/null || warn "No se pudo instalar Oh My Zsh"
        fi

        # Backup .zshrc local antes de reemplazar
        link_zshrc=1
        if [[ -f "$HOME/.zshrc" ]] && [[ ! -L "$HOME/.zshrc" ]]; then
            warn "Config local detectada: ~/.zshrc"
            read -p "¿Hacer copia de seguridad antes de reemplazar? (S/n): " zsh_backup
            case "${zsh_backup:-S}" in
                [nN])
                    warn "Se conserva ~/.zshrc; no se enlaza el del repo."
                    link_zshrc=0
                    ;;
                *)
                    cp "$HOME/.zshrc" "$HOME/.zshrc.bak"
                    success "Backup creado: ~/.zshrc.bak"
                    rm -f "$HOME/.zshrc"
                    ;;
            esac
        fi

        if [[ $link_zshrc -eq 1 ]]; then
            if [[ -f "$DOTFILES_DIR/.zshrc" ]]; then
                ln -sf "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
                success "Configuración visual y shell enlazada."
            else
                warn "No se encontró .zshrc en $DOTFILES_DIR"
            fi
        fi

        # Agregar usuario a grupos necesarios (evita duplicados)
        sudo usermod -aG video,input,audio "$USER" 2>/dev/null

        # ------------------------------------------------------------------
        # Menú de arranque
        # ------------------------------------------------------------------
        print_banner
        echo -e "${CYAN}${BOLD}¿Cómo prefieres que arranque el sistema?${NC}"
        echo -e "1) ${BOLD}Auto-login Directo${NC} (TTY1)"
        echo -e "2) ${BOLD}Gestor Visual (SDDM)${NC}"
        echo -e "3) ${BOLD}Manual (Terminal)${NC}"
        read -p "Selecciona una opción [1-3]: " login_choice

        case $login_choice in
            1)
                info "Configurando Auto-login..."
                # Deshabilitar SDDM si estaba activo antes
                if systemctl is-enabled sddm 2>/dev/null | grep -q enabled; then
                    sudo systemctl disable sddm 2>/dev/null
                    info "SDDM deshabilitado (se usará auto-login)"
                fi

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
                success "Auto-login configurado."
                ;;
            2)
                info "Instalando y habilitando SDDM..."
                sudo pacman -S --needed --noconfirm sddm > /dev/null 2>&1
                sudo systemctl enable sddm 2>/dev/null
                success "SDDM habilitado."
                ;;
            3)
                info "Modo manual seleccionado. No se configuró auto-inicio."
                ;;
            *)
                warn "Opción inválida. No se configuró el arranque."
                ;;
        esac
        ;;
    2)
        # Solo AI — no necesita paquetes del sistema
        ;;
    *)
        error "Opción inválida. Saliendo."
        exit 1
        ;;
esac

# ------------------------------------------------------------------
# Configuración de la IA (EmeBotEme) — opciones 1 y 2
# ------------------------------------------------------------------
if [[ $main_choice == "1" || $main_choice == "2" ]]; then
    info "Configurando IA (EmeBotEme)..."

    AI_INSTALL_DIR="$HOME/.config/emeboteme"

    # Limpiar instalación anterior (excepto .env y venv para conservar token)
    if [[ -d "$AI_INSTALL_DIR/ai" ]]; then
        info "Limpiando instalación anterior de IA..."
        rm -rf "$AI_INSTALL_DIR/ai"
    fi

    mkdir -p "$AI_INSTALL_DIR/ai"
    # Copiar archivos de IA excluyendo __pycache__
    (cd "$DOTFILES_DIR/modules/ai" && tar cf - --exclude='__pycache__' .) | (cd "$AI_INSTALL_DIR/ai" && tar xf -)

    # Reemplazar placeholder con ruta real de Opencode
    sed -i "s|__OPCODE_PATH__|$HOME/.opencode/bin/opencode|" "$AI_INSTALL_DIR/ai/config.json"

    # Copiar focus_listener.sh al directorio de IA para que autostart.lua lo lance
    cp "$DOTFILES_DIR/core/scripts/focus_listener.sh" "$AI_INSTALL_DIR/focus_listener.sh"
    chmod +x "$AI_INSTALL_DIR/focus_listener.sh"

    # Entorno virtual de Python
    if [[ ! -d "$AI_INSTALL_DIR/venv" ]]; then
        info "Creando entorno virtual de Python..."
        if ! command -v python3 &> /dev/null; then
            error "python3 no está instalado. Instálalo con: sudo pacman -S python"
            exit 1
        fi
        python3 -m venv "$AI_INSTALL_DIR/venv" || {
            error "No se pudo crear el entorno virtual. Instala python3-venv con: sudo pacman -S python python-venv"
            exit 1
        }
    else
        info "Entorno virtual ya existe, actualizando..."
    fi

    source "$AI_INSTALL_DIR/venv/bin/activate"

    pip install --upgrade pip > /dev/null 2>&1
    info "Instalando dependencias de Python..."
    pip install -r "$AI_INSTALL_DIR/ai/requirements.txt" > /dev/null 2>&1 &
    show_progress $! "Instalando dependencias en venv" || warn "Falló alguna dependencia de Python"

    DOT_ENV_FILE="$AI_INSTALL_DIR/.env"

    # Gestión de HF_TOKEN
    if [[ -z "$HF_TOKEN" ]]; then
        if [[ -f "$DOT_ENV_FILE" ]]; then
            HF_TOKEN=$(grep '^HF_TOKEN=' "$DOT_ENV_FILE" | cut -d'=' -f2-)
        fi
    fi

    if [[ -z "$HF_TOKEN" ]]; then
        warn "No se encontró HF_TOKEN configurado."
        read -r -p "Introduce tu HF_TOKEN de Hugging Face (deja vacío para omitir): " hf_token
        if [[ -n "$hf_token" ]]; then
            echo "HF_TOKEN=$hf_token" > "$DOT_ENV_FILE"
            success "Token guardado en $DOT_ENV_FILE"
        else
            warn "No se proporcionó token. La IA podría tener problemas para descargar modelos protegidos."
        fi
    else
        success "HF_TOKEN detectado y configurado."
        if [[ ! -f "$DOT_ENV_FILE" ]]; then
            echo "HF_TOKEN=$HF_TOKEN" > "$DOT_ENV_FILE"
        fi
    fi

    # El token es un secreto: solo el usuario debe poder leerlo.
    [[ -f "$DOT_ENV_FILE" ]] && chmod 600 "$DOT_ENV_FILE"

    # Servicio systemd --user
    mkdir -p "$HOME/.config/systemd/user"
    cp "$DOTFILES_DIR/core/services/emeboteme.service" "$HOME/.config/systemd/user/"
    sed -i "s|ExecStart=.*|ExecStart=$AI_INSTALL_DIR/venv/bin/python -u $AI_INSTALL_DIR/ai/main.py|" "$HOME/.config/systemd/user/emeboteme.service"

    systemctl --user daemon-reload 2>/dev/null || warn "No se pudo recargar systemd --user (quizás no hay sesión)"
    systemctl --user enable --now emeboteme.service 2>/dev/null || warn "No se pudo habilitar el servicio EmeBotEme (se iniciará al próximo inicio de sesión)"

    # Pre-descarga de modelos Whisper
    info "Descargando modelos de IA (Whisper tiny y base)..."
    if "$AI_INSTALL_DIR/venv/bin/python" -c "from faster_whisper import WhisperModel; WhisperModel('tiny'); WhisperModel('base')" > /tmp/whisper_download.log 2>&1; then
        success "Modelos descargados correctamente."
    else
        error "Fallo al descargar modelos de IA. Revisa /tmp/whisper_download.log"
        warn "Es posible que la IA no funcione correctamente sin conexión o espacio en disco."
    fi

    success "IA configurada."
fi

# ------------------------------------------------------------------
# Comprobación de binarios usados por autostart.lua
# ------------------------------------------------------------------
for cmd in swaybg nm-applet blueman-applet hyprshutdown; do
    command -v "$cmd" >/dev/null 2>&1 || warn "Falta '$cmd'; autostart.lua lo omitirá. Instálalo si quieres esa función."
done

# Hyprland 0.57 usa dispatchers Lua. Waybar < 0.16 sigue enviando
# "dispatch workspace N" por IPC y los clicks en workspaces no hacen nada.
if command -v waybar >/dev/null 2>&1; then
    waybar_ver=$(waybar --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    if [[ -n "$waybar_ver" ]] && [[ "$(printf '%s\n' 0.16.0 "$waybar_ver" | sort -V | head -1)" != "0.16.0" ]]; then
        warn "Waybar $waybar_ver es anterior a 0.16.0: los clicks en workspaces no funcionan con Hyprland 0.57 (Lua). Actualiza a Waybar >= 0.16."
    fi
fi

echo ""
info "¡Instalación completada!"
read -p "¿Reiniciar ahora? (s/n): " confirm_reboot
[[ $confirm_reboot == [sS] ]] && sudo reboot

#!/bin/bash

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${RED}⚠️  ADVERTENCIA DE SEGURIDAD ⚠️${NC}"
echo -e "${YELLOW}Este script configura auto-login SIN contraseña en tty1${NC}"
echo -e "${YELLOW}Cualquiera con acceso físico a tu PC podrá entrar sin password${NC}"
echo ""
read -p "¿Estás seguro de que quieres continuar? (y/n): " confirm

if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Cancelado - Deberás hacer login manual y ejecutar 'Hyprland'${NC}"
    exit 0
fi

echo -e "${GREEN}Configurando auto-login para el usuario: $USER${NC}"

# Create systemd override for getty@tty1
echo -e "${GREEN}Creando override para getty@tty1...${NC}"
sudo mkdir -p /etc/systemd/system/getty@tty1.service.d

sudo tee /etc/systemd/system/getty@tty1.service.d/override.conf > /dev/null <<EOF
[Service]
Type=simple
ExecStart=
ExecStart=-/usr/bin/agetty --autologin $USER --noclear %I \$TERM
EOF

echo -e "${GREEN}Override creado${NC}"

# Check if ~/.zprofile has the Hyprland autostart block
echo -e "${GREEN}Verificando ~/.zprofile...${NC}"

if ! grep -q "exec Hyprland" ~/.zprofile 2>/dev/null; then
    echo -e "${YELLOW}Añadiendo bloque de auto-arranque a ~/.zprofile${NC}"
    cat >> ~/.zprofile <<'EOF'

# Auto-start Hyprland on tty1
if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    exec Hyprland
fi
EOF
else
    echo -e "${GREEN}~/.zprofile ya tiene configurado el auto-arranque${NC}"
fi

echo ""
echo -e "${GREEN}=== Configuración de auto-login completada ===${NC}"
echo -e "${YELLOW}Al reiniciar, entrarás directamente a Hyprland sin contraseña${NC}"

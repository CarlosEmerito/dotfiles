# Scripts útiles

## screenshot.sh

Captura de pantalla para Hyprland.

```bash
./screenshot.sh          # Selección interactiva
./screenshot.sh full     # Seleccionar área
./screenshot.sh screen  # Pantalla completa
```

Requiere: `grim`, `slurp`, `wl-copy`, `notify-send`

---

## record.sh

Grabación de pantalla.

```bash
./record.sh start    # Iniciar grabación
./record.sh stop     # Detener grabación
./record.sh status  # Ver estado
```

Requiere: `wf-recorder`, `slurp`

---

## random-wallpaper.sh

Cambia el wallpaper aleatoriamente.

```bash
./random-wallpaper.sh                    # Usa ~/wallpapers
./random-wallpaper.sh /path/to/walls    # Directorio personalizado
```

Requiere: `hyprctl` (Hyprland)

---

## update-dotfiles.sh

Actualiza las dotfiles desde GitHub.

```bash
./update-dotfiles.sh
```

---

## hservice.sh

Gestor de servicios.

```bash
./hservice.sh restart waybar   # Reiniciar waybar
./hservice.sh kill rofi       # Matar rofi
```

---

## Instalación

Para usar los scripts desde cualquier lugar:

```bash
mkdir -p ~/scripts
cp scripts/*.sh ~/scripts/
echo 'export PATH="$HOME/scripts:$PATH"' >> ~/.bashrc
```

# Dotfiles de Hyprland

Configuración personal de Arch Linux + Hyprland, pensada para reinstalar el
escritorio en un equipo nuevo con un solo comando.

## Qué incluye

- **Hyprland** (configuración en Lua), Waybar, Kitty, Rofi, SwayNC, Swappy.
- **Starship**, Zsh, btop y fastfetch.
- **Servicios de usuario** de systemd (copias de seguridad, analíticas, etc.).
- **Scripts propios** en `~/.local/bin`.
- Un **instalador** que enlaza o copia cada cosa en su sitio, con copias de
  seguridad y modo simulación.

No incluye secretos, tokens, cachés ni el estado interno de las aplicaciones.

## Tema

El escritorio usa una paleta oscura violeta/dorado: Waybar, Rofi, SwayNC,
Kitty, btop, Starship, Hyprland y la pantalla de bloqueo comparten los mismos
colores. La referencia completa está en [docs/TEMAS.md](docs/TEMAS.md).

## Requisitos

- Arch Linux (con `pacman`).
- Un usuario normal con `sudo`.
- Hyprland 0.57 o superior (la configuración usa Lua).
- Waybar 0.16 o superior para que los clics en los workspaces funcionen.

## Instalación rápida

```bash
git clone https://github.com/CarlosEmerito/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh --dry-run     # ver qué haría, sin tocar nada
./install.sh               # menú interactivo
```

Para una instalación completa sin preguntas:

```bash
./install.sh --only all --yes --gpu nvidia
```

Después, cierra sesión y vuelve a entrar para que Hyprland cargue la
configuración nueva.

## Opciones del instalador

| Opción | Qué hace |
| :--- | :--- |
| `--dry-run`, `-n` | Enseña las acciones sin cambiar nada |
| `--yes`, `-y` | No pregunta (valores por defecto) |
| `--only config,packages,services,all` | Elige secciones |
| `--no-packages` / `--no-services` / `--no-config` | Salta una sección |
| `--enable-services` | Habilita los servicios systemd de usuario |
| `--force` | Reemplaza también los archivos que se copian |
| `--gpu intel\|nvidia\|amd\|none` | Ajusta las variables de GPU |
| `--upgrade` | Actualiza el sistema antes de instalar paquetes |

## Cómo coloca los archivos

- **Enlaces** para lo que editas tú (Hyprland, Waybar, Kitty, Rofi, Zsh…).
  Así, un cambio en tu escritorio ya queda en el repositorio.
- **Copias** para lo que las aplicaciones reescriben (ajustes GTK,
  `nwg-displays`). Se copian solo si faltan; con `--force` se reemplazan.
- **Ejemplo de monitores**: `monitors.lua` no se versiona porque depende del
  hardware. El instalador crea uno de ejemplo si no existe; genera el tuyo con
  `nwg-displays`.

Las copias de seguridad se guardan en `~/.dotfiles-backups/AAAAMMDD-HHMMSS/`.

## Estructura

```
dotfiles/
├── install.sh          Instalador
├── home/               Copia de la carpeta personal
│   ├── .zshenv  .zshrc  .zprofile  .bashrc  .bash_profile
│   ├── .config/        Hyprland, Waybar, Kitty, Rofi, servicios…
│   └── .local/share/   Lanzadores .desktop
├── bin/                Scripts propios para ~/.local/bin
└── docs/               Guías
```

## Atajos principales

| Tecla | Acción |
| :--- | :--- |
| `Super + Q` / `Super + Enter` | Terminal (Kitty) |
| `Super + Space` | Lanzador de aplicaciones (Rofi) |
| `Super + Shift + Space` | Selector de ventanas (Rofi) |
| `Ctrl + Tab` (en Rofi) | Cambiar Apps / Comandos / Ventanas |
| `Super + Escape` | Menú de apagado y bloqueo |
| `Super + L` | Bloquear la pantalla |
| `Super + E` | Explorador de archivos (Nautilus) |
| `Super + F` | Navegador (Chrome) |
| `Super + C` / `Alt + F4` | Cerrar ventana |
| `Super + N` | Centro de notificaciones |
| `Super + M` | Apagar / cerrar sesión |
| `Super + 1…0` | Cambiar de workspace |
| `Super + Shift + 1…0` | Mover ventana a otro workspace |
| `Super + flechas` | Cambiar el foco |
| `Super + S` | Mostrar/ocultar el scratchpad |
| `Super + V` | Historial del portapapeles |
| `Print` | Captura de pantalla completa |
| `Super + Print` | Captura de un área |
| `Super + Shift + S` | Captura y editar con Swappy |
| `Super + F5` | Emergencia: restaurar solo la pantalla del portátil |

## Notas

- **Monitores:** edita `~/.config/hypr/monitors.lua` o usa `nwg-displays`.
  Ese archivo es local y no se sube al repositorio.
- **GPU:** `envvariables.lua` trae los bloques de Intel, NVIDIA y AMD. El
  instalador activa solo el que elijas.
- **Zsh:** Oh My Zsh se usa solo con el plugin `sudo`; los alias de git son
  propios y ligeros. `PATH` y `EDITOR` viven en `.zshenv` para que también los
  hereden Hyprland y las apps gráficas. Starship es el prompt y
  `zsh-autosuggestions`/`zsh-syntax-highlighting` se cargan al final.
- **Secretos:** nunca se guardan aquí. Si necesitas tokens, usa archivos
  locales como `~/.config/qomu/mcp.env` (ignorados por git).
- **Servicios con proyectos externos:** algunas unidades (`mydot`,
  `history_bot`, `hermes-gateway`) esperan proyectos en `~/Proyectos/myDot`,
  `~/faceless_history_bot` y `~/.hermes`. Si no existen, el servicio fallará;
  el instalador no los habilita por defecto.
- **Red:** `nm-applet` ya no se inicia. El módulo de red de Waybar muestra el
  estado y al hacer clic abre `nm-connection-editor`.
- **Primer clic en Waybar:** el lanzador `~/.local/bin/waybar` precalienta
  `systeminfo` y lo mantiene caliente para evitar el tirón del primer clic en
  un workspace.
- **Actualizar:** `cd ~/dotfiles && git pull`. Los enlaces hacen el resto.

## Documentación

- [Guía de instalación detallada](docs/INSTALAR.md)
- [Paleta y archivos del tema](docs/TEMAS.md)

## Licencia

MIT. Consulta el archivo [LICENSE](LICENSE).

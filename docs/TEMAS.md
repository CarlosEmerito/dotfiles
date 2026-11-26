# Tema «Lanzador oscuro»

Paleta y archivos que forman el aspecto visual del escritorio.

## Paleta

| Nombre | Hex | Uso |
| :--- | :--- | :--- |
| `bg` | `#141020` | Fondo base, barra, Rofi, Kitty |
| `surface` | `#1E182C` | Tarjetas, módulos y filas |
| `surface-alt` | `#241C35` | Hover, tooltips y botones |
| `line` | `#3A2C52` | Bordes y divisores |
| `fg` | `#EDE8F5` | Texto principal |
| `muted` | `#A396B8` | Texto secundario |
| `accent` | `#8B5CF6` | Violeta de selección y controles |
| `accent-soft` | `#B79CFF` | Violeta claro para títulos y enlaces |
| `gold` | `#E8C547` | Amarillo del reloj, workspace activo y cursor |
| `red` | `#FF6B81` | Errores y urgencias |

## Dónde se aplica

| Componente | Archivo |
| :--- | :--- |
| Rofi | `home/.config/rofi/config.rasi` |
| Waybar | `home/.config/waybar/style.css` |
| SwayNC | `home/.config/swaync/style.css` |
| Kitty | `home/.config/kitty/kitty.conf` |
| Hyprland (bordes y sombras) | `home/.config/hypr/hyprland.lua` |
| Hyprlock | `home/.config/hypr/hyprlock.conf` |
| Starship | `home/.config/starship/starship.toml` |
| btop | `home/.config/btop/themes/violet.theme` |
| Fondo | `home/.local/share/wallpapers/lanzador-oscuro.png` |

## Cómo cambiar el acento

1. Cambia `accent` y/o `gold` en `waybar/style.css`, `swaync/style.css` y
   `rofi/config.rasi`.
2. En Kitty, actualiza `cursor`, `selection_background` y los colores ANSI.
3. En btop, edita `violet.theme`.
4. Reinicia Waybar y SwayNC, y vuelve a abrir las terminales.

No hay un archivo único de variables porque cada formato usa su propio
sistema de temas. Esta guía es la referencia para mantenerlos sincronizados.

## Detalles

- **Waybar**: el workspace activo es dorado y los botones ocupan todo el alto
  de la barra para poder clicar en el borde superior.
- **Rofi**: 3 columnas, búsqueda fuzzy y modos Apps / Comandos / Ventanas con
  `Ctrl + Tab`.
- **SwayNC**: panel de 680 px con volumen y brillo; sliders violeta/dorado.
- **Hyprlock**: fondo desenfocado, reloj dorado y campo de contraseña violeta.
- **btop**: tema `violet` con gráficas en violeta, dorado, verde y cian.

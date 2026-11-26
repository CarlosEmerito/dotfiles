# Guía de instalación

Esta guía explica, paso a paso, cómo dejar el escritorio funcionando en un
equipo nuevo. No hace falta saber programar.

## 1. Antes de empezar

Necesitas:

- Arch Linux instalado y con conexión a internet.
- Un usuario normal (no root) que pueda usar `sudo`.
- Al menos 2 GB libres.

## 2. Descargar el repositorio

```bash
git clone https://github.com/CarlosEmerito/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

## 3. Probar sin cambiar nada

```bash
./install.sh --dry-run
```

Verás una lista de lo que haría. No modifica ningún archivo.

## 4. Instalar

```bash
./install.sh
```

Elige una opción del menú:

1. Configuración del escritorio.
2. Paquetes.
3. Servicios de usuario.
4. Todo.

Si es la primera vez, elige **4 (Todo)**.

El instalador:

- Pregunta antes de reemplazar algo que ya exista.
- Guarda copias en `~/.dotfiles-backups/`.
- No enciende servicios sin permiso.
- Se puede volver a ejecutar sin miedo.

## 5. Elegir la GPU

Si eliges instalar paquetes o configuración, el instalador preguntará qué GPU
tienes. Solo se activa el bloque correspondiente en
`~/.config/hypr/envvariables.lua`.

También puedes hacerlo directamente:

```bash
./install.sh --only config --gpu intel
```

## 6. Configurar los monitores

La configuración de monitores depende de cada equipo y no se guarda en el
repositorio. El instalador crea un ejemplo. Para ajustarlo:

```bash
nwg-displays
```

Coloca las pantallas y pulsa **Apply**. Se generará
`~/.config/hypr/monitors.lua`.

## 7. Aplicar los cambios

Cierra sesión y vuelve a entrar, o reinicia. Hyprland cargará la configuración
nueva.

## 8. Servicios opcionales

Los servicios de systemd de usuario se instalan, pero no se habilitan por
defecto. Para habilitarlos:

```bash
./install.sh --only services --enable-services
```

Algunos servicios necesitan proyectos externos:

| Servicio | Necesita |
| :--- | :--- |
| `mydot.service` y sus timers | `~/Proyectos/myDot` |
| `history_bot.service` y su timer | `~/faceless_history_bot` |
| `hermes-gateway.service` | `~/.hermes` |

Si esos proyectos no existen, el servicio fallará. Puedes ignorarlo o no
habilitarlo.

## 9. Actualizar

```bash
cd ~/dotfiles
git pull
```

Como la mayoría de archivos son enlaces, los cambios se aplican solos. Si
cambió algo que se copia (ajustes GTK o `nwg-displays`), ejecuta:

```bash
./install.sh --only config --force
```

## 10. Si algo sale mal

Las copias de seguridad están en:

```
~/.dotfiles-backups/AAAAMMDD-HHMMSS/
```

Cada archivo conserva su ruta original dentro de esa carpeta. Para recuperar
uno, cópialo de vuelta a su sitio.

## Preguntas frecuentes

**¿Se suben mis tokens?**
No. `.gitignore` bloquea `.env`, `.npmrc`, `.git-credentials` y cualquier
archivo con secretos. Los tokens se quedan solo en tu equipo.

**¿Puedo usar otro gestor de arranque?**
Sí. El archivo `.zprofile` arranca Hyprland en la tty1 si no hay sesión
gráfica. Si usas SDDM u otro gestor, no pasa nada: esa condición no se cumple.

**¿Por qué los monitores no están en el repositorio?**
Porque cada equipo tiene pantallas distintas. Se guarda un ejemplo y el
archivo real se queda en tu equipo.

**¿Qué pasa si vuelvo a ejecutar el instalador?**
Nada malo. Detecta lo que ya está bien y solo actúa sobre lo que falta o
cambió.

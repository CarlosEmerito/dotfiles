# Entorno común para todas las shells de Zsh (interactivas y scripts).
# El PATH se define aquí para que también lo hereden Hyprland y las apps
# lanzadas desde el escritorio, no solo las terminales interactivas.

typeset -U path

path=(
    "$HOME/.opencode/bin"
    "$HOME/bin"
    "$HOME/.local/bin"
    "$HOME/.npm-global/bin"
    "$HOME/.kimi-code/bin"
    $path
)

export EDITOR='nano'

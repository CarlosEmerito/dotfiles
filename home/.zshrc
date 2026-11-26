# Path to Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"

# Prompt: Starship. No cargamos tema de Oh My Zsh.
ZSH_THEME=""

# Plugins de Oh My Zsh. git se ha sustituido por los alias de abajo.
plugins=(sudo)

# Source Oh My Zsh only if it was installed correctly.
if [[ -f "$ZSH/oh-my-zsh.sh" ]]; then
    source "$ZSH/oh-my-zsh.sh"
else
    echo "Aviso: Oh My Zsh no está instalado en $ZSH" >&2
fi

# Starship Prompt
if command -v starship >/dev/null 2>&1; then
    eval "$(starship init zsh)"
fi

# --- Modern Aliases ---
alias ls='eza --icons=auto'
alias ll='eza -lh --icons=auto'
alias la='eza -lah --icons=auto'
alias cat='bat --style=plain --paging=never'

# --- Git aliases (reemplazo ligero del plugin git de Oh My Zsh) ---
alias g='git'
alias gs='git status -sb'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit -v'
alias gcm='git commit -m'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'
alias glog='git log --oneline --graph --decorate -20'

# --- Options ---
# Oh My Zsh activa AUTO_CD por defecto; lo desactivamos para evitar
# cambios de directorio accidentales al escribir mal un comando.
unsetopt AUTO_CD

# --- History ---
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS

# --- Key bindings ---
bindkey '^H' backward-kill-word          # Ctrl+Backspace
bindkey '^[[127;5u' backward-kill-word   # Ctrl+Backspace (kitty/modern terminals)
bindkey '^[[3;5~' kill-word              # Ctrl+Delete

# Qomu MCP token
[ -f "$HOME/.config/qomu/mcp.env" ] && source "$HOME/.config/qomu/mcp.env"

# Fastfetch: solo en la primera shell interactiva de cada terminal.
# FASTFETCH_SHOWN se exporta para que las shells anidadas no lo repitan.
if [[ -o interactive && -t 1 && -z ${FASTFETCH_SHOWN:-} ]] && command -v fastfetch >/dev/null 2>&1; then
    export FASTFETCH_SHOWN=1
    fastfetch
fi

# Autosuggestions y syntax highlighting al final, en este orden.
[[ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
[[ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Path to Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"

# Theme
# ZSH_THEME="robbyrussell"

# Plugins
plugins=(git sudo)

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
alias ls='eza --icons=always'
alias ll='eza -lh --icons=always'
alias la='eza -lah --icons=always'
alias cat='bat --style=plain'

# Source Arch Linux specific plugins if they exist
[[ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
[[ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# --- PATH ---
export PATH="$HOME/.opencode/bin:$HOME/bin:$HOME/.local/bin:$HOME/.npm-global/bin:$HOME/.kimi-code/bin:/usr/local/bin:$PATH"

# --- Environment Variables ---
export EDITOR='nano'
# El HF_TOKEN se gestiona via ~/.config/emeboteme/.env
if [[ -f "$HOME/.config/emeboteme/.env" ]]; then
    source "$HOME/.config/emeboteme/.env"
    export HF_TOKEN
fi

# --- Modern CLI Tools ---
if command -v fastfetch >/dev/null 2>&1; then
    fastfetch
fi

# Better directory navigation
setopt AUTO_CD
setopt GLOB_DOTS

# History settings
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS

# Key bindings
bindkey '^H' backward-kill-word          # Ctrl+Backspace
bindkey '^[[127;5u' backward-kill-word   # Ctrl+Backspace (kitty/modern terminals)
bindkey '^[[3;5~' kill-word              # Ctrl+Delete

# Vercel MCP (vercel-mcp-pro)
# Desactivado para configurar la cuenta personal (carlos09102007@gmail.com).
# El MCP de Vercel ahora usa OAuth (https://mcp.vercel.com); este token era de la cuenta GoTogether.
# Reactivar solo si se vuelve a usar la cuenta GoTogether.
# export VERCEL_TOKEN="..."

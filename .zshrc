# Path to Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"

# Theme
# ZSH_THEME="robbyrussell"

# Plugins
plugins=(git sudo)

# Source Oh My Zsh
source $ZSH/oh-my-zsh.sh

# Starship Prompt
eval "$(starship init zsh)"

# --- Modern Aliases ---
alias ls='eza --icons=always'
alias ll='eza -lh --icons=always'
alias la='eza -lah --icons=always'
alias cat='bat --style=plain'

# Source Arch Linux specific plugins if they exist
[[ -f /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
[[ -f /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# --- PATH ---
export PATH=$HOME/.opencode/bin:$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH
export PATH="$HOME/.npm-global/bin:$PATH"

# --- Environment Variables ---
export EDITOR='nano'
# El HF_TOKEN se gestiona via ~/dotfiles/.env
[[ -f ~/dotfiles/.env ]] && source ~/dotfiles/.env



# --- Modern CLI Tools ---
if command -v fastfetch &> /dev/null; then
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
bindkey '^H' backward-kill-word       # Ctrl+Backspace
bindkey '^[[127;5u' backward-kill-word # Ctrl+Backspace (kitty/modern terminals)
bindkey '^[[3;5~' kill-word           # Ctrl+Delete

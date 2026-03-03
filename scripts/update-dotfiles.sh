#!/usr/bin/env bash
# Update dotfiles from GitHub
# Usage: update-dotfiles

repo_url="https://github.com/CarlosEmerito/dotfiles.git"
dotfiles_dir="$HOME/dotfiles"

if [[ -d "$dotfiles_dir/.git" ]]; then
    cd "$dotfiles_dir"
    echo "Actualizando dotfiles..."
    git pull origin master
    ./install.sh --configs
    echo "¡Dotfiles actualizadas!"
else
    echo "Clonando repositorio..."
    git clone "$repo_url" "$dotfiles_dir"
    cd "$dotfiles_dir"
    ./install.sh --all
fi

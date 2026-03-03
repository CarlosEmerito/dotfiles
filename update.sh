#!/usr/bin/env bash
# Update dotfiles

echo "Updating dotfiles..."

cd "$(dirname "${BASH_SOURCE[0]}")"

# Pull latest changes
if git rev-parse --git-dir > /dev/null 2>&1; then
    git pull origin master
    ./copy.sh
else
    echo "Not a git repository. Clone first:"
    echo "git clone https://github.com/CarlosEmerito/dotfiles.git"
fi

#!/bin/bash
# VS Code settings symlink setup
# Creates symlinks from VS Code config location to this repo

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Determine VS Code config directory based on OS
if [[ "$OSTYPE" == "darwin"* ]]; then
    VSCODE_DIR="$HOME/Library/Application Support/Code/User"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    VSCODE_DIR="$HOME/.config/Code/User"
else
    echo "Unsupported OS: $OSTYPE"
    exit 1
fi

echo "VS Code config directory: $VSCODE_DIR"
echo "Repo directory: $SCRIPT_DIR"

# Create VS Code directory if it doesn't exist
mkdir -p "$VSCODE_DIR"

# Function to create symlink with backup
create_symlink() {
    local source="$1"
    local target="$2"

    if [[ ! -e "$source" ]]; then
        echo "Source does not exist: $source (skipping)"
        return
    fi

    if [[ -L "$target" ]]; then
        echo "Removing existing symlink: $target"
        rm "$target"
    elif [[ -e "$target" ]]; then
        echo "Backing up existing file: $target -> ${target}.backup"
        mv "$target" "${target}.backup"
    fi

    echo "Creating symlink: $target -> $source"
    ln -s "$source" "$target"
}

# Symlink settings.json
create_symlink "$SCRIPT_DIR/settings.json" "$VSCODE_DIR/settings.json"

# Symlink keybindings.json if it exists in repo
create_symlink "$SCRIPT_DIR/keybindings.json" "$VSCODE_DIR/keybindings.json"

# Symlink snippets directory if it exists in repo
if [[ -d "$SCRIPT_DIR/snippets" ]]; then
    create_symlink "$SCRIPT_DIR/snippets" "$VSCODE_DIR/snippets"
fi

echo "Done! VS Code settings are now symlinked."

#!/bin/bash

# Setup Claude configuration symlinks
# This script creates symlinks from ~/.claude to the dotfiles in this repository

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CLAUDE_DIR="$HOME/.claude"

# Create .claude directory if it doesn't exist
mkdir -p "$CLAUDE_DIR"

# Create symlinks for Claude configuration files
echo "Setting up Claude configuration symlinks..."

# Symlink CLAUDE.md
if [ -f "$SCRIPT_DIR/CLAUDE.md" ]; then
    ln -sf "$SCRIPT_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
    echo "✓ Linked CLAUDE.md"
fi

# Symlink settings.json
if [ -f "$SCRIPT_DIR/settings.json" ]; then
    ln -sf "$SCRIPT_DIR/settings.json" "$CLAUDE_DIR/settings.json"
    echo "✓ Linked settings.json"
fi

# Symlink settings.local.json
if [ -f "$SCRIPT_DIR/settings.local.json" ]; then
    ln -sf "$SCRIPT_DIR/settings.local.json" "$CLAUDE_DIR/settings.local.json"
    echo "✓ Linked settings.local.json"
fi

echo "Claude configuration symlinks created successfully!"
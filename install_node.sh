#!/usr/bin/env bash

set -e

OS="$(uname -s)"

case "$OS" in
    Linux*)
        echo "🐧 Detected Linux system"

        # Check if nvm is installed
        if [ -s "$HOME/.nvm/nvm.sh" ]; then
            . "$HOME/.nvm/nvm.sh"
        else
            echo "📦 Installing nvm..."
            curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
            export NVM_DIR="$HOME/.nvm"
            [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        fi

        echo "📦 Installing Node.js LTS via nvm..."
        nvm install --lts
        nvm use --lts
        nvm alias default lts/*

        echo "✅ Node.js $(node --version) installed"
        echo "✅ npm $(npm --version) installed"
        ;;

    Darwin*)
        echo "🍎 Detected macOS system"

        # Check if Homebrew is installed
        if ! command -v brew &> /dev/null; then
            echo "❌ Homebrew is required but not installed."
            echo "Install it from https://brew.sh/"
            exit 1
        fi

        echo "📦 Installing Node.js via Homebrew..."
        brew install node

        # Install watchman for React Native development
        if [ "$1" == "--with-watchman" ]; then
            echo "📦 Installing watchman..."
            brew install watchman
        fi

        echo "✅ Node.js $(node --version) installed"
        echo "✅ npm $(npm --version) installed"
        ;;

    *)
        echo "❌ Unsupported operating system: $OS"
        exit 1
        ;;
esac

# Verify installation
if ! command -v node &> /dev/null; then
    echo "❌ Node.js installation failed"
    exit 1
fi

if ! command -v npm &> /dev/null; then
    echo "❌ npm installation failed"
    exit 1
fi

echo "🎉 Node.js and npm successfully installed!"
#!/bin/bash

# Install npm on Ubuntu 24
# This script installs Node.js and npm using the NodeSource repository for the latest LTS version

set -e  # Exit on any error

echo "🚀 Installing npm on Ubuntu 24..."

# Update package index
echo "📦 Updating package index..."
sudo apt update

# Install curl if not already installed
echo "🔧 Installing curl (if needed)..."
sudo apt install -y curl

# Add NodeSource repository for Node.js LTS
echo "�� Adding NodeSource repository..."
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -

# Install Node.js (which includes npm)
echo "⚡ Installing Node.js and npm..."
sudo apt install -y nodejs

# Verify installation
echo "✅ Verifying installation..."
echo "Node.js version: $(node --version)"
echo "npm version: $(npm --version)"

# Optional: Update npm to latest version
echo "🔄 Updating npm to latest version..."
sudo npm install -g npm@latest

echo "🎉 Installation complete!"
echo "Node.js version: $(node --version)"
echo "npm version: $(npm --version)"

# Display usage information
echo ""
echo "📋 Usage:"
echo "  • Create a new project: npm init"
echo "  • Install packages: npm install <package-name>"
echo "  • Install packages globally: npm install -g <package-name>"
echo "  • Check installed packages: npm list"

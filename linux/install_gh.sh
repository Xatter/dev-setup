#!/bin/bash

# GitHub CLI (gh) Installation Script for Linux
# This script automatically detects your Linux distribution and installs gh using the appropriate method

set -e  # Exit on any error

echo "🚀 GitHub CLI (gh) Installation Script"
echo "======================================"

# Function to detect Linux distribution
detect_distro() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS=$NAME
        DISTRO=$ID
    elif type lsb_release >/dev/null 2>&1; then
        OS=$(lsb_release -si)
        DISTRO=$(echo $OS | tr '[:upper:]' '[:lower:]')
    elif [[ -f /etc/redhat-release ]]; then
        OS=$(cat /etc/redhat-release)
        DISTRO="rhel"
    else
        echo "❌ Cannot detect Linux distribution"
        exit 1
    fi
    
    echo "📋 Detected OS: $OS"
    echo "📋 Distribution ID: $DISTRO"
}

# Function to check if gh is already installed
check_existing_installation() {
    if command -v gh &> /dev/null; then
        echo "✅ GitHub CLI is already installed!"
        echo "📍 Current version: $(gh --version)"
        read -p "🤔 Do you want to continue with the installation/upgrade? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "👋 Installation cancelled."
            exit 0
        fi
    fi
}

# Function to install on Ubuntu/Debian
install_ubuntu_debian() {
    echo "📦 Installing GitHub CLI on Ubuntu/Debian..."
    
    # Install wget if not present
    if ! command -v wget &> /dev/null; then
        echo "📥 Installing wget..."
        sudo apt update
        sudo apt install wget -y
    fi
    
    # Add GitHub CLI repository
    echo "🔑 Adding GitHub CLI repository..."
    sudo mkdir -p -m 755 /etc/apt/keyrings
    wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
    sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    
    # Update and install
    echo "🔄 Updating package list..."
    sudo apt update
    echo "📦 Installing GitHub CLI..."
    sudo apt install gh -y
}

# Function to install on RHEL/CentOS/Fedora
install_rhel_centos_fedora() {
    echo "📦 Installing GitHub CLI on RHEL/CentOS/Fedora..."
    
    # Check if we're using DNF5 or DNF4/YUM
    if command -v dnf &> /dev/null; then
        DNF_VERSION=$(dnf --version 2>/dev/null | head -n1 | grep -o '[0-9]\+' | head -n1)
        if [[ $DNF_VERSION -ge 5 ]]; then
            echo "🔧 Using DNF5..."
            sudo dnf install dnf5-plugins -y
            sudo dnf config-manager addrepo --from-repofile=https://cli.github.com/packages/rpm/gh-cli.repo
            sudo dnf install gh --repo gh-cli -y
        else
            echo "🔧 Using DNF4..."
            sudo dnf install 'dnf-command(config-manager)' -y
            sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
            sudo dnf install gh --repo gh-cli -y
        fi
    elif command -v yum &> /dev/null; then
        echo "🔧 Using YUM..."
        sudo yum install yum-utils -y
        sudo yum-config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
        sudo yum install gh -y
    else
        echo "❌ Neither DNF nor YUM found. Cannot install."
        exit 1
    fi
}

# Function to install on openSUSE
install_opensuse() {
    echo "📦 Installing GitHub CLI on openSUSE..."
    sudo zypper addrepo https://cli.github.com/packages/rpm/gh-cli.repo
    sudo zypper ref
    sudo zypper install gh -y
}

# Function to install on Arch Linux
install_arch() {
    echo "📦 Installing GitHub CLI on Arch Linux..."
    sudo pacman -Sy github-cli --noconfirm
}

# Function to install on Alpine Linux
install_alpine() {
    echo "📦 Installing GitHub CLI on Alpine Linux..."
    
    # Add community repository if not already present
    if ! grep -q "community" /etc/apk/repositories; then
        echo "🔧 Adding community repository..."
        sudo sh -c 'echo "https://dl-cdn.alpinelinux.org/alpine/v$(cat /etc/alpine-release | cut -d. -f1-2)/community" >> /etc/apk/repositories'
    fi
    
    sudo apk update
    sudo apk add github-cli
}

# Function to install via binary download (fallback)
install_binary() {
    echo "📦 Installing GitHub CLI via binary download..."
    
    # Detect architecture
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)
            ARCH="amd64"
            ;;
        aarch64)
            ARCH="arm64"
            ;;
        i386|i686)
            ARCH="386"
            ;;
        *)
            echo "❌ Unsupported architecture: $ARCH"
            exit 1
            ;;
    esac
    
    # Get latest version
    echo "🔍 Fetching latest version..."
    LATEST_VERSION=$(curl -s https://api.github.com/repos/cli/cli/releases/latest | grep -o '"tag_name": "v[^"]*' | grep -o 'v[^"]*')
    
    if [[ -z "$LATEST_VERSION" ]]; then
        echo "❌ Failed to fetch latest version"
        exit 1
    fi
    
    echo "📥 Downloading GitHub CLI $LATEST_VERSION..."
    DOWNLOAD_URL="https://github.com/cli/cli/releases/download/${LATEST_VERSION}/gh_${LATEST_VERSION#v}_linux_${ARCH}.tar.gz"
    
    # Download and install
    cd /tmp
    wget -O gh.tar.gz "$DOWNLOAD_URL"
    tar -xzf gh.tar.gz
    sudo mv gh_${LATEST_VERSION#v}_linux_${ARCH}/bin/gh /usr/local/bin/
    sudo chmod +x /usr/local/bin/gh
    
    # Clean up
    rm -rf gh.tar.gz gh_${LATEST_VERSION#v}_linux_${ARCH}
    
    echo "✅ GitHub CLI installed to /usr/local/bin/gh"
}

# Main installation function
install_gh() {
    case $DISTRO in
        ubuntu|debian|pop|linuxmint|elementary)
            install_ubuntu_debian
            ;;
        rhel|centos|fedora|rocky|almalinux)
            install_rhel_centos_fedora
            ;;
        opensuse*|sles)
            install_opensuse
            ;;
        arch|manjaro|endeavouros)
            install_arch
            ;;
        alpine)
            install_alpine
            ;;
        *)
            echo "⚠️  Distribution not directly supported, trying binary installation..."
            install_binary
            ;;
    esac
}

# Function to verify installation
verify_installation() {
    echo "🔍 Verifying installation..."
    if command -v gh &> /dev/null; then
        echo "✅ GitHub CLI successfully installed!"
        echo "📍 Version: $(gh --version)"
        echo ""
        echo "🎉 Next steps:"
        echo "1. Run 'gh auth login' to authenticate with GitHub"
        echo "2. Run 'gh --help' to see available commands"
        echo "3. Run 'gh repo view' in a GitHub repository to test"
        echo ""
        echo "📚 Documentation: https://cli.github.com/manual/"
    else
        echo "❌ Installation failed. GitHub CLI not found in PATH."
        exit 1
    fi
}

# Main execution
main() {
    echo "🔍 Checking system requirements..."
    
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        echo "⚠️  This script should not be run as root directly."
        echo "   It will prompt for sudo when needed."
        exit 1
    fi
    
    # Check for sudo
    if ! command -v sudo &> /dev/null; then
        echo "❌ sudo is required but not installed."
        exit 1
    fi
    
    detect_distro
    check_existing_installation
    install_gh
    verify_installation
    
    echo "🎊 Installation complete!"
}

# Run main function
main "$@"

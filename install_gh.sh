#!/usr/bin/env bash

set -e

echo "🚀 GitHub CLI (gh) Installation Script"
echo "======================================"

OS="$(uname -s)"

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

check_existing_installation

case "$OS" in
    Linux*)
        echo "🐧 Detected Linux system"

        # Function to detect Linux distribution
        if [[ -f /etc/os-release ]]; then
            . /etc/os-release
            DISTRO=$ID
        elif type lsb_release >/dev/null 2>&1; then
            DISTRO=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
        else
            echo "❌ Cannot detect Linux distribution"
            exit 1
        fi

        echo "📋 Distribution: $DISTRO"

        case $DISTRO in
            ubuntu|debian|pop|linuxmint|elementary)
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
                ;;

            rhel|centos|fedora|rocky|almalinux)
                echo "📦 Installing GitHub CLI on RHEL/CentOS/Fedora..."

                if command -v dnf &> /dev/null; then
                    sudo dnf install 'dnf-command(config-manager)' -y
                    sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
                    sudo dnf install gh --repo gh-cli -y
                elif command -v yum &> /dev/null; then
                    sudo yum install yum-utils -y
                    sudo yum-config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
                    sudo yum install gh -y
                fi
                ;;

            arch|manjaro|endeavouros)
                echo "📦 Installing GitHub CLI on Arch Linux..."
                sudo pacman -Sy github-cli --noconfirm
                ;;

            alpine)
                echo "📦 Installing GitHub CLI on Alpine Linux..."
                sudo apk add github-cli
                ;;

            *)
                echo "⚠️  Distribution not directly supported, installing via binary..."

                # Detect architecture
                ARCH=$(uname -m)
                case $ARCH in
                    x86_64) ARCH="amd64" ;;
                    aarch64) ARCH="arm64" ;;
                    *) echo "❌ Unsupported architecture: $ARCH"; exit 1 ;;
                esac

                # Get latest version
                LATEST_VERSION=$(curl -s https://api.github.com/repos/cli/cli/releases/latest | grep -o '"tag_name": "v[^"]*' | grep -o 'v[^"]*')

                echo "📥 Downloading GitHub CLI $LATEST_VERSION..."
                cd /tmp
                wget -O gh.tar.gz "https://github.com/cli/cli/releases/download/${LATEST_VERSION}/gh_${LATEST_VERSION#v}_linux_${ARCH}.tar.gz"
                tar -xzf gh.tar.gz
                sudo mv gh_${LATEST_VERSION#v}_linux_${ARCH}/bin/gh /usr/local/bin/
                sudo chmod +x /usr/local/bin/gh
                rm -rf gh.tar.gz gh_${LATEST_VERSION#v}_linux_${ARCH}
                ;;
        esac
        ;;

    Darwin*)
        echo "🍎 Detected macOS system"

        # Check if Homebrew is installed
        if ! command -v brew &> /dev/null; then
            echo "❌ Homebrew is required but not installed."
            echo "Install it from https://brew.sh/"
            exit 1
        fi

        echo "📦 Installing GitHub CLI via Homebrew..."
        brew install gh
        ;;

    *)
        echo "❌ Unsupported operating system: $OS"
        exit 1
        ;;
esac

verify_installation
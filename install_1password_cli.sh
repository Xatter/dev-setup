#!/usr/bin/env bash

set -e

echo "🔐 1Password CLI Installation Script"
echo "===================================="

OS="$(uname -s)"

# Function to verify installation
verify_installation() {
    echo "🔍 Verifying installation..."
    if command -v op &> /dev/null; then
        echo "✅ 1Password CLI successfully installed!"
        echo "📍 Version: $(op --version)"
        echo ""
        echo "🎉 Next steps:"
        echo "1. Run 'op signin' to authenticate with your 1Password account"
        echo "2. Run 'op --help' to see available commands"
        echo ""
        echo "📚 Documentation: https://developer.1password.com/docs/cli/"
    else
        echo "❌ Installation failed. 1Password CLI not found in PATH."
        exit 1
    fi
}

case "$OS" in
    Linux*)
        echo "🐧 Detected Linux system"

        # Detect distribution and architecture
        if [[ -f /etc/os-release ]]; then
            . /etc/os-release
            DISTRO=$ID
        else
            echo "❌ Cannot detect Linux distribution"
            exit 1
        fi

        ARCH=$(dpkg --print-architecture 2>/dev/null || uname -m)

        case $DISTRO in
            ubuntu|debian|pop|linuxmint|elementary)
                echo "📦 Installing 1Password CLI on Ubuntu/Debian..."

                # Add 1Password repository
                curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
                    sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg

                echo "deb [arch=$ARCH signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$ARCH stable main" | \
                    sudo tee /etc/apt/sources.list.d/1password.list

                # Add debsig-verify policy
                sudo mkdir -p /etc/debsig/policies/AC2D62742012EA22/
                curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol | \
                    sudo tee /etc/debsig/policies/AC2D62742012EA22/1password.pol

                sudo mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22
                curl -sS https://downloads.1password.com/linux/keys/1password.asc | \
                    sudo gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg

                # Update and install
                sudo apt update
                sudo apt install -y 1password-cli
                ;;

            rhel|centos|fedora|rocky|almalinux)
                echo "📦 Installing 1Password CLI on RHEL/Fedora..."

                # Add 1Password repository
                sudo rpm --import https://downloads.1password.com/linux/keys/1password.asc
                sudo sh -c 'echo -e "[1password]\nname=1Password Stable Channel\nbaseurl=https://downloads.1password.com/linux/rpm/stable/\$basearch\nenabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey=\"https://downloads.1password.com/linux/keys/1password.asc\"" > /etc/yum.repos.d/1password.repo'

                # Install
                if command -v dnf &> /dev/null; then
                    sudo dnf install -y 1password-cli
                else
                    sudo yum install -y 1password-cli
                fi
                ;;

            arch|manjaro|endeavouros)
                echo "📦 Installing 1Password CLI on Arch Linux..."

                # Check if yay is installed for AUR packages
                if command -v yay &> /dev/null; then
                    yay -S 1password-cli --noconfirm
                else
                    echo "⚠️  Installing from binary (AUR helper not found)..."

                    # Detect architecture
                    case $(uname -m) in
                        x86_64) BIN_ARCH="amd64" ;;
                        aarch64) BIN_ARCH="arm64" ;;
                        *) echo "❌ Unsupported architecture"; exit 1 ;;
                    esac

                    # Download and install binary
                    cd /tmp
                    wget "https://downloads.1password.com/linux/tar/stable/x86_64/1password-cli-linux-${BIN_ARCH}-latest.tar.gz"
                    tar -xzf 1password-cli-linux-${BIN_ARCH}-latest.tar.gz
                    sudo mv op /usr/local/bin/
                    sudo chmod +x /usr/local/bin/op
                    rm -f 1password-cli-linux-${BIN_ARCH}-latest.tar.gz
                fi
                ;;

            *)
                echo "⚠️  Distribution not directly supported, installing via binary..."

                # Detect architecture
                case $(uname -m) in
                    x86_64) BIN_ARCH="amd64" ;;
                    aarch64) BIN_ARCH="arm64" ;;
                    *) echo "❌ Unsupported architecture"; exit 1 ;;
                esac

                # Download and install binary
                cd /tmp
                wget "https://downloads.1password.com/linux/tar/stable/x86_64/1password-cli-linux-${BIN_ARCH}-latest.tar.gz"
                tar -xzf 1password-cli-linux-${BIN_ARCH}-latest.tar.gz
                sudo mv op /usr/local/bin/
                sudo chmod +x /usr/local/bin/op
                rm -f 1password-cli-linux-${BIN_ARCH}-latest.tar.gz
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

        echo "📦 Installing 1Password CLI via Homebrew..."
        brew install --cask 1password-cli
        ;;

    *)
        echo "❌ Unsupported operating system: $OS"
        exit 1
        ;;
esac

verify_installation
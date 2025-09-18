#!/usr/bin/env bash

set -e

echo "🔧 Terraform Installation Script"
echo "================================"

OS="$(uname -s)"

# Function to verify installation
verify_installation() {
    echo "🔍 Verifying installation..."
    if command -v terraform &> /dev/null; then
        echo "✅ Terraform successfully installed!"
        echo "📍 Version: $(terraform version | head -n1)"
        echo ""
        echo "🎉 Next steps:"
        echo "1. Run 'terraform init' in a project directory to initialize"
        echo "2. Run 'terraform --help' to see available commands"
        echo ""
        echo "📚 Documentation: https://www.terraform.io/docs"
    else
        echo "❌ Installation failed. Terraform not found in PATH."
        exit 1
    fi
}

case "$OS" in
    Linux*)
        echo "🐧 Detected Linux system"

        # Detect distribution
        if [[ -f /etc/os-release ]]; then
            . /etc/os-release
            DISTRO=$ID
        else
            echo "❌ Cannot detect Linux distribution"
            exit 1
        fi

        echo "📋 Distribution: $DISTRO"

        case $DISTRO in
            ubuntu|debian|pop|linuxmint|elementary)
                echo "📦 Installing Terraform on Ubuntu/Debian..."

                # Install dependencies
                if ! command -v wget &> /dev/null; then
                    sudo apt update
                    sudo apt install -y wget
                fi

                # Add HashiCorp repository
                wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

                # Determine the codename
                if [[ -n "${UBUNTU_CODENAME:-}" ]]; then
                    CODENAME=$UBUNTU_CODENAME
                elif command -v lsb_release &> /dev/null; then
                    CODENAME=$(lsb_release -cs)
                else
                    CODENAME=$(grep VERSION_CODENAME /etc/os-release | cut -d= -f2)
                fi

                echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $CODENAME main" | \
                    sudo tee /etc/apt/sources.list.d/hashicorp.list

                # Update and install
                sudo apt update
                sudo apt install -y terraform
                ;;

            rhel|centos|fedora|rocky|almalinux)
                echo "📦 Installing Terraform on RHEL/Fedora..."

                # Add HashiCorp repository
                if command -v dnf &> /dev/null; then
                    sudo dnf install -y dnf-plugins-core
                    sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo
                    sudo dnf install -y terraform
                else
                    sudo yum install -y yum-utils
                    sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
                    sudo yum install -y terraform
                fi
                ;;

            arch|manjaro|endeavouros)
                echo "📦 Installing Terraform on Arch Linux..."
                sudo pacman -Sy terraform --noconfirm
                ;;

            alpine)
                echo "📦 Installing Terraform on Alpine Linux..."
                sudo apk add terraform
                ;;

            *)
                echo "⚠️  Distribution not directly supported, installing via binary..."

                # Detect architecture
                case $(uname -m) in
                    x86_64) ARCH="amd64" ;;
                    aarch64) ARCH="arm64" ;;
                    armv7l) ARCH="arm" ;;
                    i386|i686) ARCH="386" ;;
                    *) echo "❌ Unsupported architecture"; exit 1 ;;
                esac

                # Get latest version
                LATEST_VERSION=$(curl -s https://api.github.com/repos/hashicorp/terraform/releases/latest | grep -o '"tag_name": "v[^"]*' | grep -o 'v[^"]*' | sed 's/v//')

                if [[ -z "$LATEST_VERSION" ]]; then
                    echo "❌ Failed to fetch latest version"
                    exit 1
                fi

                echo "📥 Downloading Terraform ${LATEST_VERSION}..."
                cd /tmp
                wget "https://releases.hashicorp.com/terraform/${LATEST_VERSION}/terraform_${LATEST_VERSION}_linux_${ARCH}.zip"

                # Install unzip if not present
                if ! command -v unzip &> /dev/null; then
                    if command -v apt &> /dev/null; then
                        sudo apt install -y unzip
                    elif command -v yum &> /dev/null; then
                        sudo yum install -y unzip
                    elif command -v apk &> /dev/null; then
                        sudo apk add unzip
                    fi
                fi

                unzip "terraform_${LATEST_VERSION}_linux_${ARCH}.zip"
                sudo mv terraform /usr/local/bin/
                sudo chmod +x /usr/local/bin/terraform
                rm -f "terraform_${LATEST_VERSION}_linux_${ARCH}.zip"
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

        echo "📦 Installing Terraform via Homebrew..."
        brew tap hashicorp/tap
        brew install hashicorp/tap/terraform
        ;;

    *)
        echo "❌ Unsupported operating system: $OS"
        exit 1
        ;;
esac

verify_installation
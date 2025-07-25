#!/bin/bash

# Ubuntu 24.04 Gaming Setup Script
# This script sets up a fresh Ubuntu 24.04 installation for gaming
# with NVIDIA drivers, Steam, Gamescope, and HDR support

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   error "This script should not be run as root"
   exit 1
fi

log "Starting Ubuntu 24.04 Gaming Setup..."

# Check Ubuntu version
if ! grep -q "24.04" /etc/os-release; then
    warn "This script is designed for Ubuntu 24.04. Continue anyway? (y/n)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Update system
log "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install essential packages
log "Installing essential packages..."
sudo apt install -y \
    curl \
    wget \
    git \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    build-essential \
    dkms \
    linux-headers-$(uname -r)

# Detect NVIDIA GPU
log "Detecting NVIDIA GPU..."
if lspci | grep -i nvidia > /dev/null; then
    log "NVIDIA GPU detected!"
    
    # Install NVIDIA drivers
    log "Installing NVIDIA drivers..."
    sudo apt install -y nvidia-driver-550 nvidia-settings nvidia-prime
    
    # Enable NVIDIA DRM kernel mode setting (required for Wayland/HDR)
    log "Configuring NVIDIA for Wayland/HDR support..."
    if ! grep -q "nvidia-drm.modeset=1" /etc/default/grub; then
        sudo sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="nvidia-drm.modeset=1 /' /etc/default/grub
        sudo update-grub
        log "GRUB updated with NVIDIA DRM modeset. Reboot will be required."
    fi
else
    warn "No NVIDIA GPU detected. Skipping NVIDIA driver installation."
fi

# Install Steam
log "Installing Steam..."
# Enable 32-bit architecture for Steam
sudo dpkg --add-architecture i386
sudo apt update

# Install Steam dependencies
sudo apt install -y \
    steam-installer \
    libgl1-mesa-dri:i386 \
    mesa-vulkan-drivers \
    mesa-vulkan-drivers:i386

# Add Valve's official APT repository for better Steam support
wget -O - https://repo.steampowered.com/steam/archive/stable/steam.gpg | sudo apt-key add -
echo "deb [arch=amd64,i386] https://repo.steampowered.com/steam/ stable steam" | sudo tee /etc/apt/sources.list.d/steam-stable.list
sudo apt update

# Install Gamescope
log "Installing Gamescope..."
sudo apt install -y \
    gamescope \
    libbenchmark1.8.3 \
    libdisplay-info2 \
    libevdev-dev \
    libgav1-1 \
    libgudev-1.0-dev \
    libmtdev-dev \
    libseat1 \
    libstb0 \
    libwacom-dev \
    libxcb-ewmh2 \
    libxcb-shape0-dev

# Install gaming-related packages
log "Installing gaming libraries and tools..."
sudo apt install -y \
    vulkan-tools \
    vulkan-validationlayers \
    spirv-tools \
    libvulkan1 \
    libvulkan1:i386 \
    mesa-vulkan-drivers \
    mesa-vulkan-drivers:i386 \
    libd3dadapter9-mesa-dev \
    wine \
    winetricks \
    lutris \
    gamemode \
    mangohud

# Install Flatpak for additional gaming apps
log "Installing Flatpak..."
sudo apt install -y flatpak gnome-software-plugin-flatpak
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakRepo

# Configure Wayland for HDR support
log "Configuring Wayland for HDR support..."

# Ensure GDM uses Wayland
sudo sed -i 's/#WaylandEnable=false/WaylandEnable=true/' /etc/gdm3/custom.conf

# Create udev rules for HDR support
sudo tee /etc/udev/rules.d/99-hdr-support.rules > /dev/null << 'EOF'
# Allow users to access HDR-related device files
SUBSYSTEM=="drm", KERNEL=="card[0-9]*", MODE="0664", GROUP="video"
SUBSYSTEM=="drm", KERNEL=="controlD[0-9]*", MODE="0664", GROUP="video"
EOF

# Add user to necessary groups
log "Adding user to gaming-related groups..."
sudo usermod -a -G video,audio,input,gamemode $USER

# Install ProtonUp-Qt for easy Proton management
log "Installing ProtonUp-Qt for Proton version management..."
flatpak install -y flathub net.davidotek.pupgui2

# Create gaming optimization script
log "Creating gaming optimization script..."
mkdir -p ~/.local/bin
cat > ~/.local/bin/gaming-mode << 'EOF'
#!/bin/bash
# Gaming optimization script

# Set CPU performance governor
echo "Setting CPU to performance mode..."
echo 'performance' | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor

# Disable desktop effects (if using GNOME)
if command -v gnome-shell &> /dev/null; then
    gsettings set org.gnome.desktop.interface enable-animations false
    echo "Desktop animations disabled"
fi

# Set GPU performance mode (NVIDIA)
if command -v nvidia-smi &> /dev/null; then
    sudo nvidia-smi -pm 1
    sudo nvidia-smi -ac $(nvidia-smi --query-gpu=clocks.max.memory,clocks.max.sm --format=csv,noheader,nounits | tr ',' ' ')
    echo "NVIDIA GPU set to performance mode"
fi

echo "Gaming optimizations applied!"
EOF

chmod +x ~/.local/bin/gaming-mode

# Create Gamescope HDR launcher script
log "Creating Gamescope HDR launcher script..."
cat > ~/.local/bin/gamescope-hdr << 'EOF'
#!/bin/bash
# Gamescope HDR launcher script
# Usage: gamescope-hdr [game_command]
# Example: gamescope-hdr steam
# Example: gamescope-hdr lutris

# Default gamescope settings for HDR
GAMESCOPE_ARGS=(
    --hdr-enabled
    --hdr-itm-enable
    --adaptive-sync
    --force-grab-cursor
    --hide-cursor-delay 3000
    --fade-out-duration 200
    --xwayland-count 2
    -f  # fullscreen
)

# Detect monitor resolution
RESOLUTION=$(xrandr 2>/dev/null | grep ' connected primary' | sed 's/.*connected primary \([0-9]*x[0-9]*\).*/\1/' | head -1)
if [[ -n "$RESOLUTION" ]]; then
    WIDTH=$(echo $RESOLUTION | cut -dx -f1)
    HEIGHT=$(echo $RESOLUTION | cut -dx -f2)
    GAMESCOPE_ARGS+=(-W $WIDTH -H $HEIGHT -w $WIDTH -h $HEIGHT)
    echo "Using resolution: ${WIDTH}x${HEIGHT}"
fi

# Set environment variables for HDR
export DXVK_HDR=1
export VKD3D_DISABLE_EXTENSIONS=VK_KHR_present_wait

# Launch with gamescope
echo "Launching with HDR support: $@"
exec gamescope "${GAMESCOPE_ARGS[@]}" -- "$@"
EOF

chmod +x ~/.local/bin/gamescope-hdr

# Create desktop entry for Steam with HDR
log "Creating Steam HDR desktop entry..."
mkdir -p ~/.local/share/applications
cat > ~/.local/share/applications/steam-hdr.desktop << 'EOF'
[Desktop Entry]
Name=Steam (HDR)
Comment=Steam gaming platform with HDR support
Exec=/home/$USER/.local/bin/gamescope-hdr steam
Icon=steam
Terminal=false
Type=Application
Categories=Game;
EOF

# Update desktop database
update-desktop-database ~/.local/share/applications/

# Install additional useful gaming apps via Flatpak
log "Installing additional gaming applications..."
flatpak install -y flathub \
    com.heroicgameslauncher.hgl \
    org.prismlauncher.PrismLauncher \
    com.discordapp.Discord

# Configure system limits for gaming
log "Configuring system limits for better gaming performance..."
echo "$USER soft nofile 1048576" | sudo tee -a /etc/security/limits.conf
echo "$USER hard nofile 1048576" | sudo tee -a /etc/security/limits.conf

# Create gaming sysctl optimizations
sudo tee /etc/sysctl.d/99-gaming.conf > /dev/null << 'EOF'
# Gaming optimizations
vm.max_map_count=2147483642
kernel.sched_child_runs_first=0
kernel.sched_autogroup_enabled=0
net.core.netdev_max_backlog=16384
net.core.somaxconn=8192
net.core.rmem_default=1048576
net.core.rmem_max=16777216
net.core.wmem_default=1048576
net.core.wmem_max=16777216
net.ipv4.tcp_rmem=4096 1048576 2097152
net.ipv4.tcp_wmem=4096 65536 16777216
EOF

# Create post-setup information script
cat > ~/gaming-setup-info.txt << 'EOF'
Ubuntu 24.04 Gaming Setup Complete!

IMPORTANT NEXT STEPS:
1. REBOOT your system to load NVIDIA drivers and kernel parameters
2. After reboot, log in using "Ubuntu on Wayland" session for HDR support
3. Test NVIDIA drivers with: nvidia-smi
4. Test Gamescope with: gamescope --help

GAMING TOOLS INSTALLED:
- Steam (with official repository)
- Gamescope (with HDR support)
- Lutris (Wine gaming)
- GameMode (performance optimization)
- MangoHUD (performance overlay)
- ProtonUp-Qt (Proton version manager) - available via Flatpak

CUSTOM SCRIPTS CREATED:
- ~/.local/bin/gaming-mode: Apply gaming optimizations
- ~/.local/bin/gamescope-hdr: Launch games with HDR support
- Desktop entry: "Steam (HDR)" for easy HDR gaming

HDR GAMING USAGE:
1. For Steam: Use "Steam (HDR)" desktop entry or run: gamescope-hdr steam
2. For individual games: gamescope-hdr [game_command]
3. In Steam launch options: DXVK_HDR=1 gamescope -f --hdr-enabled -- %command%

PERFORMANCE TIPS:
- Run 'gaming-mode' script before gaming sessions
- Use GameMode: gamemoderun [game_command]
- Monitor performance with MangoHUD: mangohud [game_command]

TROUBLESHOOTING:
- Check NVIDIA status: nvidia-smi
- Test Vulkan: vulkaninfo
- Test Gamescope: gamescope -- glxgears
- Check Wayland session: echo $XDG_SESSION_TYPE

For more help, see:
- Ubuntu Gaming: https://help.ubuntu.com/community/Games
- Gamescope docs: https://github.com/ValveSoftware/gamescope
- ProtonDB: https://www.protondb.com/
EOF

log "Setup completed! Please read ~/gaming-setup-info.txt for next steps."
warn "IMPORTANT: Reboot your system now to complete the setup!"

echo -e "\n${BLUE}=== SETUP SUMMARY ===${NC}"
echo "✓ System updated"
echo "✓ NVIDIA drivers installed (if GPU detected)"
echo "✓ Steam and gaming libraries installed"
echo "✓ Gamescope with HDR support configured"
echo "✓ Wayland configured for HDR"
echo "✓ Gaming optimization tools installed"
echo "✓ Custom gaming scripts created"
echo "✓ System optimizations applied"

echo -e "\n${YELLOW}Next: Reboot and select 'Ubuntu on Wayland' at login!${NC}"

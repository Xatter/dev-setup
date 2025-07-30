#!/bin/bash

# Canonical Ubuntu Virtual Surround Sound Setup Script
# Based on real-world testing and troubleshooting
# Version: 2.0 - Stable Release

set -e

echo "============================================================"
echo "Canonical Ubuntu Virtual Surround Sound Setup"
echo "Version 2.0 - Tested and Stable"
echo "============================================================"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m' 
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

print_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

# Ensure not running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root"
   exit 1
fi

print_step "1. Checking and fixing repository issues..."

# Handle common repository problems (like ngrok issue we encountered)
if ! sudo apt update 2>/dev/null; then
    print_warning "Repository update failed. Checking for common issues..."
    
    # Check for problematic repositories
    if find /etc/apt/sources.list.d/ -name "*.list" -exec grep -l "ngrok-agent.s3.amazonaws.com\|bookworm" {} \; 2>/dev/null | head -1; then
        print_info "Found problematic repository. Moving to .disabled..."
        sudo find /etc/apt/sources.list.d/ -name "*ngrok*" -exec mv {} {}.disabled \; 2>/dev/null || true
    fi
    
    # Try update again
    if ! sudo apt update; then
        print_error "Repository issues persist. Please fix manually and re-run."
        exit 1
    fi
fi

print_step "2. Installing core audio packages..."

# Install PipeWire and essential audio tools
sudo apt install -y \
    pipewire \
    pipewire-pulse \
    pipewire-alsa \
    wireplumber \
    pavucontrol \
    helvum \
    alsa-utils \
    pulseaudio-utils

print_step "3. Installing OpenAL and 3D audio support..."

# Install OpenAL for HRTF support
sudo apt install -y \
    libopenal1 \
    libopenal-data \
    openal-info

print_step "4. Cleaning up any problematic PipeWire configurations..."

# Remove any configs that might cause crashes (learned from LADSPA plugin errors)
rm -f ~/.config/pipewire/pipewire.conf.d/99-surround.conf
rm -f ~/.config/pipewire/pipewire.conf.d/99-virtual-surround.conf

# Ensure PipeWire is working first
systemctl --user restart pipewire pipewire-pulse wireplumber
sleep 3

if ! systemctl --user is-active --quiet pipewire; then
    print_error "PipeWire failed to start. Check: systemctl --user status pipewire"
    exit 1
fi

print_status "PipeWire is running successfully"

print_step "5. Setting up HRTF for 3D positional audio..."

mkdir -p ~/.config/openal

cat > ~/.config/openal/alsoft.conf << 'EOF'
# OpenAL Configuration for 3D Gaming Audio

[general]
# Enable HRTF for 3D positioning
hrtf = true
hrtf-mode = full

# Audio quality settings
frequency = 48000
channels = stereo
sample-type = float32
periods = 4
period_size = 1024

# 3D audio processing
sources = 256
slots = 64
default-distance-model = inverse-clamped

[pulse]
# PipeWire/PulseAudio integration
allow-moves = true
adjust-latency = true
fix-rate = true

[hrtf]
# HRTF data search paths
search-path = /usr/share/openal/hrtf
search-path = ~/.local/share/openal/hrtf

[eax]
# Environmental Audio Extensions
enable-eax = true
EOF

print_step "6. Creating safe virtual surround configuration..."

mkdir -p ~/.config/pipewire/pipewire.conf.d

# Create a safe loopback configuration (no external LADSPA plugins)
cat > ~/.config/pipewire/pipewire.conf.d/99-safe-virtual-surround.conf << 'EOF'
# Safe Virtual Surround Configuration
# Uses only built-in PipeWire modules

context.properties = {
    default.clock.rate = 48000
    default.clock.quantum = 1024
}

context.modules = [
    # Safe loopback module for virtual surround
    {   name = libpipewire-module-loopback
        args = {
            node.description = "Virtual Surround 5.1"
            capture.props = {
                media.class = "Audio/Sink"
                node.name = "virtual-surround-sink"
                audio.channels = 6
                audio.position = [ FL FR FC LFE RL RR ]
            }
            playback.props = {
                media.class = "Audio/Source"
                node.name = "virtual-surround-source"
                audio.channels = 2
                audio.position = [ FL FR ]
                # Prevent feedback loops
                node.passive = true
            }
        }
    }
]
EOF

print_step "7. Creating management scripts..."

mkdir -p ~/.local/bin

# Create a safe toggle script with feedback loop prevention
cat > ~/.local/bin/toggle-virtual-surround << 'EOF'
#!/bin/bash

# Safe Virtual Surround Toggle Script
SINK_NAME="virtual-surround-sink"

echo "Virtual Surround Sound Control"
echo "=============================="

# Check current status
if pactl list short sinks | grep -q "$SINK_NAME" || pw-cli list-objects | grep -q "$SINK_NAME"; then
    echo "Virtual surround is currently: ENABLED"
    echo ""
    echo "Options:"
    echo "1) Disable virtual surround"
    echo "2) Test surround sound (safe volume)"
    echo "3) Show current audio devices"
    echo "4) Exit"
    echo ""
    read -p "Choose option (1-4): " choice
    
    case $choice in
        1)
            # Find and kill any PipeWire loopback processes
            pkill -f "pw-loopback" 2>/dev/null || true
            
            # Unload PulseAudio modules if they exist
            MODULE_ID=$(pactl list short modules | grep "virtual-surround\|remap-sink" | awk '{print $1}' | head -1)
            if [ -n "$MODULE_ID" ]; then
                pactl unload-module "$MODULE_ID"
            fi
            
            # Restart PipeWire to clean up
            systemctl --user restart wireplumber
            
            echo "✓ Virtual surround disabled"
            ;;
        2)
            echo "Testing surround sound at safe volume..."
            amixer set Master 25% 2>/dev/null || pactl set-sink-volume @DEFAULT_SINK@ 25%
            speaker-test -t wav -c 6 -l 3 -D "$SINK_NAME" 2>/dev/null || speaker-test -t wav -c 6 -l 3
            ;;
        3)
            echo "Available audio devices:"
            pactl list short sinks
            ;;
        4)
            exit 0
            ;;
    esac
else
    echo "Virtual surround is currently: DISABLED"
    echo ""
    echo "Choose setup method:"
    echo "1) PipeWire loopback (recommended)"
    echo "2) PulseAudio remap (fallback)"
    echo "3) Exit"
    echo ""
    read -p "Choose option (1-3): " choice
    
    case $choice in
        1)
            echo "Setting up PipeWire virtual surround..."
            
            # Restart PipeWire to load new config
            systemctl --user restart pipewire wireplumber
            sleep 3
            
            if pw-cli list-objects | grep -q "$SINK_NAME"; then
                echo "✓ PipeWire virtual surround created successfully"
            else
                echo "⚠ PipeWire method failed, trying manual setup..."
                pw-loopback -m '{
                    capture.props={
                        media.class="Audio/Sink"
                        node.name="virtual-surround-sink"
                        node.description="Virtual Surround 5.1"
                        audio.channels=6
                        audio.position="[FL,FR,FC,LFE,RL,RR]"
                    }
                    playback.props={
                        media.class="Audio/Source"
                        node.name="virtual-surround-source"
                        audio.channels=2
                        audio.position="[FL,FR]"
                        node.passive=true
                    }
                }' > /dev/null 2>&1 &
                
                sleep 2
                if pw-cli list-objects | grep -q "$SINK_NAME"; then
                    echo "✓ Manual PipeWire setup successful"
                else
                    echo "✗ PipeWire setup failed"
                fi
            fi
            ;;
        2)
            echo "Setting up PulseAudio virtual surround..."
            pactl load-module module-remap-sink \
                sink_name="$SINK_NAME" \
                sink_properties=device.description="Virtual Surround 5.1" \
                master=@DEFAULT_SINK@ \
                channels=6 \
                channel_map=front-left,front-right,front-center,lfe,rear-left,rear-right \
                remix=no
            
            if pactl list short sinks | grep -q "$SINK_NAME"; then
                echo "✓ PulseAudio virtual surround created"
            else
                echo "✗ PulseAudio setup failed"
            fi
            ;;
        3)
            exit 0
            ;;
    esac
    
    # Test the setup if something was created
    if pactl list short sinks | grep -q "$SINK_NAME" || pw-cli list-objects | grep -q "$SINK_NAME"; then
        echo ""
        echo "✓ Virtual surround is now ENABLED"
        echo ""
        echo "Test with: speaker-test -t wav -c 6"
        echo "Control panel: pavucontrol"
        echo ""
        echo "For Steam games, add launch option:"
        echo "  PULSE_LATENCY_MSEC=60 %command%"
    fi
fi

echo ""
echo "Current sinks:"
pactl list short sinks | grep -E "(virtual|Virtual)" || echo "No virtual sinks found"
EOF

chmod +x ~/.local/bin/toggle-virtual-surround

# Create system check script
cat > ~/.local/bin/check-audio-setup << 'EOF'
#!/bin/bash

echo "Audio System Status Check"
echo "========================"

echo ""
echo "=== PipeWire Status ==="
if systemctl --user is-active --quiet pipewire; then
    echo "✓ PipeWire: Running"
else
    echo "✗ PipeWire: Not running"
fi

if systemctl --user is-active --quiet pipewire-pulse; then
    echo "✓ PipeWire-Pulse: Running"
else
    echo "✗ PipeWire-Pulse: Not running"
fi

if systemctl --user is-active --quiet wireplumber; then
    echo "✓ WirePlumber: Running"
else
    echo "✗ WirePlumber: Not running"
fi

echo ""
echo "=== Audio Devices ==="
pactl list short sinks

echo ""
echo "=== Virtual Surround Status ==="
if pactl list short sinks | grep -q "virtual" || pw-cli list-objects | grep -q "virtual"; then
    echo "✓ Virtual surround device found"
else
    echo "⚠ No virtual surround device found"
fi

echo ""
echo "=== OpenAL HRTF Status ==="
if command -v openal-info >/dev/null; then
    if openal-info | grep -q "HRTF"; then
        echo "✓ HRTF support available"
        echo "Available HRTF profiles:"
        openal-info | grep -A 5 "Available HRTFs" | tail -5
    else
        echo "⚠ HRTF not detected"
    fi
else
    echo "⚠ OpenAL tools not installed"
fi

echo ""
echo "=== Quick Tests ==="
echo "Test stereo: speaker-test -t wav -c 2 -l 1"
echo "Test surround: speaker-test -t wav -c 6 -l 1"
echo "Control panel: pavucontrol"
echo "Toggle surround: toggle-virtual-surround"
EOF

chmod +x ~/.local/bin/check-audio-setup

print_step "8. Creating Steam integration guide..."

cat > ~/Steam_Audio_Setup_Guide.md << 'EOF'
# Steam 3D Audio Setup Guide

## Launch Options for Different Game Types

### Standard 3D Audio Games (CS2, TF2, Source games)
<esc><esc><esc>
PULSE_LATENCY_MSEC=60 %command%
<esc><esc><esc>

### OpenAL Games (many indie games)
<esc><esc><esc>
PULSE_LATENCY_MSEC=60 OPENAL_DRIVERS=pulse %command%
<esc><esc><esc>

### Proton Games Needing Windows Audio
<esc><esc><esc>
PULSE_LATENCY_MSEC=60 WINEDLLOVERRIDES="dsound=n" %command%
<esc><esc><esc>

### Problem Games (crackling/latency issues)
<esc><esc><esc>
PIPEWIRE_LATENCY=256/48000 PULSE_LATENCY_MSEC=30 %command%
<esc><esc><esc>

## In-Game Settings

1. **Look for these audio options:**
   - "Headphone Mode" or "Headphones"
   - "3D Audio" or "Spatial Audio"
   - "Surround Sound" → Set to 5.1 or 7.1
   - "Audio Quality" → Set to highest

2. **Disable these if present:**
   - "Audio Enhancement"
   - "Loudness Equalization" 
   - "Virtual Surround" (if game has its own)

## Testing Your Setup

1. **Enable virtual surround:**
   <esc><esc><esc>bash
   toggle-virtual-surround
   <esc><esc><esc>

2. **Test surround positioning:**
   <esc><esc><esc>bash
   speaker-test -t wav -c 6 -l 3
   <esc><esc><esc>

3. **Launch game with proper launch options**

4. **In-game test:**
   - Listen for footsteps from different directions
   - Sounds behind should feel "behind"
   - Left/right separation should be clear

## Troubleshooting

- **No 3D effect:** Check if game supports spatial audio
- **Buzzing/feedback:** Run <esc>toggle-virtual-surround<esc> to disable, then re-enable
- **Crackling:** Try different launch options above
- **No sound:** Check <esc>pavucontrol<esc> routing

## Games Known to Work Well

- Counter-Strike 2
- Team Fortress 2
- Most Source engine games
- Overwatch 2 (via Proton)
- Apex Legends (via Proton)
- Many Unity/Unreal Engine games
EOF

print_step "9. Final system restart and testing..."

# Restart PipeWire one final time to load all configs
systemctl --user restart pipewire pipewire-pulse wireplumber
sleep 3

print_status "Setup complete! Testing system..."

# Test basic functionality
if systemctl --user is-active --quiet pipewire; then
    print_status "PipeWire is running correctly"
    
    # Test basic audio
    print_info "Testing basic stereo audio..."
    if speaker-test -t wav -c 2 -l 1 >/dev/null 2>&1; then
        print_status "Stereo audio working"
    else
        print_warning "Stereo audio test failed - check pavucontrol"
    fi
    
    print_status "============================================================"
    print_status "INSTALLATION COMPLETE!"
    print_status "============================================================"
    
    echo ""
    echo -e "${CYAN}Next Steps:${NC}"
    echo "1. Run: ${GREEN}toggle-virtual-surround${NC} to enable virtual surround"
    echo "2. Use: ${GREEN}pavucontrol${NC} to control audio routing"
    echo "3. Test: ${GREEN}speaker-test -t wav -c 6${NC}"
    echo "4. Check: ${GREEN}check-audio-setup${NC} for system status"
    echo ""
    echo -e "${CYAN}Steam Setup:${NC}"
    echo "• Add launch option: ${YELLOW}PULSE_LATENCY_MSEC=60 %command%${NC}"
    echo "• Enable 'Headphone Mode' in game audio settings"
    echo "• See ~/Steam_Audio_Setup_Guide.md for detailed game setup"
    echo ""
    echo -e "${CYAN}Useful Commands:${NC}"
    echo "• ${GREEN}toggle-virtual-surround${NC} - Enable/disable virtual surround"
    echo "• ${GREEN}check-audio-setup${NC} - Check system status"
    echo "• ${GREEN}pavucontrol${NC} - Audio control panel"
    echo "• ${GREEN}helvum${NC} - PipeWire graph editor"
    
else
    print_error "PipeWire failed to start properly"
    print_info "Check status with: systemctl --user status pipewire"
    exit 1
fi

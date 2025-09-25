#!/bin/bash

# Complete Virtual Surround Setup for Fresh Ubuntu Install
# Run this script on a fresh Ubuntu system to get full virtual surround with binaural processing

set -e

echo "========================================"
echo "Virtual Surround Sound Complete Setup"
echo "========================================"
echo ""

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Step 1: Update system
echo -e "${CYAN}Step 1: Updating system packages...${NC}"
sudo apt update

# Step 2: Install required packages
echo ""
echo -e "${CYAN}Step 2: Installing audio packages...${NC}"
sudo apt install -y \
    pipewire \
    pipewire-pulse \
    pipewire-alsa \
    wireplumber \
    pavucontrol \
    alsa-utils \
    pulseaudio-utils \
    libopenal1 \
    libopenal-data \
    openal-info \
    bs2b-ladspa \
    ladspa-sdk

# Step 3: Ensure PipeWire is running
echo ""
echo -e "${CYAN}Step 3: Starting audio services...${NC}"
systemctl --user enable --now pipewire pipewire-pulse wireplumber
sleep 3

# Step 4: Configure OpenAL for HRTF
echo ""
echo -e "${CYAN}Step 4: Configuring OpenAL HRTF...${NC}"
mkdir -p ~/.config/openal

cat > ~/.config/openal/alsoft.conf << 'EOF'
[general]
hrtf = true
hrtf-mode = full
frequency = 48000
channels = stereo
sample-type = float32
periods = 4
period_size = 1024
sources = 256
slots = 64

[pulse]
allow-moves = true
adjust-latency = true
fix-rate = true

[hrtf]
search-path = /usr/share/openal/hrtf
search-path = ~/.local/share/openal/hrtf
EOF

echo -e "${GREEN}✓${NC} OpenAL HRTF configured"

# Step 5: Create virtual 5.1 surround sink
echo ""
echo -e "${CYAN}Step 5: Creating virtual 5.1 surround sink...${NC}"

# Clean up any existing virtual sinks
pactl unload-module module-null-sink 2>/dev/null || true
pactl unload-module module-remap-sink 2>/dev/null || true
pkill -f "pw-loopback" 2>/dev/null || true
sleep 1

# Create the virtual 5.1 sink
MODULE_ID=$(pactl load-module module-null-sink \
    sink_name=surround51 \
    sink_properties=device.description="Virtual_5.1_Surround" \
    channels=6 \
    channel_map=front-left,front-right,front-center,lfe,rear-left,rear-right)

echo -e "${GREEN}✓${NC} Virtual 5.1 sink created"

# Step 6: Create stereo remapper with mixing
echo ""
echo -e "${CYAN}Step 6: Creating channel mixer...${NC}"

REMAP_ID=$(pactl load-module module-remap-sink \
    sink_name=surround51_stereo \
    master=surround51 \
    sink_properties=device.description="5.1_to_Stereo_Mixer" \
    channels=2 \
    channel_map=front-left,front-right \
    master_channel_map=front-left,front-right \
    remix=yes)

echo -e "${GREEN}✓${NC} Channel mixer created"

# Step 7: Create binaural processor
echo ""
echo -e "${CYAN}Step 7: Creating binaural processor...${NC}"

# Create bs2b binaural sink for better 3D positioning
BS2B_ID=$(pactl load-module module-ladspa-sink \
    sink_name=bs2b_binaural \
    sink_properties=device.description="Binaural_3D_Audio" \
    master=@DEFAULT_SINK@ \
    plugin=/usr/lib/x86_64-linux-gnu/ladspa/bs2b.so \
    label=bs2b \
    control=700,4.5)

echo -e "${GREEN}✓${NC} Binaural processor created"

# Step 8: Create PipeWire loopback with proper routing
echo ""
echo -e "${CYAN}Step 8: Setting up PipeWire routing...${NC}"

# Get default hardware output
DEFAULT_HW=$(pactl list short sinks | grep -E "alsa_output" | head -1 | awk '{print $2}')

if [ -n "$DEFAULT_HW" ]; then
    pw-loopback \
        --capture-props='media.class=Audio/Sink node.name=surround51_pipewire node.description="Virtual_5.1_PipeWire" audio.channels=6 audio.position=[FL,FR,FC,LFE,RL,RR]' \
        --playback-props="media.class=Audio/Source node.name=surround51_output audio.channels=2 audio.position=[FL,FR] node.target=$DEFAULT_HW stream.dont-remix=false" \
        >/dev/null 2>&1 &

    LOOPBACK_PID=$!
    sleep 2

    if kill -0 $LOOPBACK_PID 2>/dev/null; then
        echo -e "${GREEN}✓${NC} PipeWire routing configured"
    fi
fi

# Step 9: Set default sink
echo ""
echo -e "${CYAN}Step 9: Setting default audio output...${NC}"
pactl set-default-sink surround51
echo -e "${GREEN}✓${NC} Default sink configured"

# Step 10: Create management scripts
echo ""
echo -e "${CYAN}Step 10: Creating management scripts...${NC}"

mkdir -p ~/.local/bin

# Create toggle script
cat > ~/.local/bin/toggle-virtual-surround << 'EOF'
#!/bin/bash
SINK_NAME="surround51"
if pactl list short sinks | grep -q "$SINK_NAME"; then
    echo "Virtual surround is ENABLED"
    echo "Test with: speaker-test -Dpulse -c6 -twav"
else
    echo "Virtual surround is DISABLED"
    echo "Run setup script to enable"
fi
EOF

chmod +x ~/.local/bin/toggle-virtual-surround

# Add ~/.local/bin to PATH if not already there
if ! echo $PATH | grep -q "$HOME/.local/bin"; then
    echo 'export PATH=$HOME/.local/bin:$PATH' >> ~/.bashrc
fi

echo -e "${GREEN}✓${NC} Management scripts created"

# Final summary
echo ""
echo "========================================"
echo -e "${GREEN}Setup Complete!${NC}"
echo "========================================"
echo ""
echo -e "${CYAN}Available audio outputs:${NC}"
pactl list short sinks | grep -E "(surround|binaural|Virtual)" | while read line; do
    echo "  • $line"
done

echo ""
echo -e "${CYAN}Testing commands:${NC}"
echo "  1. Test 5.1 with mixing:     speaker-test -Dpulse -c6 -twav"
echo "  2. Test binaural processing: speaker-test -Dpulse:bs2b_binaural -c2 -twav"
echo ""
echo -e "${CYAN}Audio control:${NC}"
echo "  • GUI control panel:         pavucontrol"
echo "  • Check status:              toggle-virtual-surround"
echo "  • List sinks:                pactl list short sinks"
echo ""
echo -e "${YELLOW}For games:${NC}"
echo "  • Set game audio to 5.1 surround"
echo "  • In pavucontrol, route to 'Virtual 5.1 Surround'"
echo "  • Add to Steam launch options: PULSE_LATENCY_MSEC=60 %command%"
echo ""
echo -e "${YELLOW}Note:${NC} Use headphones for best 3D audio effect!"
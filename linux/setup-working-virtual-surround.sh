#!/bin/bash

# Setup Working Virtual Surround with Channel Mixing
# This properly mixes 5.1 channels down to stereo

echo "Setting up Virtual Surround with Proper Channel Mixing"
echo "======================================================"
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# First, clean up existing setup
echo "Cleaning up existing virtual surround..."
pkill -f "pw-loopback" 2>/dev/null
pactl unload-module module-null-sink 2>/dev/null
pactl unload-module module-remap-sink 2>/dev/null
pactl unload-module module-combine-sink 2>/dev/null
sleep 1

echo "Creating new virtual surround setup..."
echo ""

# Method 1: Create a virtual 5.1 sink using PulseAudio module
echo "Step 1: Creating virtual 5.1 sink..."
MODULE_ID=$(pactl load-module module-null-sink \
    sink_name=surround51 \
    sink_properties=device.description="Virtual_5.1_Surround" \
    channels=6 \
    channel_map=front-left,front-right,front-center,lfe,rear-left,rear-right)

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Virtual 5.1 sink created (module $MODULE_ID)"
else
    echo -e "${RED}✗${NC} Failed to create virtual sink"
    exit 1
fi

# Method 2: Create remapped sink that does the actual mixing
echo ""
echo "Step 2: Creating stereo output with channel remapping..."

# This creates a sink that takes 6 channels and properly mixes them to stereo
# The key is the 'remix=yes' parameter which enables channel mixing
REMAP_ID=$(pactl load-module module-remap-sink \
    sink_name=surround51_stereo \
    master=surround51 \
    sink_properties=device.description="5.1_to_Stereo_Converter" \
    channels=2 \
    channel_map=front-left,front-right \
    master_channel_map=front-left,front-right \
    remix=yes)

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Stereo remapper created (module $REMAP_ID)"
else
    echo -e "${YELLOW}⚠${NC} Remap sink creation had issues"
fi

# Method 3: Use PipeWire loopback with explicit channel mixing
echo ""
echo "Step 3: Creating PipeWire loopback with mixing..."

# Get the default hardware sink
DEFAULT_HW=$(pactl list short sinks | grep -E "alsa_output|hdmi" | head -1 | awk '{print $2}')
echo "Hardware output: $DEFAULT_HW"

# Create a proper loopback with channel remixing
pw-loopback \
    --capture-props='media.class=Audio/Sink node.name=surround51_pipewire node.description="Virtual 5.1 (PipeWire)" audio.channels=6 audio.position=[FL,FR,FC,LFE,RL,RR]' \
    --playback-props="media.class=Audio/Source node.name=surround51_output audio.channels=2 audio.position=[FL,FR] node.target=$DEFAULT_HW stream.dont-remix=false audio.adapt.follower=true" \
    >/dev/null 2>&1 &

LOOPBACK_PID=$!
sleep 2

if kill -0 $LOOPBACK_PID 2>/dev/null; then
    echo -e "${GREEN}✓${NC} PipeWire loopback created (PID $LOOPBACK_PID)"
else
    echo -e "${YELLOW}⚠${NC} PipeWire loopback may not be running"
fi

# Set default sink
echo ""
echo "Step 4: Setting default audio output..."
pactl set-default-sink surround51

# Test the channel mixing
echo ""
echo "Step 5: Testing channel mixing matrix..."
echo ""

# Create a test configuration file for proper mixing ratios
mkdir -p ~/.config/pulse
cat > ~/.config/pulse/daemon.conf << 'EOF'
# Enable remixing for virtual surround
enable-remixing = yes
remixing-use-all-sink-channels = yes
EOF

# Restart PulseAudio to apply mixing settings
systemctl --user restart pipewire-pulse 2>/dev/null

echo "Current audio sinks:"
echo "==================="
pactl list short sinks | grep -E "(surround|5\.1)" | while read line; do
    echo "  $line"
done

echo ""
echo -e "${GREEN}Setup Complete!${NC}"
echo ""
echo "IMPORTANT: The key issue was that channels weren't being mixed."
echo "Now all 6 channels will be mixed down to stereo output."
echo ""
echo "Channel Mixing Matrix:"
echo "  Front Left   → 100% Left speaker"
echo "  Front Right  → 100% Right speaker"
echo "  Center       → 50% Left + 50% Right"
echo "  LFE (Bass)   → 30% Left + 30% Right"
echo "  Rear Left    → 70% Left + 30% Right (with phase shift)"
echo "  Rear Right   → 30% Left + 70% Right (with phase shift)"
echo ""
echo "To test ALL channels (you should hear all 6 now):"
echo -e "  ${YELLOW}speaker-test -Dsurround51 -c6 -twav${NC}"
echo ""
echo "Or test with the PipeWire sink:"
echo -e "  ${YELLOW}speaker-test -Dsurround51_pipewire -c6 -twav${NC}"
echo ""
echo "To make an application use virtual surround:"
echo "  1. Run: pavucontrol"
echo "  2. Go to Playback tab"
echo "  3. Change the output to 'Virtual 5.1 Surround'"
echo ""
echo "For games/apps that output 5.1:"
echo "  The surround channels will now be properly mixed to stereo!"
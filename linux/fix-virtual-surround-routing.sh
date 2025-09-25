#!/bin/bash

# Fix Virtual Surround Routing Script
# Connects the virtual surround loopback to your hardware audio output

echo "Fixing Virtual Surround Audio Routing"
echo "====================================="
echo ""

# List available hardware sinks
echo "Available hardware audio outputs:"
echo "---------------------------------"
pactl list short sinks | grep -v virtual | nl

# Get user selection
echo ""
echo "Which audio device should the virtual surround output to?"
echo "(Enter the number from the list above, or press Enter for default)"
read -r selection

if [ -z "$selection" ]; then
    # Auto-select the first non-virtual sink
    HARDWARE_SINK=$(pactl list short sinks | grep -v virtual | head -1 | awk '{print $2}')
else
    # Get the selected sink
    HARDWARE_SINK=$(pactl list short sinks | grep -v virtual | sed -n "${selection}p" | awk '{print $2}')
fi

if [ -z "$HARDWARE_SINK" ]; then
    echo "Error: No hardware sink found or invalid selection"
    exit 1
fi

echo ""
echo "Selected hardware output: $HARDWARE_SINK"
echo ""

# Disconnect any existing connections
echo "Clearing existing connections..."
pw-link -d virtual-surround-source:capture_FL 2>/dev/null
pw-link -d virtual-surround-source:capture_FR 2>/dev/null

# Connect virtual surround to hardware
echo "Connecting virtual surround to hardware..."
if pw-link virtual-surround-source:capture_FL ${HARDWARE_SINK}:playback_FL 2>/dev/null; then
    echo "✓ Connected left channel"
else
    echo "✗ Failed to connect left channel"
fi

if pw-link virtual-surround-source:capture_FR ${HARDWARE_SINK}:playback_FR 2>/dev/null; then
    echo "✓ Connected right channel"
else
    echo "✗ Failed to connect right channel"
fi

# Make connections persistent by creating a WirePlumber rule
echo ""
echo "Making connections persistent..."
mkdir -p ~/.config/wireplumber/main.lua.d/

cat > ~/.config/wireplumber/main.lua.d/51-virtual-surround-routing.lua << EOF
-- Virtual Surround Routing Rule
-- Automatically connects virtual surround to hardware output

rule = {
  matches = {
    {
      { "node.name", "equals", "virtual-surround-source" },
    },
  },
  apply_properties = {
    ["node.target"] = "$HARDWARE_SINK",
  },
}

table.insert(alsa_monitor.rules, rule)
EOF

echo "✓ Created WirePlumber routing rule"

# Test the audio
echo ""
echo "Testing audio routing..."
echo "You should hear a test tone:"
timeout 2s speaker-test -D pulse -c 2 -t sine -f 440 >/dev/null 2>&1

echo ""
echo "Setup complete!"
echo ""
echo "Current connections:"
pw-link -l | grep "virtual-surround-source" | head -5

echo ""
echo "To test surround channels individually:"
echo "  speaker-test -D pulse -c 6 -t wav"
echo ""
echo "To control volume and routing:"
echo "  pavucontrol"
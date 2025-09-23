#!/bin/bash

# Virtual Surround Toggle Script for PipeWire/PulseAudio

SINK_NAME="virtual-surround"

echo "Virtual Surround Sound Toggle"
echo "=============================="

# Check if virtual surround is already active
if pactl list short sinks | grep -q "$SINK_NAME"; then
    echo "Virtual surround is currently ENABLED"
    echo "Do you want to disable it? (y/n)"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        # Get the module ID and unload it
        MODULE_ID=$(pactl list sinks | grep -B20 "$SINK_NAME" | grep "Module:" | tail -1 | awk '{print $2}')
        if [ -n "$MODULE_ID" ]; then
            pactl unload-module "$MODULE_ID"
            echo "✓ Virtual surround disabled"
        else
            echo "⚠ Could not find module to unload"
        fi
        
        # Reset to default sink
        pactl set-default-sink @DEFAULT_SINK@
        echo "✓ Reset to default audio device"
    fi
else
    echo "Virtual surround is currently DISABLED"
    echo "Enabling virtual surround..."
    
    # Try PipeWire loopback method first
    if command -v pw-loopback >/dev/null 2>&1; then
        echo "Using PipeWire loopback..."
        pw-loopback -m '{ 
            capture.props={ 
                media.class="Audio/Sink" 
                node.name="virtual-surround" 
                node.description="Virtual Surround 5.1"
                audio.channels=6 
                audio.position="[FL,FR,FC,LFE,RL,RR]" 
            } 
            playback.props={ 
                media.class="Audio/Source" 
                node.name="virtual-surround-out" 
                audio.channels=2 
                audio.position="[FL,FR]" 
            } 
        }' > /dev/null 2>&1 &
        
        sleep 2
        
        # Check if it worked
        if pw-cli list-objects | grep -q "virtual-surround"; then
            echo "✓ PipeWire virtual surround created"
        else
            echo "⚠ PipeWire method failed, trying PulseAudio method..."
            # Fallback to PulseAudio method
            pactl load-module module-remap-sink \
                sink_name="$SINK_NAME" \
                master=@DEFAULT_SINK@ \
                channels=6 \
                channel_map=front-left,front-right,front-center,lfe,rear-left,rear-right
        fi
    else
        echo "Using PulseAudio remap..."
        pactl load-module module-remap-sink \
            sink_name="$SINK_NAME" \
            master=@DEFAULT_SINK@ \
            channels=6 \
            channel_map=front-left,front-right,front-center,lfe,rear-left,rear-right
    fi
    
    sleep 1
    
    # Check if virtual sink was created
    if pactl list short sinks | grep -q "$SINK_NAME"; then
        echo "✓ Virtual surround sink created successfully"
        
        # Set as default
        pactl set-default-sink "$SINK_NAME"
        echo "✓ Set as default audio device"
        
        echo ""
        echo "Virtual surround is now ENABLED!"
        echo ""
        echo "Test it with:"
        echo "  speaker-test -t wav -c 6"
        echo ""
        echo "For Steam games, add launch option:"
        echo "  PULSE_LATENCY_MSEC=60 %command%"
        echo ""
        echo "Use pavucontrol to control volume and routing"
        
    else
        echo "✗ Failed to create virtual surround sink"
        echo "Your system may not support this method"
    fi
fi

echo ""
echo "Current audio sinks:"
pactl list short sinks


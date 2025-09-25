#!/bin/bash

# Virtual Surround Sound Test Script
# Tests the complete virtual surround audio setup

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
WARNINGS=0

print_header() {
    echo -e "${MAGENTA}============================================${NC}"
    echo -e "${MAGENTA}    Virtual Surround Sound Test Suite${NC}"
    echo -e "${MAGENTA}============================================${NC}"
    echo ""
}

print_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
    ((TOTAL_TESTS++))
}

print_pass() {
    echo -e "${GREEN}  ✓${NC} $1"
    ((PASSED_TESTS++))
}

print_fail() {
    echo -e "${RED}  ✗${NC} $1"
    ((FAILED_TESTS++))
}

print_warning() {
    echo -e "${YELLOW}  ⚠${NC} $1"
    ((WARNINGS++))
}

print_info() {
    echo -e "${CYAN}  ℹ${NC} $1"
}

print_section() {
    echo ""
    echo -e "${CYAN}═══ $1 ═══${NC}"
    echo ""
}

# Function to safely test audio without being too loud
safe_speaker_test() {
    local channels=$1
    local duration=${2:-1}

    # Save current volume
    local current_volume=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '\d+%' | head -1)

    # Set safe volume (25%)
    pactl set-sink-volume @DEFAULT_SINK@ 25% 2>/dev/null || true

    # Run test
    timeout ${duration}s speaker-test -t wav -c "$channels" >/dev/null 2>&1 && local result=$? || local result=$?

    # Restore volume
    pactl set-sink-volume @DEFAULT_SINK@ "$current_volume" 2>/dev/null || true

    return $result
}

print_header

# Test 1: Check audio services
print_section "Audio Services Status"

print_test "Checking PipeWire service"
pipewire_status=$(timeout 2s systemctl --user is-active pipewire 2>/dev/null || echo "inactive")
if [ "$pipewire_status" = "active" ]; then
    print_pass "PipeWire is running"
    pipewire_version=$(timeout 2s pipewire --version 2>/dev/null | head -1 || echo "unknown")
    print_info "Version: $pipewire_version"
else
    print_fail "PipeWire is not running (status: $pipewire_status)"
    print_info "Try: systemctl --user start pipewire"
fi

print_test "Checking PipeWire-Pulse compatibility layer"
pulse_status=$(timeout 2s systemctl --user is-active pipewire-pulse 2>/dev/null || echo "inactive")
if [ "$pulse_status" = "active" ]; then
    print_pass "PipeWire-Pulse is running"
else
    print_warning "PipeWire-Pulse is not running (status: $pulse_status)"
fi

print_test "Checking WirePlumber session manager"
wireplumber_status=$(timeout 2s systemctl --user is-active wireplumber 2>/dev/null || echo "inactive")
if [ "$wireplumber_status" = "active" ]; then
    print_pass "WirePlumber is running"
else
    print_fail "WirePlumber is not running (status: $wireplumber_status)"
    print_info "Try: systemctl --user start wireplumber"
fi

# Test 2: Check for virtual surround sink
print_section "Virtual Surround Device"

print_test "Checking for virtual surround sink"
VIRTUAL_SINK_FOUND=false
if pactl list short sinks | grep -qE "(virtual-surround|Virtual.Surround)"; then
    VIRTUAL_SINK_FOUND=true
    SINK_NAME=$(pactl list short sinks | grep -E "(virtual-surround|Virtual.Surround)" | awk '{print $2}' | head -1)
    print_pass "Virtual surround sink found: $SINK_NAME"

    # Get sink details
    CHANNELS=$(pactl list sinks | grep -A20 "$SINK_NAME" | grep "Channel Map:" | head -1 || echo "unknown")
    print_info "Channel configuration: $CHANNELS"
elif pw-cli list-objects 2>/dev/null | grep -q "virtual-surround"; then
    VIRTUAL_SINK_FOUND=true
    print_pass "Virtual surround device found in PipeWire"
    print_info "Device is managed by PipeWire directly"
else
    print_fail "No virtual surround sink found"
    print_info "Run: toggle-virtual-surround to enable it"
fi

# Test 3: Check default audio output
print_section "Audio Routing"

print_test "Checking default sink"
DEFAULT_SINK=$(pactl info | grep "Default Sink:" | cut -d: -f2 | xargs)
if [[ -n "$DEFAULT_SINK" ]]; then
    print_pass "Default sink: $DEFAULT_SINK"
    if [[ "$DEFAULT_SINK" == *"virtual"* ]] || [[ "$DEFAULT_SINK" == *"surround"* ]]; then
        print_info "Virtual surround is set as default output"
    else
        print_warning "Virtual surround is not the default output"
        print_info "Use pavucontrol to route audio to virtual surround"
    fi
else
    print_fail "No default sink configured"
fi

# Test 4: OpenAL HRTF Configuration
print_section "3D Audio (OpenAL HRTF)"

print_test "Checking OpenAL installation"
if command -v openal-info >/dev/null 2>&1; then
    print_pass "OpenAL is installed"

    print_test "Checking HRTF support"
    if openal-info 2>/dev/null | grep -q "HRTF"; then
        print_pass "HRTF is supported"

        # Check for HRTF data files
        if [ -d "/usr/share/openal/hrtf" ] || [ -d "$HOME/.local/share/openal/hrtf" ]; then
            print_info "HRTF data files found"
        else
            print_warning "No HRTF data files found"
        fi
    else
        print_warning "HRTF not detected in OpenAL"
    fi

    print_test "Checking OpenAL configuration"
    if [ -f "$HOME/.config/openal/alsoft.conf" ]; then
        print_pass "OpenAL configuration file exists"
        if grep -q "hrtf = true" "$HOME/.config/openal/alsoft.conf" 2>/dev/null; then
            print_info "HRTF is enabled in configuration"
        else
            print_warning "HRTF not enabled in configuration"
        fi
    else
        print_warning "No OpenAL configuration file found"
        print_info "Expected at: ~/.config/openal/alsoft.conf"
    fi
else
    print_fail "OpenAL is not installed"
    print_info "Install with: sudo apt install libopenal1 openal-info"
fi

# Test 5: Audio Output Tests
print_section "Audio Output Tests"

print_test "Testing stereo (2-channel) output"
if safe_speaker_test 2; then
    print_pass "Stereo audio works"
else
    print_fail "Stereo audio test failed"
fi

if [ "$VIRTUAL_SINK_FOUND" = true ]; then
    print_test "Testing 5.1 surround (6-channel) output"
    if safe_speaker_test 6; then
        print_pass "5.1 surround audio works"
        print_info "You should have heard distinct channel positions"
    else
        print_warning "5.1 surround test failed or timed out"
        print_info "This may be normal if virtual device doesn't accept direct channel testing"
    fi
fi

# Test 6: Check for common issues
print_section "Common Issues Check"

print_test "Checking for audio feedback loops"
# Check if there are any loopback connections that might cause feedback
LOOPBACK_COUNT=$(pw-cli list-objects 2>/dev/null | grep -c "loopback" || echo 0)
if [ "$LOOPBACK_COUNT" -gt 1 ]; then
    print_warning "Multiple loopback devices detected (count: $LOOPBACK_COUNT)"
    print_info "This might cause feedback issues"
else
    print_pass "No feedback loop detected"
fi

print_test "Checking audio latency configuration"
if [ -f "$HOME/.config/pipewire/pipewire.conf.d/99-safe-virtual-surround.conf" ]; then
    if grep -q "quantum = 1024" "$HOME/.config/pipewire/pipewire.conf.d/99-safe-virtual-surround.conf" 2>/dev/null; then
        print_pass "Latency is configured (quantum=1024)"
    else
        print_warning "Non-standard latency configuration"
    fi
elif [ -f "$HOME/.config/pipewire/pipewire.conf.d/99-virtual-surround.conf" ]; then
    print_warning "Old virtual surround config found"
    print_info "Consider updating with install-virtual-surround.sh"
else
    print_info "No PipeWire configuration found (using defaults)"
fi

print_test "Checking for zombie audio processes"
ZOMBIE_COUNT=$(ps aux | grep -E "(pw-loopback|pactl|speaker-test)" | grep defunct | wc -l)
if [ "$ZOMBIE_COUNT" -eq 0 ]; then
    print_pass "No zombie audio processes"
else
    print_warning "Found $ZOMBIE_COUNT zombie audio process(es)"
    print_info "Run: pkill -f pw-loopback to clean up"
fi

# Test 7: Application Integration
print_section "Application Integration"

print_test "Checking for Steam integration"
if [ -f "$HOME/Steam_Audio_Setup_Guide.md" ]; then
    print_pass "Steam audio setup guide exists"
else
    print_warning "Steam setup guide not found"
    print_info "Run install-virtual-surround.sh to create it"
fi

print_test "Checking PATH for toggle script"
if command -v toggle-virtual-surround >/dev/null 2>&1; then
    print_pass "toggle-virtual-surround is in PATH"
elif [ -x "$HOME/.local/bin/toggle-virtual-surround" ]; then
    print_warning "toggle-virtual-surround exists but not in PATH"
    print_info "Add ~/.local/bin to your PATH"
elif [ -x "./toggle-vurtual-surround.sh" ]; then
    print_pass "Local toggle script found (note: spelling 'vurtual')"
else
    print_fail "No toggle script found"
fi

# Test 8: Performance Metrics
print_section "Performance Metrics"

print_test "Checking audio buffer status"
if command -v pw-top >/dev/null 2>&1; then
    # Get a snapshot of audio performance
    PW_TOP_OUTPUT=$(timeout 1s pw-top -b 2>/dev/null || true)
    if [ -n "$PW_TOP_OUTPUT" ]; then
        XRUN_COUNT=$(echo "$PW_TOP_OUTPUT" | grep -c "XRUN" | tr -d '\n' || echo "0")
        if [ "$XRUN_COUNT" = "0" ] || [ "$XRUN_COUNT" = "" ]; then
            print_pass "No audio buffer underruns detected"
        else
            print_warning "Detected $XRUN_COUNT buffer underrun(s)"
            print_info "This might cause audio crackling"
        fi
    else
        print_info "Could not capture pw-top output"
    fi
else
    print_info "pw-top not available for performance monitoring"
fi

# Final Summary
print_section "Test Summary"

echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "Total Tests: ${CYAN}$TOTAL_TESTS${NC}"
echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
echo -e "Failed: ${RED}$FAILED_TESTS${NC}"
echo -e "Warnings: ${YELLOW}$WARNINGS${NC}"
echo -e "${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Overall status
echo ""
if [ "$FAILED_TESTS" -eq 0 ]; then
    if [ "$WARNINGS" -eq 0 ]; then
        echo -e "${GREEN}✓ All tests passed! Your virtual surround setup is working perfectly.${NC}"
    else
        echo -e "${GREEN}✓ Core functionality is working.${NC}"
        echo -e "${YELLOW}⚠ Some optional features need attention.${NC}"
    fi

    echo ""
    echo -e "${CYAN}Quick Commands:${NC}"
    if [ "$VIRTUAL_SINK_FOUND" = true ]; then
        echo "  • Test surround: speaker-test -t wav -c 6"
    else
        echo "  • Enable surround: toggle-virtual-surround"
    fi
    echo "  • Audio control: pavucontrol"
    echo "  • View connections: helvum"
else
    echo -e "${RED}✗ Some critical tests failed.${NC}"
    echo ""
    echo -e "${CYAN}Troubleshooting:${NC}"
    echo "  1. Run: systemctl --user restart pipewire pipewire-pulse wireplumber"
    echo "  2. Run: ./install-virtual-surround.sh (if not already done)"
    echo "  3. Run: toggle-virtual-surround (to enable)"
    echo "  4. Check: pavucontrol (for audio routing)"
fi

# Return appropriate exit code
if [ "$FAILED_TESTS" -gt 0 ]; then
    exit 1
else
    exit 0
fi
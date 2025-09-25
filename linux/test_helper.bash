#!/bin/bash

# Test helper functions for virtual surround testing

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Assert functions following TDD principles
assert_equal() {
    local actual="$1"
    local expected="$2"
    local message="${3:-Expected '$expected' but got '$actual'}"

    if [[ "$actual" != "$expected" ]]; then
        echo "ASSERTION FAILED: $message" >&2
        return 1
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-Expected '$haystack' to contain '$needle'}"

    if [[ "$haystack" != *"$needle"* ]]; then
        echo "ASSERTION FAILED: $message" >&2
        return 1
    fi
}

assert_service_running() {
    local service="$1"
    local message="${2:-Service '$service' should be running}"

    if ! systemctl --user is-active --quiet "$service"; then
        echo "ASSERTION FAILED: $message" >&2
        return 1
    fi
}

# Test description helpers (for better test readability)
given() {
    echo "  Given: $1" >&2
}

should() {
    echo "  Should: $1" >&2
}

# Utility functions for testing
get_virtual_sink_name() {
    # Check both possible sink names from the scripts
    local sink_names=("virtual-surround-sink" "virtual-surround")

    for sink in "${sink_names[@]}"; do
        if pactl list short sinks | grep -q "$sink" || pw-cli list-objects | grep -q "$sink"; then
            echo "$sink"
            return 0
        fi
    done

    return 1
}

is_virtual_surround_enabled() {
    get_virtual_sink_name >/dev/null
}

check_audio_tools() {
    local tools=("pactl" "speaker-test" "pw-cli" "openal-info")
    local missing=()

    for tool in "${tools[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            missing+=("$tool")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo "Missing required tools: ${missing[*]}" >&2
        return 1
    fi
}

# Safe audio testing (prevents loud output)
test_audio_channel_safe() {
    local sink="$1"
    local channel="$2"
    local duration="${3:-1}"

    # Set safe volume first
    pactl set-sink-volume "$sink" 25% 2>/dev/null || true

    # Test specific channel - this is a placeholder for actual implementation
    # In a real implementation, this would use speaker-test with specific channel mapping
    timeout "${duration}s" speaker-test -t sine -c 6 -s "$channel" -l 1 -D "$sink" >/dev/null 2>&1
}

# Latency testing
measure_audio_latency() {
    local sink="$1"

    # This is a simplified latency check
    # In a real implementation, this would use more sophisticated latency measurement
    pactl list sinks | grep -A 20 "$sink" | grep -o "latency: [0-9]* usec" | head -1 | grep -o "[0-9]*"
}
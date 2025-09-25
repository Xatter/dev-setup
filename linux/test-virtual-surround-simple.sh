#!/bin/bash

echo "Testing systemctl..."
systemctl --user is-active pipewire
echo "Result: $?"

echo "Testing with timeout..."
timeout 2s systemctl --user is-active pipewire
echo "Result: $?"

echo "Testing with variable..."
result=$(systemctl --user is-active pipewire)
echo "Result: $result"

echo "Done"
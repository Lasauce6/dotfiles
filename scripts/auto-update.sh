#!/bin/bash
# /usr/local/bin/auto-update.sh

echo "Starting system update: $(date)"

# Update package databases
yay -Sy

# Full system upgrade
yay -Syu --noconfirm

# Clean the cache (optional)
yay -Sc --noconfirm

echo "System update completed: $(date)"

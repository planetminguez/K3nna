#!/bin/bash

# K3nna Setup Script
# This script clones the K3nna repository to your Desktop

echo "========================================"
echo "  K3NNA - Setup Script"
echo "========================================"
echo ""

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo "❌ Git is not installed. Please install Git first."
    echo "Visit: https://git-scm.com/download/mac"
    exit 1
fi

echo "✓ Git found"

# Check if SSH key exists
if [ ! -f ~/.ssh/id_rsa ]; then
    echo "⚠ SSH key not found. Setting up SSH..."
    ssh-keyscan github.com >> ~/.ssh/known_hosts 2>/dev/null
fi

echo "✓ SSH configured"
echo ""

# Clone to Desktop
echo "📥 Cloning K3nna to ~/Desktop/..."
cd ~/Desktop
git clone git@github.com:planetminguez/K3nna.git

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ Clone successful!"
    echo ""
    echo "Next steps:"
    echo "1. cd ~/Desktop/K3nna"
    echo "2. open K3nna.xcodeproj"
    echo "3. Build and run in Xcode (⌘R)"
    echo ""
    echo "========================================"
    echo "  Ready to launch K3NNA!"
    echo "========================================"
else
    echo ""
    echo "❌ Clone failed. Check your SSH key setup."
    exit 1
fi

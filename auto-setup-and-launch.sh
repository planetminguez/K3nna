#!/bin/bash

# K3nna - Automated Setup & Launch Script
# This script clones, builds, and launches K3nna automatically

set -e

echo "========================================"
echo "  K3NNA - Auto Setup & Launch"
echo "========================================"
echo ""

# Check if already in K3nna directory
if [ ! -f "K3nnaApp.swift" ]; then
    echo "📁 Cloning K3nna to Desktop..."
    cd ~/Desktop
    git clone git@github.com:planetminguez/K3nna.git
    cd K3nna
fi

echo "✓ In K3nna directory: $(pwd)"
echo ""

# Check Python 3
echo "🐍 Checking Python 3..."
if ! command -v python3 &> /dev/null; then
    echo "⚠️  Python 3 not found. Installing via Homebrew..."
    brew install python3
fi
echo "✓ Python 3 found: $(python3 --version)"
echo ""

# Check PyInstaller
echo "📦 Checking PyInstaller..."
if ! python3 -m pip show pyinstaller &> /dev/null; then
    echo "⚠️  PyInstaller not found. Installing..."
    python3 -m pip install pyinstaller
fi
echo "✓ PyInstaller installed"
echo ""

# Check Xcode
echo "🛠️  Checking Xcode..."
if ! command -v xcodebuild &> /dev/null; then
    echo "⚠️  Xcode not found. Please install Xcode from App Store and try again."
    exit 1
fi
echo "✓ Xcode found"
echo ""

# Clean and build
echo "🔨 Building K3nna..."
echo ""
xcodebuild clean -scheme K3nna -configuration Debug 2>/dev/null || true
xcodebuild build -scheme K3nna -configuration Debug

echo ""
echo "✓ Build successful!"
echo ""

# Launch the app
echo "🚀 Launching K3nna..."
APP_PATH="./build/Debug/K3nna.app"

if [ -d "$APP_PATH" ]; then
    open "$APP_PATH"
    echo "✓ K3nna is now running!"
    echo ""
    echo "========================================"
    echo "  Welcome to K3NNA!"
    echo "  Drag Python scripts to convert them"
    echo "========================================"
else
    echo "✗ App not found at $APP_PATH"
    exit 1
fi

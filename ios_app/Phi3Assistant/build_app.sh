#!/bin/bash

# Build script for Phi-3 Assistant iOS App

echo "Building Phi-3 Assistant iOS App..."

# Navigate to project directory
cd /Users/guybonnen/Ruth-Qoder/ios_app/Phi3Assistant

# Check if xcodebuild is available
if ! command -v xcodebuild &> /dev/null; then
    echo "ERROR: xcodebuild not found. Please install Xcode command line tools."
    exit 1
fi

# Clean previous build
echo "Cleaning previous build..."
xcodebuild clean -scheme Phi3Assistant -destination 'platform=iOS Simulator,name=iPhone 15 Pro' &> /dev/null

# Build the app
echo "Building the app..."
xcodebuild build -scheme Phi3Assistant -destination 'platform=iOS Simulator,name=iPhone 15 Pro' -configuration Debug

if [ $? -eq 0 ]; then
    echo "✓ Build successful"
    echo "You can now run the app in Xcode or use the following command to run it:"
    echo "xcodebuild test -scheme Phi3Assistant -destination 'platform=iOS Simulator,name=iPhone 15 Pro'"
else
    echo "✗ Build failed"
    echo "Please check the Xcode project for errors"
fi
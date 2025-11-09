#!/bin/bash

# Script to create a proper Xcode project structure
echo "Creating Xcode project structure..."

# Create project directory
mkdir -p Phi3AssistantApp/Phi3AssistantApp

# Copy existing Swift files to new project directory
cp -r ios_app/Phi3Assistant/Phi3Assistant/*.swift Phi3AssistantApp/Phi3AssistantApp/ 2>/dev/null || echo "No existing Swift files to copy"

# Create a basic project structure
cd Phi3AssistantApp

echo "Xcode project structure created in Phi3AssistantApp directory"
echo "Please open Xcode and create a new project in this directory"
echo "Then add your Swift files and model files to the project"
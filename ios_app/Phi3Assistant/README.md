# Phi-3 Assistant iOS App

This iOS application demonstrates how to run the Microsoft Phi-3 Mini language model on iOS devices using ONNX Runtime.

## Features

- Runs Phi-3 Mini 128k model locally on device
- Simple chat interface for interacting with the model
- ONNX Runtime integration for cross-platform compatibility
- Swift implementation with SwiftUI

## Prerequisites

- Xcode 15 or higher
- iOS 15.0 or higher
- Swift Package Manager

## Setup Instructions

1. **Add Model Files**:
   - Copy the ONNX model files to your project:
     - `phi3-mini-128k-instruct-cpu-int4-rtn-block-32.onnx`
     - `phi3-mini-128k-instruct-cpu-int4-rtn-block-32.onnx.data`
   - Make sure to check "Add to target" when adding files

2. **Dependencies**:
   - The project uses Swift Package Manager to manage dependencies
   - ONNX Runtime Mobile is included as a dependency in Package.swift

3. **Build and Run**:
   - Open the project in Xcode
   - Select a simulator or device
   - Build and run the application

## Project Structure

- `Phi3AssistantApp.swift`: Main application entry point
- `ContentView.swift`: Main user interface
- `ModelHandler.swift`: Handles model loading and inference
- `Tokenizer.swift`: Simple text tokenization utilities
- `ONNXInference.swift`: ONNX Runtime inference wrapper
- `ONNXRuntimeTest.swift`: ONNX Runtime testing utilities

## Model Information

- Model: Phi-3 Mini 128k Instruct
- Format: ONNX (cpu-int4-rtn-block-32 quantization)
- Size: ~2.7GB
- Parameters: 3.8B

## Limitations

- Model size exceeds App Store guidelines for cellular downloads
- Inference speed depends on device capabilities
- Current implementation uses placeholder tokenization

## Next Steps

1. Integrate proper Phi-3 tokenizer
2. Implement full inference pipeline
3. Optimize for performance and battery usage
4. Handle model size constraints for App Store distribution

## Resources

- [Microsoft Phi-3 Model](https://huggingface.co/microsoft/Phi-3-mini-128k-instruct-onnx)
- [ONNX Runtime for Mobile](https://github.com/microsoft/onnxruntime)
- [Apple Developer Documentation](https://developer.apple.com/documentation/)
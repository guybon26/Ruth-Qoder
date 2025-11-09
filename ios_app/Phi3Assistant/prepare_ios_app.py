#!/usr/bin/env python3
"""
Script to prepare iOS app for ONNX model integration
"""

import os
import shutil

def prepare_ios_app():
    """Prepare iOS app structure for ONNX integration"""
    print("Preparing iOS app for ONNX model integration...")
    
    # Define paths
    project_root = "/Users/guybonnen/Ruth-Qoder/ios_app/Phi3Assistant"
    models_dir = "/Users/guybonnen/Ruth-Qoder/models"
    
    # Create directories if they don't exist
    os.makedirs(os.path.join(project_root, "Models"), exist_ok=True)
    
    # Copy ONNX model files to iOS project
    onnx_files = [
        "phi3-mini-128k-onnx/cpu_and_mobile/cpu-int4-rtn-block-32/phi3-mini-128k-instruct-cpu-int4-rtn-block-32.onnx",
        "phi3-mini-128k-onnx/cpu_and_mobile/cpu-int4-rtn-block-32/phi3-mini-128k-instruct-cpu-int4-rtn-block-32.onnx.data"
    ]
    
    for onnx_file in onnx_files:
        source_path = os.path.join(models_dir, onnx_file)
        filename = os.path.basename(onnx_file)
        dest_path = os.path.join(project_root, "Models", filename)
        
        if os.path.exists(source_path):
            print(f"Copying {filename} to iOS project...")
            shutil.copy2(source_path, dest_path)
            print(f"  ✓ Copied to {dest_path}")
        else:
            print(f"  ✗ {filename} not found at {source_path}")
    
    # Create a README for iOS integration
    readme_content = """# Phi-3 Assistant iOS App

## ONNX Model Integration

This app uses the ONNX Runtime for iOS to run the Phi-3 Mini 128k model.

### Model Files
- phi3-mini-128k-instruct-cpu-int4-rtn-block-32.onnx (main model)
- phi3-mini-128k-instruct-cpu-int4-rtn-block-32.onnx.data (model weights)

### Integration Steps

1. Add the ONNX Runtime Mobile dependency:
   In your Podfile:
   ```
   pod 'onnxruntime-mobile-c', '~> 1.15.0'
   ```

2. Run `pod install` to install dependencies

3. Add the model files to your Xcode project:
   - Drag the Models folder into your Xcode project
   - Ensure "Add to target" is checked

4. Import and use the ONNX Runtime in your Swift code:
   ```swift
   import onnxruntime
   
   // Load model
   let modelPath = Bundle.main.path(forResource: "phi3-mini-128k-instruct-cpu-int4-rtn-block-32", ofType: "onnx")
   let env = try ORTEnv(loggingLevel: ORTLoggingLevel.warning)
   let session = try ORTSession(env: env, modelPath: modelPath!)
   ```

### Important Considerations

1. Model Size: The model is approximately 2.7 GB, which exceeds App Store guidelines
2. On-Demand Downloading: Consider downloading the model after app installation
3. Performance: Test inference performance on various iOS devices
4. Battery Usage: Monitor battery consumption during model inference

### Alternative Approach - Model Quantization

If the model size is still too large, consider:
1. Using a smaller variant of Phi-3 (4k context instead of 128k)
2. Further quantization to reduce model size
3. Model splitting for on-demand loading

### Next Steps

1. Open your iOS project in Xcode
2. Add the Models folder to your Xcode project
3. Add ONNX Runtime Mobile to your Podfile
4. Run 'pod install'
5. Implement model loading and inference in your Swift code
6. Test with sample queries
"""
    
    readme_path = os.path.join(project_root, "ONNX_INTEGRATION.md")
    with open(readme_path, "w") as f:
        f.write(readme_content)
    
    print(f"✓ Created integration guide: {readme_path}")
    
    # Print next steps
    print("\nNext Steps:")
    print("1. Open your iOS project in Xcode")
    print("2. Add the Models folder to your Xcode project")
    print("3. Add ONNX Runtime Mobile to your Podfile")
    print("4. Run 'pod install'")
    print("5. Implement model loading and inference in your Swift code")
    print("6. Test with sample queries")

def main():
    """Main function"""
    prepare_ios_app()

if __name__ == "__main__":
    main()
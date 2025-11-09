# Immediate Next Steps for Phi-3 iOS Deployment

## Today's Goals

1. Set up ONNX Runtime Mobile in the iOS project
2. Integrate the Phi-3 model files
3. Implement basic model loading
4. Test with a simple inference

## Step-by-Step Instructions

### Step 1: Set Up ONNX Runtime Mobile

1. **Navigate to the iOS project directory**:
   ```bash
   cd /Users/guybonnen/Ruth-Qoder/ios_app/Phi3Assistant
   ```

2. **Update the Podfile** to include ONNX Runtime Mobile:
   ```ruby
   platform :ios, '15.0'
   
   target 'Phi3Assistant' do
     use_frameworks!
     
     # Add this line
     pod 'onnxruntime-mobile-c', '~> 1.15.0'
   end
   ```

3. **Install the pods**:
   ```bash
   pod install
   ```

4. **Open the workspace** (not the project file):
   ```bash
   open Phi3Assistant.xcworkspace
   ```

### Step 2: Integrate Model Files

1. **Copy the model files** to the iOS project:
   - Source: `/Users/guybonnen/Ruth-Qoder/models/phi3-mini-128k-onnx/cpu_and_mobile/cpu-int4-rtn-block-32/`
   - Files to copy:
     - `phi3-mini-128k-instruct-cpu-int4-rtn-block-32.onnx`
     - `phi3-mini-128k-instruct-cpu-int4-rtn-block-32.onnx.data`

2. **In Xcode**:
   - Drag both files into the project navigator
   - Ensure "Add to target" is checked for "Phi3Assistant"
   - Choose "Copy items if needed"

### Step 3: Update ModelHandler.swift

Replace the current ModelHandler.swift with the following implementation:

```swift
import Foundation
import onnxruntime

class ModelHandler: ObservableObject {
    private var session: ORTSession?
    private var env: ORTEnv?
    
    init() {
        loadModel()
    }
    
    private func loadModel() {
        do {
            // Initialize ONNX Runtime environment
            env = try ORTEnv(loggingLevel: ORTLoggingLevel.warning)
            
            // Get path to model file
            guard let modelPath = Bundle.main.path(forResource: "phi3-mini-128k-instruct-cpu-int4-rtn-block-32", ofType: "onnx") else {
                print("Model file not found in bundle")
                return
            }
            
            // Create inference session
            session = try ORTSession(env: env!, modelPath: modelPath)
            print("Model loaded successfully")
        } catch {
            print("Error loading model: \(error)")
        }
    }
    
    func processQuery(_ query: String) -> String {
        // This is a placeholder implementation
        // In a real implementation, you would:
        // 1. Tokenize the input query
        // 2. Run inference using the ONNX model
        // 3. Detokenize the output
        // 4. Return the response
        
        // For now, simulate processing
        Thread.sleep(forTimeInterval: 1.0)
        return "This is a response to your query: \"\(query)\" processed by Phi-3 Mini using ONNX Runtime."
    }
    
    func isModelLoaded() -> Bool {
        return session != nil
    }
}
```

### Step 4: Test the Integration

1. **Build and run** the app in Xcode simulator
2. **Verify** that:
   - The app builds without errors
   - The model loads successfully (check console output)
   - The query processing works (returns simulated response)

### Step 5: Prepare for Advanced Implementation

1. **Research tokenization** for Phi-3 models
2. **Plan the inference pipeline**:
   - Input tokenization
   - Model inference
   - Output detokenization
3. **Consider performance optimization** strategies

## Expected Outcomes

By completing these steps, you will have:
- ✅ A working iOS project with ONNX Runtime Mobile
- ✅ Phi-3 model integrated into the app bundle
- ✅ Basic model loading functionality
- ✅ Foundation for implementing full inference

## Troubleshooting

### Common Issues

1. **Pod installation fails**:
   - Ensure CocoaPods is installed: `sudo gem install cocoapods`
   - Run `pod repo update` before `pod install`

2. **Model file not found**:
   - Verify files are added to the target
   - Check file names match exactly
   - Ensure files are in the app bundle

3. **ONNX Runtime import fails**:
   - Make sure you're opening the .xcworkspace file, not .xcodeproj
   - Verify pod installation was successful

## Next After Today

Once today's steps are complete:
1. Implement proper tokenization/detokenization
2. Add actual inference code
3. Test on physical devices
4. Begin performance optimization

This approach follows Microsoft's recommended path for iOS deployment and gives us the best chance of success.
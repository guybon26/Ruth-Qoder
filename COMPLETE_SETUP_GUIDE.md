# COMPLETE SETUP GUIDE FOR PHI-3 IOS APP

## PROBLEM IDENTIFIED
There is no Xcode project in the Ruth-Qoder directory. You need to create one manually.

## SOLUTION: MANUAL XCODE PROJECT SETUP

### STEP 1: CREATE NEW XCODE PROJECT

1. Open Xcode
2. Select "Create a new Xcode project"
3. Choose "App" under iOS templates
4. Click "Next"
5. Fill in project details:
   - Product Name: `Phi3Assistant`
   - Team: None (or your Apple Developer team)
   - Organization Identifier: `com.yourname`
   - Interface: `SwiftUI`
   - Language: `Swift`
6. Click "Next"
7. Save the project in the Ruth-Qoder directory
8. Folder name: `Phi3AssistantXcodeProject`
9. Click "Create"

### STEP 2: REPLACE DEFAULT FILES WITH YOUR FILES

1. In Xcode Project Navigator, delete the default files:
   - `ContentView.swift`
   - `Phi3AssistantApp.swift`

2. Add your existing Swift files:
   - Right-click on the Phi3Assistant folder (under your project)
   - Select "Add Files to 'Phi3Assistant'..."
   - Navigate to: `/Users/guybonnen/Ruth-Qoder/ios_app/Phi3Assistant/Phi3Assistant/`
   - Select these files:
     - `ContentView.swift`
     - `ModelHandler.swift`
     - `Phi3AssistantApp.swift`
     - `Tokenizer.swift`
     - `ONNXInference.swift`
   - Check these options:
     - [✓] "Copy items if needed"
     - [✓] "Add to target" (Phi3Assistant)
   - Click "Add"

### STEP 3: ADD ONNX RUNTIME DEPENDENCY

1. Select your project in the Project Navigator
2. Select the "Phi3Assistant" target
3. Go to the "Package Dependencies" tab
4. Click the "+" button
5. Enter URL: `https://github.com/microsoft/onnxruntime`
6. Version: "Up to Next Major Version" from "1.15.0"
7. Click "Add Package"

### STEP 4: ADD MODEL FILES TO PROJECT

1. In Xcode Project Navigator, right-click on the Phi3Assistant folder
2. Select "Add Files to 'Phi3Assistant'..."
3. Navigate to: `/Users/guybonnen/Ruth-Qoder/models/phi3-mini-128k-onnx/cpu_and_mobile/cpu-int4-rtn-block-32/`
4. Select both files:
   - `phi3-mini-128k-instruct-cpu-int4-rtn-block-32.onnx`
   - `phi3-mini-128k-instruct-cpu-int4-rtn-block-32.onnx.data`
5. Check these options:
   - [✓] "Copy items if needed"
   - [✓] "Add to target" (Phi3Assistant)
6. Click "Add"

### STEP 5: VERIFY FILE INTEGRATION

1. Select each ONNX file in Project Navigator
2. Open File Inspector (⌥+⌘+0)
3. Under "Target Membership," ensure "Phi3Assistant" is checked

### STEP 6: BUILD AND TEST

1. Select a simulator (e.g., iPhone 15 Pro)
2. Press ⌘+R to build and run
3. Check Xcode console for "Model loaded successfully"
4. Test the app by entering a query

## EXPECTED OUTCOMES

When successful, you should see:
- App builds without errors
- Console shows "Model loaded successfully"
- UI displays "Model Status: Loaded Successfully"
- You can enter queries and get responses

## TROUBLESHOOTING

### If Build Fails:
- Product → Clean Build Folder (⌘+Shift+K)
- Product → Build (⌘+B)

### If Model Not Loading:
- Verify ONNX files are in "Copy Bundle Resources" (Project Settings → Build Phases)
- Check File Inspector for target membership
- Ensure both .onnx and .onnx.data files are added

### If Runtime Errors:
- Check console output for specific error messages
- Verify model file paths in ModelHandler.swift

## FILE LOCATIONS

### Your Swift Files:
`/Users/guybonnen/Ruth-Qoder/ios_app/Phi3Assistant/Phi3Assistant/`

### Model Files:
`/Users/guybonnen/Ruth-Qoder/models/phi3-mini-128k-onnx/cpu_and_mobile/cpu-int4-rtn-block-32/`

## NEXT STEPS AFTER SUCCESSFUL SETUP

1. Test basic inference functionality
2. Implement proper tokenization
3. Optimize performance
4. Handle model size constraints for App Store

This guide provides everything needed to create a working Xcode project for your Phi-3 iOS app.
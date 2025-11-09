#!/usr/bin/env python3
"""
Script to check the status of Core ML conversion and provide guidance.
"""

import coremltools as ct
import onnx
import os

def check_conversion_status():
    """Check the status of Core ML conversion and provide guidance."""
    print("Core ML Conversion Status Check")
    print("=" * 35)
    
    # Check if ONNX model exists
    onnx_path = "models/Phi-3-mini-4k-instruct-q4.onnx"
    if not os.path.exists(onnx_path):
        print("❌ ONNX model not found")
        return
    
    print("✅ ONNX model found")
    
    # Check ONNX model validity
    try:
        onnx_model = onnx.load(onnx_path)
        onnx.checker.check_model(onnx_model)
        print("✅ ONNX model is valid")
    except Exception as e:
        print(f"❌ ONNX model validation failed: {e}")
        return
    
    # Check Core ML Tools version
    print(f"✅ Core ML Tools version: {ct.__version__}")
    
    # Try conversion
    print("\nAttempting Core ML conversion...")
    try:
        # This is the approach that should work according to documentation
        mlmodel = ct.convert(
            onnx_path,
            convert_to="mlprogram"
        )
        print("✅ Conversion successful")
        print(f"   Model type: {type(mlmodel)}")
    except Exception as e:
        print(f"❌ Conversion failed: {e}")
        print("\nThis is a known issue with certain versions of Core ML Tools.")
        print("The error indicates that ONNX is not recognized as a valid source framework.")
        
        # Provide guidance
        print("\nRecommendations:")
        print("1. Try installing a different version of Core ML Tools:")
        print("   pip install coremltools==6.3.0")
        print("\n2. Or use the ONNX ML approach:")
        print("   pip install onnx-mlir")
        print("\n3. Alternative: Convert through PyTorch as intermediate step")
        
        return
    
    # Try to save the model
    print("\nAttempting to save Core ML model...")
    try:
        output_path = "models/Phi-3-mini-4k-instruct-q4.mlpackage"
        # Use a more defensive approach to saving
        if mlmodel is not None:
            # Check if it has a save method
            if hasattr(mlmodel, 'save'):
                mlmodel.save(output_path)
                print("✅ Model saved successfully")
                print(f"   Saved to: {output_path}")
            else:
                print("❌ Model object doesn't have save method")
        else:
            print("❌ Conversion returned None")
    except Exception as e:
        print(f"❌ Failed to save model: {e}")
        print("\nThis may be due to compatibility issues with the Core ML Tools version.")

def main():
    check_conversion_status()

if __name__ == "__main__":
    main()
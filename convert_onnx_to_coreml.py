#!/usr/bin/env python3

import coremltools as ct
import argparse
import os

def convert_onnx_to_coreml(onnx_path, coreml_path):
    """Convert ONNX model to Core ML format"""
    print(f"Loading ONNX model from {onnx_path}")
    
    # Convert ONNX to Core ML following the documentation example
    try:
        # Load the ONNX model and convert to Core ML
        # For newer versions of coremltools, we don't need to specify source
        mlmodel = ct.convert(onnx_path)
        
        # Save the Core ML model
        print(f"Saving Core ML model to {coreml_path}")
        # Use a more defensive approach to saving
        if mlmodel is not None:
            # Import MLModel to ensure we can create one if needed
            from coremltools.models import MLModel
            
            # Check if it's already an MLModel or if we need to create one
            if isinstance(mlmodel, MLModel):
                mlmodel.save(coreml_path)
            else:
                # Create an MLModel from the result
                coreml_model = MLModel(mlmodel)
                coreml_model.save(coreml_path)
        else:
            raise RuntimeError("Conversion returned None")
        
        print("Core ML model saved successfully")
        return coreml_path
    except Exception as e:
        print(f"Error during conversion: {str(e)}")
        # Print more details about the error
        import traceback
        traceback.print_exc()
        
        # Try alternative approach - convert through PyTorch
        print("\nTrying alternative approach: Convert through PyTorch...")
        try:
            import torch
            import onnx
            from onnx2torch import convert
            
            # Load ONNX model
            print("Loading ONNX model with onnx library...")
            onnx_model = onnx.load(onnx_path)
            
            # Convert to PyTorch
            print("Converting ONNX to PyTorch...")
            pytorch_model = convert(onnx_model)
            
            # Convert PyTorch to Core ML by first converting to TorchScript
            print("Converting PyTorch to TorchScript...")
            # Create dummy input to trace the model
            dummy_input = torch.randn(1, 10)  # Adjust size as needed
            traced_model = torch.jit.trace(pytorch_model, dummy_input)
            
            # Convert TorchScript to Core ML
            print("Converting TorchScript to Core ML...")
            mlmodel = ct.convert(traced_model)
            
            # Save the Core ML model
            print(f"Saving Core ML model to {coreml_path}")
            if mlmodel is not None:
                from coremltools.models import MLModel
                if isinstance(mlmodel, MLModel):
                    mlmodel.save(coreml_path)
                else:
                    coreml_model = MLModel(mlmodel)
                    coreml_model.save(coreml_path)
                
                print("Core ML model saved successfully (alternative method)")
                return coreml_path
        except Exception as e2:
            print(f"Alternative approach also failed: {str(e2)}")
            import traceback
            traceback.print_exc()
        
        raise

def main():
    parser = argparse.ArgumentParser(description='Convert ONNX model to Core ML')
    parser.add_argument('--input', required=True, help='Path to input ONNX model')
    parser.add_argument('--output', required=True, help='Path to output Core ML model')
    
    args = parser.parse_args()
    
    if not os.path.exists(args.input):
        raise FileNotFoundError(f"Input ONNX model not found: {args.input}")
    
    # Create output directory if it doesn't exist
    os.makedirs(os.path.dirname(args.output), exist_ok=True)
    
    try:
        coreml_path = convert_onnx_to_coreml(args.input, args.output)
        print(f"Successfully converted ONNX model to Core ML: {coreml_path}")
    except Exception as e:
        print(f"Error during conversion: {str(e)}")
        raise

if __name__ == "__main__":
    main()
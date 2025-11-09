#!/usr/bin/env python3
"""
Convert official Phi-3 Mini ONNX model to CoreML format for iOS deployment.
"""

import coremltools as ct
import torch
import os
import argparse

# --- CONFIG ---
DEFAULT_ONNX_PATH = "models/phi3-mini-128k-onnx/cpu_and_mobile/cpu-int4-rtn-block-32/phi3-mini-128k-instruct-cpu-int4-rtn-block-32.onnx"
DEFAULT_OUTPUT_PATH = "models/Phi3Mini128K.mlpackage"

def convert_onnx_to_coreml(onnx_path, output_path):
    """Convert official Phi-3 Mini ONNX model to CoreML format."""
    print(f"Converting {onnx_path} to CoreML format...")
    
    # Check if input file exists
    if not os.path.exists(onnx_path):
        raise FileNotFoundError(f"Input ONNX model not found: {onnx_path}")
    
    # Create output directory if it doesn't exist
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    
    try:
        # Convert ONNX to CoreML
        print("Converting ONNX to CoreML...")
        # Try with source specified
        mlmodel = ct.convert(
            onnx_path,
            source="auto",  # Let CoreML tools auto-detect
            convert_to="mlprogram",
            compute_units=ct.ComputeUnit.ALL,
            minimum_deployment_target=ct.target.iOS17
        )
        
        print("Conversion successful!")
        print(f"Model type: {type(mlmodel)}")
        
        # Try to save the model
        print(f"Saving CoreML model to {output_path}...")
        # Check if the model has a save method
        if hasattr(mlmodel, 'save'):
            mlmodel.save(output_path)
            print(f"Successfully saved to {output_path}")
        else:
            # Try using MLModel wrapper
            from coremltools.models import MLModel
            if not isinstance(mlmodel, MLModel):
                wrapped_model = MLModel(mlmodel)
                wrapped_model.save(output_path)
                print(f"Successfully saved to {output_path}")
            else:
                mlmodel.save(output_path)
                print(f"Successfully saved to {output_path}")
        
        return output_path
    except Exception as e:
        print(f"Error during conversion: {str(e)}")
        import traceback
        traceback.print_exc()
        raise

def main():
    parser = argparse.ArgumentParser(description='Convert Phi-3 Mini ONNX to CoreML')
    parser.add_argument('--input', default=DEFAULT_ONNX_PATH, help='Path to input ONNX model')
    parser.add_argument('--output', default=DEFAULT_OUTPUT_PATH, help='Path to output CoreML model')
    
    args = parser.parse_args()
    
    try:
        convert_onnx_to_coreml(args.input, args.output)
        print("Conversion completed successfully!")
    except Exception as e:
        print(f"Error during conversion: {str(e)}")
        raise

if __name__ == "__main__":
    main()
#!/usr/bin/env python3
"""
Convert existing ONNX model to mobile-optimized Core ML with aggressive quantization.
Uses the existing 752MB ONNX model to create a < 200MB Core ML model for iPhone.
"""

import argparse
import os
import coremltools as ct
from coremltools.models.neural_network.quantization_utils import quantize_weights

def convert_onnx_to_mobile_coreml(
    onnx_path,
    output_path,
    quantization_bits=4
):
    """
    Convert ONNX model to mobile-optimized Core ML format.
    
    Args:
        onnx_path: Path to existing ONNX model
        output_path: Path for output Core ML model
        quantization_bits: 4, 8, or 16 bits
    """
    
    print("=" * 70)
    print("Converting ONNX to Mobile-Optimized Core ML")
    print("=" * 70)
    print(f"Input:  {onnx_path}")
    print(f"Output: {output_path}")
    print(f"Quantization: {quantization_bits}-bit")
    print("=" * 70)
    
    # Check if input exists
    if not os.path.exists(onnx_path):
        raise FileNotFoundError(f"ONNX model not found: {onnx_path}")
    
    # Get input file size
    onnx_size_mb = os.path.getsize(onnx_path) / (1024 * 1024)
    print(f"\n📦 Input ONNX model size: {onnx_size_mb:.2f} MB")
    
    # Step 1: Convert ONNX to Core ML
    print("\n[1/3] Converting ONNX to Core ML...")
    try:
        mlmodel = ct.convert(
            onnx_path,
            minimum_deployment_target=ct.target.iOS15,
            compute_precision=ct.precision.FLOAT16,  # Use FP16 for smaller size
            convert_to="mlprogram"
        )
        print("✅ Initial conversion successful")
    except Exception as e:
        print(f"❌ Error during conversion: {e}")
        raise
    
    # Step 2: Apply quantization
    print(f"\n[2/3] Applying {quantization_bits}-bit quantization...")
    try:
        if quantization_bits == 4:
            # 4-bit quantization for maximum compression
            config = ct.optimize.coreml.OptimizationConfig(
                global_config=ct.optimize.coreml.OpLinearQuantizerConfig(
                    mode="linear_symmetric",
                    weight_threshold=512
                )
            )
            mlmodel = ct.optimize.coreml.linear_quantize_weights(mlmodel, config=config)
            print("✅ 4-bit quantization applied")
            
        elif quantization_bits == 8:
            # 8-bit quantization for better quality
            mlmodel = quantize_weights(mlmodel, nbits=8)
            print("✅ 8-bit quantization applied")
        else:
            # Keep FP16 (no additional quantization)
            print("✅ Using FP16 precision (no additional quantization)")
        
    except Exception as e:
        print(f"⚠️  Quantization failed: {e}")
        print("Continuing with FP16 model...")
    
    # Step 3: Save the model
    print(f"\n[3/3] Saving model to {output_path}...")
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    mlmodel.save(output_path)
    
    # Get output size
    if os.path.isdir(output_path):
        output_size = sum(
            os.path.getsize(os.path.join(dirpath, filename))
            for dirpath, dirnames, filenames in os.walk(output_path)
            for filename in filenames
        )
    else:
        output_size = os.path.getsize(output_path)
    
    output_size_mb = output_size / (1024 * 1024)
    compression_ratio = (1 - output_size_mb / onnx_size_mb) * 100
    
    print("\n" + "=" * 70)
    print("✅ CONVERSION COMPLETE")
    print("=" * 70)
    print(f"📊 Original ONNX size: {onnx_size_mb:.2f} MB")
    print(f"📦 Core ML size:       {output_size_mb:.2f} MB")
    print(f"📉 Compression:        {compression_ratio:.1f}% reduction")
    print("=" * 70)
    
    # Evaluate suitability for iPhone
    print("\n🎯 iPhone 13 mini Deployment Assessment:")
    if output_size_mb <= 150:
        print(f"   ✅ EXCELLENT: {output_size_mb:.2f} MB - Cellular download ready!")
        print("   Ideal for App Store distribution")
    elif output_size_mb <= 500:
        print(f"   ✅ GOOD: {output_size_mb:.2f} MB - Wi-Fi download recommended")
        print("   Acceptable for App Store")
    else:
        print(f"   ⚠️  WARNING: {output_size_mb:.2f} MB - Still too large")
        print("   May need further optimization or consider cloud inference")
    
    print("\n📱 Next Steps:")
    print("=" * 70)
    print("1. Copy model to Xcode project:")
    print(f"   cp -r {output_path} ios_app/Phi3Assistant/Phi3Assistant/")
    print("\n2. Update ModelHandler.swift:")
    print("   - Change model filename in loadModel() method")
    print("   - Update to use Core ML instead of ONNX Runtime")
    print("\n3. Test on iPhone 13 mini simulator or device")
    print("=" * 70)
    
    return output_path

def main():
    parser = argparse.ArgumentParser(
        description='Convert existing ONNX model to mobile-optimized Core ML'
    )
    parser.add_argument(
        '--input',
        default='models/Phi-3-mini-4k-instruct-q4.onnx',
        help='Path to existing ONNX model'
    )
    parser.add_argument(
        '--output',
        default='models/mobile_optimized/phi3_mini_mobile_coreml.mlpackage',
        help='Output path for Core ML model'
    )
    parser.add_argument(
        '--quantization',
        type=int,
        choices=[4, 8, 16],
        default=4,
        help='Quantization bits (4=smallest, 8=balanced, 16=best quality)'
    )
    
    args = parser.parse_args()
    
    try:
        convert_onnx_to_mobile_coreml(
            args.input,
            args.output,
            args.quantization
        )
    except Exception as e:
        print(f"\n❌ Conversion failed: {e}")
        import traceback
        traceback.print_exc()
        exit(1)

if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""
Convert Phi-3 Mini GGUF to CoreML format for on-device inference on iOS/Mac.
"""

import coremltools as ct
import torch
import numpy as np
from gguf import GGUFReader
from transformers import AutoTokenizer, Phi3Config, Phi3ForCausalLM
import os
import argparse

# --- CONFIG ---
DEFAULT_GGUF_PATH = "models/Phi-3-mini-4k-instruct-q4.gguf"
DEFAULT_OUTPUT_PATH = "models/Phi3Mini4K.mlpackage"
DEFAULT_TOKENIZER_DIR = "phi3-tokenizer"

def convert_gguf_to_coreml(gguf_path, output_path, tokenizer_dir):
    """Convert Phi-3 Mini GGUF model to CoreML format."""
    print(f"Converting {gguf_path} to CoreML format...")
    
    # Load tokenizer
    print("Loading tokenizer...")
    if os.path.exists(tokenizer_dir):
        tokenizer = AutoTokenizer.from_pretrained(tokenizer_dir)
    else:
        print(f"Tokenizer directory {tokenizer_dir} not found, downloading from HuggingFace...")
        tokenizer = AutoTokenizer.from_pretrained("microsoft/Phi-3-mini-4k-instruct")
        # Save tokenizer for future use
        tokenizer.save_pretrained(tokenizer_dir)
    
    # --- Load GGUF and extract weights ---
    print("Loading GGUF model...")
    reader = GGUFReader(gguf_path, 'r')
    print(f"Number of tensors: {len(reader.tensors)}")
    
    # Extract key tensors
    weights = {}
    for tensor in reader.tensors:
        name = tensor.name
        # Convert GGUF tensor data to numpy array
        if hasattr(tensor, 'tensor_type'):
            # For quantized tensors, we need to handle them properly
            data = np.array(tensor.data)
        else:
            data = np.array(tensor.data)
        shape = tensor.shape
        weights[name] = torch.from_numpy(data).view(*shape)
        print(f"Loaded tensor: {name} with shape {shape}")
    
    # Create Phi-3 model configuration
    print("Creating Phi-3 model configuration...")
    config = Phi3Config.from_pretrained("microsoft/Phi-3-mini-4k-instruct")
    config._attn_implementation = "eager"  # Important for tracing
    model = Phi3ForCausalLM(config)
    
    # --- Load weights into PyTorch model ---
    print("Loading weights into PyTorch model...")
    state_dict = model.state_dict()
    missing = []
    for name, param in state_dict.items():
        # Convert PyTorch naming to GGUF naming
        gguf_name = name.replace(".", "_")  # GGUF uses underscores instead of dots
        if gguf_name in weights:
            w = weights[gguf_name]
            if w.shape != param.shape:
                print(f"Shape mismatch for {name}: GGUF {w.shape} vs PyTorch {param.shape}")
                # Try to permute dimensions if possible
                if len(w.shape) == 2 and len(param.shape) == 2:
                    w = w.permute(1, 0)  # Transpose for linear layers
            if w.shape == param.shape:
                state_dict[name].copy_(w)
                print(f"Loaded {name}")
            else:
                print(f"Skipping {name} due to shape mismatch")
                missing.append(name)
        else:
            print(f"Missing weight for {name}")
            missing.append(name)
    
    print(f"Missing keys: {len(missing)}")
    
    model.load_state_dict(state_dict, strict=False)
    model.eval()
    
    # --- Trace with dummy input ---
    print("Tracing model with dummy input...")
    seq_len = 4
    batch = 1
    example_input = torch.randint(0, config.vocab_size, (batch, seq_len))
    
    with torch.no_grad():
        traced_model = torch.jit.trace(model, example_input)
    
    # --- Convert to CoreML ---
    print("Converting to CoreML...")
    mlmodel = ct.convert(
        traced_model,
        convert_to="mlprogram",
        inputs=[ct.TensorType(name="input_ids", shape=example_input.shape)],
        compute_units=ct.ComputeUnit.ALL,
        minimum_deployment_target=ct.target.iOS17
    )
    
    # Save
    print(f"Saving CoreML model to {output_path}...")
    mlmodel.save(output_path)
    print(f"Successfully saved to {output_path}")

def main():
    parser = argparse.ArgumentParser(description='Convert Phi-3 Mini GGUF to CoreML')
    parser.add_argument('--input', default=DEFAULT_GGUF_PATH, help='Path to input GGUF model')
    parser.add_argument('--output', default=DEFAULT_OUTPUT_PATH, help='Path to output CoreML model')
    parser.add_argument('--tokenizer', default=DEFAULT_TOKENIZER_DIR, help='Path to tokenizer directory')
    
    args = parser.parse_args()
    
    # Check if input file exists
    if not os.path.exists(args.input):
        raise FileNotFoundError(f"Input GGUF model not found: {args.input}")
    
    # Create output directory if it doesn't exist
    os.makedirs(os.path.dirname(args.output), exist_ok=True)
    
    try:
        convert_gguf_to_coreml(args.input, args.output, args.tokenizer)
        print("Conversion completed successfully!")
    except Exception as e:
        print(f"Error during conversion: {str(e)}")
        import traceback
        traceback.print_exc()
        raise

if __name__ == "__main__":
    main()
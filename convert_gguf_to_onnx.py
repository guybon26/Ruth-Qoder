#!/usr/bin/env python3

import torch
import torch.nn as nn
import onnx
import onnxruntime
import gguf
import numpy as np
import argparse
import os

class Phi3MiniModel(nn.Module):
    def __init__(self, config):
        super().__init__()
        self.vocab_size = config['vocab_size']
        self.hidden_size = config['hidden_size']
        self.num_layers = config['num_layers']
        self.num_heads = config['num_heads']
        
        # Embedding layer
        self.embed_tokens = nn.Embedding(self.vocab_size, self.hidden_size)
        
        # Transformer layers would go here
        # For simplicity, we'll just create a placeholder
        
        # Output layer
        self.lm_head = nn.Linear(self.hidden_size, self.vocab_size, bias=False)
    
    def forward(self, input_ids):
        # This is a simplified forward pass
        hidden_states = self.embed_tokens(input_ids)
        # In a real implementation, we would pass through transformer layers
        logits = self.lm_head(hidden_states)
        return logits

def load_gguf_weights(gguf_path):
    """Load weights from GGUF file"""
    reader = gguf.GGUFReader(gguf_path, 'r')
    
    weights = {}
    for tensor in reader.tensors:
        # Convert GGUF tensor to numpy array
        # Handle different data types
        if hasattr(tensor, 'tensor_type'):
            # Handle quantized tensors
            weights[tensor.name] = np.array(tensor.data)
        else:
            weights[tensor.name] = np.array(tensor.data)
        
    return weights

def create_model_config():
    """Create model configuration"""
    return {
        'vocab_size': 32064,  # Updated to match actual model
        'hidden_size': 3072,  # Updated to match actual model
        'num_layers': 32,
        'num_heads': 32,
    }

def convert_gguf_to_onnx(gguf_path, onnx_path):
    """Convert GGUF model to ONNX format"""
    print(f"Loading GGUF model from {gguf_path}")
    weights = load_gguf_weights(gguf_path)
    
    print("Creating model configuration")
    config = create_model_config()
    
    print("Initializing PyTorch model")
    model = Phi3MiniModel(config)
    
    # Load weights into model
    # Note: This is a simplified example. In practice, you would need to map
    # the GGUF tensor names to the corresponding PyTorch model parameters
    
    # For demonstration, we'll just load the embedding weights
    if 'token_embd.weight' in weights:
        embed_weight = torch.from_numpy(weights['token_embd.weight']).float()
        print(f"Embedding weight shape: {embed_weight.shape}")
        print(f"Model embedding layer weight shape: {model.embed_tokens.weight.shape}")
        
        # For quantized models, we need to handle the conversion properly
        # This is a simplified approach - in practice, you'd need to dequantize
        with torch.no_grad():
            # Only copy if shapes match
            if embed_weight.shape == model.embed_tokens.weight.shape:
                model.embed_tokens.weight.copy_(embed_weight)
            else:
                print("Warning: Embedding weight shapes don't match. Skipping weight loading.")
    
    # Set the model to evaluation mode
    model.eval()
    
    # Create dummy input for ONNX export
    dummy_input = torch.randint(0, config['vocab_size'], (1, 10))  # batch_size=1, seq_len=10
    
    print(f"Exporting to ONNX format: {onnx_path}")
    torch.onnx.export(
        model,
        (dummy_input,),  # Pass as tuple
        onnx_path,
        export_params=True,
        opset_version=13,
        do_constant_folding=True,
        input_names=['input_ids'],
        output_names=['logits'],
        dynamic_axes={
            'input_ids': {0: 'batch_size', 1: 'sequence_length'},
            'logits': {0: 'batch_size', 1: 'sequence_length'}
        }
    )
    
    print("Validating ONNX model")
    onnx_model = onnx.load(onnx_path)
    onnx.checker.check_model(onnx_model)
    print("ONNX model is valid")
    
    return onnx_path

def main():
    parser = argparse.ArgumentParser(description='Convert GGUF model to ONNX')
    parser.add_argument('--input', required=True, help='Path to input GGUF model')
    parser.add_argument('--output', required=True, help='Path to output ONNX model')
    
    args = parser.parse_args()
    
    if not os.path.exists(args.input):
        raise FileNotFoundError(f"Input GGUF model not found: {args.input}")
    
    # Create output directory if it doesn't exist
    os.makedirs(os.path.dirname(args.output), exist_ok=True)
    
    try:
        onnx_path = convert_gguf_to_onnx(args.input, args.output)
        print(f"Successfully converted GGUF model to ONNX: {onnx_path}")
    except Exception as e:
        print(f"Error during conversion: {str(e)}")
        raise

if __name__ == "__main__":
    main()
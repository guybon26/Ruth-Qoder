"""
Demo script for Edge-First Hybrid SLM-LLM Personal Assistant

This script demonstrates the capabilities of the assistant with various example queries.
"""

import sys
import os
import time

# Add the src directory to the path
sys.path.append(os.path.join(os.path.dirname(__file__), 'src'))

from main import process_query

def demo_assistant():
    """Demonstrate the assistant with various example queries"""
    print("=== Edge-First Hybrid SLM-LLM Personal Assistant Demo ===\n")
    
    # Example queries for different domains
    demo_queries = [
        {
            "query": "What is the capital of France?",
            "domain": "general",
            "description": "Simple factual query (processed locally)"
        },
        {
            "query": "Explain the theory of relativity in simple terms with examples",
            "domain": "education",
            "description": "Complex educational query (offloaded to LLM)"
        },
        {
            "query": "What are the common symptoms of the flu and when should I see a doctor?",
            "domain": "healthcare",
            "description": "Healthcare query with disclaimer"
        },
        {
            "query": "Schedule a team meeting for next Monday at 10 AM to discuss project progress",
            "domain": "productivity",
            "description": "Productivity task with scheduling"
        },
        {
            "query": "How does photosynthesis work and why is it important for life on Earth?",
            "domain": "education",
            "description": "Scientific explanation query"
        }
    ]
    
    for i, example in enumerate(demo_queries, 1):
        print(f"Demo {i}: {example['description']}")
        print(f"Query: {example['query']}")
        print(f"Domain: {example['domain']}")
        print("Processing...")
        
        try:
            # Process the query
            start_time = time.time()
            result = process_query(example['query'], example['domain'], 'config.yaml')
            end_time = time.time()
            
            # Display results
            print(f"Response: {result['response']}")
            print(f"Route: {result['metadata']['route'].upper()}")
            print(f"Processing Time: {end_time - start_time:.2f} seconds")
            
            # Show additional metadata
            if 'slm_confidence' in result['metadata']:
                print(f"SLM Confidence: {result['metadata']['slm_confidence']:.2f}")
            if 'uncertainty' in result['metadata']:
                print(f"Uncertainty: {result['metadata']['uncertainty']:.2f}")
            
            print("-" * 80)
            print()
            
        except Exception as e:
            print(f"Error processing query: {e}")
            print("-" * 80)
            print()
        
        # Add a small delay between demos
        time.sleep(1)
    
    print("=== Demo Complete ===")
    print("\nTo run your own queries, use:")
    print("python src/main.py --query \"Your query here\" [--domain domain]")

if __name__ == "__main__":
    demo_assistant()
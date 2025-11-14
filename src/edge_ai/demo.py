"""
Demo script for Edge AI System
Runs the complete edge AI pipeline with simulated sensors
"""

import asyncio
import time
from edge_ai_system import EdgeAISystem


async def demo_basic_system():
    """Basic demo with all sensors"""
    
    print("\n" + "="*70)
    print(" EDGE AI SYSTEM DEMO - Basic Operation")
    print("="*70 + "\n")
    
    model_path = "/Users/guybonnen/Ruth-Qoder/models/Phi-3-mini-4k-instruct-q4.gguf"
    
    # Create and configure system
    system = EdgeAISystem(model_path, config={
        "inference_interval": 5.0,  # Run inference every 5 seconds
        "learning_enabled": True,
        "anomaly_detection": True,
        "auto_save": False  # Disable for demo
    })
    
    # Setup sensors
    system.setup_sensors()
    
    # Start system
    await system.start()
    
    # Run for 30 seconds
    await asyncio.sleep(30)
    
    # Stop system
    await system.stop()


async def demo_with_queries():
    """Demo with specific user queries"""
    
    print("\n" + "="*70)
    print(" EDGE AI SYSTEM DEMO - Query-Based Inference")
    print("="*70 + "\n")
    
    model_path = "/Users/guybonnen/Ruth-Qoder/models/Phi-3-mini-4k-instruct-q4.gguf"
    
    system = EdgeAISystem(model_path)
    system.setup_sensors()
    
    # Initialize without starting continuous monitoring
    await system.sensor_manager.initialize_all()
    await system.sensor_manager.start_streaming()
    
    # Wait for sensors to collect data
    await asyncio.sleep(3)
    
    # Run specific queries
    queries = [
        "Is the temperature comfortable?",
        "Are there any safety concerns?",
        "What's the current activity level?",
        "Summarize the environmental conditions"
    ]
    
    for query in queries:
        print(f"\n{'─'*70}")
        print(f"Query: {query}")
        print(f"{'─'*70}")
        
        response = await system.inference_engine.run_inference(query, max_tokens=100)
        print(f"\nResponse:\n{response}\n")
        
        await asyncio.sleep(2)
    
    await system.sensor_manager.shutdown_all()


async def demo_anomaly_detection():
    """Demo showing anomaly detection capabilities"""
    
    print("\n" + "="*70)
    print(" EDGE AI SYSTEM DEMO - Anomaly Detection")
    print("="*70 + "\n")
    
    model_path = "/Users/guybonnen/Ruth-Qoder/models/Phi-3-mini-4k-instruct-q4.gguf"
    
    system = EdgeAISystem(model_path, config={
        "learning_enabled": True,
        "anomaly_detection": True
    })
    
    system.setup_sensors()
    await system.sensor_manager.initialize_all()
    await system.sensor_manager.start_streaming()
    
    print("Learning normal patterns...")
    await asyncio.sleep(10)
    
    print("\nLearning Summary:")
    summary = system.learner.get_learning_summary()
    for key, value in summary.items():
        print(f"  • {key}: {value}")
    
    print("\nMonitoring for anomalies...")
    await asyncio.sleep(20)
    
    await system.sensor_manager.shutdown_all()


async def demo_system_status():
    """Demo showing system status monitoring"""
    
    print("\n" + "="*70)
    print(" EDGE AI SYSTEM DEMO - System Status")
    print("="*70 + "\n")
    
    model_path = "/Users/guybonnen/Ruth-Qoder/models/Phi-3-mini-4k-instruct-q4.gguf"
    
    system = EdgeAISystem(model_path)
    system.setup_sensors()
    await system.sensor_manager.initialize_all()
    await system.sensor_manager.start_streaming()
    
    # Monitor status periodically
    for i in range(5):
        await asyncio.sleep(3)
        
        print(f"\n{'─'*70}")
        print(f"Status Update #{i+1}")
        print(f"{'─'*70}")
        
        status = system.get_status()
        
        print(f"\n  System Running: {status['is_running']}")
        print(f"  Active Sensors: {status['active_sensors']}")
        print(f"  Model Loaded: {status['model_loaded']}")
        
        print(f"\n  Sensor Statistics:")
        for sensor_id, stats in status['sensor_stats'].items():
            if stats:
                print(f"    {sensor_id}:")
                for key, value in stats.items():
                    if isinstance(value, float):
                        print(f"      {key}: {value:.2f}")
                    else:
                        print(f"      {key}: {value}")
    
    await system.sensor_manager.shutdown_all()


def print_demo_menu():
    """Print available demos"""
    print("\n" + "="*70)
    print(" EDGE AI SYSTEM - DEMO MENU")
    print("="*70)
    print("\nAvailable Demos:")
    print("  1. Basic System Demo (30 seconds)")
    print("  2. Query-Based Inference")
    print("  3. Anomaly Detection")
    print("  4. System Status Monitoring")
    print("  5. Run All Demos")
    print("  0. Exit")
    print("="*70 + "\n")


async def main():
    """Main demo runner"""
    
    while True:
        print_demo_menu()
        
        try:
            choice = input("Select demo (0-5): ").strip()
            
            if choice == "0":
                print("\n✓ Exiting demo\n")
                break
            elif choice == "1":
                await demo_basic_system()
            elif choice == "2":
                await demo_with_queries()
            elif choice == "3":
                await demo_anomaly_detection()
            elif choice == "4":
                await demo_system_status()
            elif choice == "5":
                print("\nRunning all demos...\n")
                await demo_basic_system()
                await demo_with_queries()
                await demo_anomaly_detection()
                await demo_system_status()
            else:
                print("\n⚠️  Invalid choice. Please select 0-5.\n")
                
        except KeyboardInterrupt:
            print("\n\n⚠️  Demo interrupted\n")
            break
        except Exception as e:
            print(f"\n⚠️  Error: {e}\n")


if __name__ == "__main__":
    asyncio.run(main())

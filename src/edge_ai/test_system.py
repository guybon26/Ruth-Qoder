"""
Quick test of Edge AI system components
"""

import asyncio
import time
from sensor_manager import SensorManager, TemperatureSensor, MotionSensor, Protocol
from sensor_preprocessor import SensorPreprocessor
from incremental_learner import IncrementalLearner


async def test_sensors():
    """Test basic sensor functionality"""
    
    print("\n" + "="*60)
    print("🧪 Testing Sensor System")
    print("="*60 + "\n")
    
    # Create sensor manager
    manager = SensorManager(buffer_size=100)
    
    # Add sensors
    temp = TemperatureSensor("temp_test", protocol=Protocol.I2C)
    motion = MotionSensor("motion_test", pin=17)
    
    manager.register_sensor(temp)
    manager.register_sensor(motion)
    
    # Initialize
    print("Initializing sensors...")
    await manager.initialize_all()
    
    # Start streaming
    print("\nStarting sensor data streaming...")
    await manager.start_streaming()
    
    # Collect data for 5 seconds
    print("Collecting sensor data for 5 seconds...\n")
    await asyncio.sleep(5)
    
    # Get recent data
    temp_data = manager.get_recent_data("temp_test", n=5)
    motion_data = manager.get_recent_data("motion_test", n=5)
    
    print("\n📊 Temperature Sensor Data:")
    for reading in temp_data[-3:]:
        print(f"  {reading.value}{reading.unit} at {time.strftime('%H:%M:%S', time.localtime(reading.timestamp))}")
    
    print("\n📊 Motion Sensor Data:")
    for reading in motion_data[-3:]:
        status = "DETECTED" if reading.value else "None"
        print(f"  {status} at {time.strftime('%H:%M:%S', time.localtime(reading.timestamp))}")
    
    # Get statistics
    temp_stats = manager.get_sensor_stats("temp_test")
    print(f"\n📈 Temperature Statistics:")
    print(f"  Mean: {temp_stats.get('mean', 0):.2f}°C")
    print(f"  Std: {temp_stats.get('std', 0):.2f}°C")
    print(f"  Min: {temp_stats.get('min', 0):.2f}°C")
    print(f"  Max: {temp_stats.get('max', 0):.2f}°C")
    
    # Stop
    await manager.stop_streaming()
    await manager.shutdown_all()
    
    print("\n✓ Sensor test completed!\n")


async def test_preprocessing():
    """Test data preprocessing"""
    
    print("\n" + "="*60)
    print("🧪 Testing Sensor Preprocessing")
    print("="*60 + "\n")
    
    # Create manager and preprocessor
    manager = SensorManager()
    preprocessor = SensorPreprocessor(window_size=5)
    
    temp = TemperatureSensor("temp_preprocess", protocol=Protocol.I2C)
    manager.register_sensor(temp)
    
    await manager.initialize_all()
    await manager.start_streaming()
    
    # Wait for some data
    await asyncio.sleep(3)
    
    # Get and process data
    readings = manager.get_recent_data("temp_preprocess", n=10)
    
    print(f"Processing {len(readings)} sensor readings...\n")
    
    for reading in readings[-3:]:
        features = preprocessor.process_reading(reading)
        
        if features:
            print(f"📊 Features extracted:")
            print(f"  Raw value: {features.context.get('raw_value', 0):.2f}°C")
            print(f"  Features: {features.feature_names}")
            print(f"  Values: {features.features}\n")
    
    await manager.shutdown_all()
    
    print("✓ Preprocessing test completed!\n")


async def test_learning():
    """Test incremental learning"""
    
    print("\n" + "="*60)
    print("🧪 Testing Incremental Learning")
    print("="*60 + "\n")
    
    manager = SensorManager()
    preprocessor = SensorPreprocessor()
    learner = IncrementalLearner(learning_rate=0.01, update_threshold=5)
    
    temp = TemperatureSensor("temp_learn", protocol=Protocol.I2C)
    manager.register_sensor(temp)
    
    await manager.initialize_all()
    await manager.start_streaming()
    
    print("Learning from sensor data for 10 seconds...\n")
    
    # Collect and learn
    for i in range(20):
        await asyncio.sleep(0.5)
        readings = manager.get_recent_data("temp_learn", n=1)
        
        if readings:
            features = preprocessor.process_reading(readings[0])
            if features:
                learner.add_experience(features)
                
                if i % 5 == 0:
                    summary = learner.get_learning_summary()
                    print(f"  Update {i//5}: {summary['total_samples']} samples, "
                          f"{summary['features_tracked']} features tracked")
    
    # Test anomaly detection
    print("\n🔍 Testing anomaly detection...")
    readings = manager.get_recent_data("temp_learn", n=1)
    if readings:
        features = preprocessor.process_reading(readings[0])
        is_anomaly, score = learner.detect_anomaly(features)
        print(f"  Current reading anomaly: {is_anomaly}, score: {score:.2f}")
    
    # Get final summary
    print("\n📊 Learning Summary:")
    summary = learner.get_learning_summary()
    for key, value in summary.items():
        print(f"  {key}: {value}")
    
    await manager.shutdown_all()
    
    print("\n✓ Learning test completed!\n")


async def main():
    """Run all tests"""
    
    print("\n" + "="*70)
    print(" 🚀 EDGE AI SYSTEM - Component Tests")
    print("="*70)
    
    try:
        await test_sensors()
        await test_preprocessing()
        await test_learning()
        
        print("\n" + "="*70)
        print(" ✅ All tests passed!")
        print("="*70 + "\n")
        
    except Exception as e:
        print(f"\n❌ Test failed: {e}\n")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    asyncio.run(main())

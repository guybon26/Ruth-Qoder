# Edge AI System - Quick Start Guide

## 🎯 What You've Got

A complete **end-to-end edge AI system** that:

1. **Connects to sensors** (temperature, motion, camera, accelerometer, GPS)
2. **Preprocesses sensor data** (feature extraction, normalization)
3. **Runs Phi-3 SLM inference** (contextual AI analysis)
4. **Learns incrementally** (online learning, anomaly detection)
5. **Works on iOS** (native sensor integration)

## 📁 Project Structure

```
/Users/guybonnen/Ruth-Qoder/
├── src/edge_ai/                         # Python Edge AI System
│   ├── sensor_manager.py                # Sensor abstraction layer
│   ├── sensor_preprocessor.py           # Feature extraction
│   ├── edge_slm_inference.py            # SLM integration
│   ├── incremental_learner.py           # Online learning
│   ├── edge_ai_system.py                # Main system orchestrator
│   ├── demo.py                          # Demo scripts
│   ├── requirements.txt                 # Python dependencies
│   └── README.md                        # Full documentation
│
└── llama.cpp/examples/llama.swiftui/
    └── llama.swiftui/Models/
        └── IosSensorBridge.swift        # iOS sensor integration
```

## 🚀 Running the System

### Step 1: Install Dependencies

```bash
cd /Users/guybonnen/Ruth-Qoder/src/edge_ai
pip install -r requirements.txt
```

### Step 2: Run Demo

```bash
python demo.py
```

**Demo Menu:**
1. Basic System Demo (30 seconds)
2. Query-Based Inference
3. Anomaly Detection
4. System Status Monitoring

### Step 3: Try It Yourself

```python
import asyncio
from edge_ai_system import EdgeAISystem

async def main():
    # Initialize system
    model_path = "/Users/guybonnen/Ruth-Qoder/models/Phi-3-mini-4k-instruct-q4.gguf"
    system = EdgeAISystem(model_path)
    
    # Setup sensors (simulated by default)
    system.setup_sensors()
    
    # Start system
    await system.start()
    
    # Let it run for 30 seconds
    await asyncio.sleep(30)
    
    # Stop
    await system.stop()

asyncio.run(main())
```

## 📱 iOS Integration

The iOS sensors are ready to use in your llama.swiftui app:

```swift
import SwiftUI

struct SensorView: View {
    @State private var sensorBridge = IosSensorBridge()
    @State private var accelData = "No data"
    
    var body: some View {
        VStack {
            Text("Accelerometer: \(accelData)")
            
            Button("Start Sensors") {
                sensorBridge.onAccelerometerData = { x, y, z in
                    accelData = String(format: "%.2f, %.2f, %.2f", x, y, z)
                }
                sensorBridge.startAccelerometer()
            }
            
            Button("Stop Sensors") {
                sensorBridge.stopAllSensors()
            }
        }
    }
}
```

## 🔧 Key Features

### 1. Sensor Types Supported
- **Temperature** (I2C/GPIO)
- **Motion/PIR** (GPIO)
- **Camera** (USB/MIPI)
- **Accelerometer** (I2C)
- **GPS** (UART)
- **Humidity, Light, Pressure** (I2C)

### 2. Communication Protocols
- I2C, SPI, UART, GPIO
- USB, Bluetooth, HTTP, MQTT

### 3. AI Capabilities
- **Real-time inference** with Phi-3 SLM
- **Incremental learning** (no retraining needed)
- **Anomaly detection** (adaptive thresholds)
- **Pattern recognition** (clustering)
- **Multi-sensor fusion**

### 4. iOS Native Sensors
- Accelerometer/Gyroscope (CoreMotion)
- GPS (CoreLocation)
- Camera (AVFoundation)

## 💡 Example Queries

Once the system is running with sensor data:

```python
# Get environmental analysis
response = await system.inference_engine.run_inference(
    "Analyze the current environmental conditions"
)

# Check comfort level
response = await system.inference_engine.run_inference(
    "Is the temperature comfortable?"
)

# Safety check
response = await system.inference_engine.run_inference(
    "Are there any safety concerns?"
)

# Activity detection
response = await system.inference_engine.run_inference(
    "What activity is currently happening?"
)
```

## 📊 Monitoring

Check system status:

```python
status = system.get_status()

print(f"Running: {status['is_running']}")
print(f"Sensors: {status['active_sensors']}")
print(f"Model: {status['model_loaded']}")

# Sensor statistics
for sensor_id, stats in status['sensor_stats'].items():
    print(f"{sensor_id}: {stats}")

# Learning progress
learning = status['learning_summary']
print(f"Samples: {learning['total_samples']}")
print(f"Updates: {learning['update_count']}")
```

## 🎓 Learning Capabilities

The system learns automatically:

```python
# Detect anomalies
is_anomaly, score = system.learner.detect_anomaly(features)
if is_anomaly:
    print(f"⚠️ Anomaly: {score:.2f}")

# Recognize patterns
pattern_id = system.learner.predict_pattern(features)

# Get feature importance
importance = system.learner.get_feature_importance("temp_room", "temperature_delta")

# Save learned parameters
system.learner.save_learned_parameters("learned_params.json")

# Load previously learned
system.learner.load_learned_parameters("learned_params.json")
```

## 🔌 Hardware Integration

### Raspberry Pi Example

For real hardware (Raspberry Pi), set `_simulate = False`:

```python
class TemperatureSensor(BaseSensor):
    def __init__(self, sensor_id: str, i2c_address: int):
        super().__init__(sensor_id, SensorType.TEMPERATURE, Protocol.I2C)
        self.i2c_address = i2c_address
        self._simulate = False  # Use real hardware
    
    async def initialize(self) -> bool:
        import smbus
        self.bus = smbus.SMBus(1)
        # Configure sensor...
        return True
    
    async def read(self) -> SensorReading:
        # Read from I2C bus
        data = self.bus.read_i2c_block_data(self.i2c_address, 0, 2)
        temperature = self._convert_to_celsius(data)
        
        return SensorReading(
            sensor_id=self.sensor_id,
            sensor_type=self.sensor_type,
            timestamp=time.time(),
            value=temperature,
            unit="°C"
        )
```

## 📈 Performance Tips

1. **Adjust sampling rates** based on sensor type:
   ```python
   temp_sensor.sampling_rate = 1.0    # 1 Hz (slow)
   accel_sensor.sampling_rate = 100.0 # 100 Hz (fast)
   ```

2. **Tune inference interval** for your use case:
   ```python
   config = {"inference_interval": 5.0}  # Every 5 seconds
   ```

3. **Optimize buffer sizes**:
   ```python
   sensor_manager = SensorManager(buffer_size=500)  # Smaller = less memory
   ```

4. **Control learning rate**:
   ```python
   learner = IncrementalLearner(learning_rate=0.01, update_threshold=10)
   ```

## 🐛 Troubleshooting

**Issue: Model not loading**
```
⚠️  llama-cpp-python not installed, using simulation mode
```
**Solution:** Install llama-cpp-python: `pip install llama-cpp-python`

**Issue: Sensor not found**
```
⚠️ Temperature sensor not available
```
**Solution:** Check hardware connections or use simulated mode

**Issue: Import errors**
```python
# Make sure you're in the correct directory
cd /Users/guybonnen/Ruth-Qoder/src/edge_ai
python demo.py
```

## 🎯 Next Steps

1. **Customize sensors** for your hardware
2. **Add new sensor types** (see README.md)
3. **Integrate with iOS app** (use IosSensorBridge.swift)
4. **Deploy to edge device** (Raspberry Pi, Jetson Nano, etc.)
5. **Connect to cloud** for hybrid inference

## 📚 Full Documentation

See `/Users/guybonnen/Ruth-Qoder/src/edge_ai/README.md` for complete API reference and examples.

---

**Questions?** Check the README or inspect the code - it's well-documented! 🚀

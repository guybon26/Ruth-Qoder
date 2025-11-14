# Edge AI System - Real-Time Sensor Integration with SLM

Complete end-to-end edge AI system that connects sensors with Phi-3 Small Language Model for real-time inference and incremental learning.

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                      Edge AI System                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐          │
│  │ Temperature  │  │    Motion    │  │    Camera    │          │
│  │   Sensors    │  │   Sensors    │  │   Sensors    │          │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘          │
│         │                  │                  │                  │
│         └──────────────────┼──────────────────┘                  │
│                            │                                     │
│                    ┌───────▼────────┐                           │
│                    │ Sensor Manager  │                           │
│                    │   (Real-time)   │                           │
│                    └───────┬────────┘                           │
│                            │                                     │
│                    ┌───────▼────────┐                           │
│                    │  Preprocessor   │                           │
│                    │  (Features)     │                           │
│                    └───────┬────────┘                           │
│                            │                                     │
│          ┌─────────────────┼─────────────────┐                  │
│          │                 │                 │                  │
│    ┌─────▼─────┐   ┌──────▼──────┐  ┌──────▼──────┐           │
│    │ Phi-3 SLM │   │  Incremental │  │   Anomaly   │           │
│    │ Inference │   │   Learning   │  │  Detection  │           │
│    └───────────┘   └──────────────┘  └──────────────┘           │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘
```

## 📦 Components

### 1. **Sensor Manager** (`sensor_manager.py`)
- Manages multiple sensor types (Temperature, Motion, Camera, Accelerometer, GPS)
- Supports various protocols (I2C, SPI, UART, GPIO, USB, Bluetooth)
- Real-time data streaming with async I/O
- Configurable sampling rates per sensor
- Circular buffer for recent data history

**Supported Sensors:**
- 🌡️ Temperature (I2C/GPIO)
- 🏃 Motion/PIR (GPIO)
- 📷 Camera (USB/MIPI)
- 📐 Accelerometer (I2C)
- 🌍 GPS (UART/USB)
- 💧 Humidity (I2C)
- 💡 Light (I2C/Analog)
- 📊 Pressure (I2C)

### 2. **Sensor Preprocessor** (`sensor_preprocessor.py`)
- Extracts features from raw sensor data
- Temporal windowing for time-series analysis
- Normalization and scaling
- Multi-sensor fusion capabilities

**Features Extracted:**
- **Temperature**: Current value, delta, mean, std, min, max
- **Motion**: Current state, frequency, time since last motion
- **Camera**: Brightness (RGB), contrast, edge density
- **Accelerometer**: 3-axis values, magnitude, jerk, variance

### 3. **Edge SLM Inference** (`edge_slm_inference.py`)
- Integrates Phi-3 GGUF model with sensor data
- Creates natural language context from sensor readings
- Real-time inference with contextual awareness
- Continuous monitoring mode
- Query-based inference support

### 4. **Incremental Learner** (`incremental_learner.py`)
- Online learning from streaming sensor data
- Lightweight parameter updates (no full retraining)
- Anomaly detection with adaptive thresholds
- Pattern recognition and clustering
- Feature importance learning

**Learning Capabilities:**
- 📊 Feature weight adaptation
- 🔔 Anomaly threshold calibration
- 🎯 Pattern clustering (k-means-like)
- 💾 Parameter persistence

### 5. **iOS Sensor Bridge** (`IosSensorBridge.swift`)
- Native iOS sensor integration
- CoreMotion for accelerometer/gyroscope
- CoreLocation for GPS
- AVFoundation for camera
- Real-time callbacks to Edge AI system

## 🚀 Quick Start

### Installation

```bash
cd /Users/guybonnen/Ruth-Qoder/src/edge_ai

# Install dependencies
pip install -r requirements.txt

# For iOS integration (llama.cpp)
cd ../../llama.cpp
bash build-xcframework.sh
```

### Python Usage

```python
from edge_ai_system import EdgeAISystem

# Create system
model_path = "/path/to/Phi-3-mini-4k-instruct-q4.gguf"
system = EdgeAISystem(model_path)

# Setup sensors
system.setup_sensors()

# Start system
await system.start()

# Query with sensor context
response = await system.inference_engine.run_inference(
    "What is the current temperature?"
)
```

### Run Demo

```bash
python demo.py
```

## 📱 iOS Integration

The iOS sensor bridge provides native sensor access:

```swift
let sensorBridge = IosSensorBridge()

// Accelerometer
sensorBridge.onAccelerometerData = { x, y, z in
    print("Accel: \(x), \(y), \(z)")
}
sensorBridge.startAccelerometer(updateInterval: 0.1)

// Camera
sensorBridge.onCameraFrame = { image in
    // Process frame
}
sensorBridge.startCamera()

// GPS
sensorBridge.onLocationData = { lat, lon, alt in
    print("Location: \(lat), \(lon)")
}
sensorBridge.startLocation()
```

## ⚙️ Configuration

```python
config = {
    "learning_rate": 0.01,           # Incremental learning rate
    "memory_size": 1000,             # Experience buffer size
    "inference_interval": 10.0,      # Seconds between inferences
    "learning_enabled": True,        # Enable online learning
    "anomaly_detection": True,       # Detect sensor anomalies
    "auto_save": True,               # Auto-save learned params
    "save_interval": 300             # Save every 5 minutes
}

system = EdgeAISystem(model_path, config=config)
```

## 📊 Features

### Real-Time Inference
- Converts sensor data to natural language context
- Runs Phi-3 SLM for contextual analysis
- Generates insights about environment
- Supports custom queries

### Incremental Learning
- **Feature Importance**: Learns which features matter most
- **Anomaly Detection**: Adapts thresholds based on data distribution
- **Pattern Recognition**: Clusters similar sensor patterns
- **Memory Efficient**: Only stores lightweight parameters

### Sensor Fusion
- Combines data from multiple sensors
- Temporal alignment of readings
- Cross-sensor correlation analysis
- Multi-modal feature extraction

## 🎯 Use Cases

### 1. Smart Home Automation
```python
# Detect occupancy and adjust environment
response = await inference_engine.run_inference(
    "Should I adjust the temperature based on current conditions?"
)
```

### 2. Predictive Maintenance
```python
# Monitor equipment sensors for anomalies
is_anomaly, score = learner.detect_anomaly(features)
if is_anomaly:
    print(f"⚠️ Anomaly detected: score={score:.2f}")
```

### 3. Environmental Monitoring
```python
# Analyze environmental conditions
sensor_context = inference_engine.create_sensor_context(sensor_data)
# Context includes temperature trends, air quality, etc.
```

### 4. Activity Recognition
```python
# Recognize patterns from accelerometer
pattern_id = learner.predict_pattern(accel_features)
# walking, running, stationary, etc.
```

## 📈 Performance

### Compute Constraints
- **CPU-only inference**: Designed for edge devices
- **Memory efficient**: ~500MB for Phi-3 Mini Q4
- **Low latency**: <100ms for feature extraction
- **Adaptive sampling**: Adjusts rates based on activity

### Inference Speed
- **Temperature sensor**: ~50 Hz
- **Motion sensor**: ~20 Hz
- **Camera**: ~10 Hz (640x480)
- **Accelerometer**: ~100 Hz
- **SLM inference**: ~1-5 seconds (256 tokens)

## 🔧 Customization

### Adding New Sensors

```python
from sensor_manager import BaseSensor, SensorType, Protocol

class CustomSensor(BaseSensor):
    def __init__(self, sensor_id: str):
        super().__init__(sensor_id, SensorType.CUSTOM, Protocol.I2C)
    
    async def read(self) -> SensorReading:
        # Implement sensor reading logic
        value = self._read_hardware()
        
        return SensorReading(
            sensor_id=self.sensor_id,
            sensor_type=self.sensor_type,
            timestamp=time.time(),
            value=value,
            unit="custom_unit"
        )
    
    async def initialize(self) -> bool:
        # Hardware initialization
        return True
    
    async def shutdown(self):
        # Cleanup
        pass
```

### Custom Feature Extraction

```python
class CustomPreprocessor(SensorPreprocessor):
    def _process_custom_sensor(self, reading: SensorReading):
        # Extract custom features
        features = []
        feature_names = []
        
        # Your feature extraction logic
        
        return ProcessedFeatures(
            features=np.array(features),
            feature_names=feature_names,
            timestamp=reading.timestamp,
            sensor_id=reading.sensor_id,
            context={}
        )
```

## 🛡️ Error Handling

The system includes robust error handling:
- Sensor initialization failures
- Communication protocol errors
- Model loading errors
- Inference timeout handling
- Graceful degradation

## 📝 Logging

All components log important events:
```
✓ Temperature sensor temp_room initialized
✓ Motion sensor motion_entrance initialized
✓ Loaded SLM model: Phi-3-mini-4k-instruct-q4.gguf
⚠️ Anomaly detected on temp_room: score=2.34
✓ Incremental update #15 completed
```

## 🔬 Testing

Run unit tests:
```bash
# Test sensor manager
python -m pytest tests/test_sensors.py

# Test preprocessor
python -m pytest tests/test_preprocessor.py

# Test learning
python -m pytest tests/test_learning.py
```

## 📚 API Reference

See inline documentation in each module for detailed API reference.

## 🤝 Contributing

This is a research/educational project demonstrating edge AI capabilities.

## 📄 License

Part of the Ruth-Qoder AI Assistant project.

---

**Built with:** Python 3.10+, llama.cpp, NumPy, OpenCV, CoreMotion (iOS)

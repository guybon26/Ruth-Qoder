"""
Edge SLM Inference Engine - Connects sensors with Phi-3 SLM
Performs real-time inference on sensor data with context awareness
"""

import asyncio
import time
import json
from typing import Dict, List, Optional, Any
import numpy as np
from pathlib import Path

from sensor_manager import SensorManager, SensorReading, SensorType
from sensor_preprocessor import SensorPreprocessor, ProcessedFeatures


class EdgeSLMInference:
    """Inference engine that connects sensors with SLM"""
    
    def __init__(self, model_path: str, sensor_manager: SensorManager):
        self.model_path = Path(model_path)
        self.sensor_manager = sensor_manager
        self.preprocessor = SensorPreprocessor(window_size=10)
        self.context_memory: List[Dict] = []
        self.max_context = 50
        
        # Try to load the model
        self.model = self._load_model()
        
    def _load_model(self):
        """Load Phi-3 GGUF model"""
        try:
            # For iOS/macOS, we use llama.cpp
            # For this Python version, we'll use llama-cpp-python if available
            try:
                from llama_cpp import Llama
                
                model = Llama(
                    model_path=str(self.model_path),
                    n_ctx=2048,
                    n_threads=4,
                    n_gpu_layers=0,  # CPU only for edge devices
                    verbose=False
                )
                print(f"✓ Loaded SLM model: {self.model_path.name}")
                return model
            except ImportError:
                print("⚠️  llama-cpp-python not installed, using simulation mode")
                return None
                
        except Exception as e:
            print(f"⚠️  Failed to load model: {e}")
            print("⚠️  Running in simulation mode")
            return None
    
    def create_sensor_context(self, sensor_data: Dict[str, List[SensorReading]]) -> str:
        """Create natural language context from sensor data"""
        context_parts = []
        
        for sensor_id, readings in sensor_data.items():
            if not readings:
                continue
            
            latest = readings[-1]
            sensor_type = latest.sensor_type.value
            
            if latest.sensor_type == SensorType.TEMPERATURE:
                value = latest.value
                context_parts.append(f"Temperature sensor '{sensor_id}': {value}°C")
                
                # Add trend information
                if len(readings) >= 3:
                    values = [r.value for r in readings[-3:]]
                    if values[-1] > values[0] + 0.5:
                        context_parts.append("(increasing)")
                    elif values[-1] < values[0] - 0.5:
                        context_parts.append("(decreasing)")
            
            elif latest.sensor_type == SensorType.MOTION:
                if latest.value:
                    context_parts.append(f"Motion detected on sensor '{sensor_id}'")
                else:
                    time_since = latest.metadata.get("last_motion")
                    if time_since:
                        elapsed = latest.timestamp - time_since
                        context_parts.append(f"No motion for {int(elapsed)}s on '{sensor_id}'")
            
            elif latest.sensor_type == SensorType.CAMERA:
                objects = latest.metadata.get("objects_detected", 0)
                brightness = latest.metadata.get("brightness", 0.5)
                context_parts.append(
                    f"Camera '{sensor_id}': {objects} objects detected, "
                    f"brightness {brightness:.2f}"
                )
            
            elif latest.sensor_type == SensorType.ACCELEROMETER:
                accel = latest.value
                magnitude = np.sqrt(accel['x']**2 + accel['y']**2 + accel['z']**2)
                context_parts.append(
                    f"Accelerometer '{sensor_id}': magnitude {magnitude:.2f} m/s²"
                )
        
        return "\n".join(context_parts)
    
    def generate_prompt(self, sensor_context: str, query: str = None) -> str:
        """Generate prompt for SLM with sensor context"""
        
        base_prompt = f"""<|system|>
You are an intelligent edge AI assistant with access to real-time sensor data. Analyze sensor readings and provide contextual insights.

Current Sensor Data:
{sensor_context}
<|end|>
<|user|>"""
        
        if query:
            base_prompt += f"\n{query}\n"
        else:
            base_prompt += "\nAnalyze the sensor data and provide insights about the current environment.\n"
        
        base_prompt += "<|end|>\n<|assistant|>"
        
        return base_prompt
    
    async def run_inference(self, query: str = None, max_tokens: int = 150) -> str:
        """Run inference with current sensor data"""
        
        # Gather recent sensor data
        sensor_data = {}
        for sensor_id in self.sensor_manager.sensors.keys():
            readings = self.sensor_manager.get_recent_data(sensor_id, n=5)
            if readings:
                sensor_data[sensor_id] = readings
        
        if not sensor_data:
            return "⚠️ No sensor data available"
        
        # Create context
        sensor_context = self.create_sensor_context(sensor_data)
        prompt = self.generate_prompt(sensor_context, query)
        
        # Run inference
        if self.model:
            try:
                response = self.model(
                    prompt,
                    max_tokens=max_tokens,
                    temperature=0.7,
                    top_p=0.9,
                    stop=["<|end|>", "<|user|>"],
                    echo=False
                )
                
                output = response['choices'][0]['text'].strip()
                
                # Store in context memory
                self.context_memory.append({
                    "timestamp": time.time(),
                    "sensor_context": sensor_context,
                    "query": query,
                    "response": output
                })
                
                if len(self.context_memory) > self.max_context:
                    self.context_memory = self.context_memory[-self.max_context:]
                
                return output
                
            except Exception as e:
                print(f"⚠️  Inference error: {e}")
                return self._simulate_response(sensor_context, query)
        else:
            return self._simulate_response(sensor_context, query)
    
    def _simulate_response(self, sensor_context: str, query: str = None) -> str:
        """Simulate AI response when model is not available"""
        
        lines = sensor_context.split('\n')
        insights = []
        
        # Simple rule-based analysis
        for line in lines:
            if 'Temperature' in line and 'increasing' in line:
                insights.append("Temperature is rising - monitor for overheating.")
            elif 'Motion detected' in line:
                insights.append("Activity detected in the area.")
            elif 'No motion' in line and '60' in line:
                insights.append("Area has been quiet for over a minute.")
        
        if not insights:
            insights = ["All sensor readings are within normal ranges."]
        
        return "Sensor Analysis:\n" + "\n".join(f"• {i}" for i in insights)
    
    async def continuous_monitoring(self, interval: float = 5.0, callback=None):
        """Continuously monitor sensors and generate insights"""
        print(f"✓ Started continuous monitoring (every {interval}s)")
        
        while True:
            try:
                response = await self.run_inference()
                
                result = {
                    "timestamp": time.time(),
                    "insights": response
                }
                
                print(f"\n{'='*60}")
                print(f"[{time.strftime('%H:%M:%S')}] Sensor Insights:")
                print(response)
                print(f"{'='*60}\n")
                
                if callback:
                    await callback(result)
                
                await asyncio.sleep(interval)
                
            except Exception as e:
                print(f"⚠️  Monitoring error: {e}")
                await asyncio.sleep(interval)
    
    def get_sensor_features(self) -> Dict[str, ProcessedFeatures]:
        """Get preprocessed features from all sensors"""
        features = {}
        
        for sensor_id in self.sensor_manager.sensors.keys():
            readings = self.sensor_manager.get_recent_data(sensor_id, n=1)
            if readings:
                processed = self.preprocessor.process_reading(readings[0])
                if processed:
                    features[sensor_id] = processed
        
        return features
    
    def export_sensor_log(self, filepath: str):
        """Export sensor data and insights to file"""
        export_data = {
            "export_time": time.time(),
            "context_history": self.context_memory,
            "sensor_stats": {
                sensor_id: self.sensor_manager.get_sensor_stats(sensor_id)
                for sensor_id in self.sensor_manager.sensors.keys()
            }
        }
        
        with open(filepath, 'w') as f:
            json.dump(export_data, f, indent=2, default=str)
        
        print(f"✓ Exported sensor log to {filepath}")

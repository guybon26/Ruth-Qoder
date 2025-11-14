"""
Complete Edge AI System Integration
Combines sensors, preprocessing, inference, and incremental learning
"""

import asyncio
import signal
import sys
from pathlib import Path

from sensor_manager import (
    SensorManager, TemperatureSensor, MotionSensor, 
    CameraSensor, AccelerometerSensor, Protocol
)
from sensor_preprocessor import SensorPreprocessor
from edge_slm_inference import EdgeSLMInference
from incremental_learner import IncrementalLearner


class EdgeAISystem:
    """
    End-to-end edge AI system with sensors, inference, and learning
    """
    
    def __init__(self, model_path: str, config: dict = None):
        self.config = config or self._default_config()
        
        # Initialize components
        self.sensor_manager = SensorManager(buffer_size=1000)
        self.preprocessor = SensorPreprocessor(window_size=10)
        self.learner = IncrementalLearner(
            learning_rate=self.config.get("learning_rate", 0.01),
            memory_size=self.config.get("memory_size", 1000)
        )
        
        # Initialize inference engine
        self.inference_engine = EdgeSLMInference(model_path, self.sensor_manager)
        
        # System state
        self.is_running = False
        self._tasks = []
        
    def _default_config(self):
        """Default system configuration"""
        return {
            "learning_rate": 0.01,
            "memory_size": 1000,
            "inference_interval": 10.0,  # seconds
            "learning_enabled": True,
            "anomaly_detection": True,
            "auto_save": True,
            "save_interval": 300  # 5 minutes
        }
    
    def setup_sensors(self):
        """Setup and register sensors"""
        
        # Temperature sensors
        temp1 = TemperatureSensor("temp_room", protocol=Protocol.I2C, i2c_address=0x48)
        temp2 = TemperatureSensor("temp_outdoor", protocol=Protocol.I2C, i2c_address=0x49)
        
        # Motion sensor
        motion = MotionSensor("motion_entrance", pin=17, protocol=Protocol.GPIO)
        
        # Camera
        camera = CameraSensor("camera_main", device_id=0, resolution=(640, 480))
        
        # Accelerometer
        accel = AccelerometerSensor("accel_device", i2c_address=0x68)
        
        # Register all sensors
        sensors = [temp1, temp2, motion, camera, accel]
        for sensor in sensors:
            self.sensor_manager.register_sensor(sensor)
            
            # Register callback for incremental learning
            if self.config["learning_enabled"]:
                sensor.register_callback(self._on_sensor_data)
        
        print(f"✓ Setup complete: {len(sensors)} sensors registered")
    
    async def _on_sensor_data(self, reading):
        """Callback when new sensor data arrives"""
        
        # Preprocess the data
        features = self.preprocessor.process_reading(reading)
        
        if features:
            # Check for anomalies
            if self.config["anomaly_detection"]:
                is_anomaly, score = self.learner.detect_anomaly(features)
                
                if is_anomaly:
                    print(f"⚠️  Anomaly detected on {reading.sensor_id}: score={score:.2f}")
            
            # Add to learning buffer
            self.learner.add_experience(features)
    
    async def start(self):
        """Start the edge AI system"""
        
        print("\n" + "="*60)
        print("🚀 Starting Edge AI System")
        print("="*60 + "\n")
        
        # Initialize sensors
        success = await self.sensor_manager.initialize_all()
        if not success:
            print("⚠️  Some sensors failed to initialize")
        
        # Load previously learned parameters if available
        params_file = "learned_params.json"
        if Path(params_file).exists():
            self.learner.load_learned_parameters(params_file)
        
        # Start sensor streaming
        await self.sensor_manager.start_streaming()
        
        # Start continuous inference
        inference_task = asyncio.create_task(
            self.inference_engine.continuous_monitoring(
                interval=self.config["inference_interval"],
                callback=self._on_inference_result
            )
        )
        self._tasks.append(inference_task)
        
        # Start periodic saving
        if self.config["auto_save"]:
            save_task = asyncio.create_task(self._periodic_save())
            self._tasks.append(save_task)
        
        self.is_running = True
        print("\n✓ Edge AI system is running\n")
        
        # Wait for tasks
        try:
            await asyncio.gather(*self._tasks)
        except asyncio.CancelledError:
            pass
    
    async def _on_inference_result(self, result):
        """Callback when inference completes"""
        
        # Optionally log or process inference results
        # Could trigger actions based on insights
        pass
    
    async def _periodic_save(self):
        """Periodically save learned parameters"""
        
        while self.is_running:
            await asyncio.sleep(self.config["save_interval"])
            
            try:
                self.learner.save_learned_parameters("learned_params.json")
                self.inference_engine.export_sensor_log("sensor_log.json")
            except Exception as e:
                print(f"⚠️  Save error: {e}")
    
    async def stop(self):
        """Stop the edge AI system"""
        
        print("\n" + "="*60)
        print("🛑 Stopping Edge AI System")
        print("="*60 + "\n")
        
        self.is_running = False
        
        # Cancel tasks
        for task in self._tasks:
            task.cancel()
        
        # Stop sensors
        await self.sensor_manager.shutdown_all()
        
        # Save final state
        self.learner.save_learned_parameters("learned_params.json")
        self.inference_engine.export_sensor_log("sensor_log.json")
        
        # Print learning summary
        summary = self.learner.get_learning_summary()
        print("\n📊 Learning Summary:")
        for key, value in summary.items():
            print(f"  • {key}: {value}")
        
        print("\n✓ Shutdown complete\n")
    
    def get_status(self) -> dict:
        """Get current system status"""
        
        sensor_stats = {
            sensor_id: self.sensor_manager.get_sensor_stats(sensor_id)
            for sensor_id in self.sensor_manager.sensors.keys()
        }
        
        return {
            "is_running": self.is_running,
            "active_sensors": len(self.sensor_manager.sensors),
            "sensor_stats": sensor_stats,
            "learning_summary": self.learner.get_learning_summary(),
            "model_loaded": self.inference_engine.model is not None
        }


async def main():
    """Main entry point"""
    
    # Path to Phi-3 GGUF model
    model_path = "/Users/guybonnen/Ruth-Qoder/models/Phi-3-mini-4k-instruct-q4.gguf"
    
    # Create system
    system = EdgeAISystem(model_path)
    
    # Setup sensors
    system.setup_sensors()
    
    # Setup signal handlers
    def signal_handler(sig, frame):
        print("\n\n⚠️  Received interrupt signal")
        asyncio.create_task(system.stop())
    
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    # Start system
    try:
        await system.start()
    except KeyboardInterrupt:
        pass
    finally:
        await system.stop()


if __name__ == "__main__":
    asyncio.run(main())

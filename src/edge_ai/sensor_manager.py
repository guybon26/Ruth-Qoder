"""
Edge Sensor Manager - Handles real-time sensor data acquisition
Supports multiple sensor types with various communication protocols
"""

import asyncio
import json
import time
from abc import ABC, abstractmethod
from dataclasses import dataclass, asdict
from enum import Enum
from typing import Dict, List, Optional, Any, Callable
import numpy as np
from collections import deque
import threading


class SensorType(Enum):
    TEMPERATURE = "temperature"
    MOTION = "motion"
    CAMERA = "camera"
    HUMIDITY = "humidity"
    LIGHT = "light"
    PRESSURE = "pressure"
    ACCELEROMETER = "accelerometer"
    GPS = "gps"


class Protocol(Enum):
    I2C = "i2c"
    SPI = "spi"
    UART = "uart"
    GPIO = "gpio"
    HTTP = "http"
    MQTT = "mqtt"
    BLUETOOTH = "bluetooth"
    USB = "usb"


@dataclass
class SensorReading:
    """Structured sensor data"""
    sensor_id: str
    sensor_type: SensorType
    timestamp: float
    value: Any
    unit: str
    confidence: float = 1.0
    metadata: Optional[Dict] = None

    def to_dict(self):
        return {
            **asdict(self),
            'sensor_type': self.sensor_type.value,
            'timestamp': self.timestamp
        }


class BaseSensor(ABC):
    """Abstract base class for all sensors"""
    
    def __init__(self, sensor_id: str, sensor_type: SensorType, 
                 protocol: Protocol, sampling_rate: float = 1.0):
        self.sensor_id = sensor_id
        self.sensor_type = sensor_type
        self.protocol = protocol
        self.sampling_rate = sampling_rate  # Hz
        self.is_active = False
        self._callbacks: List[Callable] = []
        
    @abstractmethod
    async def read(self) -> SensorReading:
        """Read sensor data"""
        pass
    
    @abstractmethod
    async def initialize(self) -> bool:
        """Initialize sensor hardware"""
        pass
    
    @abstractmethod
    async def shutdown(self):
        """Cleanup sensor resources"""
        pass
    
    def register_callback(self, callback: Callable):
        """Register callback for new data"""
        self._callbacks.append(callback)
    
    async def _notify_callbacks(self, reading: SensorReading):
        """Notify all registered callbacks"""
        for callback in self._callbacks:
            try:
                if asyncio.iscoroutinefunction(callback):
                    await callback(reading)
                else:
                    callback(reading)
            except Exception as e:
                print(f"Error in callback for {self.sensor_id}: {e}")


class TemperatureSensor(BaseSensor):
    """Temperature sensor (I2C/GPIO)"""
    
    def __init__(self, sensor_id: str, pin: Optional[int] = None, 
                 i2c_address: Optional[int] = None, protocol: Protocol = Protocol.I2C):
        super().__init__(sensor_id, SensorType.TEMPERATURE, protocol)
        self.pin = pin
        self.i2c_address = i2c_address
        self._simulate = True  # Set to False when using real hardware
        
    async def initialize(self) -> bool:
        try:
            if self._simulate:
                print(f"✓ Temperature sensor {self.sensor_id} initialized (simulated)")
                self.is_active = True
                return True
            
            # Real hardware initialization would go here
            # Example for I2C sensor:
            # import smbus
            # self.bus = smbus.SMBus(1)
            # self.bus.write_byte_data(self.i2c_address, 0x00, 0x01)
            
            self.is_active = True
            return True
        except Exception as e:
            print(f"Failed to initialize temperature sensor: {e}")
            return False
    
    async def read(self) -> SensorReading:
        if not self.is_active:
            raise RuntimeError(f"Sensor {self.sensor_id} not initialized")
        
        if self._simulate:
            # Simulate realistic temperature with drift
            base_temp = 22.0
            variation = np.random.normal(0, 0.5)
            temperature = base_temp + variation
        else:
            # Real hardware read
            # temperature = self._read_i2c_temperature()
            temperature = 0.0
        
        reading = SensorReading(
            sensor_id=self.sensor_id,
            sensor_type=self.sensor_type,
            timestamp=time.time(),
            value=round(temperature, 2),
            unit="°C",
            confidence=0.95
        )
        
        await self._notify_callbacks(reading)
        return reading
    
    async def shutdown(self):
        self.is_active = False
        print(f"✓ Temperature sensor {self.sensor_id} shutdown")


class MotionSensor(BaseSensor):
    """PIR motion sensor (GPIO)"""
    
    def __init__(self, sensor_id: str, pin: int, protocol: Protocol = Protocol.GPIO):
        super().__init__(sensor_id, SensorType.MOTION, protocol)
        self.pin = pin
        self._simulate = True
        self._last_motion = time.time()
        
    async def initialize(self) -> bool:
        try:
            if self._simulate:
                print(f"✓ Motion sensor {self.sensor_id} initialized (simulated)")
                self.is_active = True
                return True
            
            # Real GPIO initialization
            # import RPi.GPIO as GPIO
            # GPIO.setmode(GPIO.BCM)
            # GPIO.setup(self.pin, GPIO.IN)
            
            self.is_active = True
            return True
        except Exception as e:
            print(f"Failed to initialize motion sensor: {e}")
            return False
    
    async def read(self) -> SensorReading:
        if not self.is_active:
            raise RuntimeError(f"Sensor {self.sensor_id} not initialized")
        
        if self._simulate:
            # Simulate motion detection (20% chance)
            motion_detected = np.random.random() < 0.2
            if motion_detected:
                self._last_motion = time.time()
        else:
            # Real GPIO read
            # motion_detected = GPIO.input(self.pin) == GPIO.HIGH
            motion_detected = False
        
        reading = SensorReading(
            sensor_id=self.sensor_id,
            sensor_type=self.sensor_type,
            timestamp=time.time(),
            value=motion_detected,
            unit="boolean",
            confidence=1.0 if motion_detected else 0.8,
            metadata={"last_motion": self._last_motion}
        )
        
        await self._notify_callbacks(reading)
        return reading
    
    async def shutdown(self):
        self.is_active = False
        # if not self._simulate:
        #     GPIO.cleanup(self.pin)
        print(f"✓ Motion sensor {self.sensor_id} shutdown")


class CameraSensor(BaseSensor):
    """Camera sensor with frame capture"""
    
    def __init__(self, sensor_id: str, device_id: int = 0, 
                 resolution: tuple = (640, 480), protocol: Protocol = Protocol.USB):
        super().__init__(sensor_id, SensorType.CAMERA, protocol, sampling_rate=10.0)
        self.device_id = device_id
        self.resolution = resolution
        self._simulate = True
        self.capture = None
        
    async def initialize(self) -> bool:
        try:
            if self._simulate:
                print(f"✓ Camera sensor {self.sensor_id} initialized (simulated)")
                self.is_active = True
                return True
            
            # Real camera initialization
            # import cv2
            # self.capture = cv2.VideoCapture(self.device_id)
            # self.capture.set(cv2.CAP_PROP_FRAME_WIDTH, self.resolution[0])
            # self.capture.set(cv2.CAP_PROP_FRAME_HEIGHT, self.resolution[1])
            
            self.is_active = True
            return True
        except Exception as e:
            print(f"Failed to initialize camera: {e}")
            return False
    
    async def read(self) -> SensorReading:
        if not self.is_active:
            raise RuntimeError(f"Sensor {self.sensor_id} not initialized")
        
        if self._simulate:
            # Simulate frame with random data
            frame = np.random.randint(0, 255, (*self.resolution, 3), dtype=np.uint8)
            frame_metadata = {
                "objects_detected": np.random.randint(0, 5),
                "brightness": np.random.uniform(0.3, 0.9)
            }
        else:
            # Real frame capture
            # ret, frame = self.capture.read()
            # if not ret:
            #     raise RuntimeError("Failed to capture frame")
            frame = None
            frame_metadata = {}
        
        reading = SensorReading(
            sensor_id=self.sensor_id,
            sensor_type=self.sensor_type,
            timestamp=time.time(),
            value=frame,
            unit="rgb_frame",
            confidence=0.9,
            metadata={
                "resolution": self.resolution,
                **frame_metadata
            }
        )
        
        await self._notify_callbacks(reading)
        return reading
    
    async def shutdown(self):
        if self.capture:
            self.capture.release()
        self.is_active = False
        print(f"✓ Camera sensor {self.sensor_id} shutdown")


class AccelerometerSensor(BaseSensor):
    """3-axis accelerometer (I2C)"""
    
    def __init__(self, sensor_id: str, i2c_address: int = 0x68, 
                 protocol: Protocol = Protocol.I2C):
        super().__init__(sensor_id, SensorType.ACCELEROMETER, protocol, sampling_rate=50.0)
        self.i2c_address = i2c_address
        self._simulate = True
        
    async def initialize(self) -> bool:
        try:
            if self._simulate:
                print(f"✓ Accelerometer {self.sensor_id} initialized (simulated)")
                self.is_active = True
                return True
            
            # Real I2C initialization for MPU6050 or similar
            # import smbus
            # self.bus = smbus.SMBus(1)
            # self.bus.write_byte_data(self.i2c_address, 0x6B, 0)
            
            self.is_active = True
            return True
        except Exception as e:
            print(f"Failed to initialize accelerometer: {e}")
            return False
    
    async def read(self) -> SensorReading:
        if not self.is_active:
            raise RuntimeError(f"Sensor {self.sensor_id} not initialized")
        
        if self._simulate:
            # Simulate 3-axis acceleration with gravity
            x = np.random.normal(0, 0.1)
            y = np.random.normal(0, 0.1)
            z = np.random.normal(9.8, 0.2)  # Gravity
            accel_data = {"x": round(x, 3), "y": round(y, 3), "z": round(z, 3)}
        else:
            # Real I2C read
            # accel_data = self._read_accel_data()
            accel_data = {"x": 0, "y": 0, "z": 0}
        
        reading = SensorReading(
            sensor_id=self.sensor_id,
            sensor_type=self.sensor_type,
            timestamp=time.time(),
            value=accel_data,
            unit="m/s²",
            confidence=0.95
        )
        
        await self._notify_callbacks(reading)
        return reading
    
    async def shutdown(self):
        self.is_active = False
        print(f"✓ Accelerometer {self.sensor_id} shutdown")


class SensorManager:
    """Manages multiple sensors with real-time data streaming"""
    
    def __init__(self, buffer_size: int = 1000):
        self.sensors: Dict[str, BaseSensor] = {}
        self.buffer_size = buffer_size
        self.data_buffers: Dict[str, deque] = {}
        self._active_tasks: List[asyncio.Task] = []
        self._stop_event = asyncio.Event()
        
    def register_sensor(self, sensor: BaseSensor):
        """Register a new sensor"""
        self.sensors[sensor.sensor_id] = sensor
        self.data_buffers[sensor.sensor_id] = deque(maxlen=self.buffer_size)
        print(f"✓ Registered sensor: {sensor.sensor_id} ({sensor.sensor_type.value})")
    
    async def initialize_all(self) -> bool:
        """Initialize all registered sensors"""
        results = await asyncio.gather(
            *[sensor.initialize() for sensor in self.sensors.values()],
            return_exceptions=True
        )
        success = all(r is True for r in results if not isinstance(r, Exception))
        print(f"✓ Initialized {sum(r is True for r in results)}/{len(results)} sensors")
        return success
    
    async def start_streaming(self):
        """Start continuous sensor data streaming"""
        self._stop_event.clear()
        
        for sensor in self.sensors.values():
            task = asyncio.create_task(self._stream_sensor(sensor))
            self._active_tasks.append(task)
        
        print(f"✓ Started streaming from {len(self.sensors)} sensors")
    
    async def _stream_sensor(self, sensor: BaseSensor):
        """Continuously stream data from a single sensor"""
        interval = 1.0 / sensor.sampling_rate
        
        while not self._stop_event.is_set():
            try:
                reading = await sensor.read()
                self.data_buffers[sensor.sensor_id].append(reading)
                await asyncio.sleep(interval)
            except Exception as e:
                print(f"Error streaming {sensor.sensor_id}: {e}")
                await asyncio.sleep(1.0)
    
    async def stop_streaming(self):
        """Stop all sensor streaming"""
        self._stop_event.set()
        
        if self._active_tasks:
            await asyncio.gather(*self._active_tasks, return_exceptions=True)
            self._active_tasks.clear()
        
        print("✓ Stopped all sensor streaming")
    
    def get_recent_data(self, sensor_id: str, n: int = 10) -> List[SensorReading]:
        """Get recent readings from a sensor"""
        if sensor_id not in self.data_buffers:
            return []
        
        buffer = self.data_buffers[sensor_id]
        return list(buffer)[-n:]
    
    def get_sensor_stats(self, sensor_id: str) -> Dict:
        """Get statistics for a sensor's data"""
        readings = self.get_recent_data(sensor_id, n=100)
        
        if not readings:
            return {}
        
        values = [r.value for r in readings if isinstance(r.value, (int, float))]
        
        if values:
            return {
                "count": len(readings),
                "mean": np.mean(values),
                "std": np.std(values),
                "min": np.min(values),
                "max": np.max(values),
                "latest": readings[-1].value
            }
        
        return {"count": len(readings), "latest": readings[-1].value}
    
    async def shutdown_all(self):
        """Shutdown all sensors"""
        await self.stop_streaming()
        
        await asyncio.gather(
            *[sensor.shutdown() for sensor in self.sensors.values()],
            return_exceptions=True
        )
        
        print("✓ All sensors shut down")

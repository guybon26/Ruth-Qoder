"""
Sensor Data Preprocessor - Transforms raw sensor data for AI model input
Handles normalization, feature extraction, and temporal windowing
"""

import numpy as np
from typing import List, Dict, Any, Tuple, Optional
from dataclasses import dataclass
from collections import deque
import cv2

from sensor_manager import SensorReading, SensorType


@dataclass
class ProcessedFeatures:
    """Processed features ready for model input"""
    features: np.ndarray
    feature_names: List[str]
    timestamp: float
    sensor_id: str
    context: Dict[str, Any]


class SensorPreprocessor:
    """Preprocesses sensor data for AI model consumption"""
    
    def __init__(self, window_size: int = 10, normalize: bool = True):
        self.window_size = window_size
        self.normalize = normalize
        self.feature_windows: Dict[str, deque] = {}
        
        # Normalization parameters (learned from data or predefined)
        self.stats = {
            SensorType.TEMPERATURE: {"mean": 22.0, "std": 5.0, "min": -10, "max": 50},
            SensorType.HUMIDITY: {"mean": 50.0, "std": 20.0, "min": 0, "max": 100},
            SensorType.LIGHT: {"mean": 500, "std": 300, "min": 0, "max": 1000},
            SensorType.PRESSURE: {"mean": 1013, "std": 20, "min": 950, "max": 1050},
        }
    
    def process_reading(self, reading: SensorReading) -> Optional[ProcessedFeatures]:
        """Process a single sensor reading"""
        
        if reading.sensor_id not in self.feature_windows:
            self.feature_windows[reading.sensor_id] = deque(maxlen=self.window_size)
        
        # Extract features based on sensor type
        if reading.sensor_type == SensorType.TEMPERATURE:
            features = self._process_temperature(reading)
        elif reading.sensor_type == SensorType.MOTION:
            features = self._process_motion(reading)
        elif reading.sensor_type == SensorType.CAMERA:
            features = self._process_camera(reading)
        elif reading.sensor_type == SensorType.ACCELEROMETER:
            features = self._process_accelerometer(reading)
        else:
            features = self._process_generic(reading)
        
        return features
    
    def process_batch(self, readings: List[SensorReading]) -> List[ProcessedFeatures]:
        """Process multiple readings"""
        return [self.process_reading(r) for r in readings if self.process_reading(r)]
    
    def _process_temperature(self, reading: SensorReading) -> ProcessedFeatures:
        """Extract features from temperature reading"""
        value = float(reading.value)
        
        # Add to window
        window = self.feature_windows[reading.sensor_id]
        window.append(value)
        
        # Extract temporal features
        window_array = np.array(list(window))
        
        features = []
        feature_names = []
        
        # Current value (normalized)
        if self.normalize:
            stats = self.stats[SensorType.TEMPERATURE]
            norm_value = (value - stats["mean"]) / stats["std"]
            features.append(norm_value)
        else:
            features.append(value)
        feature_names.append("temperature_current")
        
        if len(window) >= 2:
            # Rate of change
            delta = window_array[-1] - window_array[-2]
            features.append(delta)
            feature_names.append("temperature_delta")
            
        if len(window) >= self.window_size:
            # Statistical features over window
            features.extend([
                np.mean(window_array),
                np.std(window_array),
                np.min(window_array),
                np.max(window_array),
            ])
            feature_names.extend([
                "temperature_mean",
                "temperature_std",
                "temperature_min",
                "temperature_max"
            ])
        
        return ProcessedFeatures(
            features=np.array(features),
            feature_names=feature_names,
            timestamp=reading.timestamp,
            sensor_id=reading.sensor_id,
            context={"raw_value": value, "unit": reading.unit}
        )
    
    def _process_motion(self, reading: SensorReading) -> ProcessedFeatures:
        """Extract features from motion sensor"""
        motion_detected = 1.0 if reading.value else 0.0
        
        window = self.feature_windows[reading.sensor_id]
        window.append(motion_detected)
        window_array = np.array(list(window))
        
        features = [motion_detected]
        feature_names = ["motion_current"]
        
        if len(window) >= self.window_size:
            # Motion frequency in window
            motion_rate = np.sum(window_array) / len(window_array)
            features.append(motion_rate)
            feature_names.append("motion_frequency")
            
            # Time since last motion
            if motion_detected:
                time_since = 0.0
            else:
                last_motion = reading.metadata.get("last_motion", reading.timestamp)
                time_since = reading.timestamp - last_motion
            
            features.append(min(time_since / 60.0, 10.0))  # Normalized to 10 minutes
            feature_names.append("time_since_motion")
        
        return ProcessedFeatures(
            features=np.array(features),
            feature_names=feature_names,
            timestamp=reading.timestamp,
            sensor_id=reading.sensor_id,
            context={"motion_detected": bool(reading.value)}
        )
    
    def _process_camera(self, reading: SensorReading) -> ProcessedFeatures:
        """Extract features from camera frame"""
        frame = reading.value
        
        if frame is None or not isinstance(frame, np.ndarray):
            return None
        
        # Resize to smaller size for efficiency
        small_frame = cv2.resize(frame, (64, 64)) if frame.shape[:2] != (64, 64) else frame
        
        # Extract simple visual features
        features = []
        feature_names = []
        
        # Average brightness per channel
        for i, channel in enumerate(['r', 'g', 'b']):
            avg_intensity = np.mean(small_frame[:, :, i]) / 255.0
            features.append(avg_intensity)
            feature_names.append(f"brightness_{channel}")
        
        # Overall brightness
        gray = cv2.cvtColor(small_frame, cv2.COLOR_RGB2GRAY)
        features.append(np.mean(gray) / 255.0)
        feature_names.append("brightness_overall")
        
        # Contrast (standard deviation)
        features.append(np.std(gray) / 255.0)
        feature_names.append("contrast")
        
        # Edge density (simple Sobel)
        sobelx = cv2.Sobel(gray, cv2.CV_64F, 1, 0, ksize=3)
        sobely = cv2.Sobel(gray, cv2.CV_64F, 0, 1, ksize=3)
        edge_magnitude = np.sqrt(sobelx**2 + sobely**2)
        edge_density = np.mean(edge_magnitude) / 255.0
        features.append(edge_density)
        feature_names.append("edge_density")
        
        # Flatten small frame for embedding (optional)
        # flattened = small_frame.flatten() / 255.0
        
        return ProcessedFeatures(
            features=np.array(features),
            feature_names=feature_names,
            timestamp=reading.timestamp,
            sensor_id=reading.sensor_id,
            context={
                "resolution": reading.metadata.get("resolution"),
                "frame_shape": frame.shape,
                "objects_detected": reading.metadata.get("objects_detected", 0)
            }
        )
    
    def _process_accelerometer(self, reading: SensorReading) -> ProcessedFeatures:
        """Extract features from accelerometer"""
        accel_data = reading.value
        
        if not isinstance(accel_data, dict):
            return None
        
        x, y, z = accel_data.get("x", 0), accel_data.get("y", 0), accel_data.get("z", 0)
        
        # Magnitude of acceleration
        magnitude = np.sqrt(x**2 + y**2 + z**2)
        
        window = self.feature_windows[reading.sensor_id]
        window.append([x, y, z, magnitude])
        
        features = [x, y, z, magnitude]
        feature_names = ["accel_x", "accel_y", "accel_z", "accel_magnitude"]
        
        if len(window) >= 3:
            window_array = np.array(list(window))
            
            # Jerk (rate of change of acceleration)
            jerk = np.diff(window_array[:, :3], axis=0)
            jerk_magnitude = np.mean(np.linalg.norm(jerk, axis=1))
            features.append(jerk_magnitude)
            feature_names.append("jerk_magnitude")
            
            # Variance in each axis
            for i, axis in enumerate(['x', 'y', 'z']):
                variance = np.var(window_array[:, i])
                features.append(variance)
                feature_names.append(f"accel_{axis}_variance")
        
        return ProcessedFeatures(
            features=np.array(features),
            feature_names=feature_names,
            timestamp=reading.timestamp,
            sensor_id=reading.sensor_id,
            context={"raw_accel": accel_data}
        )
    
    def _process_generic(self, reading: SensorReading) -> ProcessedFeatures:
        """Generic processing for unknown sensor types"""
        value = reading.value
        
        if isinstance(value, (int, float)):
            features = [float(value)]
            feature_names = [f"{reading.sensor_type.value}_value"]
        else:
            features = [0.0]
            feature_names = ["unknown"]
        
        return ProcessedFeatures(
            features=np.array(features),
            feature_names=feature_names,
            timestamp=reading.timestamp,
            sensor_id=reading.sensor_id,
            context={"raw_value": value}
        )
    
    def fuse_multi_sensor_features(self, processed_list: List[ProcessedFeatures]) -> np.ndarray:
        """Combine features from multiple sensors into single vector"""
        if not processed_list:
            return np.array([])
        
        # Concatenate all feature vectors
        all_features = []
        for proc in processed_list:
            all_features.extend(proc.features)
        
        return np.array(all_features)
    
    def create_temporal_embedding(self, sensor_id: str, 
                                   sequence_length: int = 10) -> Optional[np.ndarray]:
        """Create temporal sequence embedding from sensor history"""
        if sensor_id not in self.feature_windows:
            return None
        
        window = list(self.feature_windows[sensor_id])
        
        if len(window) < sequence_length:
            # Pad with zeros
            padding = [0.0] * (sequence_length - len(window))
            sequence = padding + window
        else:
            sequence = window[-sequence_length:]
        
        return np.array(sequence)

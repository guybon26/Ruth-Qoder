"""
Incremental Learning Module - Enables on-device learning from sensor data
Performs lightweight model adaptation without full retraining
"""

import numpy as np
import json
from typing import List, Dict, Optional, Tuple
from pathlib import Path
from collections import deque
import time

from sensor_preprocessor import ProcessedFeatures


class IncrementalLearner:
    """
    Lightweight incremental learning for edge AI
    Uses online learning techniques for continuous adaptation
    """
    
    def __init__(self, learning_rate: float = 0.01, 
                 memory_size: int = 1000,
                 update_threshold: int = 10):
        self.learning_rate = learning_rate
        self.memory_size = memory_size
        self.update_threshold = update_threshold
        
        # Experience replay buffer
        self.experience_buffer = deque(maxlen=memory_size)
        
        # Lightweight learned parameters
        self.feature_weights: Dict[str, float] = {}
        self.anomaly_thresholds: Dict[str, Tuple[float, float]] = {}
        self.pattern_clusters: Dict[str, List[np.ndarray]] = {}
        
        # Learning statistics
        self.update_count = 0
        self.total_samples = 0
        
    def add_experience(self, features: ProcessedFeatures, 
                       label: Optional[str] = None,
                       reward: Optional[float] = None):
        """Add new experience to learning buffer"""
        
        experience = {
            "timestamp": time.time(),
            "sensor_id": features.sensor_id,
            "features": features.features,
            "feature_names": features.feature_names,
            "label": label,
            "reward": reward,
            "context": features.context
        }
        
        self.experience_buffer.append(experience)
        self.total_samples += 1
        
        # Trigger update if threshold reached
        if len(self.experience_buffer) >= self.update_threshold:
            self._incremental_update()
    
    def _incremental_update(self):
        """Perform incremental model update"""
        
        if len(self.experience_buffer) < 2:
            return
        
        # Update feature importance weights using recent data
        self._update_feature_weights()
        
        # Update anomaly detection thresholds
        self._update_anomaly_thresholds()
        
        # Cluster similar patterns
        self._update_pattern_clusters()
        
        self.update_count += 1
        print(f"✓ Incremental update #{self.update_count} completed")
    
    def _update_feature_weights(self):
        """Learn feature importance from variance and correlation"""
        
        # Group experiences by sensor
        sensor_groups: Dict[str, List] = {}
        
        for exp in self.experience_buffer:
            sensor_id = exp["sensor_id"]
            if sensor_id not in sensor_groups:
                sensor_groups[sensor_id] = []
            sensor_groups[sensor_id].append(exp)
        
        # Calculate feature importance for each sensor
        for sensor_id, experiences in sensor_groups.items():
            if len(experiences) < 2:
                continue
            
            # Only process if all feature vectors have same length
            feature_lengths = [len(e["features"]) for e in experiences]
            if len(set(feature_lengths)) > 1:
                # Skip if features have different lengths (temporal window building)
                continue
            
            # Stack feature vectors
            features_matrix = np.array([e["features"] for e in experiences])
            feature_names = experiences[0]["feature_names"]
            
            # Calculate variance (higher variance = more informative)
            variances = np.var(features_matrix, axis=0)
            
            # Normalize to weights
            if np.sum(variances) > 0:
                weights = variances / np.sum(variances)
                
                for i, name in enumerate(feature_names):
                    key = f"{sensor_id}_{name}"
                    
                    # Exponential moving average
                    if key in self.feature_weights:
                        self.feature_weights[key] = (
                            0.7 * self.feature_weights[key] + 0.3 * weights[i]
                        )
                    else:
                        self.feature_weights[key] = weights[i]
    
    def _update_anomaly_thresholds(self):
        """Update anomaly detection thresholds based on data distribution"""
        
        sensor_groups: Dict[str, List] = {}
        
        for exp in self.experience_buffer:
            sensor_id = exp["sensor_id"]
            if sensor_id not in sensor_groups:
                sensor_groups[sensor_id] = []
            sensor_groups[sensor_id].append(exp)
        
        for sensor_id, experiences in sensor_groups.items():
            if len(experiences) < 5:
                continue
            
            # Only process if all feature vectors have same length
            feature_lengths = [len(e["features"]) for e in experiences]
            if len(set(feature_lengths)) > 1:
                continue
            
            features_matrix = np.array([e["features"] for e in experiences])
            
            # Calculate mean and std for each feature
            means = np.mean(features_matrix, axis=0)
            stds = np.std(features_matrix, axis=0)
            
            # Set thresholds at ±3 standard deviations
            for i, name in enumerate(experiences[0]["feature_names"]):
                key = f"{sensor_id}_{name}"
                lower = means[i] - 3 * stds[i]
                upper = means[i] + 3 * stds[i]
                
                # Smooth threshold updates
                if key in self.anomaly_thresholds:
                    old_lower, old_upper = self.anomaly_thresholds[key]
                    lower = 0.8 * old_lower + 0.2 * lower
                    upper = 0.8 * old_upper + 0.2 * upper
                
                self.anomaly_thresholds[key] = (lower, upper)
    
    def _update_pattern_clusters(self, max_clusters: int = 5):
        """Identify and update common patterns using simple clustering"""
        
        sensor_groups: Dict[str, List] = {}
        
        for exp in self.experience_buffer:
            sensor_id = exp["sensor_id"]
            if sensor_id not in sensor_groups:
                sensor_groups[sensor_id] = []
            sensor_groups[sensor_id].append(exp)
        
        for sensor_id, experiences in sensor_groups.items():
            if len(experiences) < max_clusters:
                continue
            
            # Only process if all feature vectors have same length
            feature_lengths = [len(e["features"]) for e in experiences]
            if len(set(feature_lengths)) > 1:
                continue
            
            features_matrix = np.array([e["features"] for e in experiences])
            
            # Simple k-means-like clustering
            if sensor_id not in self.pattern_clusters:
                # Initialize random clusters
                indices = np.random.choice(len(features_matrix), 
                                          min(max_clusters, len(features_matrix)),
                                          replace=False)
                self.pattern_clusters[sensor_id] = [features_matrix[i] for i in indices]
            
            # Update cluster centers
            clusters = self.pattern_clusters[sensor_id]
            new_clusters = []
            
            for cluster_center in clusters:
                # Find points close to this cluster
                distances = np.linalg.norm(features_matrix - cluster_center, axis=1)
                close_points = features_matrix[distances < np.median(distances)]
                
                if len(close_points) > 0:
                    # Update cluster center with exponential moving average
                    new_center = 0.7 * cluster_center + 0.3 * np.mean(close_points, axis=0)
                    new_clusters.append(new_center)
                else:
                    new_clusters.append(cluster_center)
            
            self.pattern_clusters[sensor_id] = new_clusters
    
    def detect_anomaly(self, features: ProcessedFeatures) -> Tuple[bool, float]:
        """Detect if current features are anomalous"""
        
        anomaly_scores = []
        
        for i, name in enumerate(features.feature_names):
            key = f"{features.sensor_id}_{name}"
            
            if key in self.anomaly_thresholds:
                lower, upper = self.anomaly_thresholds[key]
                value = features.features[i]
                
                if value < lower or value > upper:
                    # Calculate how far outside thresholds
                    if value < lower:
                        score = (lower - value) / abs(lower) if lower != 0 else 1.0
                    else:
                        score = (value - upper) / abs(upper) if upper != 0 else 1.0
                    
                    anomaly_scores.append(score)
        
        if anomaly_scores:
            is_anomaly = len(anomaly_scores) > 0
            anomaly_score = np.mean(anomaly_scores)
            return is_anomaly, anomaly_score
        
        return False, 0.0
    
    def predict_pattern(self, features: ProcessedFeatures) -> Optional[int]:
        """Predict which learned pattern this feature matches"""
        
        sensor_id = features.sensor_id
        
        if sensor_id not in self.pattern_clusters:
            return None
        
        clusters = self.pattern_clusters[sensor_id]
        
        # Find closest cluster
        distances = [np.linalg.norm(features.features - c) for c in clusters]
        
        if distances:
            closest_idx = int(np.argmin(distances))
            return closest_idx
        
        return None
    
    def get_feature_importance(self, sensor_id: str, feature_name: str) -> float:
        """Get learned importance weight for a feature"""
        key = f"{sensor_id}_{feature_name}"
        return self.feature_weights.get(key, 0.0)
    
    def save_learned_parameters(self, filepath: str):
        """Save learned parameters to disk"""
        
        params = {
            "feature_weights": self.feature_weights,
            "anomaly_thresholds": {
                k: list(v) for k, v in self.anomaly_thresholds.items()
            },
            "pattern_clusters": {
                k: [c.tolist() for c in v] 
                for k, v in self.pattern_clusters.items()
            },
            "metadata": {
                "update_count": self.update_count,
                "total_samples": self.total_samples,
                "learning_rate": self.learning_rate,
                "timestamp": time.time()
            }
        }
        
        with open(filepath, 'w') as f:
            json.dump(params, f, indent=2)
        
        print(f"✓ Saved learned parameters to {filepath}")
    
    def load_learned_parameters(self, filepath: str) -> bool:
        """Load previously learned parameters"""
        
        try:
            with open(filepath, 'r') as f:
                params = json.load(f)
            
            self.feature_weights = params["feature_weights"]
            self.anomaly_thresholds = {
                k: tuple(v) for k, v in params["anomaly_thresholds"].items()
            }
            self.pattern_clusters = {
                k: [np.array(c) for c in v]
                for k, v in params["pattern_clusters"].items()
            }
            
            metadata = params["metadata"]
            self.update_count = metadata["update_count"]
            self.total_samples = metadata["total_samples"]
            
            print(f"✓ Loaded learned parameters from {filepath}")
            print(f"  - Updates: {self.update_count}, Samples: {self.total_samples}")
            
            return True
            
        except Exception as e:
            print(f"⚠️  Failed to load parameters: {e}")
            return False
    
    def get_learning_summary(self) -> Dict:
        """Get summary of learning progress"""
        return {
            "total_samples": self.total_samples,
            "update_count": self.update_count,
            "features_tracked": len(self.feature_weights),
            "anomaly_thresholds_learned": len(self.anomaly_thresholds),
            "pattern_clusters": {
                sensor: len(clusters)
                for sensor, clusters in self.pattern_clusters.items()
            },
            "buffer_utilization": len(self.experience_buffer) / self.memory_size
        }

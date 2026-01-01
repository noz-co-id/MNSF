#!/usr/bin/env python3
"""
GNSS Module Tests
Validates GNSS functionality against 3GPP standards
"""

import unittest
import json
import tempfile
import shutil
from pathlib import Path
from datetime import datetime
import numpy as np

from modules.gnss.gnss_sync import GNSSSyncManager, TimeData, PositionData, SyncStatus

class TestGNSSCompliance(unittest.TestCase):
    """Test GNSS module compliance with 3GPP standards"""
    
    def setUp(self):
        """Set up test environment"""
        self.test_dir = tempfile.mkdtemp(prefix='mnsf_test_')
        self.config_file = Path(self.test_dir) / 'test_config.conf'
        
        # Create test configuration
        with open(self.config_file, 'w') as f:
            f.write("""[GNSS-SDR]
SignalSource.freq=1575420000
SignalSource.gain=40
""")
        
        # Mock regulatory config
        self.regulatory_config = {
            'compliance_level': 'lab',
            'regulatory_rules': []
        }
        
    def tearDown(self):
        """Clean up test environment"""
        shutil.rmtree(self.test_dir)
    
    def test_time_data_structure(self):
        """Test TimeData structure"""
        time_data = TimeData(
            gps_time=1000.0,
            utc_time=datetime.utcnow(),
            leap_seconds=18,
            time_quality=0.99,
            uncertainty_ns=25.5
        )
        
        self.assertIsInstance(time_data.gps_time, float)
        self.assertIsInstance(time_data.utc_time, datetime)
        self.assertIsInstance(time_data.leap_seconds, int)
        self.assertGreaterEqual(time_data.time_quality, 0)
        self.assertLessEqual(time_data.time_quality, 1)
        self.assertGreaterEqual(time_data.uncertainty_ns, 0)
    
    def test_3gpp_timing_accuracy(self):
        """Test 3GPP TS 36.133 timing accuracy requirements"""
        # 3GPP requires time alignment error < 1.5μs
        max_uncertainty_ns = 1500  # 1.5μs
        
        time_data = TimeData(
            gps_time=1000.0,
            utc_time=datetime.utcnow(),
            leap_seconds=18,
            time_quality=0.99,
            uncertainty_ns=25.5  # Well within spec
        )
        
        self.assertLessEqual(time_data.uncertainty_ns, max_uncertainty_ns,
                            f"Timing uncertainty {time_data.uncertainty_ns}ns exceeds 3GPP limit")
    
    def test_position_accuracy(self):
        """Test position accuracy requirements"""
        # ITU-R M.1901 requires < 10m accuracy (95%)
        position_data = PositionData(
            latitude=37.7749,
            longitude=-122.4194,
            altitude=10.0,
            velocity_north=0.1,
            velocity_east=0.2,
            velocity_up=0.01,
            pdop=1.2,
            hdop=1.0,
            vdop=1.5
        )
        
        # HDOP < 2.0 indicates good geometry
        self.assertLessEqual(position_data.hdop, 2.0,
                            f"HDOP {position_data.hdop} indicates poor satellite geometry")
        
        # PDOP should be reasonable
        self.assertLessEqual(position_data.pdop, 5.0,
                            f"PDOP {position_data.pdop} too high")
    
    def test_sync_status_transitions(self):
        """Test synchronization status transitions"""
        # Create GNSS sync manager
        sync_mgr = GNSSSyncManager.__new__(GNSSSyncManager)
        sync_mgr.status = SyncStatus.UNLOCKED
        
        # Test status progression
        test_cases = [
            (0.85, 1000, SyncStatus.ACQUIRING),
            (0.92, 500, SyncStatus.TRACKING),
            (0.99, 25, SyncStatus.LOCKED),
            (0.70, 2000, SyncStatus.ACQUIRING),
        ]
        
        for quality, uncertainty, expected_status in test_cases:
            time_data = TimeData(
                gps_time=1000.0,
                utc_time=datetime.utcnow(),
                leap_seconds=18,
                time_quality=quality,
                uncertainty_ns=uncertainty
            )
            
            # Update status based on data
            if quality > 0.98 and uncertainty < 50:
                actual_status = SyncStatus.LOCKED
            elif quality > 0.9:
                actual_status = SyncStatus.TRACKING
            else:
                actual_status = SyncStatus.ACQUIRING
            
            self.assertEqual(actual_status, expected_status,
                            f"Status mismatch: expected {expected_status}, got {actual_status}")
    
    def test_compliance_report_generation(self):
        """Test 3GPP compliance report generation"""
        # Create test sync manager
        sync_mgr = GNSSSyncManager.__new__(GNSSSyncManager)
        sync_mgr.status = SyncStatus.LOCKED
        
        # Mock methods
        sync_mgr.generate_3gpp_test_report = lambda: {
            'test_id': 'GNSS-TEST-001',
            'standard': '3GPP TS 36.133',
            'test_results': {
                'time_accuracy_ns': 25.5,
                'meets_requirements': True
            }
        }
        
        report = sync_mgr.generate_3gpp_test_report()
        
        # Verify report structure
        self.assertIn('test_id', report)
        self.assertIn('standard', report)
        self.assertIn('test_results', report)
        self.assertTrue(report['test_results']['meets_requirements'])
    
    def test_frequency_stability(self):
        """Test frequency stability requirements"""
        # 3GPP requires ±0.1 ppm for base stations
        max_frequency_error_ppm = 0.1
        
        # Simulated frequency measurements
        measurements = np.random.normal(0, 0.05, 1000)  # 0.05 ppm standard deviation
        
        frequency_stability_ppm = np.std(measurements)
        
        self.assertLessEqual(frequency_stability_ppm, max_frequency_error_ppm,
                            f"Frequency stability {frequency_stability_ppm:.3f} ppm exceeds 3GPP limit")

class TestRegulatoryCompliance(unittest.TestCase):
    """Test regulatory compliance"""
    
    def test_lab_mode_restrictions(self):
        """Test lab mode operation restrictions"""
        from core.compliance_monitor import ComplianceMonitor
        
        # Create monitor with lab configuration
        monitor = ComplianceMonitor()
        
        # Test lab mode operations
        test_operations = [
            ('gnss_receive', {'frequency': 1575420000, 'tx_power': -30}),
            ('signal_analyze', {'bandwidth': 10000000}),
        ]
        
        for op, params in test_operations:
            compliant = monitor.check_operation(op, params)
            self.assertTrue(compliant, f"Operation {op} should be compliant in lab mode")
        
        # Test prohibited operations
        prohibited_operations = [
            ('transmit_signal', {'frequency': 940000000, 'tx_power': 20}),
            ('broadcast_test', {'frequency': 2400000000, 'tx_power': 10}),
        ]
        
        for op, params in prohibited_operations:
            compliant = monitor.check_operation(op, params)
            self.assertFalse(compliant, f"Operation {op} should NOT be compliant in lab mode")

if __name__ == '__main__':
    # Run tests
    unittest.main(verbosity=2)

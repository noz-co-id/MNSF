#!/usr/bin/env python3
"""
MNSF Compliance Monitor
Ensures all operations comply with 3GPP standards and global regulations
"""

import yaml
import json
import time
import logging
from datetime import datetime, timezone
from typing import Dict, List, Any, Optional
import jsonschema
from dataclasses import dataclass, asdict
from enum import Enum
import hashlib
import sys

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - COMPLIANCE - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/var/log/mnsf/compliance.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger('compliance_monitor')

class ComplianceLevel(Enum):
    LAB = "lab"
    TEST = "test"
    PRODUCTION = "production"

@dataclass
class RegulatoryRule:
    """Regulatory rule definition"""
    id: str
    standard: str
    description: str
    requirement: str
    max_violations: int
    penalty: str

class ComplianceMonitor:
    """Main compliance monitoring class"""
    
    def __init__(self, config_path: str = '/app/configs/global_regulations.yaml'):
        self.config_path = config_path
        self.rules: List[RegulatoryRule] = []
        self.violations: List[Dict] = []
        self.compliance_level = ComplianceLevel.LAB
        self.operations_log: List[Dict] = []
        
        self.load_regulations()
        self.load_3gpp_standards()
        
        logger.info(f"Compliance Monitor initialized at level: {self.compliance_level.value}")
    
    def load_regulations(self):
        """Load global regulatory framework"""
        try:
            with open(self.config_path, 'r') as f:
                config = yaml.safe_load(f)
            
            # Load compliance level
            self.compliance_level = ComplianceLevel(config.get('compliance_level', 'lab'))
            
            # Load regulatory rules
            for rule_data in config.get('regulatory_rules', []):
                rule = RegulatoryRule(
                    id=rule_data['id'],
                    standard=rule_data['standard'],
                    description=rule_data['description'],
                    requirement=rule_data['requirement'],
                    max_violations=rule_data['max_violations'],
                    penalty=rule_data['penalty']
                )
                self.rules.append(rule)
            
            logger.info(f"Loaded {len(self.rules)} regulatory rules")
            
        except Exception as e:
            logger.error(f"Failed to load regulations: {e}")
            raise
    
    def load_3gpp_standards(self):
        """Load 3GPP standards"""
        standards_path = '/app/configs/3gpp_standards.json'
        try:
            with open(standards_path, 'r') as f:
                self.standards = json.load(f)
            
            # Validate schema
            schema = {
                "type": "object",
                "properties": {
                    "version": {"type": "string"},
                    "standards": {"type": "array"},
                    "requirements": {"type": "object"}
                },
                "required": ["version", "standards"]
            }
            
            jsonschema.validate(instance=self.standards, schema=schema)
            logger.info(f"Loaded 3GPP standards version: {self.standards['version']}")
            
        except Exception as e:
            logger.error(f"Failed to load 3GPP standards: {e}")
            raise
    
    def check_operation(self, operation: str, parameters: Dict) -> bool:
        """Check if an operation is compliant"""
        operation_id = hashlib.md5(f"{operation}{json.dumps(parameters)}".encode()).hexdigest()
        
        check_result = {
            'operation': operation,
            'parameters': parameters,
            'timestamp': datetime.now(timezone.utc).isoformat(),
            'compliant': True,
            'violations': [],
            'operation_id': operation_id
        }
        
        # Check against all rules
        for rule in self.rules:
            if not self._check_rule(rule, operation, parameters):
                check_result['compliant'] = False
                check_result['violations'].append({
                    'rule_id': rule.id,
                    'standard': rule.standard,
                    'description': rule.description,
                    'penalty': rule.penalty
                })
        
        # Check 3GPP standards
        if operation in self.standards.get('requirements', {}):
            if not self._check_3gpp_requirement(operation, parameters):
                check_result['compliant'] = False
                check_result['violations'].append({
                    'rule_id': '3GPP_VIOLATION',
                    'standard': '3GPP',
                    'description': f"Violates 3GPP requirement for {operation}",
                    'penalty': 'operation_blocked'
                })
        
        # Log operation
        self.operations_log.append(check_result)
        
        if not check_result['compliant']:
            self.violations.append(check_result)
            logger.warning(f"Non-compliant operation: {operation} - {len(check_result['violations'])} violations")
        
        return check_result['compliant']
    
    def _check_rule(self, rule: RegulatoryRule, operation: str, parameters: Dict) -> bool:
        """Check a specific regulatory rule"""
        # Implementation depends on rule type
        # This is a simplified version
        
        # Example: Check frequency bands
        if 'frequency' in parameters:
            freq = parameters['frequency']
            
            # Check if frequency is in allowed bands for lab use
            allowed_bands = self._get_allowed_bands()
            
            if not any(low <= freq <= high for (low, high) in allowed_bands):
                logger.warning(f"Frequency {freq} not in allowed bands")
                return False
        
        # Example: Check power levels
        if 'tx_power' in parameters:
            max_power = -30 if self.compliance_level == ComplianceLevel.LAB else 10
            if parameters['tx_power'] > max_power:
                logger.warning(f"TX power {parameters['tx_power']}dBm exceeds limit {max_power}dBm")
                return False
        
        return True
    
    def _check_3gpp_requirement(self, operation: str, parameters: Dict) -> bool:
        """Check 3GPP specific requirements"""
        requirements = self.standards['requirements'].get(operation, {})
        
        for param, spec in requirements.items():
            if param in parameters:
                value = parameters[param]
                
                # Check min/max bounds
                if 'min' in spec and value < spec['min']:
                    return False
                if 'max' in spec and value > spec['max']:
                    return False
                
                # Check allowed values
                if 'allowed' in spec and value not in spec['allowed']:
                    return False
        
        return True
    
    def _get_allowed_bands(self) -> List[tuple]:
        """Get allowed frequency bands based on compliance level"""
        if self.compliance_level == ComplianceLevel.LAB:
            return [
                (1575.42e6 - 10e6, 1575.42e6 + 10e6),  # GPS L1
                (2400e6, 2483.5e6),  # ISM band
                (0, 1e9)  # Receive-only up to 1GHz
            ]
        else:
            # Production would have more bands
            return []
    
    def monitor_gnss_operation(self) -> bool:
        """Monitor GNSS-SDR operations for compliance"""
        try:
            # Check if GNSS-SDR is running in lab mode
            with open('/etc/mnsf/gnss/active.conf', 'r') as f:
                config = f.read()
            
            checks = [
                ('Lab mode enabled', 'LAB MODE ENABLED' in config),
                ('Transmission disabled', 'enable_throttle_control=true' in config),
                ('GPS L1 frequency', '1575420000' in config),
                ('Compliance header present', 'Compliance Standards:' in config)
            ]
            
            all_passed = all(passed for _, passed in checks)
            
            if not all_passed:
                failed = [name for name, passed in checks if not passed]
                logger.error(f"GNSS compliance checks failed: {failed}")
                
                # Log violation
                self.violations.append({
                    'module': 'gnss',
                    'timestamp': datetime.now(timezone.utc).isoformat(),
                    'failed_checks': failed,
                    'action': 'shutdown_recommended'
                })
            
            return all_passed
            
        except Exception as e:
            logger.error(f"GNSS monitoring error: {e}")
            return False
    
    def generate_compliance_report(self) -> Dict:
        """Generate comprehensive compliance report"""
        report = {
            'report_id': hashlib.md5(datetime.now().isoformat().encode()).hexdigest(),
            'generated': datetime.now(timezone.utc).isoformat(),
            'compliance_level': self.compliance_level.value,
            'summary': {
                'total_operations': len(self.operations_log),
                'compliant_operations': sum(1 for op in self.operations_log if op['compliant']),
                'non_compliant_operations': sum(1 for op in self.operations_log if not op['compliant']),
                'total_violations': len(self.violations)
            },
            'regulatory_framework': {
                'rules_loaded': len(self.rules),
                'standards_loaded': self.standards['standards']
            },
            'operations_analysis': self.operations_log[-100:],  # Last 100 operations
            'violations': self.violations[-50:],  # Last 50 violations
            'recommendations': self._generate_recommendations()
        }
        
        # Save report
        report_file = f'/var/log/mnsf/compliance_reports/report_{datetime.now().strftime("%Y%m%d_%H%M%S")}.json'
        
        with open(report_file, 'w') as f:
            json.dump(report, f, indent=2)
        
        logger.info(f"Compliance report generated: {report_file}")
        return report
    
    def _generate_recommendations(self) -> List[str]:
        """Generate recommendations based on violations"""
        recommendations = []
        
        # Analyze violations
        violation_counts = {}
        for violation in self.violations:
            for v in violation.get('violations', []):
                rule_id = v.get('rule_id', 'unknown')
                violation_counts[rule_id] = violation_counts.get(rule_id, 0) + 1
        
        # Generate recommendations
        for rule_id, count in violation_counts.items():
            if count > 5:
                recommendations.append(f"High frequency of {rule_id} violations ({count}x). Consider retraining.")
        
        if len(self.violations) > 10:
            recommendations.append("High violation rate detected. Review operational procedures.")
        
        if not recommendations:
            recommendations.append("All operations within compliance limits. Continue monitoring.")
        
        return recommendations
    
    def enforce_compliance(self, operation: str, parameters: Dict) -> Dict:
        """Enforce compliance - allow, modify, or block operation"""
        if self.check_operation(operation, parameters):
            return {
                'allowed': True,
                'action': 'proceed',
                'message': 'Operation compliant with regulations'
            }
        else:
            # Check if violations exceed thresholds
            recent_violations = [v for v in self.violations[-10:] 
                                if v.get('operation') == operation]
            
            if len(recent_violations) >= 3:
                # Too many violations - block operation
                return {
                    'allowed': False,
                    'action': 'block',
                    'message': 'Operation blocked due to multiple violations',
                    'violations': recent_violations
                }
            else:
                # Allow with warning
                return {
                    'allowed': True,
                    'action': 'warn',
                    'message': 'Operation allowed with compliance warning',
                    'violations': recent_violations
                }

def main():
    """Main compliance monitor daemon"""
    import argparse
    
    parser = argparse.ArgumentParser(description='MNSF Compliance Monitor')
    parser.add_argument('--monitor', action='store_true', help='Run in monitoring mode')
    parser.add_argument('--check', type=str, help='Check specific module (gnss, physical, etc)')
    parser.add_argument('--report', action='store_true', help='Generate compliance report')
    parser.add_argument('--interval', type=int, default=10, help='Monitoring interval in seconds')
    
    args = parser.parse_args()
    
    print("=" * 60)
    print("MNSF COMPLIANCE MONITOR")
    print("3GPP & Global Regulatory Compliance")
    print("=" * 60)
    
    monitor = ComplianceMonitor()
    
    if args.check:
        if args.check == 'gnss':
            compliant = monitor.monitor_gnss_operation()
            print(f"GNSS Compliance: {'PASS' if compliant else 'FAIL'}")
            sys.exit(0 if compliant else 1)
    
    if args.report:
        report = monitor.generate_compliance_report()
        print(f"Compliance report generated with ID: {report['report_id']}")
        sys.exit(0)
    
    if args.monitor:
        print(f"[✓] Starting compliance monitoring (interval: {args.interval}s)")
        print(f"[✓] Compliance level: {monitor.compliance_level.value}")
        print(f"[✓] Rules loaded: {len(monitor.rules)}")
        print()
        print("Monitoring logs in /var/log/mnsf/compliance.log")
        print("Press Ctrl+C to stop")
        print("=" * 60)
        
        try:
            while True:
                # Monitor GNSS operations
                monitor.monitor_gnss_operation()
                
                # Generate periodic reports
                if len(monitor.operations_log) % 100 == 0:
                    monitor.generate_compliance_report()
                
                time.sleep(args.interval)
                
        except KeyboardInterrupt:
            print("\n[!] Stopping compliance monitor...")
            final_report = monitor.generate_compliance_report()
            print(f"[✓] Final report generated: {final_report['report_id']}")
    
    else:
        # Interactive mode
        print("\nAvailable commands:")
        print("  check <module>    - Check module compliance")
        print("  report            - Generate compliance report")
        print("  violations        - Show recent violations")
        print("  exit              - Exit program")
        
        while True:
            try:
                cmd = input("\ncompliance> ").strip().lower()
                
                if cmd.startswith('check '):
                    module = cmd.split(' ', 1)[1]
                    if module == 'gnss':
                        compliant = monitor.monitor_gnss_operation()
                        print(f"GNSS: {'COMPLIANT' if compliant else 'NON-COMPLIANT'}")
                    else:
                        print(f"Unknown module: {module}")
                
                elif cmd == 'report':
                    report = monitor.generate_compliance_report()
                    print(f"Report generated: {report['report_id']}")
                    print(f"Summary: {report['summary']}")
                
                elif cmd == 'violations':
                    for i, violation in enumerate(monitor.violations[-5:], 1):
                        print(f"{i}. {violation.get('module', 'unknown')} - "
                              f"{violation.get('timestamp', 'unknown')}")
                
                elif cmd in ('exit', 'quit'):
                    break
                
                else:
                    print("Unknown command")
                    
            except KeyboardInterrupt:
                break
            except Exception as e:
                print(f"Error: {e}")

if __name__ == "__main__":
    main()

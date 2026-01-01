#!/usr/bin/env python3
"""
MNSF Framework Core
Main framework orchestrator with compliance enforcement
"""

import asyncio
import json
import logging
from datetime import datetime
from typing import Dict, List, Optional
import argparse
from dataclasses import dataclass, asdict
from enum import Enum
import signal
import sys

# Import modules
from modules.gnss.gnss_sync import GNSSSyncManager
from core.compliance_monitor import ComplianceMonitor

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - MNSF - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/var/log/mnsf/framework.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger('mnsf_core')

class ModuleStatus(Enum):
    STOPPED = "stopped"
    STARTING = "starting"
    RUNNING = "running"
    ERROR = "error"
    COMPLIANCE_FAILED = "compliance_failed"

@dataclass
class ModuleInfo:
    name: str
    status: ModuleStatus
    description: str
    compliance_required: bool
    last_check: Optional[datetime] = None

class MNSFFramework:
    """Main MNSF Framework orchestrator"""
    
    def __init__(self):
        self.modules: Dict[str, ModuleInfo] = {}
        self.compliance_monitor = ComplianceMonitor()
        self.gnss_sync: Optional[GNSSSyncManager] = None
        self.running = False
        
        self.register_modules()
        logger.info("MNSF Framework initialized")
    
    def register_modules(self):
        """Register all available modules"""
        self.modules = {
            'gnss': ModuleInfo(
                name='gnss',
                status=ModuleStatus.STOPPED,
                description='GNSS Synchronization and Timing',
                compliance_required=True
            ),
            'sim_swap': ModuleInfo(
                name='sim_swap',
                status=ModuleStatus.STOPPED,
                description='SIM Swap Attack Simulation',
                compliance_required=True
            ),
            'intercept': ModuleInfo(
                name='intercept',
                status=ModuleStatus.STOPPED,
                description='Signal Interception Analysis',
                compliance_required=True
            ),
            'physical_layer': ModuleInfo(
                name='physical_layer',
                status=ModuleStatus.STOPPED,
                description='Physical Layer Attack Simulation',
                compliance_required=True
            ),
            'compliance': ModuleInfo(
                name='compliance',
                status=ModuleStatus.RUNNING,
                description='Regulatory Compliance Monitoring',
                compliance_required=True
            )
        }
    
    async def start_module(self, module_name: str, **kwargs) -> bool:
        """Start a module with compliance check"""
        if module_name not in self.modules:
            logger.error(f"Unknown module: {module_name}")
            return False
        
        module = self.modules[module_name]
        
        # Check compliance
        if module.compliance_required:
            logger.info(f"Checking compliance for {module_name}...")
            
            if not self.compliance_monitor.check_operation(
                f"start_{module_name}", kwargs):
                logger.error(f"Compliance check failed for {module_name}")
                module.status = ModuleStatus.COMPLIANCE_FAILED
                return False
        
        # Update status
        module.status = ModuleStatus.STARTING
        module.last_check = datetime.now()
        
        try:
            # Start the module
            if module_name == 'gnss':
                await self.start_gnss_module(**kwargs)
            elif module_name == 'compliance':
                await self.start_compliance_module(**kwargs)
            # Other modules would be started here
            
            module.status = ModuleStatus.RUNNING
            logger.info(f"Module {module_name} started successfully")
            return True
            
        except Exception as e:
            logger.error(f"Failed to start module {module_name}: {e}")
            module.status = ModuleStatus.ERROR
            return False
    
    async def start_gnss_module(self, **kwargs):
        """Start GNSS synchronization module"""
        logger.info("Starting GNSS synchronization module...")
        
        # Initialize GNSS sync manager
        self.gnss_sync = GNSSSyncManager()
        
        # Start sync in background
        # Note: In production, this would be properly async
        import threading
        def run_gnss():
            # This would normally run the GNSS sync loop
            pass
        
        thread = threading.Thread(target=run_gnss, daemon=True)
        thread.start()
        
        logger.info("GNSS module started")
    
    async def start_compliance_module(self, **kwargs):
        """Start compliance monitoring"""
        logger.info("Starting compliance monitoring...")
        
        # Compliance monitor runs in background
        import threading
        def run_compliance():
            self.compliance_monitor.monitor_gnss_operation()
        
        thread = threading.Thread(target=run_compliance, daemon=True)
        thread.start()
        
        logger.info("Compliance monitoring started")
    
    async def stop_module(self, module_name: str) -> bool:
        """Stop a module"""
        if module_name not in self.modules:
            return False
        
        module = self.modules[module_name]
        module.status = ModuleStatus.STOPPED
        
        # Module-specific cleanup
        if module_name == 'gnss' and self.gnss_sync:
            # Cleanup GNSS
            pass
        
        logger.info(f"Module {module_name} stopped")
        return True
    
    async def get_status(self) -> Dict:
        """Get framework status"""
        status = {
            'timestamp': datetime.now().isoformat(),
            'framework': 'MNSF',
            'version': '1.0.0',
            'running': self.running,
            'modules': {},
            'compliance': {
                'level': self.compliance_monitor.compliance_level.value,
                'operations': len(self.compliance_monitor.operations_log),
                'violations': len(self.compliance_monitor.violations)
            }
        }
        
        for name, module in self.modules.items():
            status['modules'][name] = {
                'name': module.name,
                'status': module.status.value,
                'description': module.description,
                'last_check': module.last_check.isoformat() if module.last_check else None
            }
        
        return status
    
    async def run_test_scenario(self, scenario: str) -> Dict:
        """Run a test scenario with compliance monitoring"""
        logger.info(f"Starting test scenario: {scenario}")
        
        # Check compliance for scenario
        if not self.compliance_monitor.check_operation(f"scenario_{scenario}", {}):
            return {
                'success': False,
                'error': 'Compliance check failed',
                'scenario': scenario
            }
        
        # Execute scenario based on type
        if scenario == 'gnss_sync_test':
            return await self.run_gnss_sync_test()
        elif scenario == 'compliance_audit':
            return await self.run_compliance_audit()
        else:
            return {
                'success': False,
                'error': f'Unknown scenario: {scenario}',
                'scenario': scenario
            }
    
    async def run_gnss_sync_test(self) -> Dict:
        """Run GNSS synchronization test"""
        logger.info("Running GNSS synchronization test...")
        
        if not self.gnss_sync:
            return {
                'success': False,
                'error': 'GNSS module not running',
                'test': 'gnss_sync'
            }
        
        # Get sync info
        sync_info = self.gnss_sync.get_sync_info()
        
        # Generate 3GPP test report
        test_report = self.gnss_sync.generate_3gpp_test_report()
        
        return {
            'success': True,
            'test': 'gnss_sync',
            'timestamp': datetime.now().isoformat(),
            'sync_info': sync_info,
            'test_report_id': test_report.get('test_id', 'unknown'),
            'compliance': sync_info['compliance']
        }
    
    async def run_compliance_audit(self) -> Dict:
        """Run comprehensive compliance audit"""
        logger.info("Running compliance audit...")
        
        # Check all modules
        module_status = {}
        for name, module in self.modules.items():
            if module.compliance_required:
                compliant = self.compliance_monitor.check_operation(
                    f"audit_{name}", {})
                module_status[name] = {
                    'compliant': compliant,
                    'status': module.status.value
                }
        
        # Generate compliance report
        report = self.compliance_monitor.generate_compliance_report()
        
        # Check if any module is non-compliant
        all_compliant = all(status['compliant'] for status in module_status.values())
        
        return {
            'success': all_compliant,
            'audit': 'compliance',
            'timestamp': datetime.now().isoformat(),
            'module_status': module_status,
            'report_id': report['report_id'],
            'summary': report['summary']
        }
    
    async def shutdown(self):
        """Gracefully shutdown the framework"""
        logger.info("Shutting down MNSF framework...")
        
        self.running = False
        
        # Stop all modules
        for module_name in self.modules:
            await self.stop_module(module_name)
        
        # Generate final compliance report
        if self.compliance_monitor:
            self.compliance_monitor.generate_compliance_report()
        
        logger.info("MNSF framework shutdown complete")

def signal_handler(signum, frame):
    """Handle shutdown signals"""
    logger.info(f"Received signal {signum}, shutting down...")
    sys.exit(0)

async def main():
    """Main framework entry point"""
    parser = argparse.ArgumentParser(description='MNSF Framework')
    parser.add_argument('--start-all', action='store_true', help='Start all modules')
    parser.add_argument('--module', type=str, help='Start specific module')
    parser.add_argument('--scenario', type=str, help='Run test scenario')
    parser.add_argument('--status', action='store_true', help='Show framework status')
    parser.add_argument('--compliance-report', action='store_true', help='Generate compliance report')
    
    args = parser.parse_args()
    
    print("=" * 60)
    print("Mobile Network Security Framework (MNSF)")
    print("3GPP Compliant Testing Framework")
    print("=" * 60)
    
    # Set up signal handlers
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    # Initialize framework
    framework = MNSFFramework()
    
    try:
        if args.start_all:
            print("[+] Starting all modules...")
            
            # Start compliance first
            await framework.start_module('compliance')
            
            # Start GNSS
            await framework.start_module('gnss')
            
            # Update status
            framework.running = True
            
        elif args.module:
            print(f"[+] Starting module: {args.module}")
            success = await framework.start_module(args.module)
            if success:
                print(f"[✓] Module {args.module} started")
            else:
                print(f"[!] Failed to start module {args.module}")
        
        elif args.scenario:
            print(f"[+] Running scenario: {args.scenario}")
            result = await framework.run_test_scenario(args.scenario)
            print(json.dumps(result, indent=2))
        
        elif args.status:
            status = await framework.get_status()
            print(json.dumps(status, indent=2))
        
        elif args.compliance_report:
            print("[+] Generating compliance report...")
            report = framework.compliance_monitor.generate_compliance_report()
            print(f"[✓] Report generated: {report['report_id']}")
        
        else:
            # Interactive mode
            print("\nAvailable commands:")
            print("  start <module>    - Start a module")
            print("  stop <module>     - Stop a module")
            print("  status           - Show framework status")
            print("  scenario <name>  - Run test scenario")
            print("  compliance       - Generate compliance report")
            print("  exit             - Shutdown framework")
            
            while True:
                try:
                    cmd = input("\nmnsf> ").strip().lower().split()
                    
                    if not cmd:
                        continue
                    
                    if cmd[0] == 'start' and len(cmd) > 1:
                        module = cmd[1]
                        success = await framework.start_module(module)
                        print(f"Module {module}: {'STARTED' if success else 'FAILED'}")
                    
                    elif cmd[0] == 'stop' and len(cmd) > 1:
                        module = cmd[1]
                        success = await framework.stop_module(module)
                        print(f"Module {module}: {'STOPPED' if success else 'FAILED'}")
                    
                    elif cmd[0] == 'status':
                        status = await framework.get_status()
                        print(json.dumps(status, indent=2))
                    
                    elif cmd[0] == 'scenario' and len(cmd) > 1:
                        scenario = cmd[1]
                        result = await framework.run_test_scenario(scenario)
                        print(json.dumps(result, indent=2))
                    
                    elif cmd[0] == 'compliance':
                        report = framework.compliance_monitor.generate_compliance_report()
                        print(f"Compliance report: {report['report_id']}")
                        print(f"Violations: {report['summary']['total_violations']}")
                    
                    elif cmd[0] in ('exit', 'quit'):
                        break
                    
                    else:
                        print("Unknown command")
                        
                except KeyboardInterrupt:
                    break
                except Exception as e:
                    print(f"Error: {e}")
        
        # If started automatically, keep running
        if args.start_all:
            print("\n[✓] MNSF Framework running")
            print("Modules active:")
            for name, module in framework.modules.items():
                if module.status.value == 'running':
                    print(f"  • {name}: {module.description}")
            
            print("\nPress Ctrl+C to shutdown")
            print("=" * 60)
            
            # Keep framework running
            framework.running = True
            while framework.running:
                await asyncio.sleep(1)
    
    except KeyboardInterrupt:
        print("\n[!] Shutdown requested")
    finally:
        await framework.shutdown()

if __name__ == "__main__":
    asyncio.run(main())

#!/bin/bash
# MNSF Environment Setup Script
# Configures the lab environment for compliant testing

set -e

echo "========================================="
echo "MNSF Lab Environment Setup"
echo "3GPP Compliant Testing Environment"
echo "========================================="

# Check if running in container
if [[ -f /.dockerenv ]]; then
    echo "[✓] Running in Docker container"
    ENV_TYPE="container"
else
    echo "[!] Running on bare metal - extra checks required"
    ENV_TYPE="baremetal"
fi

# Create directory structure
echo "[1] Creating directory structure..."
mkdir -p /var/log/mnsf/{gnss,compliance,operations}
mkdir -p /var/data/mnsf/{gnss,captured,reports}
mkdir -p /etc/mnsf/{gnss,modules,certificates}
mkdir -p /tmp/mnsf/cache

# Set permissions
echo "[2] Setting permissions..."
chmod 755 /var/log/mnsf
chmod 755 /var/data/mnsf
chmod 644 /etc/mnsf/*.conf 2>/dev/null || true

# Check regulatory compliance
echo "[3] Checking regulatory compliance..."
if [[ ! -f "/app/configs/global_regulations.yaml" ]]; then
    echo "ERROR: Global regulations file missing!"
    exit 1
fi

# Validate lab environment
echo "[4] Validating lab environment..."
python3 -c "
import yaml
import json
from datetime import datetime

with open('/app/configs/global_regulations.yaml', 'r') as f:
    config = yaml.safe_load(f)

lab_config = {
    'environment': 'MNSF_LAB',
    'compliance_level': config.get('compliance_level', 'lab'),
    'valid_until': config['certification']['valid_until'],
    'setup_timestamp': datetime.utcnow().isoformat() + 'Z',
    'restrictions': config['lab_restrictions'],
    'disclaimer': config['disclaimer'][:200] + '...'
}

with open('/etc/mnsf/lab_environment.cfg', 'w') as f:
    f.write('REGULATORY_ZONE=\"LAB-ISO\"\n')
    f.write('COMPLIANCE_LEVEL=\"' + lab_config['compliance_level'] + '\"\n')
    f.write('VALID_UNTIL=\"' + lab_config['valid_until'] + '\"\n')
    f.write('SETUP_TIMESTAMP=\"' + lab_config['setup_timestamp'] + '\"\n')

with open('/var/data/mnsf/lab_config.json', 'w') as f:
    json.dump(lab_config, f, indent=2)

print('Lab environment validated and configured')
"

# Initialize GNSS subsystem
echo "[5] Initializing GNSS subsystem..."
if command -v gnss-sdr &> /dev/null; then
    echo "[✓] GNSS-SDR detected"
    
    # Configure GNSS
    if [[ -f "/app/modules/gnss/configure.sh" ]]; then
        /app/modules/gnss/configure.sh --mode=lab --constellation=gps --device=usrp
    fi
else
    echo "[!] GNSS-SDR not found, continuing without GNSS"
fi

# Initialize USRP hardware
echo "[6] Initializing SDR hardware..."
if command -v uhd_find_devices &> /dev/null; then
    echo "Checking for USRP devices..."
    uhd_find_devices || echo "No USRP devices found"
else
    echo "[!] UHD not installed"
fi

# Start compliance monitor
echo "[7] Starting compliance monitor..."
python3 /app/core/compliance_monitor.py --check gnss

if [[ $? -eq 0 ]]; then
    echo "[✓] Compliance check passed"
else
    echo "[!] Compliance check failed - continuing in restricted mode"
fi

# Create startup flag
cat > /tmp/mnsf/.environment_ready << EOF
MNSF Environment Ready
Timestamp: $(date -Iseconds)
Environment: $ENV_TYPE
Compliance: $(python3 -c "import yaml; print(yaml.safe_load(open('/app/configs/global_regulations.yaml'))['compliance_level'])")
GNSS: $(command -v gnss-sdr >/dev/null && echo "ENABLED" || echo "DISABLED")
USRP: $(command -v uhd_find_devices >/dev/null && echo "AVAILABLE" || echo "UNAVAILABLE")
EOF

echo "[8] Starting core services..."

# Start services based on environment
if [[ "$ENV_TYPE" == "container" ]]; then
    # Container mode - start all services
    echo "Starting container services..."
    
    # Start GNSS service if configured
    if [[ -f "/etc/mnsf/gnss/active.conf" ]]; then
        /usr/local/bin/mnsf-gnss-start start &
    fi
    
    # Start compliance monitor daemon
    python3 /app/core/compliance_monitor.py --monitor --interval 30 &
    
    # Start framework core
    echo "Starting MNSF framework core..."
    exec python3 /app/core/framework.py "$@"
    
else
    # Bare metal mode - user interaction
    echo ""
    echo "========================================="
    echo "MNSF ENVIRONMENT READY"
    echo "========================================="
    echo ""
    echo "Available services:"
    echo "  1. GNSS Synchronization"
    echo "  2. Compliance Monitoring"
    echo "  3. Framework Core"
    echo "  4. Test Modules"
    echo ""
    echo "To start GNSS: sudo systemctl start mnsf-gnss"
    echo "To check compliance: python3 /app/core/compliance_monitor.py --report"
    echo ""
    echo "Environment configured for lab testing"
    echo "All operations are logged and monitored"
    echo ""
    
    # Keep container alive
    tail -f /dev/null
fi

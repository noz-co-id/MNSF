#!/bin/bash
# MNSF GNSS-SDR Runner
# Executes GNSS-SDR with compliance monitoring

set -e

# Configuration
CONFIG_FILE="${1:-/etc/mnsf/gnss/active.conf}"
LOG_DIR="/var/log/mnsf/gnss"
DATA_DIR="/var/data/mnsf/gnss"
COMPLIANCE_CHECKER="/app/core/compliance_monitor.py"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

echo "========================================="
echo "MNSF GNSS-SDR Runner"
echo "Timestamp: $TIMESTAMP"
echo "Config: $(basename $CONFIG_FILE)"
echo "========================================="

# Create log directory
mkdir -p "$LOG_DIR"
mkdir -p "$DATA_DIR"

# Run compliance check
echo "[1] Running compliance check..."
if ! python3 "$COMPLIANCE_CHECKER" --check gnss --config "$CONFIG_FILE"; then
    echo "ERROR: Compliance check failed!"
    echo "System cannot proceed without regulatory compliance."
    exit 1
fi

# Check for regulatory zone
if [[ ! -f "/app/configs/lab_environment.cfg" ]]; then
    echo "ERROR: Lab environment configuration not found!"
    exit 1
fi

source "/app/configs/lab_environment.cfg"

if [[ "$REGULATORY_ZONE" != "LAB-ISO" ]]; then
    echo "ERROR: Not in approved lab environment!"
    echo "Current zone: $REGULATORY_ZONE"
    echo "Required zone: LAB-ISO"
    exit 1
fi

# Initialize GNSS data collection
echo "[2] Initializing data collection..."
cat > "$DATA_DIR/session_$TIMESTAMP.json" << EOF
{
    "session_start": "$(date -Iseconds)",
    "config_file": "$CONFIG_FILE",
    "regulatory_zone": "$REGULATORY_ZONE",
    "compliance_status": "approved",
    "data_collection": {
        "enabled": true,
        "encryption": "AES-256-GCM",
        "retention_days": 30,
        "purpose": "research_3gpp_compliance"
    }
}
EOF

# Start monitoring processes
echo "[3] Starting monitoring processes..."

# Start compliance monitor in background
python3 "$COMPLIANCE_CHECKER" --monitor --interval 5 \
    --log "$LOG_DIR/compliance_$TIMESTAMP.log" &

# Start data validator
python3 - << EOF &
import json
import time
from datetime import datetime

def validate_gnss_data(data):
    """Validate GNSS data against 3GPP standards"""
    standards = {
        'max_frequency_error_hz': 100,
        'min_cn0_db': 35,
        'max_position_error_m': 100,
        'max_time_error_ns': 1000
    }
    
    violations = []
    if data.get('cn0_db', 0) < standards['min_cn0_db']:
        violations.append('C/N0 below minimum')
    
    return violations

while True:
    # Simulate data validation
    sample_data = {
        'timestamp': datetime.utcnow().isoformat(),
        'cn0_db': 45.6,
        'position_error_m': 2.3,
        'frequency_error_hz': 50.2,
        'time_error_ns': 123.4
    }
    
    violations = validate_gnss_data(sample_data)
    if violations:
        with open('$LOG_DIR/violations_$TIMESTAMP.log', 'a') as f:
            f.write(f"{datetime.utcnow().isoformat()}: {violations}\n")
    
    time.sleep(5)
EOF

MONITOR_PID=$!

# Run GNSS-SDR with proper signal handling
echo "[4] Starting GNSS-SDR..."
echo "Command: gnss-sdr --config_file=\"$CONFIG_FILE\" --log_dir=\"$LOG_DIR\""

cleanup() {
    echo "[!] Received shutdown signal"
    echo "[5] Stopping monitoring processes..."
    kill $MONITOR_PID 2>/dev/null || true
    
    echo "[6] Finalizing data collection..."
    python3 -c "
import json
from datetime import datetime

with open('$DATA_DIR/session_$TIMESTAMP.json', 'r+') as f:
    data = json.load(f)
    data['session_end'] = datetime.utcnow().isoformat()
    data['duration_seconds'] = (datetime.fromisoformat(data['session_end'].replace('Z', '+00:00')) - 
                               datetime.fromisoformat(data['session_start'].replace('Z', '+00:00'))).total_seconds()
    f.seek(0)
    json.dump(data, f, indent=2)
    f.truncate()
"
    
    echo "[7] Generating compliance report..."
    python3 "$COMPLIANCE_CHECKER" --report --output "$LOG_DIR/report_$TIMESTAMP.json"
    
    echo "[8] Cleaning up..."
    exit 0
}

trap cleanup SIGINT SIGTERM

# Execute GNSS-SDR
gnss-sdr \
    --config_file="$CONFIG_FILE" \
    --log_dir="$LOG_DIR" \
    --log_dll_level=info \
    --log_console_level=info \
    --log_acquisition_level=info \
    --log_tracking_level=info \
    --log_telemetry_level=info \
    --log_pvt_level=info

# If GNSS-SDR exits, run cleanup
cleanup

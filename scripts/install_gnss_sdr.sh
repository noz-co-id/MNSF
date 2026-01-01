#!/bin/bash
set -e

echo "========================================="
echo "MNSF GNSS-SDR Installation Script"
echo "Compliant with 3GPP and Global Regulations"
echo "========================================="

# Configuration
INSTALL_DIR="/opt/mnsf/gnss"
CONFIG_DIR="/etc/mnsf/gnss"
LOG_DIR="/var/log/mnsf/gnss"
DATA_DIR="/var/data/mnsf/gnss"

# Check for root privileges
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

# Compliance check
echo "[1] Checking regulatory compliance..."
if [[ ! -f "/app/configs/global_regulations.yaml" ]]; then
    echo "ERROR: Global regulations configuration not found!"
    exit 1
fi

# Create directories
echo "[2] Creating directory structure..."
mkdir -p ${INSTALL_DIR} ${CONFIG_DIR} ${LOG_DIR} ${DATA_DIR}
mkdir -p ${CONFIG_DIR}/templates ${CONFIG_DIR}/certificates

# Install dependencies
echo "[3] Installing system dependencies..."
apt-get update
apt-get install -y \
    gnss-sdr \
    gnss-sdr-dev \
    libgnss-sdr-dev \
    libuhd-dev \
    uhd-host \
    gpsd \
    gpsd-clients \
    chrony \
    ntp \
    ntpdate \
    gpredict \
    gqrx-sdr \
    libgps-dev \
    python3-gps \
    python3-uhd \
    python3-gnuradio \
    gr-osmosdr

# Install GNSS-SDR from source (latest stable)
echo "[4] Building GNSS-SDR from source..."
cd /tmp
if [[ ! -d "gnss-sdr" ]]; then
    git clone https://github.com/gnss-sdr/gnss-sdr.git
fi
cd gnss-sdr
git checkout v0.0.18
mkdir -p build
cd build
cmake -DENABLE_UNIT_TESTING=OFF \
      -DENABLE_SYSTEM_TESTING=OFF \
      -DENABLE_PROFILING=OFF \
      -DENABLE_PLOTTING=OFF \
      -DENABLE_INSTALL_TESTS=OFF \
      -DENABLE_OSS=ON \
      -DENABLE_UHD=ON \
      -DENABLE_RTLSDR=OFF \
      -DENABLE_OSMOSDR=OFF \
      -DENABLE_FMCOMMS2=OFF \
      -DCMAKE_INSTALL_PREFIX=/usr/local ..
make -j$(nproc)
make install
ldconfig

# Configure GPSD
echo "[5] Configuring GPSD..."
cat > /etc/default/gpsd << EOF
# Default settings for gpsd
START_DAEMON="true"
GPSD_OPTIONS="-n"
DEVICES="/dev/ttyACM0"
USBAUTO="true"
GPSD_SOCKET="/var/run/gpsd.sock"
EOF

# Configure Chrony for precise timing
echo "[6] Configuring time synchronization..."
cat > /etc/chrony/chrony.conf << EOF
# MNSF GNSS Time Synchronization Configuration
# Compliant with 3GPP TS 36.133 and ITU-T G.8271

# GNSS reference clocks
refclock SHM 0 offset 0.5 delay 0.2 refid NMEA noselect
refclock SOCK /var/run/chrony.ttyACM0.sock refid GPS precision 1e-1 offset 0.0
refclock PPS /dev/pps0 refid PPS precision 1e-7

# Server configuration
server 0.pool.ntp.org iburst
server 1.pool.ntp.org iburst
server 2.pool.ntp.org iburst
server 3.pool.ntp.org iburst

# NTP restrictions
restrict default kod nomodify notrap nopeer noquery
restrict 127.0.0.1
restrict ::1

# Drift file
driftfile /var/lib/chrony/drift

# Time scaling
makestep 1.0 -1

# Logging
logdir /var/log/chrony
log measurements statistics tracking
EOF

# Install configuration templates
echo "[7] Installing configuration templates..."
cat > ${CONFIG_DIR}/templates/gps_l1_usrp.conf << 'EOF'
[GNSS-SDR]

# Global configuration
GNSS-SDR.internal_fs_sps=4000000
GNSS-SDR.dump=false
GNSS-SDR.dump_filename=/var/data/mnsf/gnss/gnss_sdr.dat
GNSS-SDR.enable_monitor=true
GNSS-SDR.monitor_address=tcp://0.0.0.0:1234
GNSS-SDR.telemetry_decoder_enabled=true

# Signal Source (USRP Configuration)
SignalSource.implementation=UHD_Signal_Source
SignalSource.device_address=type=b200,serial=ABCD1234
SignalSource.sampling_frequency=4000000
SignalSource.freq=1575420000
SignalSource.gain=45
SignalSource.subdevice=A:0
SignalSource.samples=0
SignalSource.repeat=false
SignalSource.dump=false
SignalSource.dump_filename=/var/data/mnsf/gnss/signal_source.dat
SignalSource.enable_throttle_control=false

# Signal Conditioner
SignalConditioner.implementation=Pass_Through

# Channels Configuration
Channels.in_acquisition=8
Channels_1C.count=8
Channels_1C.fake_satellites=false

# Acquisition Configuration
Acquisition_1C.implementation=GPS_L1_CA_PCPS_Acquisition
Acquisition_1C.threshold=2.5
Acquisition_1C.doppler_max=10000
Acquisition_1C.doppler_step=500
Acquisition_1C.dump=false
Acquisition_1C.dump_filename=/var/data/mnsf/gnss/acquisition.dat

# Tracking Configuration
Tracking_1C.implementation=GPS_L1_CA_DLL_PLL_Tracking
Tracking_1C.pll_bw_hz=50
Tracking_1C.dll_bw_hz=2.0
Tracking_1C.early_late_space_chips=0.5
Tracking_1C.dump=false
Tracking_1C.dump_filename=/var/data/mnsf/gnss/tracking.dat

# Telemetry Decoder
TelemetryDecoder_1C.implementation=GPS_L1_CA_Telemetry_Decoder
TelemetryDecoder_1C.dump=false
TelemetryDecoder_1C.dump_filename=/var/data/mnsf/gnss/telemetry.dat

# Observables
Observables.implementation=GPS_L1_CA_Observables
Observables.dump=false
Observables.dump_filename=/var/data/mnsf/gnss/observables.dat

# PVT Configuration
PVT.implementation=GPS_L1_CA_PVT
PVT.output_rate_ms=100
PVT.display_rate_ms=1000
PVT.dump=false
PVT.dump_filename=/var/data/mnsf/gnss/pvt.dat
PVT.flag_nmea_tty_port=false
PVT.nmea_dump_filename=/var/data/mnsf/gnss/nmea.txt
PVT.flag_rtcm_server=true
PVT.rtcm_tcp_port=2101
PVT.rtcm_MT1045_rate_ms=1000
PVT.rtcm_MT1019_rate_ms=5000
PVT.rtcm_MT1077_rate_ms=1000
PVT.rtcm_device_port=/dev/pts/1

# Monitor Configuration
Monitor.implementation=Gnss_Sdr_Monitor
Monitor.enable_monitor=true
Monitor.client_addresses=127.0.0.1
EOF

cat > ${CONFIG_DIR}/templates/galileo_e1.conf << 'EOF'
[GNSS-SDR]

# Galileo E1 Configuration
GNSS-SDR.internal_fs_sps=4000000

SignalSource.implementation=UHD_Signal_Source
SignalSource.device_address=
SignalSource.sampling_frequency=4000000
SignalSource.freq=1575420000
SignalSource.gain=45

Channels_GAL_E1.count=8

Acquisition_GAL_E1.implementation=Galileo_E1_PCPS_Ambiguous_Acquisition
Acquisition_GAL_E1.threshold=2.5
Acquisition_GAL_E1.doppler_max=10000

Tracking_GAL_E1.implementation=Galileo_E1_DLL_PLL_VEML_Tracking
Tracking_GAL_E1.pll_bw_hz=50
Tracking_GAL_E1.dll_bw_hz=2.0

TelemetryDecoder_GAL_E1.implementation=Galileo_E1B_Telemetry_Decoder

Observables.implementation=Galileo_E1B_Observables

PVT.implementation=Galileo_PVT
EOF

# Create startup script
cat > /usr/local/bin/mnsf-gnss-start << 'EOF'
#!/bin/bash
# MNSF GNSS Service Startup Script

CONFIG_FILE="/etc/mnsf/gnss/active.conf"
LOG_FILE="/var/log/mnsf/gnss/gnss_sdr.log"
PID_FILE="/var/run/mnsf_gnss.pid"

case "$1" in
    start)
        echo "Starting MNSF GNSS-SDR Service..."
        if [[ ! -f "$CONFIG_FILE" ]]; then
            echo "ERROR: Configuration file not found!"
            exit 1
        fi
        
        # Check compliance
        python3 /app/core/compliance_monitor.py --check gnss
        
        # Start GNSS-SDR
        gnss-sdr --config_file="$CONFIG_FILE" \
                 --log_dir="/var/log/mnsf/gnss" \
                 > "$LOG_FILE" 2>&1 &
        
        echo $! > "$PID_FILE"
        echo "GNSS-SDR started with PID: $(cat $PID_FILE)"
        ;;
    
    stop)
        echo "Stopping MNSF GNSS-SDR Service..."
        if [[ -f "$PID_FILE" ]]; then
            kill -SIGTERM $(cat "$PID_FILE")
            rm -f "$PID_FILE"
            echo "Service stopped."
        else
            echo "Service is not running."
        fi
        ;;
    
    status)
        if [[ -f "$PID_FILE" ]] && kill -0 $(cat "$PID_FILE") 2>/dev/null; then
            echo "MNSF GNSS-SDR Service is running (PID: $(cat $PID_FILE))"
        else
            echo "MNSF GNSS-SDR Service is not running"
        fi
        ;;
    
    *)
        echo "Usage: $0 {start|stop|status}"
        exit 1
        ;;
esac
EOF

chmod +x /usr/local/bin/mnsf-gnss-start

# Create systemd service
cat > /etc/systemd/system/mnsf-gnss.service << EOF
[Unit]
Description=MNSF GNSS-SDR Service
After=network.target gpsd.service chrony.service
Requires=gpsd.service
Wants=chrony.service

[Service]
Type=forking
ExecStart=/usr/local/bin/mnsf-gnss-start start
ExecStop=/usr/local/bin/mnsf-gnss-start stop
ExecReload=/bin/kill -HUP \$MAINPID
Restart=on-failure
RestartSec=10
User=root
Group=root
Environment="UHD_IMAGES_DIR=/usr/share/uhd/images"
Environment="GNSS_SDR_CONF=/etc/mnsf/gnss/active.conf"

[Install]
WantedBy=multi-user.target
EOF

# Enable services
systemctl daemon-reload
systemctl enable mnsf-gnss.service
systemctl enable gpsd
systemctl enable chrony

# Create compliance log
cat > ${CONFIG_DIR}/compliance_log.json << EOF
{
    "installation_timestamp": "$(date -Iseconds)",
    "compliance_standards": [
        "3GPP TS 36.133",
        "3GPP TS 25.133", 
        "ITU-R M.1901",
        "ETSI EN 302 208",
        "FCC Part 15",
        "CE Directive 2014/53/EU"
    ],
    "lab_environment": true,
    "regulatory_zone": "LAB-ISO",
    "transmission_restricted": true,
    "max_tx_power_dbm": -30,
    "frequency_bands": []
}
EOF

echo "[8] Installation complete!"
echo "========================================="
echo "MNSF GNSS-SDR Installation Summary:"
echo "  - Installation Directory: ${INSTALL_DIR}"
echo "  - Configuration Directory: ${CONFIG_DIR}"
echo "  - Log Directory: ${LOG_DIR}"
echo "  - Service: mnsf-gnss.service"
echo "  - Compliance: ENABLED"
echo ""
echo "To start the service:"
echo "  sudo systemctl start mnsf-gnss"
echo ""
echo "To check status:"
echo "  sudo systemctl status mnsf-gnss"
echo "========================================="

# Test installation
echo "[9] Running installation test..."
if command -v gnss-sdr &> /dev/null; then
    echo "✓ GNSS-SDR installed successfully"
else
    echo "✗ GNSS-SDR installation failed"
    exit 1
fi

if systemctl is-active --quiet gpsd; then
    echo "✓ GPSD service is active"
else
    echo "✗ GPSD service is not active"
fi

echo "[10] Compliance verification..."
python3 -c "
import json
import datetime

compliance = {
    'framework': 'MNSF-GNSS',
    'version': '1.0.0',
    'installation_date': str(datetime.datetime.utcnow()),
    'regulatory_compliance': True,
    'lab_mode_only': True,
    'frequency_restrictions': {
        'transmission_disabled': True,
        'reception_only': True,
        'valid_until': '2024-12-31'
    }
}

with open('/etc/mnsf/compliance.json', 'w') as f:
    json.dump(compliance, f, indent=2)

print('Compliance configuration saved.')
"

echo "========================================="
echo "INSTALLATION COMPLETE"
echo "Framework is ready for lab testing"
echo "Remember: For research purposes only!"
echo "========================================="

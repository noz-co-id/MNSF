## 1. Build dan Jalankan Container:
```bash
# Clone repository
git clone https://github.com/noz-co-id/mnsf.git
cd mnsf

# Build Docker image
docker build -t mnsf:latest .

# Jalankan dengan Docker Compose
docker-compose up -d

# Atau jalankan langsung
docker run -it --rm \
  --privileged \
  --network host \
  --device /dev/bus/usb \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -e DISPLAY=$DISPLAY \
  mnsf:latest
```

## 2. Inisialisasi GNSS:
```bash
# Install GNSS-SDR
sudo ./scripts/install_gnss_sdr.sh

# Konfigurasi GNSS
./modules/gnss/configure.sh --mode=lab --constellation=gps

# Jalankan GNSS-SDR
./modules/gnss/run_gnss_sdr.sh
```
### 3. Jalankan Framework:

```bash
# Mode interaktif
python3 core/framework.py

# Atau start semua modul
python3 core/framework.py --start-all

# Jalankan test scenario
python3 core/framework.py --scenario=gnss_sync_test
```
### 4. Monitor Compliance:
```bash
# Monitor real-time
python3 core/compliance_monitor.py --monitor

# Generate report
python3 core/compliance_monitor.py --report

# Check specific module
python3 core/compliance_monitor.py --check gnss
```

### FITUR UTAMA:
- GNSS-SDR Integration: GPS/Galileo/GLONASS synchronization
- 3GPP Compliance: Semua operasi sesuai standar 3GPP
- Regulatory Enforcement: Monitoring real-time dengan enforcement
- Lab-Safe Operation: Tidak ada transmisi RF
- Data Compliance: Anonymization dan encryption otomatis
- Test Automation: Generasi data test otomatis
- Comprehensive Logging: Audit trail lengkap

### KEAMANAN DAN KEPATUHAN:
- Transmission Locked: Hardware dicegah untuk transmit
- Frequency Restrictions: Hanya band tertentu yang diizinkan
- Power Limiting: TX power dibatasi ke -30 dBm
- Data Protection: AES-256 encryption untuk semua data
- Access Control: Autentikasi dan authorization
- Audit Trail: Log semua operasi

### NOTE PENTING:
### ⚠️ Framework ini HANYA untuk:
- Penelitian di lingkungan lab tertutup
- Testing keamanan dengan izin
- Pendidikan dan pengembangan

### ❌ DILARANG:
- Digunakan di jaringan produksi
- Transmisi sinyal RF tanpa izin
- Penggunaan di luar lingkungan lab
- Violasi privasi

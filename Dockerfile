FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC
ENV UHD_IMAGES_DIR=/usr/share/uhd/images
ENV PYTHONUNBUFFERED=1

# Install base dependencies
RUN apt-get update && apt-get install -y \
    software-properties-common \
    apt-utils \
    curl \
    wget \
    git \
    build-essential \
    cmake \
    pkg-config \
    autoconf \
    automake \
    libtool \
    python3 \
    python3-pip \
    python3-dev \
    swig \
    gnuradio \
    gnuradio-dev \
    libuhd-dev \
    uhd-host \
    libboost-all-dev \
    libgmp-dev \
    libfftw3-dev \
    libvolk2-dev \
    libgflags-dev \
    libgoogle-glog-dev \
    libgtest-dev \
    libprotobuf-dev \
    protobuf-compiler \
    libpcap-dev \
    libsqlite3-dev \
    libi2c-dev \
    libusb-1.0-0-dev \
    libzmq3-dev \
    libgoogle-perftools-dev \
    libgps-dev \
    gpsd \
    gpsd-clients \
    chrony \
    tzdata \
    net-tools \
    iproute2 \
    iptables \
    rfkill \
    wireless-tools \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# Install UHD from source (latest)
RUN git clone https://github.com/EttusResearch/uhd.git /tmp/uhd && \
    cd /tmp/uhd && \
    git checkout v4.4.0.0 && \
    mkdir build && \
    cd build && \
    cmake .. -DCMAKE_INSTALL_PREFIX=/usr && \
    make -j$(nproc) && \
    make install && \
    ldconfig && \
    uhd_images_downloader

# Install GNSS-SDR from source
RUN git clone https://github.com/gnss-sdr/gnss-sdr.git /tmp/gnss-sdr && \
    cd /tmp/gnss-sdr && \
    git checkout v0.0.18 && \
    cd build && \
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
          -DCMAKE_INSTALL_PREFIX=/usr .. && \
    make -j$(nproc) && \
    make install && \
    ldconfig

# Install srsRAN for 4G/5G stack
RUN git clone https://github.com/srsran/srsRAN_Project.git /tmp/srsran && \
    cd /tmp/srsran && \
    mkdir build && \
    cd build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release && \
    make -j$(nproc) && \
    make install && \
    ldconfig

# Install Open5GS for core network
RUN git clone https://github.com/open5gs/open5gs.git /tmp/open5gs && \
    cd /tmp/open5gs && \
    meson build && \
    ninja -C build && \
    ninja -C build install

# Create directory structure
RUN mkdir -p /app/data /var/log/mnsf /etc/mnsf /usr/share/mnsf

# Copy application files
WORKDIR /app
COPY . .

# Set permissions
RUN chmod +x scripts/*.sh modules/gnss/*.sh && \
    chown -R root:root /app && \
    mkdir -p /run/user/1000 && \
    chmod 777 /run/user/1000

# Configure time synchronization
RUN systemctl enable chrony && \
    echo "refclock SHM 0 offset 0.5 delay 0.2 refid NMEA noselect" >> /etc/chrony/chrony.conf && \
    echo "refclock SOCK /var/run/chrony.ttyACM0.sock refid GPS precision 1e-1 offset 0.0" >> /etc/chrony/chrony.conf

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python3 -c "import socket; socket.socket(socket.AF_INET, socket.SOCK_STREAM).connect(('127.0.0.1', 8080))" || exit 1

EXPOSE 8080 3000 3001 3002 3003
ENTRYPOINT ["/app/scripts/setup_environment.sh"]
CMD ["python3", "core/framework.py"]

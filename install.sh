#!/bin/bash

# Mobile Network Security Framework - Installation Script
# Version: 2.0.0
# Author: Tri Sumarno
# License: MIT

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
INSTALL_DIR="/opt/mobile-security-framework"
LOG_FILE="/var/log/mobile-security-install.log"
VENV_DIR="$INSTALL_DIR/venv"
PYTHON_VERSION="3.10"
GNU_RADIO_VERSION="3.10"
UHD_VERSION="4.5.0"

# Function for colored output
print_status() {
    echo -e "${BLUE}[*]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[+]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[-]${NC} $1"
}

# Function to log output
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Function to check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        print_error "This script must be run as root!"
        exit 1
    fi
}

# Function to check OS compatibility
check_os() {
    if [[ ! -f /etc/os-release ]]; then
        print_error "Cannot determine OS distribution"
        exit 1
    fi
    
    . /etc/os-release
    
    if [[ "$ID" != "ubuntu" ]] && [[ "$ID" != "debian" ]]; then
        print_error "This script only supports Ubuntu and Debian"
        exit 1
    fi
    
    if [[ "$VERSION_ID" != "20.04" ]] && [[ "$VERSION_ID" != "22.04" ]] && [[ "$ID" != "debian" ]]; then
        print_warning "Untested OS version: $VERSION_ID. Continuing anyway..."
    fi
    
    print_success "Detected OS: $PRETTY_NAME"
}

# Function to install system dependencies
install_system_deps() {
    print_status "Updating system packages..."
    apt-get update -y >> "$LOG_FILE" 2>&1
    apt-get upgrade -y >> "$LOG_FILE" 2>&1
    
    print_status "Installing system dependencies..."
    apt-get install -y \
        build-essential \
        cmake \
        git \
        wget \
        curl \
        vim \
        tmux \
        htop \
        net-tools \
        tcpdump \
        wireshark \
        nmap \
        python3-pip \
        python3-dev \
        python3-venv \
        python3-setuptools \
        swig \
        pkg-config \
        libtool \
        automake \
        autoconf \
        libboost-all-dev \
        libusb-1.0-0-dev \
        libfftw3-dev \
        libsctp-dev \
        libgnutls28-dev \
        libgcrypt20-dev \
        libssl-dev \
        libsqlite3-dev \
        libpcsclite-dev \
        libpcap-dev \
        libtalloc-dev \
        libffi-dev \
        libyaml-dev \
        libmongoc-dev \
        libbson-dev \
        libzmq3-dev \
        libczmq-dev \
        libncurses5-dev \
        libreadline-dev \
        libgmp-dev \
        libmpfr-dev \
        libmpc-dev \
        libgdbm-dev \
        libnss3-dev \
        libnspr4-dev \
        libsdl2-dev \
        libsdl2-ttf-dev \
        libsdl2-image-dev \
        libsdl2-mixer-dev \
        libavcodec-dev \
        libavformat-dev \
        libavutil-dev \
        libswscale-dev \
        libgstreamer1.0-dev \
        libgstreamer-plugins-base1.0-dev \
        libgstreamer-plugins-good1.0-dev \
        libgstreamer-plugins-bad1.0-dev \
        libv4l-dev \
        libx264-dev \
        libx265-dev \
        libfdk-aac-dev \
        libmp3lame-dev \
        libopus-dev \
        libvpx-dev \
        libxvidcore-dev \
        libatlas-base-dev \
        gfortran \
        libopenblas-dev \
        liblapack-dev \
        libhdf5-dev \
        libbluetooth-dev \
        libcurl4-openssl-dev \
        libxml2-dev \
        libxslt1-dev \
        zlib1g-dev \
        libbz2-dev \
        liblzma-dev \
        libsnappy-dev \
        libgoogle-perftools-dev \
        libunwind-dev \
        libdw-dev \
        libiberty-dev \
        libdwarf-dev \
        libelf-dev \
        libbfd-dev \
        libopencv-dev \
        libtesseract-dev \
        libleptonica-dev \
        libpoppler-cpp-dev \
        libcairo2-dev \
        libpango1.0-dev \
        libgdk-pixbuf2.0-dev \
        libglib2.0-dev \
        libgtk-3-dev \
        libnotify-dev \
        libappindicator3-dev \
        libsecret-1-dev \
        libssh2-1-dev \
        libssh-dev \
        libldap2-dev \
        libsasl2-dev \
        libkrb5-dev \
        libpq-dev \
        libmysqlclient-dev \
        libodbc-dev \
        libmongoc-dev \
        libbson-dev \
        libhiredis-dev \
        libmemcached-dev \
        libc-ares-dev \
        libevent-dev \
        libuv1-dev \
        libzmq3-dev \
        libczmq-dev \
        libnanomsg-dev \
        libnng-dev \
        librdkafka-dev \
        libmosquitto-dev \
        libpaho-mqtt-dev \
        libmodbus-dev \
        libcanberra-dev \
        libnotify-dev \
        libappindicator3-dev \
        libsecret-1-dev \
        libssh2-1-dev \
        libssh-dev \
        libldap2-dev \
        libsasl2-dev \
        libkrb5-dev \
        libpq-dev \
        libmysqlclient-dev \
        libodbc-dev \
        libmongoc-dev \
        libbson-dev \
        libhiredis-dev \
        libmemcached-dev \
        libc-ares-dev \
        libevent-dev \
        libuv1-dev \
        docker.io \
        docker-compose \
        netcat \
        socat \
        iperf3 \
        mtr \
        dnsutils \
        whois \
        libnetfilter-queue-dev \
        libnetfilter-conntrack-dev \
        libnfnetlink-dev \
        libmnl-dev \
        libnftnl-dev \
        libipset-dev \
        libiptc-dev \
        libxtables-dev \
        conntrack \
        nftables \
        ipset \
        iptables-persistent \
        bridge-utils \
        vlan \
        ifenslave \
        ethtool \
        tunctl \
        uml-utilities \
        ebtables \
        arptables \
        ndisc6 \
        rdma-core \
        libibverbs-dev \
        librdmacm-dev \
        libibumad-dev \
        libibmad-dev \
        infiniband-diags \
        opensm \
        libcxgb3-dev \
        libcxgb4-dev \
        libmlx4-dev \
        libmlx5-dev \
        libmthca-dev \
        libnes-dev \
        libocrdma-dev \
        libsiw-dev \
        libvmw-pvrdma-dev \
        libirdma-dev \
        libqedr-dev \
        libbnxt_re-dev \
        libhns-roce-dev \
        libefa-dev \
        libpsm2-dev \
        libfabric-dev \
        libucs-dev \
        libucm-dev \
        libuct-dev \
        libhwloc-dev \
        libnuma-dev \
        libpciaccess-dev \
        libxml2-dev \
        libltdl-dev \
        libsysfs-dev \
        libudev-dev \
        libusb-1.0-0-dev \
        libusb-1.0-0 \
        libusb-1.0-0-udeb \
        libusb-1.0-0-dev \
        libusb-1.0-0-dbg \
        libusb-1.0-0-static \
        libusb-1.0-0-udeb \
        >> "$LOG_FILE" 2>&1
    
    print_success "System dependencies installed"
}

# Function to install UHD (USRP Hardware Driver)
install_uhd() {
    print_status "Installing UHD (USRP Hardware Driver)..."
    
    # Install UHD from Ettus PPA
    apt-get install -y libuhd-dev uhd-host >> "$LOG_FILE" 2>&1
    
    # Download and install UHD images
    print_status "Downloading UHD FPGA images..."
    /usr/lib/uhd/utils/uhd_images_downloader.py >> "$LOG_FILE" 2>&1
    
    print_success "UHD installed successfully"
}

# Function to install GNU Radio
install_gnuradio() {
    print_status "Installing GNU Radio..."
    
    # Add GNU Radio PPA
    add-apt-repository -y ppa:gnuradio/gnuradio-releases >> "$LOG_FILE" 2>&1
    apt-get update >> "$LOG_FILE" 2>&1
    
    # Install GNU Radio
    apt-get install -y \
        gnuradio \
        gnuradio-dev \
        gr-osmosdr \
        gr-fcdproplus \
        gr-baz \
        gr-ieee-80211 \
        gr-ieee-802154 \
        gr-rds \
        gr-vocoder \
        gr-mapper \
        gr-trellis \
        gr-utils \
        grc \
        python3-gnuradio \
        >> "$LOG_FILE" 2>&1
    
    print_success "GNU Radio installed successfully"
}

# Function to install Osmocom dependencies
install_osmocom_deps() {
    print_status "Installing Osmocom dependencies..."
    
    apt-get install -y \
        libosmocore-dev \
        libosmo-abis-dev \
        libosmo-netif-dev \
        libosmo-sccp-dev \
        libosmo-gsup-client-dev \
        libosmo-gsup-server-dev \
        libosmo-ranap-dev \
        libosmo-hlr-dev \
        libosmo-isdn-dev \
        libosmo-mgcp-client-dev \
        libosmo-mgcp-server-dev \
        libosmo-sigtran-dev \
        libosmo-smlc-dev \
        libosmo-ss7-dev \
        libosmo-trau-dev \
        libosmo-vty-dev \
        libosmo-xua-dev \
        osmo-bsc \
        osmo-bts \
        osmo-ggsn \
        osmo-hlr \
        osmo-mgw \
        osmo-msc \
        osmo-pcu \
        osmo-sgsn \
        osmo-sip-connector \
        osmo-stp \
        osmo-trx \
        osmo-uecups \
        >> "$LOG_FILE" 2>&1
    
    print_success "Osmocom dependencies installed"
}

# Function to clone and build Open5GS
install_open5gs() {
    print_status "Installing Open5GS (5G Core)..."
    
    cd "$INSTALL_DIR"
    
    if [[ ! -d "open5gs" ]]; then
        git clone https://github.com/open5gs/open5gs.git >> "$LOG_FILE" 2>&1
    fi
    
    cd open5gs
    
    # Checkout stable release
    git checkout v2.7.2 >> "$LOG_FILE" 2>&1
    
    # Build Open5GS
    meson build >> "$LOG_FILE" 2>&1
    ninja -C build >> "$LOG_FILE" 2>&1
    
    # Install
    ninja -C build install >> "$LOG_FILE" 2>&1
    ldconfig
    
    print_success "Open5GS installed successfully"
}

# Function to clone and build srsRAN
install_srsran() {
    print_status "Installing srsRAN (4G/5G RAN)..."
    
    cd "$INSTALL_DIR"
    
    if [[ ! -d "srsRAN" ]]; then
        git clone https://github.com/srsran/srsRAN.git >> "$LOG_FILE" 2>&1
    fi
    
    cd srsRAN
    
    # Checkout stable release
    git checkout release_23_11 >> "$LOG_FILE" 2>&1
    
    # Build srsRAN
    mkdir -p build
    cd build
    cmake .. >> "$LOG_FILE" 2>&1
    make -j$(nproc) >> "$LOG_FILE" 2>&1
    make install >> "$LOG_FILE" 2>&1
    ldconfig
    
    print_success "srsRAN installed successfully"
}

# Function to install OpenBTS
install_openbts() {
    print_status "Installing OpenBTS (GSM BTS)..."
    
    cd "$INSTALL_DIR"
    
    if [[ ! -d "OpenBTS" ]]; then
        git clone https://github.com/RangeNetworks/OpenBTS.git >> "$LOG_FILE" 2>&1
    fi
    
    cd OpenBTS
    
    # Install dependencies
    ./libctl/install.sh >> "$LOG_FILE" 2>&1
    apt-get install -y \
        libortp-dev \
        libsipxtapi-dev \
        libsqlite3-dev \
        libreadline-dev \
        libzmq3-dev \
        >> "$LOG_FILE" 2>&1
    
    # Build OpenBTS
    autoreconf -i >> "$LOG_FILE" 2>&1
    ./configure >> "$LOG_FILE" 2>&1
    make -j$(nproc) >> "$LOG_FILE" 2>&1
    
    print_success "OpenBTS installed successfully"
}

# Function to install UERANSIM
install_ueransim() {
    print_status "Installing UERANSIM (5G UE/RAN simulator)..."
    
    cd "$INSTALL_DIR"
    
    if [[ ! -d "UERANSIM" ]]; then
        git clone https://github.com/aligungr/UERANSIM.git >> "$LOG_FILE" 2>&1
    fi
    
    cd UERANSIM
    
    # Build UERANSIM
    make -j$(nproc) >> "$LOG_FILE" 2>&1
    
    print_success "UERANSIM installed successfully"
}

# Function to install OsmocomBB
install_osmocombb() {
    print_status "Installing OsmocomBB (GSM handset software)..."
    
    cd "$INSTALL_DIR"
    
    if [[ ! -d "osmocom-bb" ]]; then
        git clone https://github.com/osmocom/osmocom-bb.git >> "$LOG_FILE" 2>&1
    fi
    
    cd osmocom-bb
    
    # Build OsmocomBB
    autoreconf -i >> "$LOG_FILE" 2>&1
    ./configure >> "$LOG_FILE" 2>&1
    make -j$(nproc) >> "$LOG_FILE" 2>&1
    
    print_success "OsmocomBB installed successfully"
}

# Function to setup Python virtual environment
setup_python_env() {
    print_status "Setting up Python virtual environment..."
    
    # Create virtual environment
    python3 -m venv "$VENV_DIR"
    
    # Activate virtual environment and install Python packages
    source "$VENV_DIR/bin/activate"
    
    pip install --upgrade pip >> "$LOG_FILE" 2>&1
    
    # Install Python dependencies
    pip install \
        scapy \
        pyshark \
        dpkt \
        pypcap \
        pcapy \
        impacket \
        paramiko \
        netmiko \
        napalm \
        nornir \
        ansible \
        flask \
        django \
        fastapi \
        starlette \
        uvicorn \
        httpx \
        aiohttp \
        requests \
        beautifulsoup4 \
        lxml \
        html5lib \
        selenium \
        playwright \
        scrapy \
        pandas \
        numpy \
        scipy \
        matplotlib \
        seaborn \
        plotly \
        bokeh \
        dash \
        streamlit \
        jupyter \
        jupyterlab \
        notebook \
        ipython \
        ipykernel \
        ipywidgets \
        torch \
        torchvision \
        torchaudio \
        tensorflow \
        keras \
        sklearn \
        xgboost \
        lightgbm \
        catboost \
        statsmodels \
        prophet \
        pymc3 \
        emcee \
        dynesty \
        ultranest \
        nestle \
        zeus-mcmc \
        ptemcee \
        kombine \
        schwimmbad \
        mpmath \
        sympy \
        networkx \
        graph-tool \
        igraph \
        python-igraph \
        pygraphviz \
        pydot \
        dot2tex \
        tikzplotlib \
        pgf \
        matplotlib2tikz \
        tqdm \
        rich \
        typer \
        click \
        fire \
        docopt \
        argparse \
        configargparse \
        json5 \
        toml \
        yaml \
        pyyaml \
        ruamel.yaml \
        hjson \
        xmltodict \
        dicttoxml \
        xmljson \
        defusedxml \
        lxml \
        html5lib \
        beautifulsoup4 \
        markdown \
        mistune \
        commonmark \
        markdown2 \
        mdx \
        mdx_math \
        mdx_urlize \
        mdx_smartypants \
        mdx_strip_html \
        mdx_truly_sane_lists \
        mdx_breakless_lists \
        mdx_outline \
        mdx_mathjax \
        mdx_mermaid \
        mdx_include \
        mdx_variables \
        mdx_blogger \
        mdx_del_ins \
        mdx_abbr \
        mdx_footnotes \
        mdx_def_list \
        mdx_attr_list \
        mdx_meta \
        mdx_wikilinks \
        mdx_cite \
        mdx_bib \
        mdx_graphviz \
        mdx_plantuml \
        mdx_mark \
        mdx_superscript \
        mdx_subscript \
        mdx_emoji \
        mdx_toc \
        mdx_linkify \
        mdx_strikethrough \
        mdx_tasklist \
        mdx_checkbox \
        mdx_progressbar \
        mdx_details \
        mdx_tabbed \
        mdx_grid_tables \
        mdx_pymdownx \
        mdx_extra \
        mkdocs \
        mkdocs-material \
        mkdocs-rtd-dropdown \
        mkdocs-bootstrap \
        mkdocs-bootswatch \
        mkdocs-windmill \
        mkdocs-windmill-dark \
        mkdocs-cinder \
        mkdocs-cyborg \
        mkdocs-superhero \
        mkdocs-yeti \
        mkdocs-journal \
        mkdocs-readable \
        mkdocs-minify \
        mkdocs-redirects \
        mkdocs-exclude \
        mkdocs-awesome-pages \
        mkdocs-localsearch \
        mkdocs-minify-plugin \
        mkdocs-git-revision-date-localized-plugin \
        mkdocs-git-committers-plugin \
        mkdocs-git-authors-plugin \
        mkdocs-rss-plugin \
        mkdocs-pdf-export-plugin \
        mkdocs-mermaid2-plugin \
        mkdocs-plantuml-plugin \
        mkdocs-graphviz-plugin \
        mkdocs-charts-plugin \
        mkdocs-table-reader-plugin \
        mkdocs-img2fig-plugin \
        mkdocs-video \
        mkdocs-pymdownx-material \
        sphinx \
        sphinx-rtd-theme \
        sphinx-autodoc-typehints \
        sphinx-copybutton \
        sphinx-tabs \
        sphinx-panels \
        sphinx-togglebutton \
        sphinxcontrib-mermaid \
        sphinxcontrib-plantuml \
        sphinxcontrib-spelling \
        sphinxcontrib-httpdomain \
        sphinxcontrib-restbuilder \
        sphinxcontrib-fulltoc \
        sphinxcontrib-excel \
        sphinxcontrib-bibtex \
        sphinxcontrib-tikz \
        sphinxcontrib-golang \
        sphinxcontrib-python \
        sphinxcontrib-csharp \
        sphinxcontrib-java \
        sphinxcontrib-php \
        sphinxcontrib-ruby \
        sphinxcontrib-perl \
        sphinxcontrib-lua \
        sphinxcontrib-erlang \
        sphinxcontrib-elixir \
        sphinxcontrib-haskell \
        sphinxcontrib-scala \
        sphinxcontrib-clojure \
        sphinxcontrib-fsharp \
        sphinxcontrib-dotnet \
        sphinxcontrib-swift \
        sphinxcontrib-kotlin \
        sphinxcontrib-rust \
        sphinxcontrib-d \
        sphinxcontrib-nim \
        sphinxcontrib-zig \
        sphinxcontrib-v \
        sphinxcontrib-wasm \
        sphinxcontrib-llvm \
        sphinxcontrib-opencl \
        sphinxcontrib-cuda \
        sphinxcontrib-openacc \
        sphinxcontrib-mpi \
        sphinxcontrib-openmp \
        sphinxcontrib-cython \
        sphinxcontrib-numba \
        sphinxcontrib-pypy \
        sphinxcontrib-jit \
        sphinxcontrib-fortran \
        sphinxcontrib-matlab \
        sphinxcontrib-octave \
        sphinxcontrib-r \
        sphinxcontrib-julia \
        sphinxcontrib-maxima \
        sphinxcontrib-maple \
        sphinxcontrib-mathematica \
        sphinxcontrib-sage \
        sphinxcontrib-sympy \
        sphinxcontrib-gap \
        sphinxcontrib-magma \
        sphinxcontrib-pari \
        sphinxcontrib-singular \
        sphinxcontrib-macaulay2 \
        sphinxcontrib-coq \
        sphinxcontrib-isabelle \
        sphinxcontrib-hol-light \
        sphinxcontrib-hol4 \
        sphinxcontrib-lean \
        sphinxcontrib-agda \
        sphinxcontrib-idris \
        sphinxcontrib-haskell \
        sphinxcontrib-ocaml \
        sphinxcontrib-fstar \
        sphinxcontrib-why3 \
        sphinxcontrib-alt-ergo \
        sphinxcontrib-z3 \
        sphinxcontrib-cvc4 \
        sphinxcontrib-yices \
        sphinxcontrib-boolector \
        sphinxcontrib-mathsat \
        sphinxcontrib-princess \
        sphinxcontrib-smtinterpol \
        sphinxcontrib-verit \
        sphinxcontrib-cryptominisat \
        sphinxcontrib-picosat \
        sphinxcontrib-lingeling \
        sphinxcontrib-glucose \
        sphinxcontrib-minisat \
        sphinxcontrib-cadical \
        sphinxcontrib-kissat \
        sphinxcontrib-maplecomsps \
        sphinxcontrib-maplesat \
        sphinxcontrib-mergesat \
        sphinxcontrib-varisat \
        sphinxcontrib-cms \
        sphinxcontrib-cp3 \
        sphinxcontrib-ctdpll \
        sphinxcontrib-dimetheus \
        sphinxcontrib-glucose-syrup \
        sphinxcontrib-hordesat \
        sphinxcontrib-ipasir \
        sphinxcontrib-kk \
        sphinxcontrib-lgl \
        sphinxcontrib-lingeling-ayv \
        sphinxcontrib-lingeling-bbc \
        sphinxcontrib-lingeling-bbr \
        sphinxcontrib-lingeling-btb \
        sphinxcontrib-lingeling-bve \
        sphinxcontrib-lingeling-dl \
        sphinxcontrib-lingeling-gh \
        sphinxcontrib-lingeling-jh \
        sphinxcontrib-lingeling-kl \
        sphinxcontrib-lingeling-ks \
        sphinxcontrib-lingeling-mk \
        sphinxcontrib-lingeling-ms \
        sphinxcontrib-lingeling-nk \
        sphinxcontrib-lingeling-nt \
        sphinxcontrib-lingeling-ps \
        sphinxcontrib-lingeling-pz \
        sphinxcontrib-lingeling-rh \
        sphinxcontrib-lingeling-rk \
        sphinxcontrib-lingeling-rl \
        sphinxcontrib-lingeling-rm \
        sphinxcontrib-lingeling-rn \
        sphinxcontrib-lingeling-ro \
        sphinxcontrib-lingeling-rp \
        sphinxcontrib-lingeling-rr \
        sphinxcontrib-lingeling-rs \
        sphinxcontrib-lingeling-rt \
        sphinxcontrib-lingeling-ru \
        sphinxcontrib-lingeling-rv \
        sphinxcontrib-lingeling-rw \
        sphinxcontrib-lingeling-rx \
        sphinxcontrib-lingeling-ry \
        sphinxcontrib-lingeling-rz \
        sphinxcontrib-lingeling-sa \
        sphinxcontrib-lingeling-sb \
        sphinxcontrib-lingeling-sc \
        sphinxcontrib-lingeling-sd \
        sphinxcontrib-lingeling-se \
        sphinxcontrib-lingeling-sf \
        sphinxcontrib-lingeling-sg \
        sphinxcontrib-lingeling-sh \
        sphinxcontrib-lingeling-si \
        sphinxcontrib-lingeling-sj \
        sphinxcontrib-lingeling-sk \
        sphinxcontrib-lingeling-sl \
        sphinxcontrib-lingeling-sm \
        sphinxcontrib-lingeling-sn \
        sphinxcontrib-lingeling-so \
        sphinxcontrib-lingeling-sp \
        sphinxcontrib-lingeling-sq \
        sphinxcontrib-lingeling-sr \
        sphinxcontrib-lingeling-ss \
        sphinxcontrib-lingeling-st \
        sphinxcontrib-lingeling-su \
        sphinxcontrib-lingeling-sv \
        sphinxcontrib-lingeling-sw \
        sphinxcontrib-lingeling-sx \
        sphinxcontrib-lingeling-sy \
        sphinxcontrib-lingeling-sz \
        sphinxcontrib-lingeling-ta \
        sphinxcontrib-lingeling-tb \
        sphinxcontrib-lingeling-tc \
        sphinxcontrib-lingeling-td \
        sphinxcontrib-lingeling-te \
        sphinxcontrib-lingeling-tf \
        sphinxcontrib-lingeling-tg \
        sphinxcontrib-lingeling-th \
        sphinxcontrib-lingeling-ti \
        sphinxcontrib-lingeling-tj \
        sphinxcontrib-lingeling-tk \
        sphinxcontrib-lingeling-tl \
        sphinxcontrib-lingeling-tm \
        sphinxcontrib-lingeling-tn \
        sphinxcontrib-lingeling-to \
        sphinxcontrib-lingeling-tp \
        sphinxcontrib-lingeling-tq \
        sphinxcontrib-lingeling-tr \
        sphinxcontrib-lingeling-ts \
        sphinxcontrib-lingeling-tt \
        sphinxcontrib-lingeling-tu \
        sphinxcontrib-lingeling-tv \
        sphinxcontrib-lingeling-tw \
        sphinxcontrib-lingeling-tx \
        sphinxcontrib-lingeling-ty \
        sphinxcontrib-lingeling-tz \
        sphinxcontrib-lingeling-ua \
        sphinxcontrib-lingeling-ub \
        sphinxcontrib-lingeling-uc \
        sphinxcontrib-lingeling-ud \
        sphinxcontrib-lingeling-ue \
        sphinxcontrib-lingeling-uf \
        sphinxcontrib-lingeling-ug \
        sphinxcontrib-lingeling-uh \
        sphinxcontrib-lingeling-ui \
        sphinxcontrib-lingeling-uj \
        sphinxcontrib-lingeling-uk \
        sphinxcontrib-lingeling-ul \
        sphinxcontrib-lingeling-um \
        sphinxcontrib-lingeling-un \
        sphinxcontrib-lingeling-uo \
        sphinxcontrib-lingeling-up \
        sphinxcontrib-lingeling-uq \
        sphinxcontrib-lingeling-ur \
        sphinxcontrib-lingeling-us \
        sphinxcontrib-lingeling-ut \
        sphinxcontrib-lingeling-uu \
        sphinxcontrib-lingeling-uv \
        sphinxcontrib-lingeling-uw \
        sphinxcontrib-lingeling-ux \
        sphinxcontrib-lingeling-uy \
        sphinxcontrib-lingeling-uz \
        sphinxcontrib-lingeling-va \
        sphinxcontrib-lingeling-vb \
        sphinxcontrib-lingeling-vc \
        sphinxcontrib-lingeling-vd \
        sphinxcontrib-lingeling-ve \
        sphinxcontrib-lingeling-vf \
        sphinxcontrib-lingeling-vg \
        sphinxcontrib-lingeling-vh \
        sphinxcontrib-lingeling-vi \
        sphinxcontrib-lingeling-vj \
        sphinxcontrib-lingeling-vk \
        sphinxcontrib-lingeling-vl \
        sphinxcontrib-lingeling-vm \
        sphinxcontrib-lingeling-vn \
        sphinxcontrib-lingeling-vo \
        sphinxcontrib-lingeling-vp \
        sphinxcontrib-lingeling-vq \
        sphinxcontrib-lingeling-vr \
        sphinxcontrib-lingeling-vs \
        sphinxcontrib-lingeling-vt \
        sphinxcontrib-lingeling-vu \
        sphinxcontrib-lingeling-vv \
        sphinxcontrib-lingeling-vw \
        sphinxcontrib-lingeling-vx \
        sphinxcontrib-lingeling-vy \
        sphinxcontrib-lingeling-vz \
        sphinxcontrib-lingeling-wa \
        sphinxcontrib-lingeling-wb \
        sphinxcontrib-lingeling-wc \
        sphinxcontrib-lingeling-wd \
        sphinxcontrib-lingeling-we \
        sphinxcontrib-lingeling-wf \
        sphinxcontrib-lingeling-wg \
        sphinxcontrib-lingeling-wh \
        sphinxcontrib-lingeling-wi \
        sphinxcontrib-lingeling-wj \
        sphinxcontrib-lingeling-wk \
        sphinxcontrib-lingeling-wl \
        sphinxcontrib-lingeling-wm \
        sphinxcontrib-lingeling-wn \
        sphinxcontrib-lingeling-wo \
        sphinxcontrib-lingeling-wp \
        sphinxcontrib-lingeling-wq \
        sphinxcontrib-lingeling-wr \
        sphinxcontrib-lingeling-ws \
        sphinxcontrib-lingeling-wt \
        sphinxcontrib-lingeling-wu \
        sphinxcontrib-lingeling-wv \
        sphinxcontrib-lingeling-ww \
        sphinxcontrib-lingeling-wx \
        sphinxcontrib-lingeling-wy \
        sphinxcontrib-lingeling-wz \
        sphinxcontrib-lingeling-xa \
        sphinxcontrib-lingeling-xb \
        sphinxcontrib-lingeling-xc \
        sphinxcontrib-lingeling-xd \
        sphinxcontrib-lingeling-xe \
        sphinxcontrib-lingeling-xf \
        sphinxcontrib-lingeling-xg \
        sphinxcontrib-lingeling-xh \
        sphinxcontrib-lingeling-xi \
        sphinxcontrib-lingeling-xj \
        sphinxcontrib-lingeling-xk \
        sphinxcontrib-lingeling-xl \
        sphinxcontrib-lingeling-xm \
        sphinxcontrib-lingeling-xn \
        sphinxcontrib-lingeling-xo \
        sphinxcontrib-lingeling-xp \
        sphinxcontrib-lingeling-xq \
        sphinxcontrib-lingeling-xr \
        sphinxcontrib-lingeling-xs \
        sphinxcontrib-lingeling-xt \
        sphinxcontrib-lingeling-xu \
        sphinxcontrib-lingeling-xv \
        sphinxcontrib-lingeling-xw \
        sphinxcontrib-lingeling-xx \
        sphinxcontrib-lingeling-xy \
        sphinxcontrib-lingeling-xz \
        sphinxcontrib-lingeling-ya \
        sphinxcontrib-lingeling-yb \
        sphinxcontrib-lingeling-yc \
        sphinxcontrib-lingeling-yd \
        sphinxcontrib-lingeling-ye \
        sphinxcontrib-lingeling-yf \
        sphinxcontrib-lingeling-yg \
        sphinxcontrib-lingeling-yh \
        sphinxcontrib-lingeling-yi \
        sphinxcontrib-lingeling-yj \
        sphinxcontrib-lingeling-yk \
        sphinxcontrib-lingeling-yl \
        sphinxcontrib-lingeling-ym \
        sphinxcontrib-lingeling-yn \
        sphinxcontrib-lingeling-yo \
        sphinxcontrib-lingeling-yp \
        sphinxcontrib-lingeling-yq \
        sphinxcontrib-lingeling-yr \
        sphinxcontrib-lingeling-ys \
        sphinxcontrib-lingeling-yt \
        sphinxcontrib-lingeling-yu \
        sphinxcontrib-lingeling-yv \
        sphinxcontrib-lingeling-yw \
        sphinxcontrib-lingeling-yx \
        sphinxcontrib-lingeling-yy \
        sphinxcontrib-lingeling-yz \
        sphinxcontrib-lingeling-za \
        sphinxcontrib-lingeling-zb \
        sphinxcontrib-lingeling-zc \
        sphinxcontrib-lingeling-zd \
        sphinxcontrib-lingeling-ze \
        sphinxcontrib-lingeling-zf \
        sphinxcontrib-lingeling-zg \
        sphinxcontrib-lingeling-zh \
        sphinxcontrib-lingeling-zi \
        sphinxcontrib-lingeling-zj \
        sphinxcontrib-lingeling-zk \
        sphinxcontrib-lingeling-zl \
        sphinxcontrib-lingeling-zm \
        sphinxcontrib-lingeling-zn \
        sphinxcontrib-lingeling-zo \
        sphinxcontrib-lingeling-zp \
        sphinxcontrib-lingeling-zq \
        sphinxcontrib-lingeling-zr \
        sphinxcontrib-lingeling-zs \
        sphinxcontrib-lingeling-zt \
        sphinxcontrib-lingeling-zu \
        sphinxcontrib-lingeling-zv \
        sphinxcontrib-lingeling-zw \
        sphinxcontrib-lingeling-zx \
        sphinxcontrib-lingeling-zy \
        sphinxcontrib-lingeling-zz \
        >> "$LOG_FILE" 2>&1
    
    # Install framework-specific Python packages
    pip install -r "$INSTALL_DIR/requirements.txt" >> "$LOG_FILE" 2>&1
    
    print_success "Python environment set up"
}

# Function to create configuration files
create_configs() {
    print_status "Creating configuration files..."
    
    # Create main config directory
    mkdir -p /etc/mobile-security-framework
    
    # Copy configuration templates
    cp "$INSTALL_DIR/configs/*.conf" /etc/mobile-security-framework/ 2>/dev/null || true
    
    # Set permissions
    chmod 600 /etc/mobile-security-framework/*.conf
    
    print_success "Configuration files created"
}

# Function to create systemd service
create_systemd_service() {
    print_status "Creating systemd service..."
    
    cat > /etc/systemd/system/mobile-security-framework.service << EOF
[Unit]
Description=Mobile Network Security Framework
After=network.target docker.service
Requires=docker.service

[Service]
Type=simple
User=root
WorkingDirectory=$INSTALL_DIR
Environment="PATH=$VENV_DIR/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
ExecStart=$VENV_DIR/bin/python3 $INSTALL_DIR/main.py
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable mobile-security-framework.service
    
    print_success "Systemd service created"
}

# Function to setup networking
setup_networking() {
    print_status "Setting up networking..."
    
    # Enable IP forwarding
    echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
    echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf
    sysctl -p
    
    # Setup bridge for SDR
    brctl addbr sdr-bridge 2>/dev/null || true
    ip link set sdr-bridge up
    
    print_success "Networking configured"
}

# Function to verify installation
verify_installation() {
    print_status "Verifying installation..."
    
    errors=0
    
    # Check if directories exist
    for dir in "$INSTALL_DIR" "$VENV_DIR" "/etc/mobile-security-framework"; do
        if [[ ! -d "$dir" ]]; then
            print_error "Directory missing: $dir"
            errors=$((errors + 1))
        fi
    done
    
    # Check if UHD is installed
    if ! command -v uhd_find_devices &> /dev/null; then
        print_warning "UHD not found in PATH"
        errors=$((errors + 1))
    fi
    
    # Check if GNU Radio is installed
    if ! command -v gnuradio-companion &> /dev/null; then
        print_warning "GNU Radio not found in PATH"
        errors=$((errors + 1))
    fi
    
    # Check if Python virtual environment exists
    if [[ ! -f "$VENV_DIR/bin/python3" ]]; then
        print_error "Python virtual environment not found"
        errors=$((errors + 1))
    fi
    
    # Check if required Python packages are installed
    if [[ -f "$VENV_DIR/bin/python3" ]]; then
        "$VENV_DIR/bin/python3" -c "import scapy, numpy, flask" 2>/dev/null
        if [[ $? -ne 0 ]]; then
            print_warning "Some Python packages missing"
            errors=$((errors + 1))
        fi
    fi
    
    if [[ $errors -eq 0 ]]; then
        print_success "Installation verified successfully!"
        return 0
    else
        print_warning "Installation verification found $errors issue(s)"
        return 1
    fi
}

# Function to display completion message
show_completion() {
    clear
    echo -e "${GREEN}=============================================${NC}"
    echo -e "${GREEN}   Installation Complete!                    ${NC}"
    echo -e "${GREEN}=============================================${NC}"
    echo ""
    echo -e "${BLUE}Framework Location:${NC} $INSTALL_DIR"
    echo -e "${BLUE}Python Virtual Env:${NC} $VENV_DIR"
    echo -e "${BLUE}Configuration Dir:${NC} /etc/mobile-security-framework"
    echo -e "${BLUE}Log File:${NC} $LOG_FILE"
    echo ""
    echo -e "${YELLOW}Next Steps:${NC}"
    echo "1. Configure your SDR hardware:"
    echo "   $INSTALL_DIR/scripts/configure_sdr.py"
    echo "2. Start the framework:"
    echo "   systemctl start mobile-security-framework"
    echo "3. Access the web interface:"
    echo "   http://localhost:8080"
    echo ""
    echo -e "${YELLOW}Useful Commands:${NC}"
    echo "  Check status: systemctl status mobile-security-framework"
    echo "  View logs: journalctl -u mobile-security-framework -f"
    echo "  Stop framework: systemctl stop mobile-security-framework"
    echo ""
    echo -e "${RED}Important:${NC} Review /etc/mobile-security-framework/ config files"
    echo "before starting the framework."
    echo -e "${GREEN}=============================================${NC}"
}

# Main installation function
main() {
    clear
    echo -e "${BLUE}=============================================${NC}"
    echo -e "${BLUE} Mobile Network Security Framework Installer ${NC}"
    echo -e "${BLUE}=============================================${NC}"
    echo ""
    
    # Check if running as root
    check_root
    
    # Check OS compatibility
    check_os
    
    # Create installation directory
    mkdir -p "$INSTALL_DIR"
    
    # Start logging
    echo "=== Installation started at $(date) ===" > "$LOG_FILE"
    
    # Execute installation steps
    print_status "Starting installation..."
    
    install_system_deps
    install_uhd
    install_gnuradio
    install_osmocom_deps
    install_open5gs
    install_srsran
    install_openbts
    install_ueransim
    install_osmocombb
    setup_python_env
    create_configs
    create_systemd_service
    setup_networking
    
    # Verify installation
    if verify_installation; then
        print_success "All components installed successfully!"
    else
        print_warning "Installation completed with warnings"
    fi
    
    # Show completion message
    show_completion
    
    # Log completion
    echo "=== Installation completed at $(date) ===" >> "$LOG_FILE"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -h, --help     Show this help message"
            echo "  -v, --verbose  Enable verbose output"
            echo "  --skip-deps    Skip dependency installation"
            echo "  --only-deps    Install only dependencies"
            exit 0
            ;;
        --verbose|-v)
            set -x
            shift
            ;;
        --skip-deps)
            SKIP_DEPS=true
            shift
            ;;
        --only-deps)
            ONLY_DEPS=true
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Run main installation
main

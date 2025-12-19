# 📡 Mobile Network Security Framework

![License](https://img.shields.io/badge/License-MIT-blue.svg)
![Python](https://img.shields.io/badge/Python-3.8%2B-green)
![SDR](https://img.shields.io/badge/SDR-USRP%202901-orange)
![Telecom](https://img.shields.io/badge/Telecom-2G%2F3G%2F4G%2F5G-red)
![Open Source](https://img.shields.io/badge/Open%20Source-Yes-brightgreen)
![Research](https://img.shields.io/badge/Research-Security-yellow)

**An open-source, modular framework for security testing, vulnerability research, and protocol analysis of multi-generation mobile networks (2G/3G/4G/5G).** Built with SDR hardware and open-source telecom stacks to emulate realistic telecom environments for security research and defensive testing.

## 📋 Table of Contents
- [Overview](#-overview)
- [Key Features](#-key-features)
- [Architecture](#-architecture)
- [Installation](#-installation)
- [Modules](#-modules)
- [Use Cases](#-use-cases)
- [License](#-license)
- [Disclaimer](#-disclaimer)
- [Contact](#-contact)
- [Acknowledgments](#-acknowledgments)

## 🎯 Overview

The **Mobile Network Security Framework** provides a comprehensive platform for analyzing security vulnerabilities across 2G, 3G, 4G, and 5G mobile networks. By leveraging Software-Defined Radio (SDR) and open-source telecom stacks, it enables researchers to conduct security assessments in controlled lab environments without affecting production networks.

**Research Paper**: This framework is based on the research paper *"Active Exploitation Framework for Mobile Network Protocols Using Specialized Tactical Hardware"* by Tri Sumarno and Muhammad Mustafa Fagan.

## ✨ Key Features

| Feature | Description |
|---------|-------------|
| **Multi-generation Support** | Full stack implementations for GSM (2G), UMTS (3G), LTE (4G), and 5G NR |
| **Modular Architecture** | Three core modules for different attack vectors: SIM Swap, Intercept, and Physical Layer |
| **Hardware Integration** | USRP 2901, BladeRF, and other SDR platforms with GPSDO synchronization |
| **Realistic Emulation** | Complete RAN to Core network simulation with IMS and packet data support |
| **Open Source Stack** | Built on OpenBTS, Osmocom, Open5GS, srsRAN, and UERANSIM |
| **Protocol Analysis** | Comprehensive signaling analysis across MAP, Diameter, GTP, NAS, SIP/RTP |
| **Lab-Ready** | Designed for isolated lab environments with full reproducibility |

## 🏗 Architecture

### High-Level Architecture Diagram![deepseek_mermaid_20251219_5408ed](https://github.com/user-attachments/assets/3d9db4ee-ec94-402c-b2f4-8be33cd23733)


### Component Overview
| Component | Purpose | Key Protocols |
|-----------|---------|---------------|
| **OpenBTS** | GSM BTS emulation | Um, A-bis, SIP |
| **Osmocom** | 2G/3G core and BTS | SS7, MAP, GTP |
| **Open5GS** | 4G/5G core network | NGAP, PFCP, HTTP/2 |
| **srsRAN** | 4G LTE RAN | S1-AP, GTP-U |
| **UERANSIM** | 4G/5G UE simulator | NAS, RRC |
| **OsmocomBB** | GSM handset emulation | GSM L1/L2 |

## 🔧 Installation

### Prerequisites
#### Hardware Requirements
- **SDR Hardware**: USRP 2901, BladeRF, or similar SDR platform
- **Computing**: Intel i7 or equivalent (8+ cores recommended)
- **Memory**: 16GB RAM minimum (32GB recommended)
- **Storage**: 100GB+ SSD
- **Networking**: Dual NIC recommended (for separation of control/user planes)
- **Synchronization**: GPSDO for timing synchronization (optional but recommended)

#### Software Requirements
- **OS**: Ubuntu 22.04 LTS (recommended) or 20.04 LTS
- **Kernel**: 5.15+ with real-time patches (for SDR performance)
- **Dependencies**: GNU Radio 3.10+, UHD 4.0+, Docker 20.10+

### Complete Installation Guide
#### 1. System Preparation
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install base dependencies
sudo apt install -y git build-essential cmake autoconf libtool \
    pkg-config libboost-all-dev libusb-1.0-0-dev libfftw3-dev \
    libsctp-dev libgnutls28-dev libgcrypt-dev libssl-dev \
    libmongoc-dev libbson-dev libyaml-dev libpcsclite-dev \
    libtalloc-dev libpcap-dev libosmocore-dev libosmo-netif-dev \
    libosmo-sccp-dev libasn1c-dev sofia-sip-utils
```

#### 2. System Preparation
```bash
# Clone the repository
git clone https://github.com/noz-co-id/MNSF.git
cd MNSF

# Run automated installation script (takes 30-60 minutes)
chmod +x install.sh
sudo ./install.sh --all
```

## 📦 Modules
The Mobile Network Security Framework consists of three core modules, each designed to test specific vulnerabilities and attack vectors in mobile networks. These modules can be used independently or in combination for comprehensive security assessments.

## 1. SIM Swap Module
### 🎯 Purpose
The SIM Swap Module is designed to analyze vulnerabilities in subscriber identity management and authentication procedures across 2G, 3G, 4G, and 5G mobile networks. It enables security researchers to simulate and test SIM swap attacks in controlled lab environments.

### 🔧 Features
- IMSI Collection: Passive and active IMSI harvesting techniques
- Authentication Bypass: Testing of AKA, MILENAGE, COMP128 algorithms
- Location Update Attacks: Manipulation of VLR/HLR registration
- Roaming Scenarios: Inter-PLMN attack simulations
- Multi-Generation Support: Testing across 2G/3G/4G/5G networks

### 🏗 Architecture
```bash
┌─────────────────────────────────────────────┐
│            SIM Swap Module                  │
├─────────────────────────────────────────────┤
│  Attack Scenarios                           │
│  • Traditional SIMSwap(HLR/HSS manipulation)│
│  • Authentication Bypass                    │
│  • Location Update Hijacking                │
│  • Roaming-based Attacks                    │
├─────────────────────────────────────────────┤
│  Core Components                            │
│  • IMSI Catcher                             │
│  • HLR/HSS Emulator                         │
│  • Authentication Vector Generator          │
│  • Signaling Analyzer                       │
├─────────────────────────────────────────────┤
│  Supported Protocols                        │
│  • MAP (2G/3G)                              │
│  • Diameter (4G/5G)                         │
│  • EAP-AKA/5G-AKA                           │
│  • GSM-AUTH/MAP-AUTH                        │
└─────────────────────────────────────────────┘
```
### 📋 Supported Attack Scenarios

|Scenario |	Description	|Target Network |
|---------|-------------|---------------|
|**Traditional SIM Swap**|	Manipulating HLR/HSS to redirect subscriber services |	2G/3G/4G/5G
|**Authentication Bypass**|	Bypassing SIM authentication procedures |	2G/3G/4G/5G
|**Location Update Hijack**|	Forcing location updates to malicious VLR/MME |	2G/3G/4G/5G
|**Roaming SIM Swap**|	Exploiting roaming interfaces for identity theft |	2G/3G/4G/5G
|**Silent SMS Attack**|	Using silent SMS for IMSI discovery |	2G/3G/4G


## 2. Intercept Module
### 🎯 Purpose
The Intercept Module implements lawful intercept architectures and analyzes signaling/data interception points across mobile network generations. It enables testing of interception capabilities and validation of privacy protections.

### 🔧 Features
- Signaling Interception: MAP, Diameter, GTP-C monitoring
- User Plane Interception: GTP-U, RTP, SIP content capture
- LI Compliance Testing: 3GPP-compliant lawful intercept (HI1/HI2/HI3)
- MSISDN-IMSI Correlation: Identity resolution across interfaces
- Real-time Analysis: Live traffic inspection and filtering

### 🏗 Architecture
```bash
┌─────────────────────────────────────────────┐
│          Intercept Module                   │
├─────────────────────────────────────────────┤
│  Interception Points                        │
│  • HLR/HSS/UDM Interfaces                   │
│  • MME/AMF/SGSN Signaling                   │
│  • PGW/UPF User Plane                       │
│  • MSC/IMS Call Control                     │
├─────────────────────────────────────────────┤
│  Analysis Components                        │
│  • Protocol Decoders                        │
│  • Session Reconstructor                    │
│  • Metadata Extractor                       │
│  • Forensic Timeline Builder                │
├─────────────────────────────────────────────┤
│  Output Formats                             │
│  • PCAP with decoded layers                 │
│  • JSON/XML structured logs                 │
│  • HTML interactive reports                 │
│  • Real-time WebSocket streams              │
└─────────────────────────────────────────────┘
```

### 📋 Supported Interception Types
|Type|	Protocol|	Interface|Content|
|----|----------|----------|-------|
|**Signaling (HI2)**|	MAP, CAP|	HLR-VLR, HSS-MME|Authentication, Location, SMS|
|**Signaling (HI2)**|Diameter|	S6a, S13, Sh|Subscriber data, Equipment info|
|**Signaling (HI2)**|GTP-C|	S11, S5/S8|Session management, Bearer control|
|**Content (HI3)**|GTP-U|	S1-U, S5/S8|User data packets|
|**Content (HI3)**|RTP/SRTP|	IMS, MGW|Voice/media streams|
|**Content (HI3)**|SIP|	IMS, MSC|Call setup, messaging|


## 3. Peripheral Module (Layer 1)
### 🎯 Purpose
The Peripheral Module implements Physical Layer (Layer 1) attack vectors in mobile networks. It operates at the radio interface level, exploiting vulnerabilities in modulation, synchronization, and frame structure. These attacks are particularly stealthy as they bypass traditional cryptographic protections

### 🔧 Features
- Synchronization Attacks: PSS/SSS jamming and spoofing
- Reference Signal Manipulation: CRS, DMRS, SRS manipulation
- Cell Spoofing: Malicious eNodeB/gNodeB emulation
- DoS Attacks: Physical channel disruption
- Baseband Exploits: RCE via SIB, RAR, PDCCH payloads
- Custom Waveform Generation: Arbitrary signal generation

### 🏗 Architecture
```bash
┌─────────────────────────────────────────────┐
│        Peripheral Module (Layer 1)          │
├─────────────────────────────────────────────┤
│  Attack Categories                          │
│  • Jamming & Interference                   │
│  • Spoofing & Impersonation                 │
│  • Resource Exhaustion                      │
│  • Protocol Exploitation                    │
├─────────────────────────────────────────────┤
│  SDR Integration                            │
│  • USRP B210/N310/X310                      │
│  • BladeRF 2.0 micro xA4/A9                 │
│  • LimeSDR/LimeNET                          │
│  • HackRF One/PortaPack                     │
├─────────────────────────────────────────────┤
│  Signal Processing                          │
│  • GNU Radio Companion flows                │
│  • Custom C++ blocks                        │
│  • Python-controlled SDR                    │
│  • Real-time spectrum analysis              │
└─────────────────────────────────────────────┘
```

### 📋 Supported Attack Types
|Attack Type|Target|Effect|Stealth Level|
|-----------|------|------|-------------|
|**Sync Signal Jamming**|PSS/SSS (LTE/NR)|Prevents cell synchronization|Medium|
|**Reference Signal Jamming**|CRS/DMRS (LTE/NR)|Degrades channel estimation|High|
|**Broadcast Channel Spoofing**|PBCH (LTE/NR)|Fake system information|High|
|**RACH Jamming	PRACH**|(LTE/NR)|Prevents network access|Low|
|**Control Channel DoS**|PDCCH (LTE)|Blocks scheduling information|Medium|
|**SIB Injection**|BCCH (LTE)|Malicious system info|Very High|
|**Beacon Flooding**|	All cells|Network discovery confusion|Low| 

## 💡 Use Cases
### 🎓 Academic Research
- Protocol Analysis: Detailed study of 3GPP protocol implementations
- Vulnerability Research: Discovery of new attack vectors
- Thesis Projects: Complete platform for graduate research
- Publications: Reproducible experiments for paper submissions

### 🔒 Telecom Security
- Operator Assessments: Security testing for mobile operators
- Penetration Testing: Red team exercises in controlled environments
- Compliance Validation: 3GPP security requirement verification
- Forensic Analysis: Incident response and investigation training

### 🛡️ Defense Development
- IDS/IPS Testing: Validation of intrusion detection/prevention systems
- Security Patch Validation: Testing fixes before deployment
- Threat Modeling: Real-world attack simulation for defense planning
- Training Platforms: Hands-on labs for security teams

### 🔬 Protocol Development
- Interoperability Testing: Multi-vendor compatibility testing
- Standard Compliance: 3GPP specification verification
- Performance Analysis: Protocol efficiency and optimization
- Feature Validation: New feature security impact assessment


## 📄 License
This project is licensed under the MIT License - see the LICENSE file for details.


## ⚠️ Disclaimer
IMPORTANT LEGAL NOTICE
Intended Use
This framework is ONLY intended for:
- ✅ Authorized security research in controlled lab environments
- ✅ Educational and academic purposes
- ✅ Defensive security testing with explicit permission
- ✅ Telecommunications security training and certification
- ✅ Compliance testing on networks you own or have written permission to test

Prohibited Use
DO NOT use this framework for:
- ❌ Testing networks without explicit written authorization
- ❌ Disrupting telecommunications services
- ❌ Intercepting communications without legal authority
- ❌ Any illegal activities or unauthorized access
- ❌ Testing production networks without permission

Legal Compliance
Users of this framework must:
- 🔒 Comply with all applicable laws and regulations
- 🔒 Obtain proper authorization before testing
- 🔒 Use only in isolated, controlled environments
- 🔒 Respect privacy and data protection regulations

No Warranty
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND. The developers assume no liability for any misuse, damage, or legal issues arising from the use of this framework.

## 📞 Contact
Project Maintainers
- [Tri Sumarno](https://www.linkedin.com/in/noz) - tri@noz.co.id
- [Muhammad Mustafa Fagan](https://www.linkedin.com/in/mmustafafagan/) - fagan@noz.co.id


## 🙏 Acknowledgments
Open Source Projects
This framework builds upon the following amazing open source projects:

|Project|Contribution|Link|
|-------|------------|----|
|OpenBTS|GSM BTS implementation|[GitHub](https://github.com/RangeNetworks/openbts)|
|Osmocom|2G/3G mobile communications suite|[Osmocom](https://osmocom.org/)
|Open5GS|Open source 5G Core implementation|[Open5GS](https://github.com/open5gs/open5gs)
|srsRAN|4G/5G software radio suite|[srsRAN](https://github.com/srsran/srsRAN)
|UERANSIM|5G UE and RAN simulator|[UERANSIM](https://github.com/aligungr/UERANSIM)
|GNU Radio|SDR signal processing toolkit|[GNURadio](https://www.gnuradio.org/)


## Research Foundations
- 3GPP Specifications: TS 33.102, TS 33.401, TS 33.501
- Telecommunications Security Research Community
- Open Source Security Initiatives


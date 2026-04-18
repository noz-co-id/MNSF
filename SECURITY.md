# Security Policy: 5G NSA & Network Security Function (NSF) Research

## Overview
This security policy governs the vulnerability reporting process for research conducted by **PT NOZ Berkarya Indonesia**. Our research environment is strictly isolated, utilizing **Open5GS (NSA)** and **srsRAN** as the EPC/Radio stack to replicate complex signaling scenarios.

## Supported Versions

We actively provide security research and validation for the following simulation environments:

| Version (Simulation Stack) | Supported          | Core Technology          |
| -------------------------- | ------------------ | ------------------------- |
| 5G NSA (Option 3x) v1.x    | :white_check_mark: | Open5GS + srsRAN          |
| X2-C Interface Research    | :white_check_mark: | Signalling Storm Analysis |
| NSF Testing Framework      | :white_check_mark: | Isolated Lab Environment  |
| Legacy EPC (Standalone)    | :x:                | Non-Supported             |

## Reporting a Vulnerability

If you identify a potential security flaw—particularly regarding **X2-C interface signaling**, **SIP Registration anomalies**, or **Signalling Storm mitigation**—please report it through the following process.

### How to Report
1. **Private Disclosure**: Do not open a public GitHub issue. Please send a detailed technical report to:
   - **Primary**: tri@noz.co.id
   - **Technical Lead**: f4co@noz.co.id
2. **Required Documentation**:
   - **Scenario Description**: Specifically detailing the replication of **Signaling Storm scenarios** and their impact on **Network Security Function (NSF)** capabilities.
   - **Technical Proof (PoC)**: PCAP files (Wireshark), Docker logs, or srsRAN/Open5GS configuration files used in the isolated setup.
   - **Metrics**: Data showing how the X2-C link reacts under stress.

### Vulnerability Classification (Based on Simulation Metrics)
- **CRITICAL**: Core Network authentication bypass or unauthorized access to the HSS/UDM within the 5G NSA stack.
- **HIGH**: Validated vulnerabilities that bypass **Network Security Function (NSF)** controls during signaling storms.
- **MEDIUM**: Routing anomalies or SIP-level packet drops observed in isolated EPC/IMS environments.

## Our Commitment
Our research aims to test capabilities in a **realistic and isolated manner**. Upon receiving a report, our team will:
1. **Acknowledge**: Confirm receipt within 48 hours.
2. **Replicate**: Validate the finding within our isolated **srsRAN + Open5GS** testbed.
3. **Coordinate**: If the vulnerability is inherent to the FOSS project, we will assist in reporting to the respective maintainers for CVE registration.

---
*Note: All research is conducted in compliance with 3GPP standards (TS 23.501, TS 33.501) for the purpose of global telecommunication security improvement.*

**Author:** Tri Sumarno, S.H., M.T.I.  
**Affiliation:** PT NOZ Berkarya Indonesia

# Mobile Network Security Framework (MNSF) with GNSS-SDR Integration

## Framework Structure
```text
mnsf/
├── README.md
├── docker-compose.yml
├── Dockerfile
├── requirements.txt
├── scripts/
│   ├── install_gnss_sdr.sh
│   ├── setup_environment.sh
│   └── compliance_check.sh
├── modules/
│   ├── sim_swap/
│   │   ├── __init__.py
│   │   ├── attack_module.py
│   │   ├── detection_module.py
│   │   └── config.json
│   ├── intercept/
│   │   ├── __init__.py
│   │   ├── imsi_catcher.py
│   │   ├── sdr_controller.py
│   │   └── config.json
│   ├── physical_layer/
│   │   ├── __init__.py
│   │   ├── rogue_bts.py
│   │   ├── sync_analyzer.py
│   │   └── config.json
│   └── gnss/
│       ├── __init__.py
│       ├── install.sh
│       ├── configure.sh
│       ├── run_gnss_sdr.sh
│       ├── gnss_sync.py
│       ├── spoofing_detector.py
│       └── config/
│           ├── gps_l1_usrp.conf
│           ├── galileo_e1.conf
│           └── gnss_constellations.json
├── core/
│   ├── framework.py
│   ├── hardware_manager.py
│   ├── protocol_stack.py
│   └── compliance_monitor.py
├── configs/
│   ├── global_regulations.yaml
│   ├── 3gpp_standards.json
│   └── lab_environment.cfg
├── tests/
│   ├── test_gnss.py
│   ├── test_compliance.py
│   └── integration_tests.py
└── docs/
    ├── compliance_guidelines.md
    └── technical_specifications.md
```

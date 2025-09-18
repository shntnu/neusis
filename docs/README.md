# Neusis Documentation

NixOS/nix-darwin configuration management for compute servers and workstations.

## Quick Start

### For Users

- [Getting Started](user/01_getting_started.md) - Set up your account
- [Development Environments](user/03_environment_setup.md) - Use templates
- [Architecture Overview](user/02_architecture.md) - How this repo works

### For Operators

- [Deployment](operations/01_deployment.md) - Deploy and rebuild procedures
- [Secrets](operations/02_secrets.md) - Manage secrets with Agenix
- [Monitoring](operations/03_monitoring.md) - Access Grafana and metrics
- [Troubleshooting](operations/99_troubleshooting.md) - Fix common issues

## Server Status

| Server | OS | Config | Docs |
|--------|----|----|------|
| Oppy | NixOS | This repo | [Operations](operations/) |
| Spirit | Ubuntu | [imaging-server-maintenance](https://github.com/broadinstitute/imaging-server-maintenance) | [External](https://github.com/broadinstitute/imaging-server-maintenance) |

## Repository Map

```text
neusis/
├── docs/              # This documentation
│   ├── operations/    # Server operations
│   └── user/          # User guides
├── machines/          # Server configurations
├── homes/             # User home configs
├── secrets/           # Encrypted secrets
└── scripts/           # Deployment tools
```

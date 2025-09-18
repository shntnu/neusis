# Operations Documentation

Quick reference for operating Oppy via NixOS.

## Essential Tasks

- [Deployment](deployment.md) - Deploy, rebuild, recover
- [Secrets](secrets.md) - Manage secrets with Agenix
- [Monitoring](monitoring.md) - Access Grafana, view metrics
- [Troubleshooting](troubleshooting.md) - Common issues and fixes

## Current Status

**Oppy**: Managed via this repo (NixOS)  
**Spirit**: Managed via imaging-server-maintenance (Ubuntu/Ansible)

## Quick Commands

```bash
# Rebuild Oppy
nixos-rebuild switch --flake .#oppy --target-host oppy

# Access monitoring
open http://grafana.oppy  # via Tailscale

# Check system status
ssh oppy systemctl status

# View logs
ssh oppy journalctl -f -u <service>
```

## Key Locations

- Hardware specs: [Local](../../../../misc/imaging-server-maintenance/INVENTORY.md) | [GitHub](https://github.com/broadinstitute/imaging-server-maintenance/blob/main/INVENTORY.md)
- Network topology: [Local](../../../../misc/imaging-server-maintenance/INVENTORY.md#network-architecture) | [GitHub](https://github.com/broadinstitute/imaging-server-maintenance/blob/main/INVENTORY.md#network-architecture)
- Physical access: Markley Group, Rack C17, U17-20

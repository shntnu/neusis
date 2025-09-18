# Operations Documentation

Quick reference for operating Oppy via NixOS.

## Essential Tasks

- [Deployment](01_deployment.md) - Fresh deployment and rebuilds
- [Secrets](02_secrets.md) - Manage secrets with Agenix
- [Monitoring](03_monitoring.md) - Access Grafana, view metrics
- [Troubleshooting](99_troubleshooting.md) - NixOS-specific issues and fixes

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

## External References

For hardware specifications, network topology, and physical access details, see:

- [imaging-server-maintenance repository](https://github.com/broadinstitute/imaging-server-maintenance)

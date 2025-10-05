# Oppy NixOS Configuration

NixOS configuration for Oppy datacenter server.

## What This Configures

- **Users**: Declarative management via neusis lib (admins, regulars, locked users)
- **CSLab Infrastructure**: Policies from imaging-server-maintenance (imaging group, /work/* structure, quota monitoring)
- **Storage**: ZFS pools with activation script import
- **Networking**: Bonded ethernet, Infiniband, Tailscale mesh

## Module Structure

### Core Modules

#### default.nix

- Main entry point
- Imports all oppy-specific and common modules
- Tailscale configuration
- Integrates with neusis lib (provides agenix, home-manager, disko via flake inputs)

#### hardware-configuration.nix

- Auto-generated hardware detection (nixos-generate-config)
- File systems, kernel modules, boot loader

#### boot.nix

- Systemd-boot bootloader
- ZFS pool import workaround (boot.zfs.extraPools disabled due to disko bug #359)
- Activation script imports zstore03 and zstore16 at boot

#### disko.nix

- Disk layout and partitioning
- ZFS pool definitions (RAID-Z, lz4 compression, dedup enabled)
- Boot drive: Samsung 990 PRO 4TB

#### network.nix

- Bonded ethernet (802.3ad LACP): enp206s0f0 + enp206s0f1 → bond001
- Static IP configuration
- Infiniband interface configuration
- MAC addresses and GUIDs hardcoded for interface matching

#### misc.nix

- Monitoring stack (Grafana/Prometheus via neusis.services.monitoring)
- CUDA support enabled
- IPMI device access (ipmiusers group)
- FHS compatibility (programs.nix-ld)
- System packages: vim, podman-tui, ipmitool, etc.

#### vm.nix

- VM testing configuration (vmVariantWithDisko)
- Mounts secrets from host via virtio
- Used for: `TESTVM_SECRETS=... nix run .#nixosConfigurations.oppy.config.system.build.vmWithDisko`

### CSLab-Specific Modules

#### cslab-infrastructure.nix

- Creates `imaging` group (GID 1000) for all lab members
- /work/* directory structure (datasets, users, scratch, tools, _archive)
- Per-user directories with 750 permissions
- Build assertion: fails if emergency accounts (exx, root) in user config

#### cslab-monitoring.nix

- Quota monitoring: Monday 9 AM (Nushell script, Slack alerts via agenix)
- Group auditing: Wednesday 9 AM (detects unauthorized sudo between rebuilds)
- Logs: /var/log/lab-scripts/

Implementation Notes: These are machine-specific (not in modules/nixos/) because only Oppy runs NixOS currently

### Common Modules (from ../common/)

- `networking.nix`: Firewall, network utilities
- `gpu/nvidia_dc.nix`: NVIDIA datacenter driver (535.x), persistence mode, GSP firmware
- `substituters.nix`: Nix binary cache configuration (cachix: devenv, cuda, gaming, ai)
- `virtualization.nix`: Libvirt, Docker, Podman
- `input_device.nix`: X11 keyboard layout, touchpad/libinput
- `ssh.nix`: SSH server configuration
- `us_eng.nix`: US/English locale and timezone (America/New_York)
- `nosleep.nix`: Disables sleep/suspend/hibernate
- `nix.nix`: Nix daemon, flakes, experimental features
- `printing.nix`: CUPS printing service
- `zfs.nix`: ZFS kernel module, scrubbing
- `comin.nix`: Automatic system updates

## Scripts

### check-quotas.nu

- Nushell script for quota monitoring
- Called by cslab-monitoring.nix systemd timer
- Checks /home usage against 100GB soft limit
- Sends Slack alerts when users over quota

### archive-user.sh

- Manual user archival on removal
- Usage: `sudo ./archive-user.sh <username>`
- Archives /home/<user> to /work/users/_archive/<user>_YYYY-MM-DD
- Changes ownership to root:imaging

### test-cslab-infrastructure.sh

- Comprehensive infrastructure validation
- Tests: imaging group, /work/* structure, permissions, monitoring, secrets
- Run: `sudo /run/current-system/sw/bin/test-cslab-infrastructure.sh`

## Key Configuration Details

### User Management

Users defined in `../../users/cslab.nix` (from neusis repo root), integrated via `lib.neusisOS.mkNeusisOS`

- Four types: admins (wheel), regulars, locked (nologin), removed (not in config)

### ZFS Pools

- Import: Activation script (not boot.zfs.extraPools due to disko bug #359)
- Permissions: 0777 on /datastore03 and /datastore16

### Network

- bond001: Static IP (defined in network.nix)
- Infiniband: ibp69s0 configured
- Tailscale: Persistent mesh with OAuth credentials via agenix

## Related Documentation

This README documents Oppy's NixOS configuration implementation. Operational procedures and policies are in the imaging-server-maintenance repository.

- **Policies** (requirements this implements): `../../imaging-server-maintenance/policies/` - policies reference this doc for implementation status
- **Operations** (deploy, user management, troubleshooting): `../../imaging-server-maintenance/RUNBOOK_NIX.md`
- **Hardware** (specs, drives, network): `../../imaging-server-maintenance/INVENTORY.md`
- **Development history**: `../../imaging-server-maintenance/assets/EXPERIMENTS_CSLAB_INFRASTRUCTURE.md`

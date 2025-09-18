# Troubleshooting

## BMC Network Failure (2024-08-29 Incident)

### Symptoms

- Cannot access <https://oppy-mgmt.broadinstitute.org>
- BMC port LED not blinking

### Recovery via Management Port

```bash
# 1. Connect laptop to management port (front panel)
# 2. Configure laptop network
sudo ifconfig en0 10.192.5.1 netmask 255.255.255.0

# 3. Access BMC
open http://10.192.5.25
```

### Recovery via Crash Cart

1. Connect VGA display + keyboard
2. Power cycle server
3. Enter BIOS → Server Management → BMC Network
4. Switch from DHCP to Static:
   - IP: 10.192.5.25
   - Gateway: 10.192.5.1
   - Netmask: 255.255.255.0
5. Save and reboot

### Remote Hands Support

Create BITS ticket: <help@broadinstitute.org>

Full incident details: [Local](../../../../misc/imaging-server-maintenance/MAINTENANCE_LOG.md#2024-08-29---bmc-network-failure) | [GitHub](https://github.com/broadinstitute/imaging-server-maintenance/blob/main/MAINTENANCE_LOG.md#2024-08-29---bmc-network-failure)

## nixos-anywhere SSH Issues

### Error: Permission denied

```bash
# Fix in scripts/anywhere.py line 141
# Change "--i" to "-i"

# Or run manually:
nixos-anywhere --flake .#oppy \
  --extra-files /tmp/neusis_anywhere_temp \
  -i ~/.ssh/id_ed25519 \
  -t \
  oppy
```

## ZFS Issues

### Pool not imported after reboot

```bash
sudo zpool import -f zstore16
sudo zpool import -f zstore03
sudo zfs mount -a
```

### Dataset not mounting

```bash
sudo zfs get mountpoint zstore16/datastore
sudo zfs set mountpoint=/datastore16 zstore16/datastore
sudo zfs mount zstore16/datastore
```

## Network Issues

### InfiniBand not working

```bash
# Check module loaded
lsmod | grep mlx
sudo modprobe mlx5_ib

# Check interface
ip addr show | grep 192.0.2
```

### Bond interface down

```bash
sudo systemctl restart systemd-networkd
ip link show bond001
```

## Monitoring Issues

### Grafana not accessible

```bash
# Check Tailscale
tailscale status
sudo systemctl restart tailscale

# Check nginx
sudo systemctl status nginx
sudo nginx -t
```

### No metrics in Prometheus

```bash
# Check exporters
systemctl status prometheus-node-exporter
systemctl status prometheus-nvidia-gpu-exporter

# Test endpoints
curl http://localhost:9100/metrics | head
curl http://localhost:9835/metrics | head
```

## Rebuild Failures

### Out of disk space

```bash
# Clean old generations
sudo nix-collect-garbage -d
sudo nix-store --gc

# Remove old system profiles
sudo nix-env --profile /nix/var/nix/profiles/system --list-generations
sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations +5
```

### Hash mismatch

```bash
# Update flake inputs
nix flake update
git add flake.lock
git commit -m "Update flake.lock"
```

# Troubleshooting

## NixOS Deployment Issues

### nixos-anywhere SSH Authentication

If the deployment script fails with SSH permission denied:

```bash
# Add the -i flag manually to specify SSH key:
python scripts/anywhere.py deploy \
  --target-host oppy \
  --extra-files secrets/oppy/anywhere \
  --flake .#oppy \
  --key ~/.ssh/id_ed25519 \
  -i ~/.ssh/id_ed25519
```

### Secrets Decryption Failed

```bash
# Verify your key is in secrets/secrets.nix
grep "$(cat ~/.ssh/id_ed25519.pub)" secrets/secrets.nix

# Rekey secrets after adding new users
nix develop
cd secrets
agenix --rekey
```

## NixOS Rebuild Issues

### Out of Disk Space

```bash
# Clean old generations
sudo nix-collect-garbage -d

# Remove old system profiles (keep last 5)
sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations +5

# Check disk usage
df -h /nix/store
```

### Flake Lock Issues

```bash
# Update specific input
nix flake update nixpkgs

# Update all inputs
nix flake update

# After updating
git add flake.lock
git commit -m "Update flake.lock"
```

### Build Failures

```bash
# Build with more verbose output
nixos-rebuild switch --flake .#oppy --target-host oppy --show-trace

# Test build locally first
nix build .#nixosConfigurations.oppy.config.system.build.toplevel
```

## Service Issues (NixOS-specific)

### Monitoring Services Not Starting

```bash
# Check service status
systemctl status prometheus
systemctl status grafana
systemctl status loki

# View service logs
journalctl -u prometheus -n 50
journalctl -u grafana -n 50

# Restart services
sudo systemctl restart prometheus grafana loki
```

### Tailscale Not Connecting

```bash
# Check if enabled in configuration
grep -r "tailscale.enable" machines/oppy/

# Restart service
sudo systemctl restart tailscale

# Re-authenticate if needed
sudo tailscale up --auth-key=<key-from-secrets>
```

## Home-Manager Issues

### Home Configuration Not Applying

```bash
# Check home-manager generation
home-manager generations

# Switch to specific user config
home-manager switch --flake .#username@oppy

# Debug home-manager build
home-manager build --flake .#username@oppy --show-trace
```

## Common NixOS Commands

```bash
# Show current system generation
nixos-rebuild list-generations

# Rollback to previous generation
sudo nixos-rebuild switch --rollback

# Show what would be built
nixos-rebuild dry-build --flake .#oppy

# Check configuration syntax
nix flake check

# Search for packages
nix search nixpkgs <package-name>
```

## For Hardware/Infrastructure Issues

For BMC, networking, and hardware-related troubleshooting, refer to:

- [imaging-server-maintenance repository](https://github.com/broadinstitute/imaging-server-maintenance)

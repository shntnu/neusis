# Deployment Operations

## Rebuild Oppy

```bash
nixos-rebuild switch --flake .#oppy --target-host oppy
```

## Deploy Fresh NixOS to Oppy

This process uses `nixos-anywhere` to completely wipe and reinstall NixOS on the target machine. It will:

1. Boot into a NixOS installer via kexec
2. Partition disks using disko configuration
3. Install NixOS from the flake
4. Copy encrypted machine SSH keys for future boots

Prerequisites:

- SSH access to current system (can be any Linux, not just NixOS)
- Your SSH key added to `secrets/secrets.nix` and rekeyed
- Target machine defined in flake with disko configuration

### 1. Add your SSH key to secrets

Edit `secrets/secrets.nix`:

```nix
let
  yourname = "ssh-ed25519 AAAA... yourname@host";
  users = [ ank shantanu yourname ];
```

### 2. Rekey secrets

```bash
nix develop
cd secrets
agenix --rekey
git add . && git commit -m "Add yourname to secrets"
git push
```

### 3. Run deployment

```bash
# From the neusis repository root
nix develop
python scripts/anywhere.py deploy \
  --target-host oppy \
  --extra-files secrets/oppy/anywhere \
  --flake .#oppy \
  --key ~/.ssh/id_ed25519
```

If SSH authentication fails, add the `-i` flag manually:

```bash
python scripts/anywhere.py deploy \
  --target-host oppy \
  --extra-files secrets/oppy/anywhere \
  --flake .#oppy \
  --key ~/.ssh/id_ed25519 \
  -i ~/.ssh/id_ed25519
```

## Common Issues

### ZFS Pool Import Error

```bash
zpool import -f zstore16
zpool import -f zstore03
```

### Monitoring Not Accessible

Check Tailscale:

```bash
tailscale status
systemctl restart tailscale
```

Access Grafana at <http://grafana.oppy> (not HTTPS)

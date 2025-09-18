# Deployment Operations

## Rebuild Oppy

```bash
nixos-rebuild switch --flake .#oppy --target-host oppy
```

## Deploy Fresh NixOS to Oppy

Prerequisites:

- SSH access to current system
- Your SSH key in `secrets/secrets.nix`

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
cd /path/to/neusis
nix develop
python scripts/anywhere.py deploy oppy \
  --flake .#oppy \
  --key ~/.ssh/id_ed25519 \
  secrets/oppy/anywhere
```

If SSH authentication fails, edit line 141 in `scripts/anywhere.py`:

```python
# Change from "--i" to "-i"
cmd.extend(["-i", str(value)])
```

## Common Issues

### BMC Network Failure

Access BMC via management port:

1. Connect laptop to management port
2. Configure laptop IP: 10.192.5.1/24
3. Access BMC at 10.192.5.25

For detailed BMC recovery: [Local](../../../../misc/imaging-server-maintenance/RUNBOOK.md#bmc-access) | [GitHub](https://github.com/broadinstitute/imaging-server-maintenance/blob/main/RUNBOOK.md#bmc-access)

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

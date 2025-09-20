# Secret Management

## Add New Secret

### 1. Create encrypted secret

```bash
cd secrets/oppy
echo -n "your-secret-value" | agenix -e newsecret.age
```

### 2. Add to secrets.nix

```nix
"oppy/newsecret.age".publicKeys = users ++ [ oppy ];
```

### 3. Use in configuration

```nix
age.secrets.newsecret = {
  file = ../../secrets/oppy/newsecret.age;
  owner = "serviceuser";
};

services.myservice = {
  secretFile = config.age.secrets.newsecret.path;
};
```

## Rekey All Secrets

Required when:

- Adding/removing users
- Rotating machine keys
- Changing access permissions

```bash
nix develop
cd secrets
agenix --rekey
git add . && git commit -m "Rekey secrets"
```

## Add User to Secrets

### 1. Add public key

```nix
# secrets/secrets.nix
let
  newuser = "ssh-ed25519 AAAA... user@host";
  users = [ ank shantanu newuser ];
```

### 2. Rekey

```bash
agenix --rekey
```

## Machine Keys

Machine keys stored at `/etc/ssh/ssh_host_ed25519_key` on each host.

### Extract machine public key

```bash
ssh oppy "sudo cat /etc/ssh/ssh_host_ed25519_key.pub"
```

### Update machine key in secrets

```nix
# secrets/secrets.nix
let
  oppy = "ssh-ed25519 <new-key>";
```

## Current Secrets

| Secret | Purpose | Users |
|--------|---------|-------|
| `common/persistent_tsauthkey.age` | Persistent Tailscale auth | All users + machines |
| `common/ephemeral_tsauthkey.age` | Ephemeral Tailscale auth | All users + machines |
| `common/hashedInitialPassword.age` | User initial passwords | All users + machines |
| `common/tsclient.age` | Tailscale client config | All users + machines |
| `common/tssecret.age` | Tailscale secret | All users + machines |
| `oppy/tsauthkey.age` | Oppy Tailscale auth | All users + machines |
| `oppy/alloy_key.age` | Grafana Cloud metrics push | ank, shantanu, oppy |
| `oppy/anywhere/etc/ssh/ssh_host_ed25519_key.age` | SSH host key for deployment | ank, shantanu, oppy |
| `ank/ghauth.age` | GitHub auth token | ank only |

## Troubleshooting

### Permission Denied

```bash
# Check key is loaded
ssh-add -l

# Add key if missing  
ssh-add ~/.ssh/id_ed25519
```

### Decryption Failed

Verify your public key matches in `secrets/secrets.nix`

## Scratch

```bash

uv run scripts/anywhere.py \
  decrypt secrets/oppy/anywhere \
  --temp-folder scratch \
  --key ~/.ssh/id_ed25519

sudo uv run scripts/anywhere.py \
  decrypt secrets/oppy/anywhere \
  --temp-folder scratch \
  --key /etc/ssh/ssh_host_ed25519_key

TESTVM_SECRETS=/home/shsingh/work/GitHub/nix/neusis/scratch/ QEMU_KERNEL_PARAMS=console=ttyS0 nix run .\#nixosConfigurations.oppy.config.system.build.vmWithDisko
```

```sh
nix build .\#kexec_tailscale  

python scripts/anywhere.py \
  deploy root@oppy secrets/oppy/anywhere \
  --flake .#oppy \
  --temp-folder scratch \
  --key /home/shsingh/.ssh/id_ed25519 \
  --identity-file /home/shsingh/.ssh/id_ed25519 \
  --kexec  /nix/store/y1hvwmdz4084lvm4wryv7ay31xyah338-kexec-tarball/nixos-kexec-installer-noninteractive-x86_64-linux.tar.gz
```

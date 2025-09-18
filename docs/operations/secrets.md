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
| `oppy/tsauthkey.age` | Tailscale auth | All users + oppy |
| `oppy/alloy_key.age` | Grafana metrics | ank, shantanu, oppy |
| `oppy/anywhere/etc/ssh/ssh_host_ed25519_key.age` | SSH host key | ank, shantanu, oppy |

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

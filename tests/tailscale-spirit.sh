#!/usr/bin/env bash
# Evaluate the Spirit-only migration contract. Never build, activate or decrypt.
set -euo pipefail
repo=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
nix --extra-experimental-features 'nix-command flakes' eval \
  --json --no-write-lock-file "$repo#nixosConfigurations.spirit.config" \
  --apply 'c:
    assert c.services.tailscale.enable;
    assert c.neusis.tailscale.tailnetOrg == "ToFdp7kzyV11CNTRL";
    assert !c.neusis.tailscale.forceHostName;
    assert !c.neusis.tailscale.disableKeyExpiry;
    assert c.neusis.tailscale.clientIdFile == null;
    assert c.neusis.tailscale.clientSecretFile == null;
    assert builtins.elem "--advertise-tags=tag:cslab-servers" c.services.tailscale.extraUpFlags;
    assert builtins.elem "--ssh=false" c.services.tailscale.extraUpFlags;
    assert builtins.elem "--ssh=false" c.services.tailscale.extraSetFlags;
    assert builtins.baseNameOf c.age.secrets.tsauthkey.file == "spirit-authkey.age";
    assert !builtins.hasAttr "ts-client-id" c.age.secrets;
    assert !builtins.hasAttr "ts-client-secret" c.age.secrets;
    assert !builtins.hasAttr "tailscale-force-claim" c.systemd.services;
    assert !builtins.hasAttr "tailscale-disable-key-expiry" c.systemd.services;
    true'
printf '\n'
# Compare public recipient lists only; never decrypt enrollment material.
nix --extra-experimental-features nix-command eval --json \
  --file "$repo/secrets/secrets.nix" \
  --apply 's:
    assert s."runxi-tailnet/spirit-authkey.age".publicKeys == s."spirit/tsauthkey.age".publicKeys;
    true'
printf '\n'

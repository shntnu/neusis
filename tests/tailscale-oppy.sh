#!/usr/bin/env bash
set -euo pipefail
repository=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
nix eval --json --no-write-lock-file "path:$repository#nixosConfigurations.oppy.config" --apply 'config: {
  secret = toString config.age.secrets.tsauthkey.file;
  up = config.services.tailscale.extraUpFlags;
  set = config.services.tailscale.extraSetFlags;
  tailnet = config.neusis.tailscale.tailnetOrg;
  force = config.neusis.tailscale.forceHostName;
  expiry = config.neusis.tailscale.disableKeyExpiry;
  clientId = config.neusis.tailscale.clientIdFile;
  clientSecret = config.neusis.tailscale.clientSecretFile;
  claimHelper = builtins.hasAttr "tailscale-force-claim" config.systemd.services;
  expiryHelper = builtins.hasAttr "tailscale-disable-key-expiry" config.systemd.services;
}' | jq -e '
  (.secret | endswith("/secrets/common/persistent_cslab_mesh.age")) and
  .up == ["--hostname", "oppy", "--advertise-tags=tag:cslab-servers", "--ssh=false"] and
  .set == ["--ssh=false"] and .tailnet == "ToFdp7kzyV11CNTRL" and
  .force == false and .expiry == false and .clientId == null and .clientSecret == null and
  .claimHelper == false and .expiryHelper == false
' >/dev/null
nix eval --json --file "$repository/secrets/secrets.nix" | jq -e '
  (.["common/persistent_cslab_mesh.age"].publicKeys | sort) == (.["common/persistent_tsauthkey.age"].publicKeys | sort)
' >/dev/null
printf 'Oppy lab enrollment configuration and recipients passed.\n'

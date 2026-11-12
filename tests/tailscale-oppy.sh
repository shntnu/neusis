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
  .force == true and .expiry == true and
  (.clientId | endswith("/secrets/common/tsclient.age")) and
  (.clientSecret | endswith("/secrets/common/tssecret.age")) and
  .claimHelper == true and .expiryHelper == true
' >/dev/null
nix eval --json --file "$repository/secrets/secrets.nix" | jq -e '
  . as $secrets |
  (.["common/persistent_tsauthkey.age"].publicKeys | sort) as $expected |
  all(["common/persistent_cslab_mesh.age", "common/tsclient.age", "common/tssecret.age"][];
    . as $name | ($secrets[$name].publicKeys | sort) == $expected)
' >/dev/null
printf 'Oppy lab enrollment configuration and recipients passed.\n'

#!/usr/bin/env bash
set -euo pipefail
repository=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
nix eval --json --no-write-lock-file "path:$repository#nixosConfigurations" --apply 'systems:
  builtins.mapAttrs (name: system: let config = system.config; in {
    tailnet = config.neusis.tailscale.tailnetOrg;
    autoEnroll = config.neusis.tailscale.autoEnroll;
    authKey = config.services.tailscale.authKeyFile;
    secret = if config.age.secrets ? tsauthkey then toString config.age.secrets.tsauthkey.file else null;
    up = config.services.tailscale.extraUpFlags;
    set = config.services.tailscale.extraSetFlags;
    force = config.neusis.tailscale.forceHostName;
    expiry = config.neusis.tailscale.disableKeyExpiry;
    clientId = config.neusis.tailscale.clientIdFile;
    clientSecret = config.neusis.tailscale.clientSecretFile;
    autoconnect = config.systemd.services.tailscaled-autoconnect.enable or false;
    claimHelper = builtins.hasAttr "tailscale-force-claim" config.systemd.services;
    expiryHelper = builtins.hasAttr "tailscale-disable-key-expiry" config.systemd.services;
    origin = if name == "oppy" then config.systemd.sockets.overleaf-private-origin.listenStreams else [];
    firewall = if name == "oppy" then config.networking.nftables.tables.overleaf-origin.content else "";
    proxy = if name == "karkinos" then config.systemd.services.overleaf-oppy-origin.serviceConfig.ExecStart else "";
  }) (builtins.intersectAttrs { spirit = null; oppy = null; karkinos = null; } systems)
' | jq -e '
  all(to_entries[];
    .key as $host | .value |
    .tailnet == "ToFdp7kzyV11CNTRL" and
    .up == ["--hostname", $host, "--advertise-tags=tag:cslab-servers", "--ssh=false"] and
    .set == ["--ssh=false"] and
    .force == false and .expiry == false and
    .clientId == null and .clientSecret == null and
    .claimHelper == false and .expiryHelper == false and
    .autoEnroll == true and .autoconnect == true and
    .authKey == "/run/agenix/tsauthkey" and
    (.secret | endswith("/secrets/common/persistent_cslab_mesh.age"))
  ) and
  .oppy.origin == ["100.93.122.65:18080"] and
  (.oppy.firewall | contains("iifname != \"lo\" tcp dport 3100 drop")) and
  (.oppy.firewall | contains("iifname \"tailscale0\" ip daddr 100.93.122.65 tcp dport 18080 ip saddr 100.117.220.62 accept")) and
  (.oppy.firewall | contains("ip daddr 100.93.122.65 tcp dport 18080 drop")) and
  (.oppy.firewall | contains("100.79.40.39") | not) and
  (.karkinos.proxy | endswith(" 100.93.122.65:18080"))
' >/dev/null
nix eval --json --no-write-lock-file "path:$repository#nixosConfigurations" --apply 'systems:
  builtins.mapAttrs (name: system: let config = system.config.virtualisation.vmVariantWithDisko; in {
    tailnet = config.neusis.tailscale.tailnetOrg;
    clientId = config.neusis.tailscale.clientIdFile;
    clientSecret = config.neusis.tailscale.clientSecretFile;
    force = config.neusis.tailscale.forceHostName;
    expiry = config.neusis.tailscale.disableKeyExpiry;
    secret = toString config.age.secrets.tsauthkey.file;
  }) (builtins.intersectAttrs { oppy = null; spirit = null; } systems)
' | jq -e 'all(.[];
  .tailnet == "ToFdp7kzyV11CNTRL" and .clientId == null and .clientSecret == null and
  .force == false and .expiry == false and
  (.secret | endswith("/secrets/common/persistent_cslab_mesh.age"))
)' >/dev/null
printf 'Three-server shared enrollment, VM templates and scoped Overleaf ingress passed.\n'

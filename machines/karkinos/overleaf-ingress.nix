{
  config,
  pkgs,
  ...
}:

let
  oppyOrigin = "100.79.40.39:18080";
in
{
  age.secrets.cloudflared-overleaf = {
    file = ../../secrets/karkinos/cloudflared-overleaf.age;
    owner = "cloudflared";
    group = "cloudflared";
    mode = "0400";
  };

  users.users.cloudflared = {
    isSystemUser = true;
    group = "cloudflared";
    description = "Cloudflare Tunnel connector";
  };
  users.groups.cloudflared = { };

  # The Cloudflare dashboard routes the tunnel to localhost:18080. This local
  # socket crosses Tailscale to the private, address-scoped origin on Oppy.
  systemd.sockets.overleaf-oppy-origin = {
    description = "Local Overleaf ingress socket backed by Oppy";
    wantedBy = [ "sockets.target" ];
    listenStreams = [ "127.0.0.1:18080" ];
  };

  systemd.services.overleaf-oppy-origin = {
    description = "Proxy Overleaf ingress to Oppy over Tailscale";
    after = [ "tailscaled.service" ];
    wants = [ "tailscaled.service" ];
    serviceConfig = {
      ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd ${oppyOrigin}";
      DynamicUser = true;
      NoNewPrivileges = true;
      PrivateDevices = true;
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";
      RestrictAddressFamilies = [
        "AF_INET"
        "AF_INET6"
        "AF_UNIX"
      ];
    };
  };

  # Cloudflare manages the public hostname and forwards requests to the local
  # socket above; only the connector and private Tailscale path are exposed.
  systemd.services.cloudflared-overleaf = {
    description = "Cloudflare Tunnel — overleaf.quasimorphic.com";
    after = [
      "network-online.target"
      "overleaf-oppy-origin.socket"
    ];
    wants = [
      "network-online.target"
      "overleaf-oppy-origin.socket"
    ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "notify";
      User = "cloudflared";
      Group = "cloudflared";
      EnvironmentFile = config.age.secrets.cloudflared-overleaf.path;
      ExecStart = "${pkgs.cloudflared}/bin/cloudflared --no-autoupdate tunnel --protocol http2 --edge-ip-version 4 run";
      Restart = "on-failure";
      RestartSec = "5s";
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      RestrictAddressFamilies = [
        "AF_UNIX"
        "AF_INET"
        "AF_INET6"
      ];
      MemoryDenyWriteExecute = true;
      LockPersonality = true;
    };
  };
}

{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  hostSystem = pkgs.stdenv.hostPlatform.system;
  privateOriginAddress = "100.79.40.39";
  karkinosAddress = "100.69.243.77";
  runtimePkgs = import inputs.overleaf-runtime-nixpkgs {
    system = hostSystem;
    config.allowUnfree = true;
  };
  overleafCfg = config.services.overleaf;
  runtimeTexlive = runtimePkgs.texliveSmall.withPackages (
    tl:
    let
      selected = overleafCfg.texlivePackages tl;
    in
    if builtins.isList selected then selected else builtins.attrValues selected
  );
  overleafRuntimePath = [
    overleafCfg.package
    runtimePkgs.nodejs_24
    runtimeTexlive
    runtimePkgs.poppler-utils
    runtimePkgs.optipng
    runtimePkgs.qpdf
    runtimePkgs.ghostscript
    runtimePkgs.coreutils
    runtimePkgs.gnused
    runtimePkgs.gawk
    runtimePkgs.findutils
    runtimePkgs.git
    runtimePkgs.bash
  ];
  applicationUnits = map (name: "overleaf-${name}") [
    "chat"
    "clsi"
    "contacts"
    "docstore"
    "document-updater"
    "filestore"
    "git-bridge"
    "history-v1"
    "notifications"
    "project-history"
    "real-time"
    "references"
    "web"
  ];
in
{
  imports = [
    inputs.overleaf-nix.nixosModules.overleaf
  ];

  # The existing database uses FCV 7.0 and cannot be opened directly by the
  # MongoDB 8.2 package in nixos-25.11.
  services.mongodb.package = runtimePkgs.mongodb-ce.overrideAttrs (_: {
    version = "8.0.28";
    src = runtimePkgs.fetchurl {
      url = "https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-ubuntu2404-8.0.28.tgz";
      hash = "sha256-MCC+2HO/6oaNc4jDpK/1lIxHaijNrD6JSu8wnv5RAPI=";
    };
  });
  services.redis.package = runtimePkgs.redis;
  services.nginx.package = runtimePkgs.nginxStable;

  services.overleaf = {
    enable = true;
    package = inputs.overleaf-nix.packages.${hostSystem}.overleaf;

    # The public connector runs on Karkinos. Keep the application loopback-only
    # and publish one narrowly scoped origin on Oppy's Tailscale address below.
    host = "127.0.0.1";
    port = 18080;
    openFirewall = false;
    siteUrl = "https://overleaf.quasimorphic.com";
    appName = "Quasimorphic Overleaf";

    gitBridge = {
      enable = true;
      package = runtimePkgs.callPackage ./overleaf-git-bridge.nix { };
      apiBaseUrl = "http://127.0.0.1:18080/api/v0";
    };
  };

  # Common networking disables the NixOS firewall, so enforce the origin's
  # Karkinos-only trust boundary in a dedicated, narrowly scoped nftables table.
  networking.nftables = {
    enable = true;
    tables.overleaf-origin = {
      family = "inet";
      content = ''
        chain input {
          type filter hook input priority filter; policy accept;
          iifname "tailscale0" ip daddr ${privateOriginAddress} tcp dport 18080 ip saddr ${karkinosAddress} accept
          ip daddr ${privateOriginAddress} tcp dport 18080 drop
        }
      '';
    };
  };

  # Karkinos reaches only this Tailscale-bound socket. Overleaf's nginx vhost,
  # MongoDB, Redis, and every Node service remain bound to loopback on Oppy.
  systemd.sockets.overleaf-private-origin = {
    description = "Private Tailscale origin socket for Overleaf";
    wantedBy = [ "sockets.target" ];
    listenStreams = [ "${privateOriginAddress}:18080" ];
    socketConfig.FreeBind = true;
  };

  # Keep Node, TeX, PDF, and shell tools on the pinned Overleaf package set
  # instead of mixing them with Oppy's nixos-25.11 packages.
  systemd.services =
    (lib.genAttrs applicationUnits (_: {
      path = lib.mkForce overleafRuntimePath;
    }))
    // {
      overleaf-migrations.path = lib.mkForce [
        overleafCfg.package
        runtimePkgs.nodejs_24
        runtimePkgs.bash
        runtimePkgs.coreutils
      ];

      overleaf-private-origin = {
        description = "Private Overleaf origin for Karkinos";
        after = [
          "nginx.service"
          "overleaf-web.service"
        ];
        serviceConfig = {
          ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd 127.0.0.1:18080";
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
    };
}

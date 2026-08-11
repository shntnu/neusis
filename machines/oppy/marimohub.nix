{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  hubHost = "marimohub.quasimorphic.com";
  hubUrl = "https://${hubHost}";
  hostSystem = pkgs.stdenv.hostPlatform.system;
  marimohubEnv = config.age.secrets.marimohub-env.path;
  privateOriginAddress = "100.79.40.39";

  collaboratorEmails = [
    "alan@quasimorphic.com"
    "shsingh@broadinstitute.org"
    # Add collaborators here, then add the matching bcrypt hash to
    # secrets/oppy/marimohub.env.age. The env var name is derived from the email,
    # e.g. jane.doe@example.com -> DEX_JANE_DOE_EXAMPLE_COM_PASSWORD_HASH.
    # "collaborator@example.com"
  ];

  mkDexUser =
    email:
    let
      username = email;
      passwordHashEnvStem = lib.toUpper (
        builtins.replaceStrings
          [
            "@"
            "."
            "-"
            "+"
          ]
          [
            "_"
            "_"
            "_"
            "_"
          ]
          email
      );
    in
    {
      inherit email username;
      userId = email;
      passwordHashEnv = "DEX_${passwordHashEnvStem}_PASSWORD_HASH";
    };

  dexUsers = map mkDexUser collaboratorEmails;
  dexPasswordHashEnvVars = map (user: user.passwordHashEnv) dexUsers;

  backupMarimohubStorage = pkgs.writeShellScript "backup-marimohub-storage-before-0.3.0" ''
    set -eu

    state=/var/lib/marimohub
    backup="$state/backups/pre-0.3.0-storage"
    partial="$backup.partial"

    if [ -d "$state/storage" ] && [ ! -e "$backup" ]; then
      ${pkgs.coreutils}/bin/mkdir -p "$state/backups"
      ${pkgs.coreutils}/bin/rm -rf "$partial"
      ${pkgs.coreutils}/bin/cp -a --reflink=auto "$state/storage" "$partial"
      ${pkgs.coreutils}/bin/mv "$partial" "$backup"
    fi
  '';

  checkMarimohubEnv = pkgs.writeShellScript "check-marimohub-env" ''
    set -eu

    required_vars="
      MARIMOHUB_AUTH_OIDC_CLIENT_SECRET
      MARIMOHUB_AUTH_SESSION_SECRET
      MARIMOHUB_SUPER_ADMINS
      MARIMOHUB_SECRETS_KEK
      ${lib.concatStringsSep "\n      " dexPasswordHashEnvVars}
    "

    for name in $required_vars; do
      eval "value=\''${$name-}"
      if [ -z "$value" ]; then
        echo "marimohub secret env is missing $name" >&2
        exit 1
      fi
      case "$value" in
        *replace-me*|*replace-with*|*example.com*|*you@*)
          echo "marimohub secret env still contains placeholder value for $name" >&2
          exit 1
          ;;
      esac
    done
  '';
in
{
  imports = [
    inputs.marimohub-nix.nixosModules.marimohub
  ];

  age.secrets = {
    marimohub-env = {
      file = ../../secrets/oppy/marimohub.env.age;
      owner = "root";
      group = "root";
      mode = "0400";
    };
  };

  services.marimohub = {
    enable = true;
    package = inputs.marimohub-nix.packages.${hostSystem}.marimohub;
    listenAddress = "127.0.0.1";
    # Oppy's monitoring stack already uses 3000 for Grafana.
    port = 18081;
    openFirewall = false;

    # Rootless Podman gives each live notebook kernel its own container without
    # exposing a root-equivalent Docker socket to the hub service.
    podman = {
      enable = true;
      image = inputs.marimohub-nix.packages.${hostSystem}.sandbox-image;
      imageReference = inputs.marimohub-nix.packages.${hostSystem}.sandbox-image.imageReference;
    };

    dex = {
      enable = true;
      issuer = "${hubUrl}/dex";
      redirectUri = "${hubUrl}/api/auth/callback";
      environmentFile = marimohubEnv;
      allowInsecureHttp = false;
      users = dexUsers;
    };

    settings = {
      MARIMOHUB_APP_BASE_URL = hubUrl;

      MARIMOHUB_STORAGE_BACKEND = "fs";
      MARIMOHUB_STORAGE_FS_ROOT = "/var/lib/marimohub/storage";

      MARIMOHUB_AUTH_BACKEND = "oidc";

      # The URL is public, but access is collaborator-only through the local
      # Dex username/password accounts declared above.
      MARIMOHUB_DEFAULT_ROLE = "none";

      # Trusted collaborators: viewers may start private live kernels whose
      # edits are discarded. This tier also permits shared "Run as app" usage.
      MARIMOHUB_VIEWER_MODE = "ephemeral-sandbox";

      # Trusted-team default. Switch to "exclusive" if collaborators routinely
      # step on each other's live editor kernel state.
      MARIMOHUB_EDITOR_SANDBOX_SHARING = "shared";

      # The hub proxies private loopback kernel ports; do not expose sandbox
      # ports directly through Cloudflare or the firewall.
      MARIMOHUB_SANDBOX_EXPOSURE = "proxy";
      MARIMOHUB_SANDBOX_PROXY_ACK_UNTRUSTED = true;

      # Enables the Environment variables integration used to inject the
      # project-level GENEGENIE_TOKEN into fgx notebook sessions.
      MARIMOHUB_INTEGRATIONS = "on";

      MARIMOHUB_RUN_MAINTENANCE = true;
      MARIMOHUB_MAX_SESSIONS_PER_USER = 5;
      MARIMOHUB_MAX_APPS_PER_PROJECT = 20;
      MARIMOHUB_SESSION_IDLE_TIMEOUT_SECONDS = 1800;
      MARIMOHUB_SESSION_MAX_LIFETIME_SECONDS = 14400;
    };
  };

  # Take one consistent, service-stopped snapshot before the first 0.3.0 start.
  # The immutable destination also makes later restarts idempotent.
  systemd.services.marimohub.serviceConfig.ExecStartPre = [
    backupMarimohubStorage
    checkMarimohubEnv
  ];

  virtualisation.podman.autoPrune.enable = true;

  # Keep both application origins loopback-only, with narrowly scoped private
  # origin sockets for the external connector.
  systemd.sockets.marimohub-private-origin = {
    description = "Private origin socket for marimohub";
    wantedBy = [ "sockets.target" ];
    listenStreams = [ "${privateOriginAddress}:18081" ];
    socketConfig.FreeBind = true;
  };

  systemd.services.marimohub-private-origin = {
    description = "Private marimohub origin";
    after = [ "marimohub.service" ];
    serviceConfig = {
      ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd 127.0.0.1:18081";
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

  systemd.sockets.dex-private-origin = {
    description = "Private origin socket for marimohub Dex";
    wantedBy = [ "sockets.target" ];
    listenStreams = [ "${privateOriginAddress}:5556" ];
    socketConfig.FreeBind = true;
  };

  systemd.services.dex-private-origin = {
    description = "Private Dex origin";
    after = [ "dex.service" ];
    serviceConfig = {
      ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd 127.0.0.1:5556";
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
}

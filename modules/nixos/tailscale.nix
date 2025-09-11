{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.neusis.tailscale;
  forceClaimHostName =
    mkIf
      (
        cfg.forceHostName
        && cfg.clientIdFile != null
        && cfg.clientSecretFile != null
        && cfg.tailnetOrg != null
        && cfg.hostName != null
      )
      (
        pkgs.writeShellScript "tailscale-forceClaimHost" ''
          # Read OAuth credentials from agenix secrets
          TS_CLIENT_ID=''$(cat ${config.age.secrets.ts-client-id.path})
          TS_CLIENT_SECRET=''$(cat ${config.age.secrets.ts-client-secret.path})
          TAILNET_ORG=${toString cfg.tailnetOrg}
          NODE_NAME=${toString cfg.hostName}

          # Get OAuth token
          export TOKEN=''$(curl -s -d "client_id=''${TS_CLIENT_ID}" -d "client_secret=''${TS_CLIENT_SECRET}" "https://api.tailscale.com/api/v2/oauth/token" | jq -r '.access_token')

          # Check if token was obtained successfully
          if [ "''${TOKEN}" = "null" ] || [ -z "''${TOKEN}" ]; then
            echo "Failed to obtain OAuth token"
            exit 1
          fi

          # Delete old device with same hostname
          echo "Checking for existing devices with hostname: ''${NODE_NAME}"
          IDS=''$(curl -s "https://api.tailscale.com/api/v2/tailnet/''${TAILNET_ORG}/devices" -H "Authorization: Bearer ''${TOKEN}" | jq -r ".devices[] | select(.hostname | contains(\"''${NODE_NAME}\")) | .nodeId")

          if [ ! -z "''${IDS}" ]; then
            for ID in ''${IDS}; do
              echo "Deleting device ''${ID} with hostname ''${NODE_NAME}";
              curl -s -X DELETE "https://api.tailscale.com/api/v2/device/''${ID}" -H "Authorization: Bearer ''${TOKEN}"
            done
          else
            echo "No existing devices found with hostname: ''${NODE_NAME}"
          fi
        ''
      );

  disableKeyExpiryScript =
    mkIf
      (
        cfg.disableKeyExpiry
        && cfg.clientIdFile != null
        && cfg.clientSecretFile != null
        && cfg.tailnetOrg != null
        && cfg.hostName != null
      )
      (
        pkgs.writeShellScript "tailscale-disable-key-expiry" ''
          # Read OAuth credentials from agenix secrets
          TS_CLIENT_ID=''$(cat ${config.age.secrets.ts-client-id.path})
          TS_CLIENT_SECRET=''$(cat ${config.age.secrets.ts-client-secret.path})
          TAILNET_ORG=${toString cfg.tailnetOrg}
          NODE_NAME=${toString cfg.hostName}

          # Get OAuth token
          export TOKEN=''$(curl -s -d "client_id=''${TS_CLIENT_ID}" -d "client_secret=''${TS_CLIENT_SECRET}" "https://api.tailscale.com/api/v2/oauth/token" | jq -r '.access_token')

          # Check if token was obtained successfully
          if [ "''${TOKEN}" = "null" ] || [ -z "''${TOKEN}" ]; then
            echo "Failed to obtain OAuth token for key expiry disable"
            exit 1
          fi

          # Wait for device to appear in the tailnet (retry for up to 60 seconds)
          echo "Waiting for device with hostname ''${NODE_NAME} to appear in tailnet..."
          for i in $(seq 1 12); do
            DEVICE_ID=''$(curl -s "https://api.tailscale.com/api/v2/tailnet/''${TAILNET_ORG}/devices" -H "Authorization: Bearer ''${TOKEN}" | jq -r ".devices[] | select(.hostname == \"''${NODE_NAME}\") | .nodeId")
            
            if [ ! -z "''${DEVICE_ID}" ] && [ "''${DEVICE_ID}" != "null" ]; then
              echo "Found device ''${DEVICE_ID} with hostname ''${NODE_NAME}"
              echo "Disabling key expiry for device ''${DEVICE_ID}"
              curl -s -X POST "https://api.tailscale.com/api/v2/device/''${DEVICE_ID}/expire" -H "Authorization: Bearer ''${TOKEN}"
              echo "Key expiry disabled for device ''${DEVICE_ID}"
              exit 0
            fi
            
            echo "Device not found yet, waiting 5 seconds... (attempt $i/12)"
            sleep 5
          done

          echo "Warning: Could not find device with hostname ''${NODE_NAME} to disable key expiry"
          exit 1
        ''
      );
in
{
  options = {
    neusis.tailscale = {
      enable = mkEnableOption "Enable Neusis tailscale config";

      authkey_file = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Path to the age tsauthkey file.";
      };

      persistent_authkey_file = mkOption {
        type = types.path;
        default = ../../secrets/common/persistent_tsauthkey.age;
        description = "Path to the persistent age tsauthkey file.";
      };

      ephemeral_authkey_file = mkOption {
        type = types.path;
        default = ../../secrets/common/ephemeral_tsauthkey.age;
        description = "Path to the ephemeral age tsauthkey file.";
      };

      isPersistent = mkOption {
        type = types.bool;
        default = false;
        description = "Use userspace networking.";
      };

      isUserSpace = mkOption {
        type = types.bool;
        default = false;
        description = "Use userspace networking.";
      };

      hostName = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Custom hostname to use.";
      };

      forceHostName = mkOption {
        type = types.nullOr types.bool;
        default = true;
        description = ''
          Force claim hostname on the tailnet.
          This will remove the existing device with this hostname
        '';
      };

      clientIdFile = mkOption {
        type = types.nullOr types.path;
        default = ../../secrets/common/tsclient.age;
        description = "Path to the age file containing Tailscale OAuth client ID.";
      };

      clientSecretFile = mkOption {
        type = types.nullOr types.path;
        default = ../../secrets/common/tssecret.age;
        description = "Path to the age file containing Tailscale OAuth client secret.";
      };

      tailnetOrg = mkOption {
        type = types.nullOr types.str;
        default = "leoank.github";
        description = "Tailscale organization/tailnet name.";
      };

      disableKeyExpiry = mkOption {
        type = types.bool;
        default = false;
        description = "Disable key expiry for the device after connection.";
      };

    };
  };

  config = lib.mkIf cfg.enable {

    # make the tailscale command usable to users
    environment.systemPackages = [ pkgs.tailscale ];

    # add agenix auth key
    age.secrets.tsauthkey.file =
      if cfg.authkey_file != null then
        cfg.authkey_file
      else if cfg.isPersistent then
        cfg.persistent_authkey_file
      else
        cfg.ephemeral_authkey_file;

    # add agenix OAuth secrets for force hostname functionality
    age.secrets = mkIf (cfg.forceHostName && cfg.clientIdFile != null && cfg.clientSecretFile != null) {
      ts-client-id.file = cfg.clientIdFile;
      ts-client-secret.file = cfg.clientSecretFile;
    };

    # enable the tailscale service
    services.tailscale = {
      enable = true;
      authKeyFile = config.age.secrets.tsauthkey.path;
      extraUpFlags = mkIf (cfg.hostName != null) [
        "--hostname"
        "${cfg.hostName}"
      ];
    };

    # Add ExecStartPre for force hostname functionality
    systemd.services.tailscaled.serviceConfig =
      mkIf
        (
          cfg.forceHostName
          && cfg.clientIdFile != null
          && cfg.clientSecretFile != null
          && cfg.tailnetOrg != null
          && cfg.hostName != null
        )
        {
          ExecStartPre = forceClaimHostName;
        };

    # Add systemd service to disable key expiry after connection
    systemd.services.tailscale-disable-key-expiry =
      mkIf
        (
          cfg.disableKeyExpiry
          && cfg.clientIdFile != null
          && cfg.clientSecretFile != null
          && cfg.tailnetOrg != null
          && cfg.hostName != null
        )
        {
          description = "Disable Tailscale key expiry";
          after = [ "tailscaled-autoconnect.service" ];
          wants = [ "tailscaled-autoconnect.service" ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = disableKeyExpiryScript;
            User = "root";
            RemainAfterExit = true;
          };
        };

    # nixos/tailscale: tailscaled-autoconnect.service prevents multi-user.target from reaching "active" state when server errors #430756
    # https://github.com/NixOS/nixpkgs/issues/430756
    #systemd.services.tailscaled-autoconnect.serviceConfig.TimeoutStartSec = "30s";
    systemd.services.tailscaled-autoconnect.serviceConfig.Type = lib.mkForce "simple";

  };
}

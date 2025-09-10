{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.neusis.tailscale;
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

    # enable the tailscale service
    services.tailscale = {
      enable = true;
      authKeyFile = config.age.secrets.tsauthkey.path;
      extraUpFlags = mkIf (cfg.hostName != null) [
        "--hostname"
        "${cfg.hostName}"
      ];
    };

    # nixos/tailscale: tailscaled-autoconnect.service prevents multi-user.target from reaching "active" state when server errors #430756
    # https://github.com/NixOS/nixpkgs/issues/430756
    #systemd.services.tailscaled-autoconnect.serviceConfig.TimeoutStartSec = "30s";
    systemd.services.tailscaled-autoconnect.serviceConfig.Type = lib.mkForce "simple";

  };
}

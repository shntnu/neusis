{
  config,
  lib,
  pkgs,
  ...
}:
let
  package = pkgs.callPackage ./package.nix { };
  home = config.home.homeDirectory;
in
{
  home.packages = [ package ];
  # Also supports a targeted rollout without replacing the full user profile.
  home.file.".local/bin/t3".source = lib.getExe package;
  # Keep the CLI's service-status/access model consistent with the actual unit.
  # This store-backed file must never contain credentials.
  home.file.".t3/service.env".text = ''
    T3CODE_HOST=127.0.0.1
    T3CODE_PORT=3773
    T3CODE_LAN=false
  '';

  systemd.user.services.t3code = {
    Unit = {
      Description = "Personal T3 Code server (SSH-tunnel access only)";
      Documentation = [ "https://github.com/pingdotgg/t3code" ];
      ConditionHost = "oppy";
    };
    Service = {
      Type = "simple";
      ExecStart = "${lib.getExe package} serve --host 127.0.0.1 --port 3773 --no-browser";
      WorkingDirectory = home;
      Environment = [
        "HOME=${home}"
        # Store paths keep provider discovery independent of stale login profiles.
        "PATH=${
          lib.makeBinPath [
            pkgs.codex
            pkgs.claude-code
          ]
        }:${home}/.local/bin:${home}/.nix-profile/bin:/etc/profiles/per-user/${config.home.username}/bin:/run/wrappers/bin:/run/current-system/sw/bin"
        "T3CODE_HOME=${home}/.t3"
        "T3CODE_HOST=127.0.0.1"
        "T3CODE_PORT=3773"
        "T3CODE_LAN=false"
      ];
      UMask = "0077";
      Restart = "on-failure";
      RestartSec = 5;
      TimeoutStopSec = 30;
    };
    Install.WantedBy = [ "default.target" ];
  };
}

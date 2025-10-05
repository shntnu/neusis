# CSLab Monitoring Configuration
#
# Implements monitoring policies for Oppy:
# - Weekly quota checks (Mondays 9 AM)
# - Future: Daily scratch cleanup (90-day retention)
#
# References:
# - imaging-server-maintenance/policies/data-storage.md (quota monitoring)
# - imaging-server-maintenance/scripts/monitoring/check-quotas.nu
#
# Note: This is oppy-specific. When Spirit migrates to NixOS, extract to
# modules/nixos/cslab-monitoring.nix if identical setup needed.

{ config, lib, pkgs, ... }:

{
  # Slack webhook secret for quota notifications
  age.secrets.slack_webhook = {
    file = ../../secrets/oppy/slack_webhook.age;
    mode = "400";  # Read-only by root
    owner = "root";
  };
  # Weekly quota monitoring - Mondays at 9 AM
  systemd.timers.cslab-check-quotas = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "Mon *-*-* 09:00:00";  # Weekly on Monday morning
      Persistent = true;  # Run on boot if missed
      RandomizedDelaySec = "5m";  # Spread load if multiple servers
    };
  };

  systemd.services.cslab-check-quotas = {
    description = "CSLab Home Directory Quota Check";

    # Script requires fd for file search
    path = [ pkgs.fd ];

    serviceConfig = {
      Type = "oneshot";
      User = "root";  # Needs root to read all user directories

      # Environment variables for script configuration
      Environment = [
        "HOME_BASE_DIR=/home"
        "QUOTA_GB=100"
        "LARGE_FILE_GB=1"
        "LOG_DIR=/var/log/lab-scripts"
      ];

      # Script exits with code 2 when users need action (by design)
      # Treat this as success so systemd doesn't report failures
      SuccessExitStatus = [ 0 2 ];
    };

    script = ''
      # Create log directory
      mkdir -p /var/log/lab-scripts

      # Load Slack webhook URL from secret
      export SLACK_WEBHOOK_URL=$(cat ${config.age.secrets.slack_webhook.path})

      # Run quota check script with Slack notifications enabled
      ${pkgs.nushell}/bin/nu ${./scripts/check-quotas.nu}
    '';
  };

  # Future: Scratch cleanup (90-day retention policy)
  # Uncomment when scratch-cleanup.nu script is ready
  #
  # systemd.timers.cslab-scratch-cleanup = {
  #   wantedBy = [ "timers.target" ];
  #   timerConfig = {
  #     OnCalendar = "daily";
  #     Persistent = true;
  #   };
  # };
  #
  # systemd.services.cslab-scratch-cleanup = {
  #   description = "CSLab Scratch Directory Cleanup (90-day retention)";
  #   serviceConfig = {
  #     Type = "oneshot";
  #     User = "root";
  #   };
  #   script = ''
  #     ${pkgs.nushell}/bin/nu /path/to/scratch-cleanup.nu
  #   '';
  # };
}

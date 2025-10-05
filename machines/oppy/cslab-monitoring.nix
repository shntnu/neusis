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

      # SLACK_WEBHOOK_URL should be set via agenix secret when Slack integration is added
      # For now, script will run without notifications (logs only)
    };

    # Script execution
    # TODO: Update path to point to actual script location
    # Options:
    #   1. Copy script to /etc/cslab-scripts/ via systemd.tmpfiles
    #   2. Reference from imaging-server-maintenance repo
    #   3. Package script in neusis
    script = ''
      # Create log directory if it doesn't exist
      mkdir -p /var/log/lab-scripts

      # TODO: Replace with actual script path
      # For now, this is a placeholder that logs execution
      echo "[$(date -Iseconds)] CSLab quota check triggered (script not yet configured)" >> /var/log/lab-scripts/check-quotas.log

      # Future implementation:
      # ${pkgs.nushell}/bin/nu /path/to/check-quotas.nu
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

# CSLab Monitoring Configuration
#
# Implements monitoring policies for Oppy:
# - Weekly quota checks (Mondays 9 AM)
# - Weekly group membership checks (Wednesdays 9 AM)
# - Future: Daily scratch cleanup (90-day retention)
#
# References:
# - imaging-server-maintenance/policies/data-storage.md (quota monitoring)
# - imaging-server-maintenance/policies/user-access.md (group membership)
# - imaging-server-maintenance/scripts/monitoring/check-quotas.nu
#
# Note: This is oppy-specific. When Spirit migrates to NixOS, extract to
# modules/nixos/cslab-monitoring.nix if identical setup needed.

{ config, lib, pkgs, ... }:

let
  # Import cslab user config to derive expected group memberships
  cslabUserConfig = import ../../../users/cslab.nix { inherit pkgs; };

  # Extract usernames by type
  adminUsernames = builtins.map (u: u.username) cslabUserConfig.admins;
  regularUsernames = builtins.map (u: u.username) cslabUserConfig.regulars;

  # Generate group violation check script
  checkGroupsScript = pkgs.writeShellScript "check-groups.sh" ''
    LOG_FILE=/var/log/lab-scripts/group-violations.log
    mkdir -p /var/log/lab-scripts

    VIOLATIONS=""
    TIMESTAMP=$(date -Iseconds)

    # Check regulars don't have wheel group (unauthorized sudo)
    REGULARS="${lib.concatStringsSep " " regularUsernames}"
    for user in $REGULARS; do
      if groups "$user" | grep -qw wheel; then
        VIOLATIONS="$VIOLATIONS- $user has wheel group (unauthorized sudo)\n"
      fi
    done

    # Check admins DO have wheel group (expected sudo)
    ADMINS="${lib.concatStringsSep " " adminUsernames}"
    for user in $ADMINS; do
      if ! groups "$user" | grep -qw wheel; then
        VIOLATIONS="$VIOLATIONS- $user missing wheel group (admin should have sudo)\n"
      fi
    done

    # Report violations if found
    if [ -n "$VIOLATIONS" ]; then
      echo "[$TIMESTAMP] Group violations detected" >> "$LOG_FILE"
      echo -e "$VIOLATIONS" >> "$LOG_FILE"

      # Send Slack notification
      if [ -n "$SLACK_WEBHOOK_URL" ]; then
        curl -X POST -H 'Content-type: application/json' \
          --data "{\"text\":\"🚨 Security Alert: Group membership violations detected on Oppy\n\n$VIOLATIONS\nRun \`nixos-rebuild switch\` to enforce correct groups.\"}" \
          "$SLACK_WEBHOOK_URL" 2>&1 | tee -a "$LOG_FILE"
      fi

      exit 2  # Exit code 2 = violations found
    else
      echo "[$TIMESTAMP] No group violations detected" >> "$LOG_FILE"
      exit 0
    fi
  '';
in
{
  # Slack webhook secret for quota notifications
  age.secrets.slack_webhook = {
    file = ../../../secrets/oppy/slack_webhook.age;
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

  # Weekly group membership monitoring - Wednesdays at 9 AM
  systemd.timers.cslab-check-groups = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "Wed *-*-* 09:00:00";  # Weekly on Wednesday morning
      Persistent = true;  # Run on boot if missed
      RandomizedDelaySec = "5m";  # Spread load if multiple servers
    };
  };

  systemd.services.cslab-check-groups = {
    description = "CSLab Group Membership Violation Check";

    serviceConfig = {
      Type = "oneshot";
      User = "root";  # Needs root to check all users

      # Exit code 2 = violations found (by design)
      # Treat this as success so systemd doesn't report failures
      SuccessExitStatus = [ 0 2 ];
    };

    script = ''
      # Load Slack webhook URL from secret
      export SLACK_WEBHOOK_URL=$(cat ${config.age.secrets.slack_webhook.path})

      # Run group violation check script
      ${checkGroupsScript}
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

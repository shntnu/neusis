# CSLab Infrastructure Configuration
#
# Implements cslab-specific policies for Oppy:
# - imaging group for all lab members
# - /work/* directory structure (datasets, users, scratch, tools)
# - Per-user directories with correct ownership and permissions
#
# References:
# - imaging-server-maintenance/policies/user-access.md
# - imaging-server-maintenance/policies/data-storage.md
#
# Note: This is oppy-specific. When Spirit migrates to NixOS, extract to
# modules/nixos/cslab-infrastructure.nix if identical setup needed.

{ config, lib, pkgs, ... }:

let
  # Import cslab user config directly to avoid circular dependency
  # (reading config.users.users while defining users.users causes infinite recursion)
  cslabUserConfig = import ../../users/cslab.nix { inherit pkgs; };

  # Extract usernames from all user categories (admins, regulars, locked, guests)
  allCslabUsers =
    (builtins.map (u: u.username) cslabUserConfig.admins) ++
    (builtins.map (u: u.username) cslabUserConfig.regulars) ++
    (builtins.map (u: u.username) (cslabUserConfig.locked or [])) ++
    (builtins.map (u: u.username) cslabUserConfig.guests);

  cslabUsers = allCslabUsers;

  # Emergency accounts that must NEVER be in user configuration
  emergencyAccounts = [ "exx" "root" ];

  # Check if any emergency accounts are in the configuration
  emergencyAccountViolations = builtins.filter
    (account: builtins.elem account allCslabUsers)
    emergencyAccounts;

in
{
  # Build-time safety check: Fail if emergency accounts in config
  assertions = [
    {
      assertion = emergencyAccountViolations == [];
      message = ''
        CRITICAL BUILD FAILURE: Emergency accounts detected in users/cslab.nix

        Accounts found: ${builtins.toString emergencyAccountViolations}

        The following accounts must NEVER be managed by this configuration:
        - exx: Emergency admin account (prevents lockout)
        - root: System root account (security critical)

        Action required: Remove these accounts from users/cslab.nix immediately.
      '';
    }
  ];
  # Create imaging group for all lab members
  users.groups.imaging = {
    gid = 1000; # Consistent GID across reinstalls
  };

  # Add imaging group to all cslab users
  # Note: This modifies the users already created by neusisOS.mkAdmin/mkRegular
  users.users = lib.genAttrs cslabUsers (username: {
    extraGroups = [ "imaging" ];
  });

  # Create /work directory structure
  # Using systemd-tmpfiles for declarative directory creation
  systemd.tmpfiles.rules = [
    # Main work directory
    "d /work 0750 root imaging - -"

    # Subdirectories for data organization (see policies/data-storage.md)
    "d /work/datasets 0750 root imaging - -"      # Reference data (read-only)
    "d /work/users 0750 root imaging - -"         # Project workspaces
    "d /work/scratch 0750 root imaging - -"       # Temporary workspace (90-day retention)
    "d /work/tools 0750 root imaging - -"         # Shared software
    "d /work/users/_archive 0750 root imaging - -" # Archived user data
  ];

  # Create per-user directories in /work/users and /work/scratch
  # These are created at system activation (boot or nixos-rebuild switch)
  system.activationScripts.cslabUserDirectories = lib.stringAfter [ "users" ] ''
    # Create user-specific directories
    ${lib.concatMapStringsSep "\n" (user: ''
      # /work/users/<username> - project workspace
      mkdir -p /work/users/${user}
      chown ${user}:imaging /work/users/${user}
      chmod 750 /work/users/${user}

      # /work/scratch/<username> - temporary files
      mkdir -p /work/scratch/${user}
      chown ${user}:imaging /work/scratch/${user}
      chmod 750 /work/scratch/${user}
    '') cslabUsers}

    echo "CSLab user directories created/verified for: ${lib.concatStringsSep ", " cslabUsers}"
  '';
}

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
  # See this comment thread for alternatives
  # https://github.com/leoank/neusis/pull/36#discussion_r2490494840
  cslabUserConfig = import ../../../users/cslab.nix { inherit pkgs; };

  # Extract usernames from all user categories (admins, regulars, locked, guests)
  allCslabUsers =
    (builtins.map (u: u.username) cslabUserConfig.admins) ++
    (builtins.map (u: u.username) cslabUserConfig.regulars) ++
    (builtins.map (u: u.username) (cslabUserConfig.locked or [])) ++
    (builtins.map (u: u.username) cslabUserConfig.guests);

  cslabUsers = allCslabUsers;

  # Ensure root account is never in user configuration
  # (root is a system account that must not be redefined)
  rootInConfig = builtins.elem "root" allCslabUsers;

  # Package test script for system PATH
  testScript = pkgs.writeScriptBin "test-cslab-infrastructure.sh" (builtins.readFile ./scripts/test-cslab-infrastructure.sh);

in
{
  # Build-time safety check: Fail if root account in config
  assertions = [
    {
      assertion = !rootInConfig;
      message = ''
        CRITICAL BUILD FAILURE: 'root' account detected in users/cslab.nix

        The root account is a system account that must not be redefined.

        Action required: Remove 'root' from users/cslab.nix immediately.
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
    "d /work/datasets 0770 root imaging - -"      # Reference data (group writable for REGISTRY.yaml)
    "d /work/users 0750 root imaging - -"         # Project workspaces
    "d /work/scratch 0770 root imaging - -"       # Temporary workspace (group writable)
    "d /work/tools 0770 root imaging - -"         # Shared software (group writable)
    "d /work/users/_archive 0750 root imaging - -" # Archived user data
  ];

  # Create per-user directories in /work/users and /work/scratch
  # Use systemd service to ensure ZFS is mounted before creating directories
  systemd.services.cslab-setup-directories = {
    description = "Setup CSLab user directories and permissions";
    wantedBy = [ "multi-user.target" ];
    after = [ "zfs-mount.service" ];
    requires = [ "zfs-mount.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      # Fix ZFS dataset mount point permissions (disko creates them with defaults)
      # ZFS mounts override systemd.tmpfiles, so we fix them here after mounting
      chown root:imaging /work/datasets /work/tools /work/users/_archive
      chmod 770 /work/datasets /work/tools
      chmod 750 /work/users/_archive

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
  };

  # Add test script to system PATH
  environment.systemPackages = [ testScript ];
}

# Current 6-Drive Configuration for Oppy (3x Kioxia + 3x Kingston, STRIPE)
# Reflects the live `work` pool after the 2026-07-07 non-destructive expansion:
# the 3 original Kioxia were joined by 3 Kingston DC3000ME drives via `zpool add`.
# The 4 temporary Intel SSDPF2KE032T1 drives were pulled first to free U.2 bays.
#
# NOTE: This file is the reinstall blueprint only — disko does NOT run on
# `nixos-rebuild switch`. The live pool was expanded imperatively with
# `zpool add work <3 Kingston by-id>`; this config keeps the repo in sync so a
# future clean install reproduces the same 6-drive layout.
#
# WARNING: NO REDUNDANCY - stripe mode means ANY single drive failure = total
# data loss, now across all 6 drives. Back up non-reproducible data accordingly.
#
# RAIDZ2 MIGRATION (future, now DESTRUCTIVE - pool holds ~39TB of live data):
# Unlike the empty-pool 2025 plan, converting stripe -> raidz2 is not in-place.
# It requires evacuating/confirming all data, then a clean reinstall with
# mode = "raidz2" across the 6 drives (~56TB usable, 2-drive fault tolerance).
# See imaging-server-maintenance assets/disko-raidz2-future.nix.

{
  # Required for testing on virtual machines
  # https://github.com/nix-community/disko/blob/master/docs/interactive-vm.md
  disko.memSize = 16384; # 16GB
  disko.devices = {
    disk = {
      # Root SSD - Samsung 4TB for OS (unchanged from current)
      ssd00 = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-Samsung_SSD_990_PRO_4TB_S7KGNJ0X130041T";
        imageSize = "10G";  # For VM testing
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };

      # 3x Kioxia KCD6XLUL15T3 drives in STRIPE mode (current hardware)
      # Same drives as current zstore16, but organized as "work" pool
      kioxia00 = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-KCD6XLUL15T3_34G0A04DT5R8";  # nvme1n1
        imageSize = "1G";
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "work";  # Changed from "zstore16" to match future config
              };
            };
          };
        };
      };

      kioxia01 = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-KCD6XLUL15T3_34G0A042T5R8";  # nvme4n1
        imageSize = "1G";
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "work";
              };
            };
          };
        };
      };

      kioxia02 = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-KCD6XLUL15T3_34G0A05QT5R8";  # nvme7n1
        imageSize = "1G";
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "work";
              };
            };
          };
        };
      };

      # 3x Kingston DC3000ME 15.36TB drives, added 2026-07-07 via `zpool add`
      # (non-destructive stripe expansion; joined the pool alongside the Kioxia).
      # Live pool added these as whole disks; disko partitions them identically
      # to the Kioxia on a fresh install — same on-disk result.
      kingston00 = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-KINGSTON_SEDC3000ME15T3_TW253100793";
        imageSize = "1G";
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "work";
              };
            };
          };
        };
      };

      kingston01 = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-KINGSTON_SEDC3000ME15T3_TW253100851";
        imageSize = "1G";
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "work";
              };
            };
          };
        };
      };

      kingston02 = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-KINGSTON_SEDC3000ME15T3_TW253101449";
        imageSize = "1G";
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "work";
              };
            };
          };
        };
      };
    };

    # ZFS Pool Configuration
    zpool = {
      work = {
        type = "zpool";
        mode = "";  # STRIPE mode (no redundancy) across all 6 drives.
                    # RAIDZ2 stays the eventual goal but is now a DESTRUCTIVE
                    # rebuild (pool holds live data) - see header notes.

        postCreateHook = "zfs list -t snapshot -H -o name | grep -E '^work@blank$' || zfs snapshot work@blank";

        rootFsOptions = {
          # Pool-level defaults
          mountpoint = "none";
          compression = "lz4";
          atime = "off";
          xattr = "sa";
          acltype = "posixacl";
          dnodesize = "auto";
          normalization = "formD";

          # IMPORTANT: ZFS dataset properties below are ONLY applied during installation.
          # They do NOT update on nixos-rebuild. To change after installation, use:
          # sudo zfs set property=value dataset
          # Example: sudo zfs set com.sun:auto-snapshot:daily=false work/scratch

          # Lean auto-snapshot policy: keep only the most recent daily +
          # monthly (retention counts in modules/nixos/zfs.nix). Frequent /
          # hourly / weekly are disabled at the pool level so the timers
          # skip these datasets entirely.
          "com.sun:auto-snapshot" = "true";
          "com.sun:auto-snapshot:frequent" = "false";
          "com.sun:auto-snapshot:hourly" = "false";
          "com.sun:auto-snapshot:daily" = "true";
          "com.sun:auto-snapshot:weekly" = "false";
          "com.sun:auto-snapshot:monthly" = "true";
        };

        options = {
          ashift = "12";      # 4K sectors
          autotrim = "on";    # TRIM/UNMAP for SSDs
        };

        datasets = {
          # /work/datasets - Reference data (controlled by permissions)
          datasets = {
            type = "zfs_fs";
            options = {
              mountpoint = "/work/datasets";
              dedup = "off";          # Changed from current "on" - better performance
              recordsize = "1M";      # Optimize for large files
              # Keep all snapshots - critical reference data
            };
          };

          # /work/users - Active project workspaces
          users = {
            type = "zfs_fs";
            options = {
              mountpoint = "/work/users";
              dedup = "off";          # Changed from current "on" - better performance
              quota = "20T";          # Prevent runaway usage
              # Reduce snapshot frequency - active work changes often
              "com.sun:auto-snapshot:frequent" = "false";
              "com.sun:auto-snapshot:hourly" = "false";
            };
          };

          # /work/users/_archive - Archived user data
          "users/_archive" = {
            type = "zfs_fs";
            options = {
              mountpoint = "/work/users/_archive";
              compression = "zstd";   # Better compression for cold data
              # Minimal snapshots - data doesn't change
              "com.sun:auto-snapshot:frequent" = "false";
              "com.sun:auto-snapshot:hourly" = "false";
              "com.sun:auto-snapshot:daily" = "false";
              "com.sun:auto-snapshot:weekly" = "false";
            };
          };

          # /work/scratch - Temporary workspace (90-day retention)
          scratch = {
            type = "zfs_fs";
            options = {
              mountpoint = "/work/scratch";
              quota = "10T";                     # Limit scratch space
              # NO snapshots for temp data - must explicitly disable all types
              "com.sun:auto-snapshot" = "false";
              "com.sun:auto-snapshot:frequent" = "false";
              "com.sun:auto-snapshot:hourly" = "false";
              "com.sun:auto-snapshot:daily" = "false";
              "com.sun:auto-snapshot:weekly" = "false";
              "com.sun:auto-snapshot:monthly" = "false";
              sync = "disabled";                 # Max performance, data is temporary
              compression = "lz4";               # Fast compression
              recordsize = "1M";                 # Large records for big files
              atime = "on";                      # Need atime for cleanup policy
            };
          };

          # /work/tools - Shared software and models
          tools = {
            type = "zfs_fs";
            options = {
              mountpoint = "/work/tools";
              dedup = "off";          # Changed from current "on" - better performance
              recordsize = "128K";     # Mixed file sizes
              # Keep all snapshots - protect installations
            };
          };
        };
      };
    };
  };
}

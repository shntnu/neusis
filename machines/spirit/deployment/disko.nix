# 6-Drive Configuration for Spirit (3x Kioxia + 3x Kingston, STRIPE)
# Mirrors oppy's disko layout — same `work` pool, same /work/{datasets,users,scratch,tools}
# dataset structure and snapshot policies.
#
# WARNING: STRIPE mode — any drive failure = total data loss.
#   This matches the current fleet policy for scratch/imaging data; important
#   references live on the ipdata NFS shares which have their own redundancy.
#   Future RAIDZ2 migration is a destructive rebuild (requires a full reinstall).
#
# Intel SSDPF2KE032T1 drives are intentionally NOT declared here — they occupy 2
# bays but are left untouched so they don't entangle the pool. See the
# imaging-server-maintenance MAINTENANCE_LOG.md entry (2026-07-07) for rationale.

{
  # Required for testing on virtual machines
  # https://github.com/nix-community/disko/blob/master/docs/interactive-vm.md
  disko.memSize = 16384; # 16GB
  disko.devices = {
    disk = {
      # Root SSD - Samsung 4TB for OS
      ssd00 = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-Samsung_SSD_990_PRO_4TB_S7KGNU0X502737W";
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

      # 3x Kioxia KCD6XLUL15T3 drives (were in mdraid5 /data on Ubuntu)
      kioxia00 = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-KCD6XLUL15T3_34G0A043T5R8";
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

      kioxia01 = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-KCD6XLUL15T3_34G0A04ST5R8";
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
        device = "/dev/disk/by-id/nvme-KCD6XLUL15T3_34G0A05VT5R8";
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

      # 3x Kingston DC3000ME drives (added 2026-07-07)
      kingston00 = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-KINGSTON_SEDC3000ME15T3_TW253101363";
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
        device = "/dev/disk/by-id/nvme-KINGSTON_SEDC3000ME15T3_TW253100857";
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
        device = "/dev/disk/by-id/nvme-KINGSTON_SEDC3000ME15T3_TW253100922";
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

      # Intel SSDPF2KE032T1 drives (nvme0n1 PHAX35240B063P8CGN,
      # nvme1n1 PHAX352405L33P8CGN) are NOT declared — left untouched.
    };

    # ZFS Pool Configuration
    zpool = {
      work = {
        type = "zpool";
        mode = "";  # STRIPE mode (no redundancy) — matches oppy

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

          # Enable auto-snapshots by default (disable per-dataset as needed)
          "com.sun:auto-snapshot" = "true";
          "com.sun:auto-snapshot:frequent" = "true";  # Every 15 mins, keep 4
          "com.sun:auto-snapshot:hourly" = "true";    # Every hour, keep 24
          "com.sun:auto-snapshot:daily" = "true";     # Every day, keep 31
          "com.sun:auto-snapshot:weekly" = "true";    # Every week, keep 8
          "com.sun:auto-snapshot:monthly" = "true";   # Every month, keep 12
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
              dedup = "off";
              recordsize = "1M";      # Optimize for large files
            };
          };

          # /work/users - Active project workspaces
          users = {
            type = "zfs_fs";
            options = {
              mountpoint = "/work/users";
              dedup = "off";
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
              quota = "10T";
              "com.sun:auto-snapshot" = "false";
              "com.sun:auto-snapshot:frequent" = "false";
              "com.sun:auto-snapshot:hourly" = "false";
              "com.sun:auto-snapshot:daily" = "false";
              "com.sun:auto-snapshot:weekly" = "false";
              "com.sun:auto-snapshot:monthly" = "false";
              sync = "disabled";
              compression = "lz4";
              recordsize = "1M";
              atime = "on";
            };
          };

          # /work/tools - Shared software and models
          tools = {
            type = "zfs_fs";
            options = {
              mountpoint = "/work/tools";
              dedup = "off";
              recordsize = "128K";
            };
          };
        };
      };
    };
  };
}

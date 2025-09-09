{
  disko.memSize = 16384; # 16GB
  disko.devices = {
    disk = {
      # SSD cluster
      ssd0 = {
        type = "disk";
        device = "/dev/nvme1n1";
        imageSize = "3G";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "zroot";
              };
            };
          };
        };
      };
      ssd1 = {
        type = "disk";
        device = "/dev/nvme0n1";
        imageSize = "3G";
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "zroot";
              };
            };
          };
        };
      };
      ssd2 = {
        type = "disk";
        device = "/dev/nvme2n1";
        imageSize = "3G";
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "zroot";
              };
            };
          };
        };
      };

      # HDD cluster
      hdd0 = {
        type = "disk";
        device = "/dev/sda";
        imageSize = "1G";
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "zstore";
              };
            };
          };
        };
      };

      hdd1 = {
        type = "disk";
        device = "/dev/sdb";
        imageSize = "1G";
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "zstore";
              };
            };
          };
        };
      };

      hdd2 = {
        type = "disk";
        device = "/dev/sdc";
        imageSize = "1G";
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "zstore";
              };
            };
          };
        };
      };
    };
    # Z pool definitions
    zpool = {
      zroot = {
        type = "zpool";
        mode = "";
        postCreateHook = "zfs list -t snapshot -H -o name | grep -E '^zroot@blank$' || zfs snapshot zroot@blank";
        rootFsOptions = {
          # Make sure these options are correct
          mountpoint = "none";
          acltype = "posixacl";
          dnodesize = "auto";
          normalization = "formD";
          atime = "off";
          compression = "lz4";
          xattr = "sa";
          "com.sun:auto-snapshot" = "false";
        };
        options.ashift = "12";
        options.autotrim = "on";

        datasets = {
          "root" = {
            type = "zfs_fs";
            mountpoint = "/";
          };
          "nix" = {
            type = "zfs_fs";
            mountpoint = "/nix";
          };
        };
      };

      zstore = {
        type = "zpool";
        mode = "";
        postCreateHook = "zfs list -t snapshot -H -o name | grep -E '^zstore@blank$' || zfs snapshot zstore@blank";
        rootFsOptions = {
          # Make sure these options are correct
          mountpoint = "none";
          acltype = "posixacl";
          dnodesize = "auto";
          normalization = "formD";
          atime = "off";
          compression = "lz4";
          xattr = "sa";
          "com.sun:auto-snapshot" = "true";
        };
        options.ashift = "12";
        options.autotrim = "on";

        datasets = {
          datastore = {
            type = "zfs_fs";
            options = {
              mountpoint = "/datastore";
            };
          };
        };
      };
    };
  };
}

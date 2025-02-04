{
  disko.devices = {
    disk = {
      # root ssd - 4 TB Drive
      ssd00 = {
        type = "disk";
        device = "/dev/nvme7n1";
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

      # SSD cluster kioxia 3 * 16TB drives
      kioxia00 = {
        type = "disk";
        device = "/dev/nvme2n1";
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "zstore16";
              };
            };
          };
        };
      };
      kioxia01 = {
        type = "disk";
        device = "/dev/nvme5n1";
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "zstore16";
              };
            };
          };
        };
      };
      kioxia02 = {
        type = "disk";
        device = "/dev/nvme6n1";
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "zstore16";
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
        rootFsOptions = {
          # Make sure these options are correct
          canmount = "off";
          acltype = "posixacl";
          dnodesize = "auto";
          normalization = "formD";
          atime = "off";
          compression = "lz4";
          mountpoint = "none";
          xattr = "sa";
          "com.sun:auto-snapshot" = "false";
        };
        options.ashift = "12";
        options.autotrim = "on";

        datasets = {
          "local" = {
            type = "zfs_fs";
            options.mountpoint = "none";
          };
          "local/home" = {
            type = "zfs_fs";
            mountpoint = "/home";
            options."com.sun:auto-snapshot" = "true";
          };
          "local/nix" = {
            type = "zfs_fs";
            mountpoint = "/nix";
            options."com.sun:auto-snapshot" = "false";
          };
          "local/root" = {
            type = "zfs_fs";
            mountpoint = "/";
            options."com.sun:auto-snapshot" = "false";
            postCreateHook = "zfs snapshot zroot/local/root@blank";
          };
        };
      };

      zstore16 = {
        type = "zpool";
        mode = "";
        rootFsOptions = {
          # Make sure these options are correct
          canmount = "off";
          acltype = "posixacl";
          dnodesize = "auto";
          normalization = "formD";
          atime = "off";
          compression = "lz4";
          mountpoint = "none";
          xattr = "sa";
          "com.sun:auto-snapshot" = "false";
        };
        options.ashift = "12";
        options.autotrim = "on";

        datasets = {
          datastore = {
            type = "zfs_fs";
            mountpoint = "/datastore16";
            options."com.sun:auto-snapshot" = "false";
            postCreateHook = "zfs snapshot zstore16/datastore@blank";
          };
        };
      };
    };
  };
}

{
  # Required for testing on virtual machines
  # https://github.com/nix-community/disko/blob/master/docs/interactive-vm.md
  disko.memSize = 16384; # 16GB
  disko.devices = {
    disk = {
      # root ssd - 4 TB Drive
      ssd00 = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-Samsung_SSD_990_PRO_4TB_S7KGNJ0X130041T";
        # Required for testing on virtual machines
        # Adjust this to your liking.
        # WARNING: if you set a too low value the image might be not big enough to contain the nixos installation
        imageSize = "10G";
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

      # SSD cluster kioxia 3 * 16TB drives
      # nvme4n1
      kioxia00 = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-KCD6XLUL15T3_34G0A04DT5R8";
        imageSize = "1G";
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
      # nvme5n1
      kioxia01 = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-KCD6XLUL15T3_34G0A042T5R8";
        imageSize = "1G";
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
      # nvme7n1
      kioxia02 = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-KCD6XLUL15T3_34G0A05QT5R8";
        imageSize = "1G";
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

      # ssd cluster - intel 4 * 3.2 TB drives
      # nvme0n1
      intel00 = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-INTEL_SSDPF2KE032T1_PHAX352405LZ3P8CGN";
        imageSize = "1G";
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "zstore03";
              };
            };
          };
        };
      };

      # nvme1n1
      intel01 = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-INTEL_SSDPF2KE032T1_PHAX35240B063P8CGN";
        imageSize = "1G";
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "zstore03";
              };
            };
          };
        };
      };

      # nvme2n1
      intel02 = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-INTEL_SSDPF2KE032T1_PHAX35230AYH3P8CGN";
        imageSize = "1G";
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "zstore03";
              };
            };
          };
        };
      };

      # nvme3n1
      intel03 = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-INTEL_SSDPF2KE032T1_PHAX352405L33P8CGN";
        imageSize = "1G";
        content = {
          type = "gpt";
          partitions = {
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "zstore03";
              };
            };
          };
        };
      };
    };

    # Z pool definitions
    zpool = {
      zstore16 = {
        type = "zpool";
        mode = "";
        mountpoint = "/datastore16";
        rootFsOptions = {
          # Make sure these options are correct
          #canmount = "off";
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
          datastore = {
            type = "zfs_fs";
            mountpoint = "/datastore16";
            postCreateHook = "zfs snapshot zstore16/datastore@blank";
          };
        };
      };
      # https://github.com/nix-community/disko/issues/581
      zstore03 = {
        type = "zpool";
        mode = "";
        mountpoint = "/datastore03";
        rootFsOptions = {
          # Make sure these options are correct
          #canmount = "off";
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
          datastore = {
            type = "zfs_fs";
            mountpoint = "/datastore03";
            postCreateHook = "zfs snapshot zstore03/datastore@blank";
          };
        };
      };
    };
  };
}

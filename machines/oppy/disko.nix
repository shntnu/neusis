{
  disko.devices = {
    disk = {
      # root ssd - 4 TB Drive
      ssd00 = {
        type = "disk";
        device = "/dev/by-id/nvme-Samsung_SSD_990_PRO_4TB_S7KGNJ0X130041T";
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
      # kioxia00 = {
      #   type = "disk";
      #   device = "/dev/nvme2n1";
      #   content = {
      #     type = "gpt";
      #     partitions = {
      #       zfs = {
      #         size = "100%";
      #         content = {
      #           type = "zfs";
      #           pool = "zstore16";
      #         };
      #       };
      #     };
      #   };
      # };
      # kioxia01 = {
      #   type = "disk";
      #   device = "/dev/nvme5n1";
      #   content = {
      #     type = "gpt";
      #     partitions = {
      #       zfs = {
      #         size = "100%";
      #         content = {
      #           type = "zfs";
      #           pool = "zstore16";
      #         };
      #       };
      #     };
      #   };
      # };
      # kioxia02 = {
      #   type = "disk";
      #   device = "/dev/nvme6n1";
      #   content = {
      #     type = "gpt";
      #     partitions = {
      #       zfs = {
      #         size = "100%";
      #         content = {
      #           type = "zfs";
      #           pool = "zstore16";
      #         };
      #       };
      #     };
      #   };
      # };

      # ssd cluster - intel 4 * 3.2 TB drives
      intel00 = {
        type = "disk";
        device = "/dev/by-id/nvme-INTEL_SSDPF2KE032T1_PHAX352405LZ3P8CGN";
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

      intel01 = {
        type = "disk";
        device = "/dev/by-id/nvme-INTEL_SSDPF2KE032T1_PHAX35240B063P8CGN";
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

      intel02 = {
        type = "disk";
        device = "/dev/by-id/nvme-INTEL_SSDPF2KE032T1_PHAX35230AYH3P8CGN";
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

      intel03 = {
        type = "disk";
        device = "/dev/by-id/nvme-INTEL_SSDPF2KE032T1_PHAX352405L33P8CGN";
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
      # zstore16 = {
      #   type = "zpool";
      #   mode = "";
      #   rootFsOptions = {
      #     # Make sure these options are correct
      #     canmount = "off";
      #     acltype = "posixacl";
      #     dnodesize = "auto";
      #     normalization = "formD";
      #     atime = "off";
      #     compression = "lz4";
      #     mountpoint = "none";
      #     xattr = "sa";
      #     "com.sun:auto-snapshot" = "false";
      #   };
      #   options.ashift = "12";
      #   options.autotrim = "on";
      #
      #   datasets = {
      #     datastore = {
      #       type = "zfs_fs";
      #       mountpoint = "/datastore16";
      #       options."com.sun:auto-snapshot" = "false";
      #       postCreateHook = "zfs snapshot zstore16/datastore@blank";
      #     };
      #   };
      # };
      zstore03 = {
        type = "zpool";
        mode = "";
        mountpoint = "/datastore03";
        rootFsOptions = {
          # Make sure these options are correct
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
          root = {
            type = "zfs_fs";
            mountpoint = "/datastore03";
            options."com.sun:auto-snapshot" = "false";
            postCreateHook = "zfs snapshot zstore03/datastore@blank";
          };
        };
      };
    };
  };
}

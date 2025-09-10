{
  pkgs,
  config,
  ...
}:
{

  virtualisation.vmVariantWithDisko = {
    # Create ephemeral tailscale connections with custom vm hostName
    neusis.tailscale = {
      isPersistent = false;
      hostName = "diskoTest${config.networking.hostName}";
    };

    virtualisation.qemu.options = [
      "-nographic"
      # This will add a drive with secrets to the vm
      #"-drive file=$TESTVM_SECRETS_HDD,id=drive7,if=none,index=7,werror=report -device virtio-blk-pci,drive=drive7"
      "-virtfs local,path=$TESTVM_SECRETS,mount_tag=hostshare,security_model=mapped-xattr"
      # "-object memory-backend-memfd,id=mem,size=1G,share=on \
      #   -numa node,memdev=mem \
      #   -chardev socket,id=char0,path=/tmp/qemu-virtiofs.sock \
      #   -device vhost-user-fs-pci,chardev=char0,tag=hostshare"
    ];

    # Add a filesystem mount config for the secrets drive
    # fileSystems."/mnt/secrets" = {
    #   device = "/dev/vdg";
    #   fsType = "ext4";
    # };

    # systemd.services.mount_vm_secrets = {
    #   wantedBy = [
    #     "sysinit.target"
    #     "agenix-install-secrets.target"
    #   ];
    #   after = [ "systemd-sysusers.service" ];
    #   unitConfig.DefaultDependencies = "no";
    #
    #   path = [ pkgs.mount ];
    #   serviceConfig = {
    #     Type = "oneshot";
    #     ExecStart = pkgs.writeShellScript "mount_vm_secrets" ''
    #       mkdir -p "/mnt/secrets"
    #       mount -t ext4 /dev/vdg /mnt/secrets
    #       ${pkgs.coreutils}/bin/cp -r /mnt/secrets/etc/ /etc/
    #     '';
    #     RemainAfterExit = true;
    #   };
    # };

    age.identityPaths = [ "/mnt/secrets/etc/ssh/ssh_host_ed25519_key" ];

    boot.initrd.availableKernelModules = [
      "virtio-blk"
      "virtio-pci"
    ];
    # systemd.services.agenix-install-secrets = {
    #   serviceConfig = {
    #     ExecStartPre = pkgs.writeShellScript "mount_vm_secrets" ''
    #       mkdir -p "/mnt/secrets"
    #       mount -t ext4 /dev/vdg /mnt/secrets
    #     '';
    #   };
    # };

    system.activationScripts = {
      mountVmSecrets = {
        text = ''
          echo "[mountVmSecrets] Creating /mnt/secrets/"
          mkdir -p "/mnt/secrets"
          echo "[mountVmSecrets] Mounting virtio hostshare to /mnt/secrets/"
          mount -t 9p -o trans=virtio,access=any,version=9p2000.L,subtype=ramfs,rw hostshare /mnt/secrets
          #mount -t virtiofs hostshare /mnt/secrets -o subtype=ramfs
          echo "[mountVmSecrets] Contents of /mnt/secrets/"
          echo $(ls -lah /mnt/secrets/)
        '';
        deps = [ "specialfs" ];
      };

      agenixInstall.deps = [
        "mountVmSecrets"
      ];

    };

    # systemd.services.copyMyFiles = {
    #   description = "Copy essential secret files agenix setup";
    #   wantedBy = [ ".target" ]; # Or a more specific target if needed
    #   script = ''
    #     mkdir -p "/mnt/secrets"
    #
    #     ${pkgs.coreutils}/bin/cp -r /path/to/source/files /path/to/destination/
    #     # Add more cp commands for other files if necessary
    #   '';
    #   # Consider adding 'requires = [ "local-fs.target" ];' if copying to local filesystems
    #   # and 'after = [ "local-fs.target" ];' for correct ordering.
    # };

    # For running VM on macos: https://www.tweag.io/blog/2023-02-09-nixos-vm-on-macos/
    # virtualisation.host.pkgs = inputs.nixpkgs.legacyPackages.aarch64-darwin;
  };
}

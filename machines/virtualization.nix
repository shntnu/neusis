{pkgs, ...}:
{
  environment.systemPackages = with pkgs; [
    looking-glass-client
    scream
    virt-manager
  ];

  virtualisation.libvirtd = {
    enable = true;
    qemu.ovmf.enable = true;
    qemu.runAsRoot = false;
    onBoot = "ignore";
    onShutdown = "shutdown";
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelParams = [ "amd_iommu=on" "pcie_aspm=off" ];
  boot.kernelModules = [ "kvm-amd" ];

  boot.initrd.availableKernelModules = [ "amdgpu" "vfio-pci" ];
  # boot.initrd.preDeviceCommands = ''
  #   DEVS="0000:0b:00.0 0000:0b:00.1"
  #   for DEV in $DEVS; do
  #     echo "vfio-pci" > /sys/bus/pci/devices/$DEV/driver_override
  #   done
  #   modprobe -i vfio-pci
  # '';

  systemd.tmpfiles.rules = [
    "f /dev/shm/scream-ivshmem 0660 ank qemu-libvirtd -"
    "f /dev/shm/looking-glass 0660 ank qemu-libvirtd -"
  ];

  systemd.user.services.scream-ivshmem = {
    enable = true;
    description = "Scream IVSHMEM";
    serviceConfig = {
      ExecStart = "${pkgs.scream}/bin/scream -m /dev/shm/scream-ivshmem";
      Restart = "always";
    };
    wantedBy = [ "multi-user.target" ];
    requires = [ "pulseaudio.service" ];
  };
}

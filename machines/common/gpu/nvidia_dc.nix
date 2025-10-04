{
  pkgs,
  config,
  lib,
  ...
}:
let
  package_ver = config.boot.kernelPackages.nvidiaPackages.dc_535;
in
# package_ver = config.boot.kernelPackages.nvidiaPackages.mkDriver rec {
#   version = "565.57.01";
#   url = "https://us.download.nvidia.com/tesla/${version}/NVIDIA-Linux-x86_64-${version}.run";
#   sha256_64bit = "sha256-buvpTlheOF6IBPWnQVLfQUiHv4GcwhvZW3Ks0PsYLHo=";
#   persistencedSha256 = "sha256-hdszsACWNqkCh8G4VBNitDT85gk9gJe1BlQ8LdrYIkg=";
#   fabricmanagerSha256 = "sha256-umhyehddbQ9+xhhoiKC7SOSVxscA5pcnqvkQOOLIdsM=";
#   useSettings = false;
#   usePersistenced = true;
#   useFabricmanager = true;
# };
{
  hardware = {
    # Include GSP firmware for datacenter GPUs
    firmware = [ package_ver.firmware ];

    # Enable OpenGL
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        vaapiVdpau
      ];
    };

    # Configure Nvidia driver
    nvidia = {
      modesetting.enable = true;
      # datacenter.enable required for nvidia-container-toolkit on NixOS 25.05
      # Note: This enables fabricmanager service, but we disable it below (see systemd.services)
      datacenter.enable = true;
      powerManagement.enable = false;
      open = false;
      nvidiaSettings = true;
      nvidiaPersistenced = true;
      package = package_ver;
    };

    # Enable nvidia container
    nvidia-container-toolkit.enable = true;
  };

  # Disable fabricmanager service to suppress boot-time failure warnings
  # datacenter.enable automatically enables this service, but it always fails on H100 NVL
  # (fabricmanager only manages NVSwitch fabrics for DGX/HGX, not NVLink bridges)
  # Failure is harmless but shows as error in systemctl status - cleaner to disable entirely
  systemd.services.nvidia-fabricmanager.enable = lib.mkForce false;

  # Nvidia related nix configs
  nixpkgs = {
    config = {
      allowUnfree = true;
      cudaSupport = true;
      nvidia.acceptLicense = true;
    };
  };
}

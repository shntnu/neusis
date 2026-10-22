{ pkgs, ... }:
{
  # Select the native headless driver path without enabling an X server or
  # NVSwitch fabric-manager. H100 NVL uses NVLink bridges, not NVSwitch.
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        libva-vdpau-driver
      ];
    };

    nvidia = {
      # R580 is NVIDIA's data-center long-term support branch. The native
      # module selects matching kernel modules, userspace and GSP firmware.
      branch = "dc_580";
      datacenter.enable = false;
      open = false;
      gsp.enable = true;
      # Keep the compute host free of DRM console/fbdev setup.
      modesetting.enable = false;
      powerManagement.enable = false;
      nvidiaSettings = false;
      videoAcceleration = false;
      nvidiaPersistenced = true;
    };

    nvidia-container-toolkit.enable = true;
  };

  nixpkgs = {
    config = {
      allowUnfree = true;
      cudaSupport = true;
      nvidia.acceptLicense = true;
    };
  };
}

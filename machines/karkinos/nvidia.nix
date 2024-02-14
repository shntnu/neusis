{ config, ...}:
{
  # Nvidia and Cuda support
  services.xserver.videoDrivers = ["nvidia"];
  config.allowUnfree = true;
  config.cudaSupport = true;

  hardware = {

    # Enable OpenGL
    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
    };

    # Configure Nvidia driver
    nvidia = {
      modesetting.enable = true;
      powerManagement.enable = false;
      open = false;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.latest;
    };
  };
}

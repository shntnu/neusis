{ pkgs, config, ...}:
{

  hardware = {

    # Enable OpenGL
    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
      extraPackages = with pkgs; [
        vaapiVdpau
      ];
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
  
  # Nvidia and Cuda support
  services.xserver.videoDrivers = ["nvidia"];
  config = {
    allowUnfree = true;
    cudaSupport = true;
  };
}

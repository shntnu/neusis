{ pkgs, config, ...}:
let
  package_ver = config.boot.kernelPackages.nvidiaPackages.latest;
in
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
      package = package_ver;
    };
  };
  
  # Nvidia and Cuda support
  services.xserver.videoDrivers = ["nvidia"];
  config = {
    allowUnfree = true;
    cudaSupport = true;
  };
}

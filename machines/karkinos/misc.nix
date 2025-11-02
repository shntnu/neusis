{
  pkgs,
  outputs,
  ...
}:
{

  # FHS
  programs.nix-ld.enable = true;

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.displayManager.gdm.autoSuspend = false;
  services.xserver.desktopManager.gnome.enable = true;

  # Have to add this to make theme related things work in GUI less env
  programs.dconf.enable = true;

  # enable ollama
  services.ollama = {
    enable = true;
    package = pkgs.unstable.ollama;
    acceleration = "cuda";
    models = "/datastore/ollama";
    host = "0.0.0.0";
    port = 11434;
    environmentVariables = {
      OLLAMA_CONTEXT_LENGTH = "262144";
    };
  };

  nixpkgs = {
    # You can add overlays here
    overlays = builtins.attrValues outputs.overlays;
    # Configure your nixpkgs instance
    config = {
      sunshine = {
        cudaSupport = true;
      };
      # Disable if you don't want unfree packages
      allowUnfree = true;
    };
  };

  # Default system wide packages
  environment.systemPackages = with pkgs; [
    vim
    dive
    podman-tui
    unstable.ollama
    gnomeExtensions.forge
    gnomeExtensions.blur-my-shell
    gnomeExtensions.burn-my-windows
    gnomeExtensions.appindicator
    gnomeExtensions.unite
  ];
  environment.shells = [ pkgs.zsh ];
  programs.zsh.enable = true;

}

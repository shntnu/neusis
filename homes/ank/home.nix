{ outputs, ... }:
{
  nixpkgs = {
    overlays = [
      outputs.overlays.unstable-packages
    ];
  };

  home.username = "ank";
  home.homeDirectory = "/home/ank";

  home.stateVersion = "23.11";

  dconf.settings = {
    "org/gnome/desktop/background" = {
      picture-uri = "${./gui/wallpapers/gruvbox_astro.jpg}";
      picture-uri-dark = "${./gui/wallpapers/gruvbox_astro.jpg}";
      picture-options = "zoom";
    };
  };
  programs.home-manager.enable = true;
}

{ outputs, ... }:
{
  nixpkgs = {
    overlays = [
      outputs.overlays.unstable-packages
    ];
  };

  home.username = "ashah";
  home.homeDirectory = "/home/ashah";

  home.stateVersion = "23.11";

  dconf.settings = {
    "org/gnome/desktop/background" = {
      picture-uri = "${./gui/wallpapers/gruvbox_astro.jpg}";
      picture-uri-dark = "${./gui/wallpapers/gruvbox_astro.jpg}";
      picture-options = "zoom";
    };
    "org/gnome/shell".enabled-extensions = [
      "blur-my-shell@aunetx"
      "burn-my-windows@schneegans.github.com"
      "forge@jmmaranan.com"
      "appindicatorsupport@rgcjonas.gmail.com"
    ];
  };
  programs.home-manager.enable = true;
}

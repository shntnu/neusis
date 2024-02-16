{ pkgs, ... }:
{
  home.sessionVariables.WLR_NO_HARDWARE_CURSORS = "1";
  home.sessionVariables.NIXOS_OZONE_WL = "1";

  wayland.windowManager.hyprland.enable = true;
  wayland.windowManager.hyprland.xwayland.enable = true;
  wayland.windowManager.hyprland.enableNvidiaPatches = true;
  wayland.windowManager.hyprland.systemdIntegration = true;
  wayland.windowManager.hyprland.extraConfig = ''
    monitor =,preferred,auto,auto
    exec-once = dunst & hyprpaper & ${pkgs.polkit-kde-agent}/libexec/polkit-kde-authentication-agent-1
  '';

  xdg.configFile."hypr/hyprpaper.conf".text = ''
    preload = ${./wallpapers/gruvbox_astro.jpg}
    wallpaper = ${./wallpapers/gruvbox_astro.jpg}
  '';

  # xdg.portal = {
  #   enable = true;
  #   wlr.enable = true;
  #   extraPortals = [
  #      pkgs.xdg-desktop-portal-gtk
  #     ];
  # };

  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    hyprpaper
    xdg-desktop-portal-gtk
    xdg-desktop-portal-hyprland
    xwayland
    wayland-protocols
    wayland-utils
    wl-clipboard
    wlroots
    # notification daemon
    dunst
    libnotify
    # app launchers
    wofi
    # fonts
    nerdfonts
    meslo-lgs-nf
  ];
}

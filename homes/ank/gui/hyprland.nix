{ inputs, pkgs, ... }:
{
  imports = [ inputs.hyprland.homeManagerModules.default ];
  environment.sessionVariables.WLR_NO_HARDWARE_CURSORS = "1";
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  programs.hyprland.enable = true;
  programs.hyprland.xwayland.enable = true;
  programs.hyprland.xwayland.hidpi = true;
  programs.hyprland.enableNvidiaPatches = true;

  wayland.windowManger.hyprland.enable = true;
  wayland.windowManger.hyprland.systemdIntegration = true;
  wayland.windowManger.hyprland.extraConfig = ''
    monitor =,preferred,auto,auto
    exec-once = dunst & hyprpaper & ${pkgs.polkit-kde-agent}/libexec/polkit-kde-authentication-agent-1
  '';

  xdg.configFiles."hypr/hyprpaper.conf".text = ''
    preload = ${./wallpapers/gruvbox_astro.jpg}
    wallpaper = ${./wallpapers/gruvbox_astro.jpg}
  '';

  services.dbus.enable = true;

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [
       pkgs.xdg-desktop-portal-gtk
      ];
  };

  fonts.fonts = with pkgs; [
    nerdfonts
    meslo-lgs-nf
  ];

  home.packages = with pkgs; [
    hyprland
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
  ];
}

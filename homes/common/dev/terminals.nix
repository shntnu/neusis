{
  inputs,
  pkgs,
  ...
}:
{
  home.packages = [
    pkgs.wezterm
    (pkgs.writers.writePython3Bin "gclb" { } ./gclb.py)
  ];
  programs = {

    wezterm = {
      enable = true;
      package = pkgs.wezterm;
      enableZshIntegration = true;
      extraConfig = builtins.readFile ./wezterm.lua;
    };

    kitty = {
      enable = true;
      settings = {
        hide_window_decorations = "true";
        draw_minimal_borders = "yes";
      };

    };

    zellij = {
      enable = true;
      settings = {
        theme = "gruvbox-dark";
        simplified_ui = true;
        default_mode = "locked";
      };
      enableZshIntegration = false;
    };
  };
  xdg.configFile = {
    "zellij/config.kdl".source = ./zellij.kdl;
    "zellij/layouts/default.kdl".source = ./zellij_layout.kdl;
  };
}

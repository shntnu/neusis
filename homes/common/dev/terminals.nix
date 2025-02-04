{
  inputs,
  pkgs,
  ...
}:
{
  home.packages = [
    inputs.superfile.packages.${pkgs.system}.default
    pkgs.master.wezterm
  ];

  programs.kitty = {
    enable = true;
    settings = {
      hide_window_decorations = "true";
      draw_minimal_borders = "yes";
    };

  };

  programs.zellij = {
    enable = true;
    settings = {
      theme = "gruvbox-dark";
      simplified_ui = true;
      default_mode = "locked";
    };
    enableZshIntegration = false;
  };
  xdg.configFile = {

    # wezeterm config file
    "wezterm/wezterm.lua".source = ./wezterm.lua;
    "zellij/config.kdl".source = ./zellij.kdl;
    "zellij/layouts/default.kdl".source = ./zellij_layout.kdl;
  };
}

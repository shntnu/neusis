{
  inputs,
  pkgs,
  ...
}:
{
  home.packages = [
    inputs.superfile.packages.${pkgs.system}.default
    pkgs.wezterm
  ];

  programs.kitty = {
    enable = true;
  };

  programs.zellij = {
    enable = true;
    settings = {
      theme = "gruvbox-dark";
      simpified_ui = true;
      default_mode = "locked";
    };
    enableZshIntegration = true;
  };
  xdg.configFile = {

    # wezeterm config file
    "wezterm/wezterm.lua".source = ./wezterm.lua;
    "zellij/config.kdl".source = ./zellij.kdl;
    "zellij/layouts/default.kdl".source = ./zellij_layout.kdl;
  };
}

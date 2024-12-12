{
  inputs,
  pkgs,
  ...
}: {
  home.packages = [
    inputs.superfile.packages.${pkgs.system}.default
    pkgs.wezterm
  ];
  programs.kitty = {
    enable = true;
    theme = "Gruvbox Dark Hard";
    settings = {
      font_family = "MesloLGS Nerd Font Mono";
    };
  };
}

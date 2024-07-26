{
  inputs,
  pkgs,
  ...
}: {
  home.packages = [
    inputs.superfile.packages.${pkgs.system}.default
  ];
  programs.kitty = {
    enable = true;
    theme = "Gruvbox Dark Hard";
    settings = {
      font_family = "MesloLGS Nerd Font Mono";
    };
  };
}

{ pkgs, ...}:
{
  programs.kitty = {
    enable = true;
    theme = "Gruvbox Dark Hard";
    settings = {
      font_family = "MesloLGS Nerd Font Mono";
    };
  };
}

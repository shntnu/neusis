{
  pkgs,
  ...
}:
{
  # Default system wide packages
  environment.systemPackages = with pkgs; [
    vim
    dive
    podman-tui
    ipmitool
  ];

  environment.shells = [ pkgs.zsh ];

  programs.zsh.enable = true;
  programs.fish.enable = true;
}

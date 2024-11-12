{pkgs, ...}: {
  home.username = "suganya";
  home.homeDirectory = "/home/suganya";
  home.packages = [
    pkgs.screen
  ];
}

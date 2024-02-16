{ pkgs, ...}:
{
  home.packages = with pkgs; [
    nvim 
  ];
}

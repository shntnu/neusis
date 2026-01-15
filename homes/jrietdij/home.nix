{ pkgs, ... }:
{
  home = {
    username = "jrietdij";
    homeDirectory = "/home/jrietdij";

    packages = with pkgs; [
      jq
    ];
  };
}

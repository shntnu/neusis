{ pkgs, ... }:
{
  home = {
    username = "ank";
    homeDirectory = "/home/ank";

    packages = with pkgs; [
      duckdb
      jq
      mpv
    ];
  };
}

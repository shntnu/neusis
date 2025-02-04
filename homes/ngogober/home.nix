{ pkgs, ... }:
{
  home = {
    username = "ngogober";
    homeDirectory = "/home/ngogober";

    packages = with pkgs; [
      duckdb
      jq
    ];
  };
}

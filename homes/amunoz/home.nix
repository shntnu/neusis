{ pkgs, ... }:
{
  home = {
    username = "amunoz";
    homeDirectory = "/home/amunoz";

    packages = with pkgs; [
      duckdb
      jq
    ];
  };
}

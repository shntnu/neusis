{ pkgs, ... }:
{
  home = {
    username = "jfredinh";
    homeDirectory = "/home/jfredinh";

    packages = with pkgs; [
      claude-code
      duckdb
      jq
      pkgs.unstable.opencode
    ];
  };
}

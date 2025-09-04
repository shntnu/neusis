{ pkgs, outputs, ... }:
{
  home = {
    username = "ank";
    homeDirectory = "/home/ank";

    packages = import ./packages.nix { inherit pkgs outputs; };

    programs.atuin = {
      enable = true;
      settings = {
        auto_sync = true;
        sync_frequency = "1m";
        sync_address = "https://api.atuin.sh";
        search_mode = "fuzzy";
      };
    };
  };
}

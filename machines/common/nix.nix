{ pkgs, ... }:
let
  gc_freq =
    if pkgs.stdenv.isDarwin then
      {
        interval = {
          Weekday = 0;
          Hour = 0;
          Minute = 0;
        };
      }
    else
      {
        dates = "weekly";
      };
in
{
  nix = {
    package = pkgs.nix;
    gc = {
      automatic = true;
      options = "--delete-older-than 15d";
    } // gc_freq;

    # Deduplicate and optimize nix store
    optimise.automatic = true;

    # Turn this on to make command line easier
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };
}

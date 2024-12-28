{pkgs, ...}:
let
darwin_gc = if (pkgs.stdenv.isDarwin) then {
  users = "root";
  interval = { Weekday = 0; Hour = 0; Minute = 0; };
} else {};
in
{
  nix = {
    package = pkgs.nix;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 15d";
    } // darwin_gc;

    # Deduplicate and optimize nix store
    optimise.automatic = true;

    # Turn this on to make command line easier
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };
}

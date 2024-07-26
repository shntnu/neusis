{pkgs, ...}: {
  nix = {
    package = pkgs.nix;
    gc = {
      user = "root";
      automatic = true;
      interval = {
        Weekday = 0;
        Hour = 2;
        Minute = 0;
      };
      options = "--delete-older-than 30d";
    };

    # Deduplicate and optimize nix store
    auto-optimise-store = true;

    # Turn this on to make command line easier
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };
}

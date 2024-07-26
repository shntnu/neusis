{
  config,
  pkgs,
  inputs,
  outputs,
  ...
}: {
  imports = [
    inputs.home-manager.darwinModules.home-manager
    # Configure home manager
    {
      home-manager = {
        userGlobalPkgs = true;
        useUserPackages = true;
        extraSpecialArgs = {inherit inputs outputs;};
        user.kumarank = {
          imports = [
            ../../homes/ank/machines/darwin001.nix
          ];
        };
      };
    }
    inputs.nix-homebrew.darwinModules.nix-homebrew
    ../common/darwin_home_manager.nix
    ../common/nix-homebrew.nix
    ../common/nix.nix
    ../common/substituters.nix
  ];

  # Create users
  users.users.kumarank = {
    description = "Ankur Kumar";
    home = "/Users/kumarank";
    createHome = true;
    isHidden = false;
    shell = pkgs.zsh;
    openssh.authorizedKeys.keyFiles = [
      ../../homes/ank/id_rsa.pub
      ../../homes/ank/id_ed25519.pub
    ];
  };

  # Configure homebrew
  homebrew = {
    enable = true;
    brews = ["input-leap"]; # Example of brew
    taps = map (key: builtins.replaceStrings ["homebrew-"] [""] key) (builtins.attrNames config.nix-homebrew.taps);
    casks = import ../common/casks.nix;
    onActivation = {
      cleanup = "uninstall";
      autoUpdate = true;
      upgrade = true;
    };
  };

  # sudo with touch id
  security.pam.enableSudoTouchIdAuth = true;

  # remap keys : Caps -> Esc
  system.keyboard.enableKeyMapping = true;
  system.keyboard.remapCapsLockToEscape = true;

  # Disable press and hold for diacritics.
  # I want to be able to press and hold j and k
  # in vim to move around.
  system.defaults.NSGlobalDomain.ApplePressAndHoldEnabled = false;

  # Turn off NIX_PATH warnings now that we're using flakes
  system.checks.verifyNixPath = false;
  system = {
    stateVersion = 4;

    #   defaults = {
    #     NSGlobalDomain = {
    #       AppleShowAllExtensions = true;
    #       ApplePressAndHoldEnabled = false;
    #
    #       # 120, 90, 60, 30, 12, 6, 2
    #       KeyRepeat = 2;
    #
    #       # 120, 94, 68, 35, 25, 15
    #       InitialKeyRepeat = 15;
    #
    #       "com.apple.mouse.tapBehavior" = 1;
    #       "com.apple.sound.beep.volume" = 0.0;
    #       "com.apple.sound.beep.feedback" = 0;
    #     };
    #
    #     dock = {
    #       autohide = true;
    #       show-recents = false;
    #       launchanim = true;
    #       orientation = "left";
    #       tilesize = 48;
    #     };
    #
    #     finder = {
    #       _FXShowPosixPathInTitle = false;
    #     };
    #
    #     trackpad = {
    #       Clicking = true;
    #       TrackpadThreeFingerDrag = true;
    #     };
    #   };
  };
}

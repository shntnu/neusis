{
  config,
  pkgs,
  inputs,
  outputs,
  ...
}:
{
  imports = [
    inputs.mac-app-util.darwinModules.default
    inputs.home-manager.darwinModules.home-manager
    inputs.nix-homebrew.darwinModules.nix-homebrew
    #../common/darwin_home_manager.nix
    (import ../common/nix-homebrew.nix {
      inherit inputs;
      user = "ank";
    })
    ../common/nix.nix
    ../common/substituters.nix
  ];

  # Configure nixpkgs
  nixpkgs = {
    # You can add overlays here
    overlays = builtins.attrValues outputs.overlays;
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
    };
  };

  nix.linux-builder = {
    enable = true;
    ephemeral = true;
    maxJobs = 10;
    config = {
      virtualisation = {
        darwin-builder = {
          diskSize = 100 * 1024;
          memorySize = 24 * 1024;
        };
        cores = 10;
      };
    };
  };

  nix.settings = {

    trusted-users = [
      "@admin"
      "ank"
    ];
  };

  networking.hostName = "rogue";

  # Create users
  users.users.ank = {
    description = "Ankur Kumar";
    home = "/Users/ank";
    createHome = true;
    isHidden = false;
    shell = pkgs.zsh;
    openssh.authorizedKeys.keyFiles = [
      ../../homes/ank/id_rsa.pub
      ../../homes/ank/id_ed25519.pub
    ];
  };

  # This is important! Removing this will break your shell and thus your system
  # This is needed even if you enable zsh in home manager
  programs.zsh.enable = true;

  # Configure homebrew
  homebrew = {
    enable = true;
    masApps = {
      Xcode = 497799835;
      "Microsoft Outlook" = 985367838;
    };
    # brews = [
    #   "pixi"
    #   "gnu-sed"
    # ]; # Example of brew
    taps = map (key: builtins.replaceStrings [ "homebrew-" ] [ "" ] key) (
      builtins.attrNames config.nix-homebrew.taps
    );
    casks = [
      "fiji"
      "hammerspoon"
    ];
    onActivation = {
      cleanup = "uninstall";
      autoUpdate = true;
      upgrade = true;
    };
  };

  # Configure home manager
  home-manager = {
    extraSpecialArgs = { inherit inputs outputs; };
    users.ank = {
      imports = [
        inputs.mac-app-util.homeManagerModules.default
        ../../homes/ank/machines/rogue.nix
      ];
    };
  };

  security.pam.services.sudo_local.touchIdAuth = true;
  # sudo with touch id
  system = {

    primaryUser = "ank";
    # remap keys : Caps -> Esc
    keyboard.enableKeyMapping = true;
    keyboard.remapCapsLockToEscape = true;

    # Disable press and hold for diacritics.
    # I want to be able to press and hold j and k
    # in vim to move around.
    defaults.NSGlobalDomain.ApplePressAndHoldEnabled = false;

    # Turn off NIX_PATH warnings now that we're using flakes
    checks.verifyNixPath = false;

    stateVersion = 5;

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

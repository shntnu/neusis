{ ... }:
{
  admins = [
    {
      username = "ank";
      fullName = "Ankur Kumar";
      shell = "zsh";
      sshKeys = [
        ../homes/ank/id_rsa.pub
        ../homes/ank/id_ed25519.pub
        ../homes/ank/id2_ed25519.pub
      ];
      # home-manager profiles for spirit will be added in follow-up PRs
      # per user, once we validate each home config against nixpkgs 25.11.
      homeModules = {
        spirit = null;
      };
    }
    {
      username = "amunoz";
      fullName = "Alan";
      shell = "fish";
      sshKeys = [
        ../homes/amunoz/id_ed25519.pub
      ];
      homeModules = {
        spirit = null;
      };
    }
    {
      username = "shsingh";
      fullName = "Shantanu";
      shell = "zsh";
      sshKeys = [
        ../homes/shsingh/id_ed25519.pub
      ];
      homeModules = {
        # Home Manager for this user is applied from shntnu/nixos-config.
        # Keep the account and SSH key in neusis, but do not create a
        # home-manager.users.shsingh profile during system rebuilds.
        spirit = null;
      };
    }
    {
      username = "jfredinh";
      fullName = "Johan";
      shell = "zsh";
      sshKeys = [
        ../homes/jfredinh/id_ed25519.pub
      ];
      homeModules = {
        spirit = null;
      };
    }
    {
      username = "rshen";
      fullName = "Runxi Shen";
      shell = "zsh";
      sshKeys = [
        ../homes/rshen/id_ed25519.pub
      ];
      homeModules = {
        spirit = null;
      };
    }
  ];

  regulars = [
    {
      username = "kshimofu";
      fullName = "Kazumasa Shimofuruta";
      shell = "zsh";
      sshKeys = [
        ../homes/kshimofu/id_ed25519.pub
      ];
      homeModules = {
        spirit = null;
      };
    }
    {
      username = "ngogober";
      fullName = "Nodar";
      shell = "bash";
      sshKeys = [
        ../homes/ngogober/id_ed25519.pub
      ];
      homeModules = {
        spirit = null;
      };
    }
  ];

  # Locked users - accounts exist but cannot login, data preserved
  locked = [ ];

  guests = [ ];

}

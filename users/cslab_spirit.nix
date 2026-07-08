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
      homeModules = {
        spirit = [
          ../homes/ank/machines/spirit.nix
        ];
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
        # Home Manager for this user is applied from afermg/nix-configs.
        # Keep the account and SSH key in neusis, but do not create a
        # home-manager.users.amunoz profile during system rebuilds.
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
        spirit = [
          ../homes/jfredinh/machines/spirit.nix
        ];
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
        spirit = [
          ../homes/rshen/machines/spirit.nix
        ];
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
        spirit = [
          ../homes/kshimofu/machines/spirit.nix
        ];
      };
    }
    {
      username = "ngogober";
      fullName = "Nodar";
      shell = "zsh";
      sshKeys = [
        ../homes/ngogober/id_ed25519.pub
      ];
      homeModules = {
        spirit = [
          ../homes/ngogober/machines/spirit.nix
        ];
      };
    }
  ];

  # Locked users - accounts exist but cannot login, data preserved
  locked = [ ];

  guests = [ ];

}

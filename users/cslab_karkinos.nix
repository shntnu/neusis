{ pkgs, ... }:
{
  admins = [
    {
      username = "ank";
      fullName = "Ankur Kumar";
      shell = pkgs.zsh;
      sshKeys = [
        ../homes/ank/id_rsa.pub
        ../homes/ank/id_ed25519.pub
        ../homes/ank/id2_ed25519.pub
      ];
      homeModules = {
        oppy = [
          ../homes/ank/machines/oppy.nix
        ];
        karkinos = [
          ../homes/ank/machines/karkinos.nix
        ];
      };
    }
    {
      username = "amunoz";
      fullName = "Alan";
      shell = pkgs.fish;
      sshKeys = [
        ../homes/amunoz/id_ed25519.pub
      ];
      homeModules = {
        karkinos = [
          ../homes/amunoz/machines/karkinos.nix
        ];
      };
    }
    {
      username = "shsingh";
      fullName = "Shantanu";
      shell = pkgs.zsh;
      sshKeys = [
        ../homes/shsingh/id_ed25519.pub
      ];
      homeModules = {
        karkinos = [
          ../homes/shsingh/machines/karkinos.nix
        ];
      };
    }
    {
      username = "jfredinh";
      fullName = "Johan";
      shell = pkgs.zsh;
      sshKeys = [
        ../homes/jfredinh/id_ed25519.pub
      ];
      homeModules = {
        karkinos = [
          ../homes/jfredinh/machines/karkinos.nix
        ];
      };
    }
  ];

  regulars = [
  ];

  # Locked users - accounts exist but cannot login, data preserved
  locked = [
  ];

  guests = [ ];

}

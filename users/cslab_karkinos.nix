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
      shell = "fish";
      sshKeys = [
        ../homes/amunoz/id_ed25519.pub
      ];
      homeModules = {
        # Home Manager for this user is applied from afermg/nix-configs.
        # Keep the account and SSH key in neusis, but do not create a
        # home-manager.users.amunoz profile during system rebuilds.
        karkinos = null;
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
        karkinos = null;
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
        karkinos = [
          ../homes/jfredinh/machines/karkinos.nix
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
        karkinos = [
          ../homes/rshen/machines/karkinos.nix
        ];
      };
    }
  ];

  regulars = [ ];

  # Locked users - accounts exist but cannot login, data preserved
  locked = [
    {
      username = "yektefai";
      fullName = "Yasha Ektefaie";
      shell = "zsh";
      sshKeys = [
        ../homes/yektefai/id_ed25519.pub
      ];
      homeModules = {
        karkinos = [
          ../homes/yektefai/machines/karkinos.nix
        ];
      };
    }
    {
      username = "zhaochuj";
      fullName = "Julia Zhao";
      shell = "zsh";
      sshKeys = [
        ../homes/zhaochuj/id_ed25519.pub
      ];
      homeModules = {
        karkinos = [
          ../homes/zhaochuj/machines/karkinos.nix
        ];
      };
    }
    {
      username = "arao";
      fullName = "Arya Rao";
      shell = "zsh";
      sshKeys = [
        ../homes/arao/id_ed25519.pub
      ];
      homeModules = {
        karkinos = [
          ../homes/arao/machines/karkinos.nix
        ];
      };
    }
    {
      username = "limeliss";
      fullName = "Melissa Li";
      shell = "zsh";
      sshKeys = [
        ../homes/limeliss/id_ed25519.pub
      ];
      homeModules = {
        karkinos = [
          ../homes/limeliss/machines/karkinos.nix
        ];
      };
    }
  ];

  guests = [ ];

}

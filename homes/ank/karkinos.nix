{ inputs, ... }:
{
  imports = [
    inputs.home-manager.nixosModule
    ./home.nix
    ./dev
    ./secrets
    ./gui
    ./browsers
    ./misc
  ];

  home-manager.users.ank = {
    imports = [
     inputs.hyprland.homeManagerModules.default 
     inputs.agenix.homeManagerModules.default
    ];
  };
}

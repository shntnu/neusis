
{ inputs, pkgs, ...}:
{
  imports = [
     inputs.agenix.nixosModules.default 
     inputs.agenix.homeManagerModules.default
  ];
  environment.systemPackages = with pkgs; [
    agenix
  ];
}

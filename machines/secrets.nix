
{ inputs, pkgs, ...}:
{
  imports = [
     inputs.agenix.nixosModules.default 
  ];
  environment.systemPackages = with pkgs; [
    agenix
  ];
}

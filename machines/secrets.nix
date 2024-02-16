
{ inputs, pkgs, ...}:
{
  imports = [
     inputs.agenix.nixosModules.default 
  ];
  age.secrets.tsauthkey.file = ../secrets/tsauthkey.age;
  environment.systemPackages = with pkgs; [
    agenix
  ];
}

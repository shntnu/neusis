
{ inputs, ...}:
{
  imports = [
     inputs.agenix.nixosModules.default 
  ];
  age.secrets.tsauthkey.file = ../secrets/tsauthkey.age;
}

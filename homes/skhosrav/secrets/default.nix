{ ... }:
{
  imports = [
    ./tsauthkey.nix
  ];
  
  age.identityPaths = [ "/home/ank/.ssh/id_ed5519" ];
  
}

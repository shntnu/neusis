{
  config,
  lib,
  pkgs,
  ...
}:
let
  globus = pkgs.callPackage ../../../pkgs/globus-connect-personal { };
  downloads = "${config.home.homeDirectory}/Downloads";
in
{
  imports = [ ./oppy.nix ];

  home = {
    packages = [ globus ];
    # Only access policy is declarative; registration credentials stay local.
    file.".globusonline/lta/config-paths".text = "${downloads},0,1\n";
    activation.globusDirectories = lib.hm.dag.entryBetween [ "linkGeneration" ] [ "writeBoundary" ] ''
      run mkdir -p "$HOME/.globusonline/lta" "$HOME/Downloads"
      run chmod 700 "$HOME/.globusonline" "$HOME/.globusonline/lta"
    '';
  };

  # After local registration: systemctl --user start globus-connect-personal
  systemd.user.services.globus-connect-personal = {
    Unit = {
      Description = "Globus Connect Personal (Downloads only)";
      ConditionPathExists = [
        "%h/.globusonline/lta/config"
        "%h/.globusonline/lta/client-id.txt"
      ];
    };
    Service = {
      ExecStart = "${globus}/bin/globusconnectpersonal -start -restrict-paths rw${downloads} -shared-paths n/";
      Restart = "on-failure";
      RestartSec = 10;
      UMask = "0077";
    };
    Install.WantedBy = [ "default.target" ];
  };
}

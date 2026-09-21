{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.neusis.safeSwitch.enable = lib.mkEnableOption "hostname checks before switching NixOS configurations";

  config = lib.mkIf config.neusis.safeSwitch.enable {
    # Activation scripts run too late: switch-to-configuration has already
    # stopped services by then. This hook runs before that and bootloader writes.
    system.preSwitchChecks.neusis-hostname = ''
      ${pkgs.bash}/bin/bash ${./safe-switch/check-hostname.sh} \
        ${lib.escapeShellArg config.networking.hostName} \
        "$( ${pkgs.coreutils}/bin/uname -n )"
    '';
  };
}

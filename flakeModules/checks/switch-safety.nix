{ self, lib, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      checks = lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux (
        let
          fleet = map (name: self.nixosConfigurations.${name}) [
            "oppy"
            "karkinos"
            "spirit"
          ];
          oppy = self.nixosConfigurations.oppy;
          overridden = oppy.extendModules {
            modules = [ { systemd.services.libvirt-guests.serviceConfig.TimeoutStopSec = 600; } ];
          };
          disabled = oppy.extendModules {
            modules = [ { neusis.safeSwitch.enable = lib.mkForce false; } ];
          };
          # Exercise the real preSwitchChecksScript without building/activating a
          # fleet system. The target name deliberately differs from a build host.
          candidate = self.inputs.nixpkgs.lib.nixosSystem {
            modules = [
              ../../modules/nixos/safe-switch.nix
              {
                nixpkgs.pkgs = pkgs;
                networking.hostName = "neusis-guard-test-target";
                neusis.safeSwitch.enable = true;
              }
            ];
          };
        in
        {
          switch-safety =
            assert lib.all (
              machine:
              machine.config.systemd.services.libvirt-guests.serviceConfig.TimeoutStopSec == 300
              && machine.config.neusis.safeSwitch.enable
              && machine.config.system.preSwitchChecks ? neusis-hostname
              && lib.hasInfix "TimeoutStopSec=300" machine.config.systemd.units."libvirt-guests.service".text
            ) fleet;
            assert overridden.config.systemd.services.libvirt-guests.serviceConfig.TimeoutStopSec == 600;
            assert !(disabled.config.system.preSwitchChecks ? neusis-hostname);
            pkgs.runCommand "switch-safety" { nativeBuildInputs = [ pkgs.shellcheck ]; } ''
              guard=${../../modules/nixos/safe-switch/check-hostname.sh}
              shellcheck "$guard"

              ${pkgs.bash}/bin/bash "$guard" oppy oppy
              if ${pkgs.bash}/bin/bash "$guard" gpa85-cad oppy 2>error; then
                echo "wrong-host switch was accepted" >&2
                exit 1
              fi
              grep -q 'Refusing to switch' error
              grep -q -- '--target-host' error
              grep -q 'profile may already have changed' error

              # Only the documented, exact override value permits a rename.
              NEUSIS_ALLOW_HOSTNAME_CHANGE=1 ${pkgs.bash}/bin/bash "$guard" gpa85-cad oppy
              for value in 0 true yes; do
                if NEUSIS_ALLOW_HOSTNAME_CHANGE="$value" ${pkgs.bash}/bin/bash "$guard" gpa85-cad oppy; then
                  exit 1
                fi
              done
              if ${pkgs.bash}/bin/bash "$guard" "" oppy; then exit 1; fi
              if ${pkgs.bash}/bin/bash "$guard" oppy ""; then exit 1; fi

              # The generated NixOS hook must reject before every switch action,
              # not just live activation; these calls do not change the system.
              hook=${candidate.config.system.preSwitchChecksScript}
              for action in check dry-activate test switch boot; do
                if "$hook" /unused "$action" 2>error; then
                  echo "pre-switch hook accepted $action on the wrong host" >&2
                  exit 1
                fi
                grep -q "Pre-switch check 'neusis-hostname' failed" error
                NEUSIS_ALLOW_HOSTNAME_CHANGE=1 "$hook" /unused "$action"
              done
              touch "$out"
            '';
        }
      );
    };
}

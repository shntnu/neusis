{
  pkgs,
  inputs,
  outputs,
  ...
}:
let
  modules = [
    inputs.nixos-images.nixosModules.kexec-installer
    inputs.nixos-images.nixosModules.noninteractive
    inputs.agenix.nixosModules.default
    outputs.nixosModules.tailscale
    ../machines/oppy/network.nix
    {
      system.kexec-installer.name = "nixos-kexec-installer-noninteractive";
      neusis.tailscale = {
        enable = true;
        isPersistent = true;
      };
    }
  ];
in
(pkgs.nixos modules).config.system.build.kexecInstallerTarball

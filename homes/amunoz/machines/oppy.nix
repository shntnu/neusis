{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  # Sourced from afermg/nixos-config through the `amunoz-nixos-config` input.
  # The exported Oppy profile includes the shared personal configuration plus
  # host-specific secrets and services such as Pi-msg, so this file intentionally
  # does not duplicate that wiring or import Neusis's common Home Manager modules.
  imports = [
    inputs.amunoz-nixos-config.homeModules."amunoz-oppy"
  ];

  # Reuse the personal configuration, but select Atuin from Neusis's newer
  # package set rather than the personal/Moby pin. The stable package predates
  # migrations already present in this user's history database.
  programs.atuin.package = lib.mkForce (
    inputs.nixpkgs-ollama.legacyPackages.${pkgs.stdenv.hostPlatform.system}.atuin
  );

  # A previous targeted Home Manager rollout left this path ahead of the user
  # profile. Manage it here too so it cannot diverge from the daemon's package.
  home.file.".local/bin/atuin".source = lib.getExe config.programs.atuin.package;

  # Apply the same package over an older unit until the system's Home Manager
  # generation is rebuilt. This generated drop-in can also be deployed alone,
  # without restarting unrelated user services or rolling out a system change.
  xdg.configFile."systemd/user/atuin-daemon.service.d/10-home-manager-package.conf".text = ''
    [Service]
    ExecStart=
    ExecStart=${lib.getExe config.programs.atuin.package} daemon start
    ExecStartPre=
    ExecStartPre=${pkgs.coreutils}/bin/test -s ${config.home.homeDirectory}/.local/share/atuin/key
    UMask=0077
  '';

  systemd.user.services.atuin-daemon.Service = {
    ExecStartPre = [
      "${pkgs.coreutils}/bin/test -s ${config.home.homeDirectory}/.local/share/atuin/key"
    ];
    UMask = "0077";
  };
}

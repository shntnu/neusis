{
  inputs,
  lib,
  ...
}:
{
  # Personal Oppy package selection only. The imported personal package list
  # resolves both CLI names through this Home Manager package set.
  nixpkgs.overlays = lib.mkAfter [
    (final: _: {
      codex = final.callPackage ./codex.nix { };
      claude-code = inputs.claude-code-nix.packages.${final.stdenv.hostPlatform.system}.claude-code;
    })
  ];
}

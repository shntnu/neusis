{
  ...
}:
{

  virtualisation.vmVariantWithDisko = {
    virtualisation.qemu.options = [
      "-nographic"
      "-hda ''$TESTVM_SECRETS_HDD"
    ];

    # For running VM on macos: https://www.tweag.io/blog/2023-02-09-nixos-vm-on-macos/
    # virtualisation.host.pkgs = inputs.nixpkgs.legacyPackages.aarch64-darwin;
  };
}

{
  self,
  ...
}:
{
  perSystem =
    {
      system,
      ...
    }:
    let
      unfreePkgs = import self.inputs.nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      # This sets `pkgs` to a nixpkgs with allowUnfree option set.
      packages = import ../pkgs {
        inherit (self) inputs outputs;
        pkgs = unfreePkgs;
      };

    };
}

{
  self,
  lib,
  pkgs,
  ...
}:
{
  perSystem =
    {
      config,
      pkgs,
      inputs',
      self',
      system,
      ...
    }:
    {
      checks = {
        # FIXME: This fails because of creds issue
        # oppy_test = pkgs.testers.runNixOSTest {
        #   name = "oppy-test";
        #   nodes.oppy.imports = self.nixosConfigurations.oppy._module.args.modules;
        #   node.specialArgs = { inherit (self) inputs outputs; };
        #   node.pkgsReadOnly = false;
        #
        #   testScript = builtins.readFile ./oppy_test.py;
        # };
      };
    };
}

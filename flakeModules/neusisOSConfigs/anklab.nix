{
  self,
  ...
}:
{
  config.flake.nixosConfigurations = {
    chiral = self.lib.neusisOS.mkNeusisOS {
      machineName = "chiral";
      userModule = ../../machines/chiral;
      specialArgs = { inherit (self) inputs outputs; };
      userConfig = import ../../users/ank.nix { };
      homeManager = true;
    };
  };

  config.flake.darwinConfigurations = {
    darwin001 = self.lib.neusisOS.mkNeusisDarwinOS {
      machineName = "darwin001";
      # Not using the userConfig and directly creating user in the config
      userModule = ../../machines/darwin001;
      specialArgs = { inherit (self) inputs outputs; };
      homeManager = true;
    };
  };
}

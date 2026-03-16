{ inputs, ... }:
{

  imports = [
    inputs.comin.nixosModules.comin
  ];

  services.comin = {
    enable = true;
    remotes = [
      {
        name = "origin";
        url = "https://github.com/shntnu/neusis.git";
        branches.main.name = "prod";
      }
    ];
  };

}

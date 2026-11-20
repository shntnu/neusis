# Run: nix eval --impure --file tests/rshen-globus.nix
let
  flake = builtins.getFlake (toString ../.);
  homes = flake.homeConfigurations;
  config = homes."rshen@karkinos".config;
  service = config.systemd.user.services.globus-connect-personal;
  globusPackages =
    cfg: builtins.filter (p: (p.pname or "") == "globus-connect-personal") cfg.home.packages;
in
assert builtins.length (globusPackages config) == 1;
assert config.home.file.".globusonline/lta/config-paths".text == "/home/rshen/Downloads,0,1\n";
assert
  service.Service.ExecStart == [
    "${builtins.head (globusPackages config)}/bin/globusconnectpersonal -start -restrict-paths rw/home/rshen/Downloads -shared-paths n/"
  ];
assert
  service.Unit.ConditionPathExists == [
    "%h/.globusonline/lta/config"
    "%h/.globusonline/lta/client-id.txt"
  ];
assert builtins.all
  (
    host:
    let
      cfg = homes."rshen@${host}".config;
    in
    globusPackages cfg == [ ]
    && !(cfg.systemd.user.services ? globus-connect-personal)
    && !(cfg.home.file ? ".globusonline/lta/config-paths")
  )
  [
    "oppy"
    "spirit"
  ];
true

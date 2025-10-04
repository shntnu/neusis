{
  flake = {
    path = ./flake;
    description = "Generic flake";
  };

  flakevirt = {
    path = ./flakevirt;
    description = "Generic flake";
  };

  fhsflake = {
    path = ./fhsflake;
    description = "Generic fhs flake";
  };

  python-nix = {
    path = ./python-nix;
    description = "Pure Nix Python environment (nixpkgs only, max reproducibility)";
  };

  python-uv = {
    path = ./python-uv;
    description = "Python with uv (PyPI + git sources, default for pure Python)";
  };

  python-pixi = {
    path = ./python-pixi;
    description = "Python with pixi (conda packages for GPU/RAPIDS, single environment)";
  };

  python-pixi-multienv = {
    path = ./python-pixi-multienv;
    description = "Python with pixi (multiple environments for conflicting dependencies)";
  };

  rust = {
    path = ./rust;
    description = "Generic rust environment";
  };

}

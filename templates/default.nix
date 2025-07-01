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

  python = {
    path = ./python;
    description = "Generic python environment";
  };

  pythonml = {
    path = ./pythonml;
    description = "Generic python machine learning environment";
  };

  fhspythonml = {
    path = ./fhspythonml;
    description = "FHS python machine learning environment";
  };

  rust = {
    path = ./rust;
    description = "Generic rust environment";
  };

}

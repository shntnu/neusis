{
  inputs,
  outputs,
}:
{
  sunshine = import ./sunshine.nix;
  xilinx = import ./xilinx.nix { inherit outputs; };
}

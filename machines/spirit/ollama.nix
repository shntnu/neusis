{ pkgs, inputs, ... }:
let
  # Ollama from a newer nixpkgs than pkgs.unstable (flake input `nixpkgs-ollama`), because
  # qwen3.8 needs ollama >= 0.32.12. CUDA packages are unfree and not in the binary cache,
  # so this builds locally; restricting CUDA to this machine's H100 NVL (compute
  # capability 9.0 -- karkinos is 8.9, do not copy that value here) keeps the build short.
  ollamaPkgs = import inputs.nixpkgs-ollama {
    system = pkgs.stdenv.hostPlatform.system;
    config = {
      allowUnfree = true;
      cudaSupport = true;
      cudaCapabilities = [ "9.0" ];
    };
  };
in
{
  services.ollama = {
    enable = true;
    package = ollamaPkgs.ollama-cuda;
    acceleration = "cuda";
    host = "127.0.0.1";
    port = 11434;
    # Pulled by ollama-model-loader.service once ollama.service is up (~16.5 GB).
    loadModels = [ "qwen3.8:27b" ];
  };
}

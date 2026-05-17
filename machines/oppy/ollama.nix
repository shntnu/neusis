{ pkgs, ... }:
{
  services.ollama = {
    enable = true;
    package = pkgs.unstable.ollama-cuda;
    acceleration = "cuda";
    host = "127.0.0.1";
    port = 11434;
  };

  # Optional: Open firewall port if you want to access ollama from other machines
  # networking.firewall.allowedTCPPorts = [ 11434 ];
}

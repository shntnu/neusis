{...}:
{
  # CVE-2026-31431 "Copy Fail" — algif_aead LPE.
  # The `install` directive (not just blacklist) is required: the kernel
  # autoloads algif_aead on AF_ALG socket creation by any local user, and
  # blacklist alone does not block request_module()-driven autoload.
  # Remove this file once flake.lock pulls a nixos-25.11 channel revision
  # whose linux_6_12 is >= 6.12.85 (or kernel is bumped to >= 6.18.26).
  boot.extraModprobeConfig = ''
    install algif_aead /run/current-system/sw/bin/false
  '';
}

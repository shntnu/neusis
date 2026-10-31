{ lib, ... }:
{
  # User-only Neusis override. The imported personal profile is pinned through
  # flake.lock and may lag nixos-config; force these tracked local files so an
  # Oppy rebuild cannot restore GPT-5.5 or Sol's old 272k metadata.
  home.file.".pi/agent/settings.json".source = lib.mkForce ./settings.json;
  home.file.".pi/agent/model-allowlist.ts".source = lib.mkForce ./model-allowlist.ts;
  home.file.".pi/agent/reliable-compaction.ts".source = lib.mkForce ./reliable-compaction.ts;
}

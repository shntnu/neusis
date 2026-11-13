{
  lib,
  stdenv,
  stdenvNoCC,
  fetchurl,
  installShellFiles,
}:
let
  version = "0.167.1";
  targets = {
    x86_64-linux = {
      target = "x86_64-unknown-linux-musl";
      hash = "sha256-qUXfPfg+hJ3Xt0eH4n+KRZwZRrDjr+Pcju+KjRhF/U8=";
    };
    aarch64-linux = {
      target = "aarch64-unknown-linux-musl";
      hash = "sha256-7z4UQ6d5XVlvFgGlM9ciWhAwSI1gyWWvHwYQq5WIkDE=";
    };
  };
  release = targets.${stdenv.hostPlatform.system};
in
stdenvNoCC.mkDerivation {
  pname = "codex";
  inherit version;
  src = fetchurl {
    url = "https://github.com/openai/codex/releases/download/rust-v${version}/codex-package-${release.target}.tar.gz";
    inherit (release) hash;
  };
  sourceRoot = ".";
  dontBuild = true;
  # Official Linux executables use static musl. Preserve their bundled layout
  # and runtime resources; rewriting/stripping the vendor binaries is unwanted.
  dontPatchELF = true;
  dontStrip = true;
  nativeBuildInputs = [ installShellFiles ];

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/libexec/codex" "$out/bin"
    cp -a bin codex-path codex-resources codex-package.json "$out/libexec/codex/"
    chmod -R u+w "$out/libexec/codex"
    # Codex verifies bundled helper digests. Keep the static upstream helpers
    # byte-for-byte intact rather than replacing them with Nixpkgs binaries.
    for binary in codex codex-code-mode-host codex-exec-server; do
      ln -s "../libexec/codex/bin/$binary" "$out/bin/$binary"
    done
    runHook postInstall
  '';

  postInstall = lib.optionalString (stdenv.buildPlatform.canExecute stdenv.hostPlatform) ''
    installShellCompletion --cmd codex \
      --bash <("$out/bin/codex" completion bash) \
      --fish <("$out/bin/codex" completion fish) \
      --zsh <("$out/bin/codex" completion zsh)
  '';

  meta = {
    description = "OpenAI Codex CLI with its official bundled runtime companions";
    homepage = "https://github.com/openai/codex";
    license = lib.licenses.asl20;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = builtins.attrNames targets;
    mainProgram = "codex";
  };
}

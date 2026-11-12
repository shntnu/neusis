{
  lib,
  stdenv,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  openssl,
  zlib,
  libsecret,
  vulkan-loader,
  glib,
  nspr,
  nss,
  at-spi2-core,
  dbus,
  libX11,
  libXcomposite,
  libXdamage,
  libXext,
  libXfixes,
  libXrandr,
  libgbm,
  expat,
  libxcb,
  libxkbcommon,
  systemd,
  alsa-lib,
  fontconfig,
  freetype,
  clientAssets ? null,
}:
let
  version = "0.1.8";
  releases = {
    x86_64-linux = {
      platform = "linux-x64";
      hash = "sha256-ucSdwAwj+7xZYb2v8tiOVW2WyNvWOMRQHik3xwZQqeU=";
    };
    aarch64-linux = {
      platform = "linux-arm64";
      hash = "sha256-K/+/YI7vc2xcNeNDGn5SYdDJCeM9io/rg+8mo3R8+PQ=";
    };
  };
  release = releases.${stdenv.hostPlatform.system};
  browserLibraryPath = lib.makeLibraryPath [
    stdenv.cc.cc.lib
    glib
    nspr
    nss
    at-spi2-core
    dbus
    libX11
    libXcomposite
    libXdamage
    libXext
    libXfixes
    libXrandr
    libgbm
    expat
    libxcb
    libxkbcommon
    systemd
    alsa-lib
    fontconfig
    freetype
  ];
in
stdenvNoCC.mkDerivation {
  pname = "t3code-cli";
  inherit version;

  src = fetchurl {
    url = "https://github.com/pingdotgg/t3code/releases/download/v${version}/t3-${version}-${release.platform}.tar.gz";
    inherit (release) hash;
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];
  buildInputs = [
    stdenv.cc.cc.lib
    openssl
    zlib
    libsecret
    vulkan-loader
  ];
  dontBuild = true;
  # This is an upstream standalone Node executable, not a source build.
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/libexec/t3code" "$out/bin"
    cp -a . "$out/libexec/t3code/"
    chmod -R u+w "$out/libexec/t3code"

    ${lib.optionalString (clientAssets != null) ''
      test -f ${clientAssets}/index.html
      rm -rf "$out/libexec/t3code/client"
      cp -a ${clientAssets} "$out/libexec/t3code/client"
      chmod -R u+w "$out/libexec/t3code/client"
    ''}

    # NixOS uses glibc; bundled musl-only alternatives are never selected here.
    find "$out/libexec/t3code/node_modules" -type d \
      \( -name '*-musl' -o -name 'musl_x64' -o -name 'musl_arm64' \) \
      -prune -exec rm -rf {} +

    makeWrapper "$out/libexec/t3code/t3" "$out/bin/t3" \
      --prefix LD_LIBRARY_PATH : ${lib.escapeShellArg browserLibraryPath} \
      --prefix NIX_LD_LIBRARY_PATH : ${lib.escapeShellArg browserLibraryPath} \
      --set-default T3CODE_RESOURCE_MONITOR_PATH \
        "$out/libexec/t3code/resource-monitor/${release.platform}/t3-resource-monitor"
    runHook postInstall
  '';

  passthru = { inherit browserLibraryPath; };

  meta = {
    description = "T3 Code standalone coding-agent server and CLI";
    homepage = "https://github.com/pingdotgg/t3code";
    license = lib.licenses.mit;
    platforms = builtins.attrNames releases;
    mainProgram = "t3";
  };
}

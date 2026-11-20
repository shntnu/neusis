{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  python3,
  coreutils,
  gnugrep,
  zlib,
  libxcrypt-legacy,
  libGL,
  libx11,
  libxft,
  audit,
  wayland,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "globus-connect-personal";
  version = "3.3.2";

  src = fetchurl {
    # shortcut: rolling upstream URL; refresh version/hash when upstream replaces the pinned archive.
    url = "https://downloads.globus.org/globus-connect-personal/linux/stable/globusconnectpersonal-latest.tgz";
    hash = "sha256-pcYlH8t5W5K+yOyVoyFjgVT9vi7gYQgMUYpaovwt7a4=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
  ];
  buildInputs = [
    zlib
    libxcrypt-legacy
    libGL
    libx11
    libxft
    audit
    wayland
  ];
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/libexec/globus-connect-personal" "$out/bin"
    cp -R . "$out/libexec/globus-connect-personal/"
    patchShebangs "$out/libexec/globus-connect-personal"
    makeWrapper "$out/libexec/globus-connect-personal/globusconnectpersonal" \
      "$out/bin/globusconnectpersonal" \
      --prefix PATH : ${
        lib.makeBinPath [
          python3
          coreutils
          gnugrep
        ]
      }
    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    test "$("$out/bin/globusconnectpersonal" -version)" = "Globus Connect Personal ${finalAttrs.version}"
    "$out/bin/globusconnectpersonal" -setup --help > /dev/null
    GLOBUS_LOCATION="$out/libexec/globus-connect-personal/gt_amd64" \
      LD_LIBRARY_PATH="$out/libexec/globus-connect-personal/gt_amd64/lib" \
      "$out/libexec/globus-connect-personal/gt_amd64/sbin/globus-gridftp-server" -version > /dev/null
    "$out/libexec/globus-connect-personal/gt_amd64/bin/ssh" -V
    runHook postInstallCheck
  '';

  meta = {
    description = "Globus personal file transfer endpoint";
    homepage = "https://docs.globus.org/globus-connect-personal/";
    license = lib.licenses.asl20;
    platforms = [ "x86_64-linux" ];
    mainProgram = "globusconnectpersonal";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
})

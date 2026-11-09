{ fetchurl, runCommand }:

# The pinned Overleaf TeX Live ships lineno 5.7. Its LaTeX >= 2025-06-01
# column hook writes the wrong column tags, moving review numbers into the
# gutter. Upstream 5.9 fixes this without changing conference style files.
# Keep the source immutable; do not upgrade the entire Overleaf runtime.
let
  source = fetchurl {
    url = "https://raw.githubusercontent.com/latex-lineno/lineno/f470c9d42ce1d67e3493b1ca5710fa5e6ac4cbbf/lineno.sty";
    hash = "sha256-WSwl/D/XcpnymAVGIwK/HhnCkEMyjaBKnsNdjbDS9UY=";
  };
in
runCommand "overleaf-lineno-5.9" { } ''
  install -Dm444 ${source} "$out/share/texmf/tex/latex/lineno/lineno.sty"
''

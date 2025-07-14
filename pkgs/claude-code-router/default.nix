{
  lib,
  buildNpmPackage,
  fetchFromGitHub,
  nodejs_20,
}:

buildNpmPackage rec {
  name = "claude-code-router";
  rev = "2d7eee05853a21cf221771193e105417c0ced6fe";

  nodejs = nodejs_20; # required for sandboxed Nix builds on Darwin

  src = fetchFromGitHub {
    inherit rev;
    owner = "leoank";
    repo = name;
    hash = "sha256-zx8KkN6xUh8yO75C+E9RPAKiohmeyeRFt0VB2GHzo1E=";

  };

  npmDepsHash = "sha256-KKl8pWDjNIpupqRNxADkKfvgbuWRS3XC1ASh6cvtTEw=";

  passthru.updateScript = ./update.sh;

  meta = {
    description = "";
    homepage = "";
    downloadPage = "https://www.npmjs.com/package/@musistudio/claude-code-router";
    license = lib.licenses.mit;
    maintainers = [ lib.maintainers.malo ];
    mainProgram = "claude-code-router";
  };
}

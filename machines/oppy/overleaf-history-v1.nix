{
  runCommand,
  makeWrapper,
  nodejs,
  overleaf,
}:

# Upstream history-v1 ignores HISTORY_V1_HOST and calls listen(port) without a
# host. Patch only its entrypoint, retaining the existing dependencies/package
# so this fix does not rebuild or restart every Overleaf service.
runCommand "overleaf-history-v1-loopback" { nativeBuildInputs = [ makeWrapper ]; } ''
  source=${overleaf}/share/overleaf
  target="$out/share/overleaf/services/history-v1"
  mkdir -p "$target" "$out/bin"
  ln -s "$source/node_modules" "$out/share/overleaf/node_modules"
  cp -rs "$source/services/history-v1/." "$target/"
  rm "$target/app.js"
  substitute "$source/services/history-v1/app.js" "$target/app.js" \
    --replace-fail 'app.listen(port, err => {' \
      'app.listen(port, process.env.HISTORY_V1_HOST || "127.0.0.1", err => {'

  makeWrapper ${nodejs}/bin/node "$out/bin/overleaf-history-v1" \
    --chdir "$target" \
    --set NODE_ENV production \
    --set OVERLEAF_CONFIG "$source/server-ce/config/settings.js" \
    --add-flags "$target/app.js"
''

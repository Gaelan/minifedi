{ pkgs }:
let
  binPath = pkgs.lib.makeBinPath (with pkgs; [
    bundix
    coreutils
    diffutils
    nix-prefetch-github
    nix-prefetch-git
    gnused
    jq
    prefetch-yarn-deps
  ]);
in pkgs.runCommand "mastodon-mk-version" {
  nativeBuildInputs = [ pkgs.makeWrapper ];
} ''
  mkdir -p $out/bin
  cp ${./mk-version.sh} $out/bin/mastodon-mk-version
  patchShebangs $out/bin/mastodon-mk-version
  wrapProgram $out/bin/mastodon-mk-version --prefix PATH : ${binPath}
''

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
in pkgs.runCommand "mk-mastodon" {
  nativeBuildInputs = [ pkgs.makeWrapper ];
} ''
  mkdir -p $out/bin
  cp ${./mk-version.sh} $out/bin/mk-mastodon
  patchShebangs $out/bin/mk-mastodon
  wrapProgram $out/bin/mk-mastodon --prefix PATH : ${binPath}
''

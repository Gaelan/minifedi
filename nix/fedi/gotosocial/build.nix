{ stdenv, lib, fetchurl, fetchFromGitHub, buildGoModule, nixosTests }:
let
  owner = "superseriousbusiness";
  repo = "gotosocial";

  version = "0.10.0-rc1";
  source-hash = "sha256-nk/dIlSk71u7NT8rtcHmHiYJCyrIhtkMWr4W5ZYF0YM=";
  web-assets-hash = "sha256-PGoACPpg76sMKk951tUX2i47/1ZUAtBfDme7mSRXrEE=";

  web-assets = fetchurl {
    url =
      "https://github.com/${owner}/${repo}/releases/download/v${version}/${repo}_${version}_web-assets.tar.gz";
    hash = web-assets-hash;
  };
in buildGoModule rec {
  inherit version;
  pname = repo;

  src = fetchFromGitHub {
    inherit owner repo;
    rev = "refs/tags/v${version}";
    hash = source-hash;
  };

  vendorHash = null;

  ldflags = [ "-s" "-w" "-X main.Version=${version}" ];

  postInstall = ''
    tar xf ${web-assets}
    mkdir -p $out/share/gotosocial
    mv web $out/share/gotosocial/
  '';

  # minifedi: tests push us over 4GB build space; not reasonable to expect more
  # than that
  doCheck = false;
}

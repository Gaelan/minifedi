{
  inputs.flake-utils.url = "github:numtide/flake-utils";
  outputs = { self, flake-utils, nixpkgs }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in {
        apps.default = let
          s6 = (import ./nix/s6.nix {
            inherit pkgs;
            services = pkgs.lib.attrsets.mapAttrs (_: v: v.service)
              (import ./nix/services.nix { inherit pkgs; });
            path = "service";
          });
        in {
          type = "app";
          program = let
            script = pkgs.writeShellScript "minifedi" ''
              export PATH=${pkgs.gnugrep}/bin:${pkgs.gnused}/bin:${pkgs.coreutils}/bin

              if ! [[ -e .is-minifedi ]]; then
                echo "please run this from the minifedi directory"
                exit 1
              fi
              mkdir -p data
              mkdir -p cert
              rm -rf data/run
              mkdir data/run
              export MINIFEDI_CERT=$(pwd)/cert
              export MINIFEDI_DATA=$(pwd)/data
              export MINIFEDI_RUN=$(pwd)/data/run
              exec ${s6.start}
            '';
          in "${script}";
        };
        apps.install-cert = {
          type = "app";
          program = let
            script = pkgs.writeShellScript "minifedi-install-cert" ''
              if ! [[ -e .is-minifedi ]]; then
                echo "please run this from the minifedi directory"
                exit 1
              fi

              mkdir -p cert
              export MINIFEDI_CERT=$(pwd)/cert

              CAROOT=$MINIFEDI_CERT ${pkgs.mkcert}/bin/mkcert -install
            '';
          in "${script}";
        };
        apps.x86_64-darwin.mastodon-mk-version = {
          type = "app";
          program = "${
              import ./nix/fedi/mastodon/mk-version { inherit pkgs; }
            }/bin/mastodon-mk-version";
        };
      });
}

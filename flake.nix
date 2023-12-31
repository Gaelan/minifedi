{
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, flake-utils, nixpkgs }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = nixpkgs.legacyPackages.${system};
      in {
        apps.start = let
          config = import ./config.nix {
            types = {
              mastodon = import ./nix/fedi/mastodon;
              akkoma = import ./nix/fedi/akkoma;
              gotosocial = import ./nix/fedi/gotosocial;
            };
          };
          s6 = (import ./nix/s6.nix {
            inherit pkgs;
            services = pkgs.lib.attrsets.mapAttrs (_: v: v.service)
              (import ./nix/services.nix { inherit pkgs config; });
            path = "service";
          });
        in {
          type = "app";
          program = let
            script = pkgs.writeShellScript "minifedi" ''
              oldpath=$PATH
              export PATH=${pkgs.gnugrep}/bin:${pkgs.gnused}/bin:${pkgs.coreutils}/bin

              if ! [[ -e .is-minifedi ]]; then
                echo "please run this from the minifedi directory"
                exit 1
              fi
              mkdir -p data
              mkdir -p cert
              rm -rf data/run
              mkdir data/run
              mkdir -p data/logs
              ${if pkgs.stdenv.isLinux then
                "export LOCALE_ARCHIVE=${pkgs.glibcLocales}/lib/locale/locale-archive"
              else
                ""}
              export MINIFEDI_CERT=$(pwd)/cert
              export MINIFEDI_DATA=$(pwd)/data
              export MINIFEDI_RUN=$(pwd)/data/run
              export MINIFEDI_LOG=$(pwd)/data/logs

              echo "Minifedi is starting! Once they're up, instances will be visible at:"
              ${pkgs.lib.strings.concatStrings (builtins.map (i: ''
                echo "* https://${i.name}.lvh.me"
              '') config.instances)}
              echo "Instance logs are in ./data/logs."
              ${if config.mitmproxy then ''
                echo "View requests between instances at http://localhost:8081."
              '' else
                ""}

              ${if pkgs.stdenv.isLinux then ''
                echo "=> You'll probably get prompted for a sudo password now. This is just so we can bind to port 80/443; we will acquire cap_net_bind_service then switch back to being $USER."
                exec $(PATH=$oldpath which sudo) -E ${pkgs.libcap}/bin/capsh --keep=1 --user="$USER" --inh='cap_net_bind_service' --addamb='cap_net_bind_service' -- -c ${s6.start}
              '' else ''
                exec ${s6.start}
              ''}
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
        apps.mk-mastodon = {
          type = "app";
          program = "${
              import ./nix/fedi/mastodon/mk-version { inherit pkgs; }
            }/bin/mk-mastodon";
        };
      });
}

{
  outputs = { self, nixpkgs }: {
    # nixosModules.base = {pkgs, ...}: {
    #   system.stateVersion = "22.05";

    #   # Configure networking
    #   networking.useDHCP = false;
    #   networking.interfaces.eth0.useDHCP = true;

    #   # Create user "test"
    #   services.getty.autologinUser = "test";
    #   users.users.test.isNormalUser = true;

    #   # Enable passwordless ‘sudo’ for the "test" user
    #   users.users.test.extraGroups = ["wheel"];
    #   security.sudo.wheelNeedsPassword = false;
    # };
    # nixosModules.vm = {...}: {
    #   # Make VM output to the terminal instead of a separate window
    #   virtualisation.vmVariant.virtualisation.graphics = false;
    # };
    # nixosConfigurations.darwinVM = nixpkgs.lib.nixosSystem {
    #   system = "x86_64-linux";
    #   modules = [
    #     (builtins.trace (builtins.attrNames self) self.nixosModules.base)
    #     self.nixosModules.vm
    #     {
    #       virtualisation.vmVariant.virtualisation.host.pkgs = nixpkgs.legacyPackages.x86_64-darwin;
    #     }
    #   ];
    # };
    # packages.x86_64-darwin.darwinVM = self.nixosConfigurations.darwinVM.config.system.build.vm;
    apps.x86_64-darwin.default = let
      pkgs = nixpkgs.legacyPackages.x86_64-darwin;
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
    apps.x86_64-darwin.install-cert =
      let pkgs = nixpkgs.legacyPackages.x86_64-darwin;
      in {
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
    apps.x86_64-darwin.mastodon-mk-version =
      let pkgs = nixpkgs.legacyPackages.x86_64-darwin;
      in {
        type = "app";
        program = "${
            import ./nix/fedi/mastodon/mk-version { inherit pkgs; }
          }/bin/mastodon-mk-version";
      };
  };
}

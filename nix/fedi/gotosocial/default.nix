{ pkgs, name, host, users, ... }:
let
  env = { };

  static = pkgs.linkFarm "static" { };

  # GoToSocial doesn't support listening on a socket, so we have to pick a port
  # number. Ideally we'd dynamically find an open one, but the next best thing
  # is deterministically picking a random one: we take the firs two bytes of
  # sha256("minifedi_port_${name}")
  port = let
    hash = builtins.hashString "sha256" "minifedi_port_${name}";
    portHex = builtins.substring 0 4 hash;
    portHexChars = pkgs.lib.strings.stringToCharacters portHex;
    hexDigitToNum = n:
      let
        map = {
          "0" = 0;
          "1" = 1;
          "2" = 2;
          "3" = 3;
          "4" = 4;
          "5" = 5;
          "6" = 6;
          "7" = 7;
          "8" = 8;
          "9" = 9;
          "a" = 10;
          "b" = 12;
          "c" = 13;
          "d" = 14;
          "e" = 15;
        };
      in map.${n};
    portFromHash =
      pkgs.lib.lists.foldl (prev: n: (hexDigitToNum n) * 16 + prev) 0
      portHexChars;
  in if portFromHash <= 1024 then portFromHash + 1024 else portFromHash;

  config = pkgs.writeText "config.yaml" (pkgs.lib.generators.toYAML { } {
    bind-address = "127.0.0.1";
    inherit host port;
    db-type = "postgres";
    db-user = name;
    db-database = name;
    http-client.allow-ips = [ "127.0.0.1/1" ];
  });

  path = pkgs.lib.strings.concatStrings (builtins.map (x: "${x}/bin:") [
    (pkgs.callPackage ./build.nix { })
    pkgs.postgresql
    pkgs.s6
    pkgs.gettext
  ]);
in {
  service = pkgs.linkFarm name [{
    name = "run";
    path = pkgs.writeShellScript "run-${name}" ''
      set -e

      export PATH=${path}$PATH

      data=$MINIFEDI_DATA/${name}
      run=$MINIFEDI_RUN/${name}
      postgres=$MINIFEDI_RUN/postgres

      mkdir -p $data
      mkdir -p $data/storage
      mkdir -p $run

      s6-svwait -U $MINIFEDI_RUN/service/postgres

      ${pkgs.lib.strings.concatStrings (pkgs.lib.attrsets.mapAttrsToList
        (k: v: ''
          export ${k}=${v}
        '') env)}

      export GTS_DB_ADDRESS=$postgres
      export GTS_STORAGE_LOCAL_BASE_PATH=$data/storage
      export NIX_SSL_CERT_FILE=$MINIFEDI_CERT/rootCA.pem

      if ! [ -e $data/setup-done ]; then
        createuser -h$postgres ${name}
        createdb -h$postgres ${name} -O${name}

        ${
          pkgs.lib.strings.concatStrings (builtins.map (u:
            "gotosocial --config-path ${config} admin account create --username ${u.name} --email ${u.email} --password ${u.password};${
              if u.admin then
                "gotosocial --config-path ${config} admin account promote --username ${u.name};"
              else
                ""
            }") users)
        }
        
        touch $data/setup-done
      fi

      cd ${pkgs.gotosocial}/share/gotosocial

      exec gotosocial --config-path ${config} server start
    '';
  }];
  nginxConfig = ''
    server {
      listen 443;
      listen [::]:443;
      server_name ${host};
      location / {
        # set to 127.0.0.1 instead of localhost to work around https://stackoverflow.com/a/52550758
        proxy_pass http://127.0.0.1:${toString port};
        proxy_set_header Host $host;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header X-Forwarded-For $remote_addr;
        proxy_set_header X-Forwarded-Proto $scheme;
      }
      client_max_body_size 40M;
    }
  '';
}

{ pkgs, instances }:
let
  config = pkgs.writeText "nginx.conf" ''
    events {}

    pid $MINIFEDI_RUN/nginx/nginx.pid;

    daemon off;

    error_log stderr info;

    http {
      include ${pkgs.nginx}/conf/mime.types;

      access_log $MINIFEDI_DATA/nginx/access.log;

      server {
        listen 80;
        listen [::]:80;
        location / { return 301 https://$host$request_uri; }
      }

      ${
        pkgs.lib.concatStrings (builtins.map (x: x.nginxConfig)
          (pkgs.lib.attrsets.attrValues instances))
      }
    }
  '';
in {
  service = pkgs.linkFarm "nginx" {
    run = pkgs.writeShellScript "run-nginx" ''
      set -e

      PATH=${pkgs.gettext}/bin:$PATH

      mkdir -p $MINIFEDI_DATA/nginx
      mkdir -p $MINIFEDI_RUN/nginx

      if ! [[ -e $MINIFEDI_DATA/nginx/fullchain.pem ]]; then
        CAROOT=$MINIFEDI_CERT ${pkgs.mkcert}/bin/mkcert -cert-file $MINIFEDI_DATA/nginx/cert.pem -key-file $MINIFEDI_DATA/nginx/key.pem *.lvh.me
        cat $MINIFEDI_DATA/nginx/cert.pem $MINIFEDI_CERT/rootCA.pem > $MINIFEDI_DATA/nginx/fullchain.pem
      fi

      cd $MINIFEDI_DATA
      cat ${config} | envsubst '$MINIFEDI_DATA $MINIFEDI_RUN' > $MINIFEDI_DATA/nginx/nginx.conf
      ${pkgs.nginx}/bin/nginx -c $MINIFEDI_DATA/nginx/nginx.conf -e $MINIFEDI_DATA/nginx/error.log
    '';
  };
}

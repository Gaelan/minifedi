{ pkgs, name }:
let
  mastodon = pkgs.callPackage ./build.nix { };
  env = {
    LOCAL_DOMAIN = "${name}.lvh.me";
    WEB_DOMAIN = "${name}.lvh.me";
    ALLOWED_PRIVATE_ADDRESSES = "127.0.0.1";
    RAILS_ENV = "production";
    NODE_ENV = "production";
    DB_USER = name;
    DB_NAME = name;
    REDIS_NAMESPACE = "${name}_";
    EMAIL_DOMAIN_ALLOWLIST = "${name}.example";
    SMTP_DELIVERY_METHOD = "file";
  };
  s6 = import ../../s6.nix {
    inherit pkgs;
    services = {
      web = pkgs.linkFarm "web" {
        run = pkgs.writeShellScript "run-web" ''
          cd ${mastodon}

          export SOCKET=$MINIFEDI_RUN/${name}/web.sock

          puma -C config/puma.rb
        '';
      };
      sidekiq = pkgs.linkFarm "sidekiq" {
        run = pkgs.writeShellScript "run-sidekiq" ''
          cd ${mastodon}
          sidekiq
        '';
      };
      streaming = pkgs.linkFarm "sidekiq" {
        run = pkgs.writeShellScript "run-sidekiq" ''
          cd ${mastodon}

          export SOCKET=$MINIFEDI_RUN/${name}/streaming.sock

          ${mastodon}/run-streaming.sh
        '';
      };
    };
    path = "${name}/service";
  };
  path = pkgs.lib.strings.concatStrings (builtins.map (x: "${x}/bin:") [
    mastodon
    pkgs.postgresql
    pkgs.s6
    # used by mastodon file upload:
    pkgs.file
    pkgs.imagemagick
    # used by sidekiq:
    pkgs.ps
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
      mkdir -p $data/files
      mkdir -p $run

      cd ${mastodon}

      ${pkgs.lib.strings.concatStrings (pkgs.lib.attrsets.mapAttrsToList
        (k: v: ''
          export ${k}=${v}
        '') env)}

      if ! [ -e $data/setup-done ]; then
        rake secret > $data/secret_key_base
        rake secret > $data/otp_secret
        # from nixos
        keypair=$(rake webpush:generate_keys)
        echo $keypair | grep --only-matching "Private -> [^ ]\+" | sed 's/^Private -> //' > $data/vapid_private_key
        echo $keypair | grep --only-matching "Public -> [^ ]\+" | sed 's/^Public -> //' > $data/vapid_public_key
      fi

      export SECRET_KEY_BASE=$(cat $data/secret_key_base)
      export OTP_SECRET=$(cat $data/otp_secret)
      export VAPID_PRIVATE_KEY=$(cat $data/vapid_private_key)
      export VAPID_PUBLIC_KEY=$(cat $data/vapid_public_key)

      export DB_HOST=$postgres
      export REDIS_URL=unix://$MINIFEDI_RUN/redis/redis.sock
      export NIX_SSL_CERT_FILE=$MINIFEDI_CERT/rootCA.pem
      export PAPERCLIP_ROOT_PATH=$data/files

      s6-svwait -U $MINIFEDI_RUN/service/postgres

      if ! [ -e $data/setup-done ]; then
        createdb -h$postgres ${name}
        createuser -h$postgres ${name}

        rails db:schema:load
        rails db:seed

        touch $data/setup-done

        tootctl accounts create a --email=a@${name}.example --confirmed --role Owner
        rails runner "Account.find_local('a').user.update!(password: 'Aa12345!')"
        tootctl accounts create b --email=b@${name}.example --confirmed
        rails runner "Account.find_local('b').user.update!(password: 'Bb12345!')"
        tootctl accounts create c --email=c@${name}.example --confirmed
        rails runner "Account.find_local('c').user.update!(password: 'Cc12345!')"
        tootctl accounts create d --email=d@${name}.example --confirmed
        rails runner "Account.find_local('d').user.update!(password: 'Dd12345!')"
        tootctl accounts create e --email=e@${name}.example --confirmed
        rails runner "Account.find_local('e').user.update!(password: 'Ee12345!')"
      fi

      exec ${s6.start}
    '';
  }];
  nginxConfig = ''
    map $http_upgrade ${"$"}${name}_connection_upgrade {
      default upgrade;
      ${"''"} close;
    }

    upstream ${name}_backend {
      server unix:$MINIFEDI_RUN/${name}/web.sock fail_timeout=0;
    }

    upstream ${name}_streaming {
      server unix:$MINIFEDI_RUN/${name}/streaming.sock fail_timeout=0;
    }

    server {
      listen 443 ssl http2;
      listen [::]:443 ssl http2;
      server_name ${name}.lvh.me;

      ssl_protocols TLSv1.2 TLSv1.3;
      ssl_ciphers HIGH:!MEDIUM:!LOW:!aNULL:!NULL:!SHA;
      ssl_prefer_server_ciphers on;
      ssl_session_cache shared:SSL:10m;
      ssl_session_tickets off;

      # Uncomment these lines once you acquire a certificate:
      ssl_certificate     $MINIFEDI_DATA/nginx/fullchain.pem;
      ssl_certificate_key $MINIFEDI_DATA/nginx/key.pem;

      keepalive_timeout    70;
      sendfile             on;
      client_max_body_size 99m;

      root ${mastodon}/public;

      gzip on;
      gzip_disable "msie6";
      gzip_vary on;
      gzip_proxied any;
      gzip_comp_level 6;
      gzip_buffers 16 8k;
      gzip_http_version 1.1;
      gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript image/svg+xml image/x-icon;

      location / {
        try_files $uri @proxy;
      }

      # If Docker is used for deployment and Rails serves static files,
      # then needed must replace line `try_files $uri =404;` with `try_files $uri @proxy;`.
      location = /sw.js {
        add_header Cache-Control "public, max-age=604800, must-revalidate";
        add_header Strict-Transport-Security "max-age=63072000; includeSubDomains";
        try_files $uri =404;
      }

      location ~ ^/assets/ {
        add_header Cache-Control "public, max-age=2419200, must-revalidate";
        add_header Strict-Transport-Security "max-age=63072000; includeSubDomains";
        try_files $uri =404;
      }

      location ~ ^/avatars/ {
        add_header Cache-Control "public, max-age=2419200, must-revalidate";
        add_header Strict-Transport-Security "max-age=63072000; includeSubDomains";
        try_files $uri =404;
      }

      location ~ ^/emoji/ {
        add_header Cache-Control "public, max-age=2419200, must-revalidate";
        add_header Strict-Transport-Security "max-age=63072000; includeSubDomains";
        try_files $uri =404;
      }

      location ~ ^/headers/ {
        add_header Cache-Control "public, max-age=2419200, must-revalidate";
        add_header Strict-Transport-Security "max-age=63072000; includeSubDomains";
        try_files $uri =404;
      }

      location ~ ^/packs/ {
        add_header Cache-Control "public, max-age=2419200, must-revalidate";
        add_header Strict-Transport-Security "max-age=63072000; includeSubDomains";
        try_files $uri =404;
      }

      location ~ ^/shortcuts/ {
        add_header Cache-Control "public, max-age=2419200, must-revalidate";
        add_header Strict-Transport-Security "max-age=63072000; includeSubDomains";
        try_files $uri =404;
      }

      location ~ ^/sounds/ {
        add_header Cache-Control "public, max-age=2419200, must-revalidate";
        add_header Strict-Transport-Security "max-age=63072000; includeSubDomains";
        try_files $uri =404;
      }

      location /system/ {
        add_header Cache-Control "public, max-age=2419200, immutable";
        add_header Strict-Transport-Security "max-age=63072000; includeSubDomains";

        alias $MINIFEDI_DATA/${name}/files/;

        try_files $uri =404;
      }

      location ^~ /api/v1/streaming {
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Proxy "";

        proxy_pass http://${name}_streaming;
        proxy_buffering off;
        proxy_redirect off;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection ${"$"}${name}_connection_upgrade;

        add_header Strict-Transport-Security "max-age=63072000; includeSubDomains";

        tcp_nodelay on;
      }

      location @proxy {
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Proxy "";
        proxy_pass_header Server;

        proxy_pass http://${name}_backend;
        proxy_buffering on;
        proxy_redirect off;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection ${"$"}${name}_connection_upgrade;

        # proxy_cache CACHE;
        # proxy_cache_valid 200 7d;
        # proxy_cache_valid 410 24h;
        # proxy_cache_use_stale error timeout updating http_500 http_502 http_503 http_504;
        add_header X-Cached $upstream_cache_status;

        tcp_nodelay on;
      }

      error_page 404 500 501 502 503 504 /500.html;
    }
  '';
}

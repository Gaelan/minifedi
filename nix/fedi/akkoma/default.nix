{ pkgs, name, }:
let
  env = {
    MIX_ENV = "prod";
    ERL_EPMD_ADDRESS = "127.0.0.1";
  };

  static = pkgs.linkFarm "static" {
    frontends = pkgs.linkFarm "frontends" {
      akkoma =
        pkgs.linkFarm "pleroma" { stable = pkgs.akkoma-frontends.akkoma-fe; };
      # admin =
      #   pkgs.linkFarm "admin" { stable = pkgs.akkoma-frontends.admin-fe; };
    };
  };

  config = pkgs.writeText "config.exs" ''
    import Config

    config :pleroma, Pleroma.Web.Endpoint,
      url: [host: "${name}.lvh.me", scheme: "https", port: 443],
      http: [ip: {:local, "$MINIFEDI_RUN/${name}/akkoma.sock"}, port: 0],
      secret_key_base: "$SECRET_KEY_BASE",
      live_view: [signing_salt: "$LIVE_VIEW_SIGNING_SALT"],
      signing_salt: "$SIGNING_SALT"

    config :pleroma, :instance,
      name: "${name}",
      email: "a@${name}.example",
      notify_email: "noreply@${name}.example",
      limit: 5000,
      registrations_open: true

    config :pleroma, :media_proxy,
      enabled: false,
      redirect_on_failure: true
      #base_url: "https://cache.pleroma.social"

    config :pleroma, Pleroma.Repo,
      adapter: Ecto.Adapters.Postgres,
      username: "${name}",
      password: "",
      database: "${name}",
      socket_dir: "$MINIFEDI_RUN/postgres/"

    # Configure web push notifications
    config :web_push_encryption, :vapid_details,
      subject: "mailto:a@${name}.example",
      public_key: "$WEB_PUSH_PUBLIC_KEY",
      private_key: "$WEB_PUSH_PRIVATE_KEY"

    config :pleroma, :database, rum_enabled: false
    config :pleroma, :instance, static_dir: "${static}"
    config :pleroma, Pleroma.Uploaders.Local, uploads: "$MINIFEDI_DATA/${name}/uploads"

    config :joken, default_signer: "$JWT_SECRET"

    config :pleroma, configurable_from_database: false

    config :tzdata, :data_dir, "$MINIFEDI_DATA/${name}/tzdata"

    config :pleroma, :frontends,
      primary: %{
        "name" => "akkoma",
        "ref" => "stable"
      }

    config :pleroma, :http, adapter: [pools: %{default: [conn_opts: [transport_opts: [cacertfile: "$MINIFEDI_CERT/rootCA.pem"]]]}]
  '';
  # admin: %{
  #   "name" => "admin",
  #   "ref" => "stable"
  # }

  path = pkgs.lib.strings.concatStrings (builtins.map (x: "${x}/bin:") [
    pkgs.akkoma
    pkgs.elixir
    pkgs.s6
    pkgs.postgresql
    # used by pleroma shell script for rpc
    pkgs.gawk
    # envsubst
    pkgs.gettext
    # used to generate keys
    pkgs.openssl
  ]);
in {
  service = pkgs.linkFarm name [{
    name = "run";
    path = pkgs.writeShellScript "run-${name}" ''
      set -e

      export PATH=${path}$PATH

      cd ${pkgs.akkoma}

      data=$MINIFEDI_DATA/${name}
      run=$MINIFEDI_RUN/${name}
      postgres=$MINIFEDI_RUN/postgres

      mkdir -p $data
      mkdir -p $data/uploads
      mkdir -p $data/tzdata
      mkdir -p $run

      s6-svwait -U $MINIFEDI_RUN/service/postgres

      ${pkgs.lib.strings.concatStrings (pkgs.lib.attrsets.mapAttrsToList
        (k: v: ''
          export ${k}=${v}
        '') env)}

      if ! [ -e $data/setup-done ]; then
        openssl rand -base64 64 | head -c 64 > $data/secret_key_base
        openssl rand -base64 64 | head -c 64 > $data/jwt_secret
        openssl rand -base64 8 | head -c 8 > $data/signing_salt
        openssl rand -base64 8 | head -c 8 > $data/live_view_signing_salt
        openssl ecparam -genkey -name prime256v1 | openssl ec -out $data/web_push_keypair.pem
        openssl ec -in $data/web_push_keypair.pem -pubout -out $data/web_push_public_key
        openssl ec -in $data/web_push_keypair.pem -out $data/web_push_private_key
      fi

      export SECRET_KEY_BASE=$(cat $data/secret_key_base)
      export JWT_SECRET=$(cat $data/jwt_secret)
      export SIGNING_SALT=$(cat $data/jwt_secret)
      export LIVE_VIEW_SIGNING_SALT=$(cat $data/live_view_signing_salt)
      export WEB_PUSH_PRIVATE_KEY=$(cat $data/web_push_private_key)
      export WEB_PUSH_PUBLIC_KEY=$(cat $data/web_push_public_key)

      export RELEASE_COOKIE=$(openssl rand -base64 64)

      cat ${config} | envsubst > $data/config.exs
      export AKKOMA_CONFIG_PATH=$data/config.exs

      # elixir takes 2 sigints to exit if it has something on stdin
      exec </dev/null

      if ! [ -e $data/setup-done ]; then
        createuser -h$postgres ${name}
        createdb -h$postgres ${name} -O${name}

        psql -h$postgres -d${name} -c 'CREATE EXTENSION IF NOT EXISTS citext;'
        psql -h$postgres -d${name} -c 'CREATE EXTENSION IF NOT EXISTS pg_trgm;'
        psql -h$postgres -d${name} -c 'CREATE EXTENSION IF NOT EXISTS "uuid-ossp";'

        pleroma_ctl migrate

        export PLEROMA_CTL_RPC_DISABLED=true
        pleroma_ctl user new a a@${name}.example --assume-yes --password Aa12345! --admin
        pleroma_ctl user new b b@${name}.example --assume-yes --password Bb12345!
        pleroma_ctl user new c c@${name}.example --assume-yes --password Cc12345!
        pleroma_ctl user new d d@${name}.example --assume-yes --password Dd12345!
        pleroma_ctl user new e e@${name}.example --assume-yes --password Ee12345!
        
        touch $data/setup-done
      fi

      exec pleroma start
    '';
  }];
  nginxConfig = ''
    upstream ${name}_phoenix {
      server unix:$MINIFEDI_RUN/${name}/akkoma.sock max_fails=5 fail_timeout=60s;
    }

    # Enable SSL session caching for improved performance
    ssl_session_cache shared:ssl_session_cache:10m;

    server {
      server_name ${name}.lvh.me;

      listen 443 ssl http2;
      listen [::]:443 ssl http2;
      ssl_session_timeout 1d;
      ssl_session_cache shared:MozSSL:10m;  # about 40000 sessions
      ssl_session_tickets off;

      ssl_certificate           $MINIFEDI_DATA/nginx/fullchain.pem;
      ssl_certificate_key       $MINIFEDI_DATA/nginx/key.pem;

      ssl_protocols TLSv1.2 TLSv1.3;
      ssl_ciphers "ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384:!aNULL:!eNULL:!EXPORT:!DES:!MD5:!PSK:!RC4";
      ssl_prefer_server_ciphers off;
      ssl_ecdh_curve X25519:prime256v1:secp384r1:secp521r1;

      gzip_vary on;
      gzip_proxied any;
      gzip_comp_level 6;
      gzip_buffers 16 8k;
      gzip_http_version 1.1;
      gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript application/activity+json application/atom+xml;

      # the nginx default is 1m, not enough for large media uploads
      client_max_body_size 16m;
      ignore_invalid_headers off;

      proxy_http_version 1.1;
      proxy_set_header Upgrade $http_upgrade;
      proxy_set_header Connection "upgrade";
      proxy_set_header Host $http_host;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

      location / {
        proxy_pass http://${name}_phoenix;
      }

      location ~ ^/(media|proxy) {
        proxy_ignore_client_abort on;
        proxy_buffering    on;
        chunked_transfer_encoding on;
        proxy_pass         http://${name}_phoenix;
      }
    }
  '';
}

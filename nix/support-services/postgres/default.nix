{ pkgs }:

{
  service = pkgs.linkFarm "postgres" {
    run = pkgs.writeShellScript "run-postgres-outer" ''
      exec >$MINIFEDI_LOG/postgres.log 2>$MINIFEDI_LOG/postgres.log

      exec ${pkgs.s6}/bin/s6-notifyoncheck ${
        pkgs.writeShellScript "run-postgres-inner" ''
          export PATH=${pkgs.gettext}/bin:$PATH

          mkdir -p $MINIFEDI_DATA/postgres
          mkdir -p $MINIFEDI_RUN/postgres
          cd $MINIFEDI_DATA/postgres
          export PGDATA=$(pwd)/data
          [[ -e $PGDATA ]] || ${pkgs.postgresql}/bin/initdb
          cat ${./postgresql.conf} | envsubst > $PGDATA/postgresql.conf
          exec ${pkgs.postgresql}/bin/postgres
        ''
      }
    '';

    data = pkgs.linkFarm "data" {
      check = pkgs.writeShellScript "check-postgres" ''
        ${pkgs.postgresql}/bin/pg_isready -h $MINIFEDI_RUN/postgres
      '';
    };

    notification-fd = pkgs.writeText "notification-fd" "3";
  };
}

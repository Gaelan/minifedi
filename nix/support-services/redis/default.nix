{ pkgs }:
let
  config = pkgs.writeText "redis.conf" ''
    port 0
    protected-mode yes
  '';
in {
  service = pkgs.linkFarm "redis" {
    run = pkgs.writeShellScript "run-redis" ''
      set -e

      mkdir -p $MINIFEDI_DATA/redis
      mkdir -p $MINIFEDI_RUN/redis

      exec >$MINIFEDI_LOG/redis.log 2>$MINIFEDI_LOG/redis.log

      cd $MINIFEDI_RUN/redis
      exec ${pkgs.redis}/bin/redis-server ${config} --unixsocket $MINIFEDI_RUN/redis/redis.sock
    '';
  };
}

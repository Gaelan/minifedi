{ pkgs }:
let
  config = pkgs.writeText "redis.conf" ''
    port 0
    protected-mode yes
  '';
in {
  service = pkgs.linkFarm "nginx" {
    run = pkgs.writeShellScript "run-nginx" ''
      set -e

      mkdir -p $MINIFEDI_DATA/redis
      mkdir -p $MINIFEDI_RUN/redis

      cd $MINIFEDI_RUN/redis
      ${pkgs.redis}/bin/redis-server ${config} --unixsocket $MINIFEDI_RUN/redis/redis.sock
    '';
  };
}

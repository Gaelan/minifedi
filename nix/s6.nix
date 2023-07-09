{ pkgs, services, path }:

let scandir = pkgs.linkFarm "service" services;
in {
  start = pkgs.writeShellScript "s6-start" ''
    cp -RL ${scandir} $MINIFEDI_RUN/${path}
    chmod -R +w $MINIFEDI_RUN/${path}
    exec ${pkgs.s6}/bin/s6-svscan $MINIFEDI_RUN/${path}
  '';
}

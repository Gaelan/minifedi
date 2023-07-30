{ pkgs }: {
  service = pkgs.linkFarm "mitmproxy" {
    run = pkgs.writeShellScript "run-mitmproxy" ''
      set -e

      mkdir -p $MINIFEDI_DATA/mitmproxy

      exec >$MINIFEDI_LOG/mitmproxy.log 2>$MINIFEDI_LOG/mitmproxy.log

      if ! [[ -e $MINIFEDI_DATA/mitmproxy/fullchain.pem ]]; then
        CAROOT=$MINIFEDI_CERT ${pkgs.mkcert}/bin/mkcert -cert-file $MINIFEDI_DATA/mitmproxy/cert.pem -key-file $MINIFEDI_DATA/mitmproxy/key.pem *.lvh.me
        cat $MINIFEDI_DATA/mitmproxy/key.pem $MINIFEDI_DATA/mitmproxy/cert.pem $MINIFEDI_CERT/rootCA.pem > $MINIFEDI_DATA/mitmproxy/fullchain.pem
      fi

      exec ${pkgs.mitmproxy}/bin/mitmweb --certs $MINIFEDI_DATA/mitmproxy/fullchain.pem -k -v  
    '';
  };
}

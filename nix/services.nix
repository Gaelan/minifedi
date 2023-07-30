{ pkgs, config }:
let
  instances = config.instances;
  util = import ./util.nix { inherit pkgs; };
  evaldInstances = builtins.listToAttrs (builtins.map (inst:
    pkgs.lib.attrsets.nameValuePair inst.name (inst.type ({
      inherit pkgs util;
      host = "${inst.name}.lvh.me";
      users = [
        {
          name = "a";
          email = "a@example.com";
          password = "MiniFediA1!";
          admin = true;
        }
        {
          name = "b";
          email = "b@example.com";
          password = "MiniFediB1!";
          admin = false;
        }
        {
          name = "c";
          email = "c@example.com";
          password = "MiniFediC1!";
          admin = false;
        }
        {
          name = "d";
          email = "d@example.com";
          password = "MiniFediD1!";
          admin = false;
        }
        {
          name = "e";
          email = "e@example.com";
          password = "MiniFediE1!";
          admin = false;
        }
      ];
      proxy = if config.mitmproxy then "http://localhost:8080" else null;
    } // inst))) instances);
in evaldInstances // {
  postgres = import ./support-services/postgres { inherit pkgs; };
  redis = import ./support-services/redis { inherit pkgs; };
  nginx = import ./support-services/nginx {
    inherit pkgs;
    instances = evaldInstances;
  };
} // pkgs.lib.attrsets.optionalAttrs config.mitmproxy {
  mitmproxy = import ./support-services/mitmproxy { inherit pkgs; };
}

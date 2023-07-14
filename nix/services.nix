{ pkgs, configFn }:
let
  instances = (configFn {
    types = {
      mastodon = import ./fedi/mastodon;
      akkoma = import ./fedi/akkoma;
      gotosocial = import ./fedi/gotosocial;
    };
  }).instances;
  evaldInstances = builtins.listToAttrs (builtins.map (inst:
    pkgs.lib.attrsets.nameValuePair inst.name (inst.type ({
      inherit pkgs;
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
    } // inst))) instances);
in evaldInstances // {
  postgres = import ./support-services/postgres { inherit pkgs; };
  redis = import ./support-services/redis { inherit pkgs; };
  nginx = import ./support-services/nginx {
    inherit pkgs;
    instances = evaldInstances;
  };
}

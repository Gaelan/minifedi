{ pkgs }:
let
  instances = [
    {
      name = "mastodon";
      type = ./fedi/mastodon;
      versionDef = ../versions/mastodon/mastodon-4.1.4;
    }
    {
      name = "glitch";
      type = ./fedi/mastodon;
      versionDef = ../versions/mastodon/glitch-a40529f;
    }
    {
      name = "akkoma";
      type = ./fedi/akkoma;
    }
    {
      name = "gotosocial";
      type = ./fedi/gotosocial;
    }
  ];
  evaldInstances = builtins.listToAttrs (builtins.map (inst:
    pkgs.lib.attrsets.nameValuePair inst.name (import inst.type ({
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

{ pkgs }:
let
  instances = {
    mastodon = import ./fedi/mastodon {
      inherit pkgs;
      name = "mastodon";
      versionDef = ../versions/mastodon/mastodon-4.1.4;
    };
    glitch = import ./fedi/mastodon {
      inherit pkgs;
      name = "glitch";
      versionDef = ../versions/mastodon/glitch-a40529f;
    };
    akkoma = import ./fedi/akkoma {
      inherit pkgs;
      name = "akkoma";
    };
  };
in instances // {
  postgres = import ./support-services/postgres { inherit pkgs; };
  redis = import ./support-services/redis { inherit pkgs; };
  nginx = import ./support-services/nginx {
    inherit pkgs;
    inherit instances;
  };
}

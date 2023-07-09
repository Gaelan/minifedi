{ pkgs }:
let
  instances = {
    mastodon = import ./fedi/mastodon {
      inherit pkgs;
      name = "mastodon";
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

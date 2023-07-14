{ types }:

{
  instances = [
    {
      name = "mastodon";
      type = types.mastodon;
      version = ./versions/mastodon/mastodon-4.1.4;
    }
    {
      name = "glitch";
      type = types.mastodon;
      version = ./versions/mastodon/glitch-a004718;
    }
    {
      name = "akkoma";
      type = types.akkoma;
    }
    {
      name = "gotosocial";
      type = types.gotosocial;
    }
  ];
}

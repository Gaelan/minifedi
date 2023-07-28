# Minifedi

Minifedi is a tool to quickly spin up a bunch of ActivityPub servers for local testing.

Minifedi is entirely self-contained and needs no changes to your system configuration besides installing Nix; you can install it with a git clone, delete it with `rm -rf`, and your system will be exactly the way it was before.

## System Requirements

- macOS or Linux (any distribution). Tested on x86_64, aarch64 should work. Other architectues probably won't due to poor Nix support, unfortunately.
  - Windows isn't natively supported, but might work under WSL.
- A recent version of [Nix](https://nixos.org).
  - This doesn't mean you need to be on NixOS; Nix can be installed on more or less any distribution, and is happy to do its own thing without interfering with your system.
- ~4GB free on disk.
- ~4GB free in /tmp.
  - On many Linux distributions, this means you'll need ~8GB of RAM.
  - You might be able to get away with less if you disable GoToSocial.
- Ports 80 and 443 free.
  - This is required because some (all) fedi software is only willing to federate with servers on the standard ports.
  - macOS lets any user listen on these ports. On Linux, Minifedi will use sudo to gain the capability required to listen on these ports, then immediately switch back to your user and relinquish all other capabilties.

## Warnings

Minifedi is very new software. I'm fairly sure it won't break your system (it's designed very specifically to not do anything that possibly could) but it might not work either.

Minifedi is designed for testing only. The assumption is you'll happily throw out everything stored in it when you're done. Don't store anything you care about in an instance run by Minifedi.

## Getting Started

Minifedi's goal is to "just work" on every machine. If the instructions below fail for you, please file an issue; I'll fix it if at all possible.

1. Install [Nix](https://nixos.org), if you haven't.
   - If you install Nix through your OS package manager, you may need to add yourself to the `nix-users` group and/or ensure the `nix-daemon` service is enabled.
2. ```
   git clone https://github.com/Gaelan/minifedi.git
   cd minifedi
   ```
3. If you'd like, edit `config.nix` to customize which instances you get. By default, you get one each of Mastodon, Glitch, Akkoma, and GoToSocial, but you're welcome to disable some or run multiple copies of the same type.
4. `./minifedi start`
5. Wait for stuff to build then start up; this should take 20-30 minutes.
6. Your instances should be running and accessible at INSTANCENAME.lvh.me (e.g. https://mastodon.lvh.me).
   - You'll have to click through an HTTPS warning; if you'd like, you can run `./minifedi install-cert` to add Minifedi's root to your system certificate store, avoiding this. (We don't do this by default, as our policy is not to touch your system configuration.)

Each instance is created by default with five users:

- username `a`, email `a@example.com`, password `MiniFediA1!`, admin
- username `b`, email `b@example.com`, password `MiniFediB1!`
- username `c`, email `c@example.com`, password `MiniFediC1!`
- username `d`, email `d@example.com`, password `MiniFediD1!`
- username `e`, email `e@example.com`, password `MiniFediE1!`

Enjoy your testing!

## Supported Software

Minifedi currently supports the following:

- Mastodon
- Akkoma
- GoToSocial

Forks of the above should work fine as well, as long as they haven't changed anything about the build, installation, or configuration process.

## How do I…

### Reset Minifedi, restoring every instance to its default state?

```sh
rm -r data/
```

### Use a different version (including a fork) of Mastodon?

```sh
./minifedi mk-mastodon NAME REPO COMMIT-OR-TAG
# eg
./minifedi mk-mastodon mastodon-4.1.4 https://github.com/Mastodon/Mastodon.git v4.1.4
```

This'll create a directory in `versions/mastodon`, which you can then refer to from your `config.nix`.

Custom versions for Akkoma and GoToSocial aren't supported yet.

### Use Minifedi to test some fedi software I'm hacking on locally?

There isn't a good solution for this yet, but the plan is that you'll run your software locally however you usually do, with Minifedi's nginx running in front to serve it from a domain accessible to the other instances.

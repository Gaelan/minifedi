# MINIFEDI IS NOT DONE. It's like 80% of the way there, but the docs below remain slightly aspirational for the moment.

# Minifedi

Minifedi is a tool to quickly spin up a bunch of ActivityPub servers for local testing.

Minifedi should run on any macOS or Linux system with [Nix](https://nixos.org) installed. (Nix itself works fine on any Linux distribution; you don't need to be using NixOS.) Windows isn't natively supported, but WSL should work. Minifedi is entirely self-contained and needs no changes to your system configuration besides installing Nix; you can install it with a git clone, delete it with `rm -rf`, and your system will be exactly the way it was before.

Minifedi's goal is to "just work" on every machine. If the instructions below fail for you, please file an issue; I'll fix it if at all possible.

## Getting Started

```
git clone https://github.com/Gaelan/minifedi.git
cd minifedi
vi nix/services.nix # if you'd like, edit the list of instances - by default, we run one of each
nix run
```

Give it some time, and you should see

## Supported Software

Minifedi currently supports:

- Mastodon (and forks)
- Akkoma
- GoToSocial

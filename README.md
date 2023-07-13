# Minifedi

Minifedi is a tool to quickly spin up a bunch of ActivityPub servers for local testing.

Minifedi should run on any macOS or Linux system with [Nix](https://nixos.org) installed. (Nix itself works fine on any Linux distribution; you don't need to be using NixOS.) Windows isn't natively supported, but WSL should work. Besides Nix, it is entirely self-contained and needs no changes to your system configuration; you can install it with a git clone, delete it with `rm -rf`, and your system will be exactly the way it was before.

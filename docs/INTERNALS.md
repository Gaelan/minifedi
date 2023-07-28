# Minifedi internals

Quick brain dump of how this all works:

We run everything as the user, with no containers, VMs, etc. This means we can be lightweight, work natively on both macOS and Linux, and lose many points of failure.

We use Nix to manage all dependencies and build copies of all the fedi software. We use [s6](https://skarnet.org/software/s6/index.html) to orchestrate all the processes.

We run one central copy of Postgres and Redis, which all instances use.

We also run one copy of Nginx, which serves as a proxy in front of every instance. This nginx instance listens on ports 80/443, as some (all?) fedi software won't federate with stuff running anywhere else. We use the domain `lvh.me`, which resolves all subdomains to `127.0.0.1`, to give each instance a distinct hostname.

To minimize moving parts (what happens if a port is taken?), whenever possible we prefer Unix sockets over TCP for everything but the user-facing (and other-instance-facing) Nginx server. In cases where this isn't supported (GoToSocial's HTTP interface) we choose a deterministic random port based on the instance name and hope it's open.

We use [mkcert](https://github.com/FiloSottile/mkcert) to generate a root CA, which is then used to sign a wildcard certificate used by Nginx to serve each instance. Each instance is then configured to trust our root, or if that's not possible (Akkoma), disable certificate checking altogether. This cert can optionally be added to the system trust store so the user can access instances through browsers, or they can just click through the HTTPS warning if they'd rather not mess with their settings.

## Custom version support

We allow the user to use any commit of any git repo as the source for a Mastodon instance. How this works is a little tricky, as Nix (especially with language-specifc package managers in the mix) requires several hashes and other bits of metadata to successfully build a project. To abstract this from the user, we provide a `mk-mastodon` script that fetches all this metadata and crates a `versions/mastodon` subdirectory with everything needed to build that version.

The plan is eventually to support something similar for GoToSocial and Akkoma. For GoToSocial, it should be straightforward enough; it's just need to get done. Akkoma is going to be a little more tricky, as the Nixpkgs build script for Akkoma (which we use) hardcodes various details about its precise dependencies; the easy option would be to only support forks of the latest Akkoma version with no substantial dependency versions, but it'd be nice to do better.

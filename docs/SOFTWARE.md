# A survey of fedi software

…with an eye to features relevant to running it under Minifedi.

## Supported

| Name       | Languages           | Storage            | Optional                        | Storage socket? | Listen socket? | Customize CA?         | Proxied federation? | Make admins?       | API?  |
| ---------- | ------------------- | ------------------ | ------------------------------- | --------------- | -------------- | --------------------- | ------------------- | ------------------ | ----- |
| Mastodon   | Ruby + JS (yarn1)   | Postgres + Redis   | Elasticsearch                   | Yes             | Yes            | Yes (Nixpkgs OpenSSL) | Yes                 | CLI (no passwords) | Masto |
| Akkoma     | Elixir + JS (yarn1) | Postgres           | RUM (pg extension), Mellisearch | Yes             | Yes            | Insecure only         | Yes                 | CLI                | Masto |
| GoToSocial | Go + JS (yarn1)     | SQLite or Postgres | -                               | Yes             | No             | Linux only            | Yes                 | Yes                | Masto |

## Not yet supported

| Name               | Languages                   | Storage                   | Optional          | Storage socket? | Listen socket?    | Customize CA?                      | Proxied federation? | Make admins?             | API?           |
| ------------------ | --------------------------- | ------------------------- | ----------------- | --------------- | ----------------- | ---------------------------------- | ------------------- | ------------------------ | -------------- |
| Misskey            | JS (pnpm)                   | Postgres + Redis          | Mellisearch       | Probably        | Yes               | `NODE_EXTRA_CA_CERTS`              | Yes                 | first user               | Keylike        |
| Foundkey           | JS (yarn6)                  | Postgres + Redis          | Mellisearch       | Probably        | No                | `NODE_EXTRA_CA_CERTS`              | Yes                 | first user               | Keylike        |
| Firefish/Iceshrimp | JS (pnpm) + Rust            | Postgres + Redis          | many choices      | Probably        | No                | `NODE_EXTRA_CA_CERTS`              | Yes                 | first user               | Masto, Keylike |
| Lemmy              | Rust + JS (yarn1)           | Postgres                  | -                 | Probably        | No                | Linux only unless Nix patches smth | Yes (HTTP_PROXY)    | one in config            | Lemmy          |
| kbin               | PHP (Composer) + JS (yarn1) | Postgres + Redis          | RabbitMQ, Mercure | Yes             | Yes (FastCGI)     | Probably (libcurl)                 | Yes (HTTP_PROXY)    | CLI                      | Kbin           |
| PeerTube           | JS (yarn1)                  | Postgres + Redis          | -                 | Probably        | no                | `NODE_EXTRA_CA_CERTS`              | Yes (HTTP_PROXY)    | one (named root)         | PeerTube       |
| Pixelfed           | PHP (Composer)              | MySQL or Postgres + Redis | -                 | Yes             | Yes (FastCGI)     | Probably (libcurl)                 | Yes (HTTP_PROXY)    | CLI                      | Masto          |
| Takahe             | Python (pip)                | Postgres                  | -                 | Probably        | Probably (Django) | Yes                                | Yes (HTTP_PROXY)    | email or interactive CLI | Masto          |
| Bookwyrm           | Python (pip)                | Postgres                  | -                 | Unclear         | Probably (Django) | Yes                                | Yes (HTTP_PROXY)    | CLI-web interactive      | -              |
| honk               | Go                          | SQLite                    | -                 | SQLite only     | Yes               | Linux only                         | Yes (HTTP_PROXY)    | CLI                      | honk           |
| Friendica?         |
| GNU Social?        |
| Writefreely?       |
| Wordpress?         |
| Plume?             |
| Mobilizion?        |
| Hubzilla?          |
| Funkwhale?         |
| Owncast?           |

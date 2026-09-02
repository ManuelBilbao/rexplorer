# Deployment

Rexplorer is built and deployed with Nix. The flake at the repository root
serves two purposes: it defines the **development shell** every `make` target
runs inside, and it builds the three **release artifacts** a NixOS host runs.

## Development environment

The only host requirement is Nix with flakes enabled. `nix develop` provides
Elixir 1.19 on Erlang/OTP 28, PostgreSQL 18, Node.js 24 and pnpm, and its
`shellHook` brings up a project-local Postgres.

That Postgres is deliberately **not** a system service: the cluster lives in
`.pg-data/` and listens only on a Unix socket in `.pg-socket/`, with TCP
disabled entirely. Nothing can collide with a Homebrew or system Postgres on
port 5432, and the whole database is thrown away by deleting a directory.

`backend/config/dev.exs` and `backend/config/test.exs` pick the connection
method up from the environment: when `PGHOST` is set (inside the Nix shell)
they connect over the socket as the current OS user, and otherwise they fall
back to a conventional `postgres:postgres@localhost` over TCP. A contributor
who is not using Nix therefore still gets a working default.

```mermaid
sequenceDiagram
    participant Dev as Developer
    participant Make as make <target>
    participant Nix as nix develop
    participant Hook as shellHook
    participant PG as PostgreSQL
    participant Cmd as mix / pnpm

    Dev->>Make: make test
    Make->>Nix: nix develop --command bash -c "…"
    Nix->>Hook: evaluate shellHook

    alt .pg-data missing
        Hook->>PG: initdb --no-locale -U $USER
    end
    Hook->>PG: pg_ctl start -k .pg-socket -c listen_addresses=
    PG-->>Hook: accepting connections on socket

    Hook->>Hook: export PGHOST/PGUSER/PGDATABASE
    Hook->>Hook: export MIX_HOME=.nix-mix, HEX_HOME=.nix-hex
    alt Hex not installed
        Hook->>Hook: mix local.hex --force && mix local.rebar --force
    end

    Nix->>Cmd: cd backend && mix test
    Cmd->>PG: connect via socket_dir=$PGHOST
    PG-->>Cmd: rows
    Cmd-->>Dev: 130 tests, 0 failures
```

Because Hex is bootstrapped by the hook, any target works from a clean
checkout without a separate setup step. `make shell` opens the same
environment interactively; `direnv allow` loads it on `cd`.

### Local service control

| Command | Effect |
|---------|--------|
| `make services.start` | Start the project-local Postgres |
| `make services.stop` | Stop it |
| `make services.status` | Report cluster status |

## Release artifacts

```bash
make nix.build            # all three
make nix.build.web        # nix build .#rexplorer-web
make nix.build.indexer    # nix build .#rexplorer-indexer
make nix.build.frontend   # nix build .#rexplorer-frontend
```

| Output | Contents |
|--------|----------|
| `rexplorer-web` | Mix release, `bin/rexplorer_web` — public API, BFF, channels |
| `rexplorer-indexer` | Mix release, `bin/rexplorer_indexer` — chain ingestion |
| `rexplorer-frontend` | Static SPA bundle (`index.html` + `assets/`) |

The umbrella declares both releases explicitly in `backend/mix.exs`; each
bundles the shared `rexplorer` core plus exactly one tier, so a web node never
starts indexer workers and vice versa.

### Reproducible dependencies

Three fixed-output derivations pin everything fetched from the network. All
three hashes live in `nix/packages.nix` and must be refreshed when the
corresponding lockfile changes — build, read the `got:` hash from the
mismatch error, and paste it in.

| Hash | Covers | Refresh after changing |
|------|--------|------------------------|
| `mixFodDeps.hash` | Hex packages | `backend/mix.lock` |
| `pnpmDeps.hash` | npm packages | `frontend/pnpm-lock.yaml` |
| `nifCache` entries | `ex_keccak` precompiled NIFs | the `ex_keccak` version |

The `nifCache` deserves a note. `ex_abi` pulls in `ex_keccak`, which uses
`rustler_precompiled` to **download** a prebuilt Rust NIF at compile time —
network access the Nix sandbox forbids, so the build fails with
`Error while downloading precompiled NIF: erofs`. We fetch those tarballs
ahead of time as fixed-output derivations and point the compiler at them with
`RUSTLER_PRECOMPILED_GLOBAL_CACHE_PATH`. Erlang 28 reports NIF version 2.17,
for which `rustler_precompiled` falls back to the `nif-2.16` tarballs; all
four default systems are covered so the release builds on Linux servers and
macOS dev machines alike.

## NixOS deployment

`nixosModules.rexplorer` turns the artifacts into a running host: two systemd
units, PostgreSQL, and an Nginx vhost with ACME TLS.

```nix
{
  imports = [ rexplorer.nixosModules.rexplorer ];

  services.rexplorer = {
    enable = true;
    domain = "explorer.example.com";
    webPath = "/opt/rexplorer/web";
    indexerPath = "/opt/rexplorer/indexer";
    frontendPath = "/opt/rexplorer/frontend";
    envFile = "/etc/rexplorer/env";
    nginx.acmeEmail = "admin@example.com";
  };
}
```

[`nix/server-example.nix`](../nix/server-example.nix) is a complete host
configuration to copy from.

### Request routing

```mermaid
graph TD
    Client["Browser / API client"] -->|"HTTPS :443"| Nginx["Nginx<br/>(ACME TLS)"]

    Nginx -->|"/"| Static["Static SPA<br/>frontendPath"]
    Nginx -->|"/api, /api/v1"| Web["rexplorer_web<br/>127.0.0.1:4000"]
    Nginx -->|"/internal"| Web
    Nginx -->|"/swaggerui"| Web
    Nginx -->|"/socket (WebSocket)"| Web

    Web -->|"Ecto"| PG[("PostgreSQL")]
    Indexer["rexplorer_indexer"] -->|"Ecto"| PG
    Indexer -->|"JSON-RPC"| Nodes["Chain RPC nodes"]
```

`/` falls back to `index.html` so client-side routes deep-link correctly. When
`frontendPath` is null, `/` is proxied to Phoenix instead.

### Configuration options

| Option | Default | Purpose |
|--------|---------|---------|
| `domain` | — | Public hostname; also `PHX_HOST` |
| `port` | `4000` | Loopback port Phoenix binds |
| `envFile` | `/etc/rexplorer/env` | Secrets, read by both units |
| `webPath` | `/opt/rexplorer/web` | Deployed web release |
| `indexerPath` | `/opt/rexplorer/indexer` | Deployed indexer release |
| `frontendPath` | `null` | Static SPA root; `null` proxies `/` to Phoenix |
| `enableIndexer` | `true` | Run the indexer on this host |
| `localPostgres` | `true` | Provision PostgreSQL 18 locally |
| `nginx.enable` | `true` | Configure the reverse proxy |
| `nginx.enableACME` | `true` | Let's Encrypt TLS |
| `nginx.acmeEmail` | — | ACME registration address |

The env file must define at least:

```sh
DATABASE_URL=ecto://rexplorer@localhost/rexplorer
SECRET_KEY_BASE=<64+ chars, from `mix phx.gen.secret`>
```

Both units run as the unprivileged `rexplorer` user under systemd hardening
(`ProtectSystem=strict`, `PrivateTmp`, `NoNewPrivileges`, and friends), with
`/var/lib/rexplorer` as the only writable path.

### Scaling out

The web and indexer tiers are separate releases precisely so they can live on
different machines. On a multi-node deployment, set `enableIndexer = false`
on every web node and run the indexer on exactly one host (or a dedicated
indexer node) — the workers poll chain heads and write blocks, so running
several against one database duplicates work and causes write contention.

```mermaid
graph LR
    subgraph web["Web tier (scale horizontally)"]
        W1["rexplorer_web #1<br/>enableIndexer = false"]
        W2["rexplorer_web #2<br/>enableIndexer = false"]
    end

    subgraph idx["Indexer tier (exactly one per chain set)"]
        I1["rexplorer_indexer"]
    end

    W1 --> PG[("PostgreSQL")]
    W2 --> PG
    I1 --> PG
    I1 --> RPC["Chain RPC nodes"]
```

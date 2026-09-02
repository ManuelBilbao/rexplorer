{
  description = "Rexplorer — multi-chain Ethereum-like blockchain explorer";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # Elixir 1.19 on Erlang/OTP 28 — matches the versions the umbrella
        # declares in apps/*/mix.exs.
        erlang = pkgs.beam.interpreters.erlang_28;
        elixir = pkgs.beam.packages.erlang_28.elixir_1_19;

        # File-system watching for Phoenix live reload; macOS uses fsevents.
        linuxOnlyPackages = pkgs.lib.optionals pkgs.stdenv.isLinux [ pkgs.inotify-tools ];

        packages = import ./nix/packages.nix { inherit pkgs; };
      in
      {
        inherit packages;

        devShells.default = pkgs.mkShell {
          buildInputs = [
            # Elixir / Erlang
            erlang
            elixir

            # Database
            pkgs.postgresql_18

            # Frontend
            pkgs.nodejs_22
            pkgs.pnpm

            # Build tools
            pkgs.gnumake
            pkgs.gcc
            pkgs.openssl
          ] ++ linuxOnlyPackages;

          shellHook = ''
            # Postgres — project-local instance over a Unix socket (no TCP), so
            # it never collides with a system-wide Postgres on 5432.
            export PGDATA="$PWD/.pg-data"
            export PGHOST="$PWD/.pg-socket"
            export PGUSER="''${PGUSER:-$USER}"
            export PGDATABASE="''${PGDATABASE:-rexplorer_dev}"

            # Initialise the cluster on first entry.
            if [ ! -d "$PGDATA" ]; then
              echo "Initialising PostgreSQL data directory…"
              initdb --no-locale --encoding=UTF8 -U "$PGUSER" >/dev/null
            fi

            mkdir -p "$PGHOST"

            # Start Postgres if it is not already up.
            if ! pg_isready -q 2>/dev/null; then
              pg_ctl start -l "$PGDATA/postgres.log" \
                -o "-k $PGHOST -c listen_addresses=" \
                >/dev/null
            fi

            # Keep Mix/Hex/npm state inside the project rather than $HOME.
            export MIX_HOME="''${MIX_HOME:-$PWD/.nix-mix}"
            export HEX_HOME="''${HEX_HOME:-$PWD/.nix-hex}"
            export ERL_AFLAGS="''${ERL_AFLAGS:--kernel shell_history enabled}"
            export PATH="$MIX_HOME/bin:$HEX_HOME/bin:$PATH"

            # Bootstrap Hex/rebar into the project-local MIX_HOME on first
            # entry, so every make target works without a separate setup step.
            if ! mix hex.info >/dev/null 2>&1; then
              echo "Installing Hex and rebar into $MIX_HOME…"
              mix local.hex --force >/dev/null
              mix local.rebar --force >/dev/null
            fi

            echo "Rexplorer dev environment"
            echo "  Elixir $(elixir --version | tail -1 | cut -d' ' -f2) · Node $(node --version) · pnpm $(pnpm --version) · Postgres socket at $PGHOST (user: $PGUSER)"
            echo ""
            echo "Quick start:"
            echo "  make setup         # deps + database + frontend"
            echo "  make server        # Phoenix API + indexer on :4000"
            echo "  make frontend.dev  # Vite dev server on :5173"
            echo "  make test          # Elixir tests"
            echo ""
          '';

          LANG = "en_US.UTF-8";
          LC_ALL = "en_US.UTF-8";
        };
      }
    )
    // {
      nixosModules.rexplorer = import ./nix/nixos-module.nix;
      nixosModules.default = import ./nix/nixos-module.nix;
    };
}

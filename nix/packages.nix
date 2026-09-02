{ pkgs }:

let
  beamPackages = pkgs.beam.packages.erlang_28;
  elixir = beamPackages.elixir_1_19;

  version = "0.1.0";
  src = ../backend;

  # Fetch Mix dependencies reproducibly. Regenerate the hash after changing
  # mix.lock with:  make nix.hash.mix
  mixFodDeps = beamPackages.fetchMixDeps {
    pname = "rexplorer-mix-deps";
    inherit version elixir src;
    hash = "sha256-yT8+d/ki1or/4XbLPdjE9Ije4ZZ0mHCq/FhaQn6z5og=";
  };

  # Prefetch the precompiled Rust NIF for ex_keccak (pulled in by ex_abi).
  # rustler_precompiled normally downloads it at compile time, which the Nix
  # sandbox forbids. We fetch it ahead of time as a fixed-output derivation
  # and hand it over via the global cache path.
  #
  # Erlang 28 reports NIF version 2.17, for which rustler_precompiled falls
  # back to the 2.16 tarballs. All four default systems are covered so the
  # release builds on Linux servers and macOS dev machines alike.
  nifCache = pkgs.linkFarm "rustler-nif-cache" (
    map
      (target: {
        name = "libexkeccak-v0.7.8-nif-2.16-${target.triple}.so.tar.gz";
        path = pkgs.fetchurl {
          url = "https://github.com/exWeb3/ex_keccak/releases/download/v0.7.8/libexkeccak-v0.7.8-nif-2.16-${target.triple}.so.tar.gz";
          inherit (target) hash;
        };
      })
      [
        { triple = "x86_64-unknown-linux-gnu"; hash = "sha256-1Ej5BhCzs0Kw8i3EQm5/0+6aXD4ZrRxWbEOB5Fm+NWY="; }
        { triple = "aarch64-unknown-linux-gnu"; hash = "sha256-WXhd9jvfj0sZNgJ4ThE3iVPiPuJuALriUFcCp0twYCo="; }
        { triple = "aarch64-apple-darwin"; hash = "sha256-FJFMAKkNwg0G0/ix+R/1ljuC22KcSe9eSU6VLUSkwdA="; }
        { triple = "x86_64-apple-darwin"; hash = "sha256-iqdD6sC5Byyh4x0rhXq4IhQYIwJ9DgjfouLP2nY26dM="; }
      ]
  );

  # One umbrella, two releases. `mixReleaseName` selects which of the
  # releases declared in backend/mix.exs gets assembled.
  mkRelease =
    name:
    beamPackages.mixRelease {
      pname = "rexplorer-${name}";
      inherit version src mixFodDeps elixir;

      mixReleaseName = "rexplorer_${name}";

      nativeBuildInputs = [ pkgs.gcc pkgs.gnumake pkgs.openssl ];

      # Point rustler_precompiled at the prefetched NIF tarballs.
      RUSTLER_PRECOMPILED_GLOBAL_CACHE_PATH = nifCache;

      # rustler_precompiled needs a writable HOME for its metadata files.
      HOME = "/tmp";

      # Keep the generated Erlang cookie in the release so it starts without
      # RELEASE_COOKIE being set.
      removeCookie = false;
    };

  # Fetch pnpm dependencies reproducibly. Regenerate the hash after changing
  # pnpm-lock.yaml with:  make nix.hash.pnpm
  pnpmDeps = pkgs.pnpm.fetchDeps {
    pname = "rexplorer-frontend-deps";
    inherit version;
    src = ../frontend;
    hash = "sha256-ieD/tzxGvU9cv4/T9gM1cMKjMYYnd4TevT4QvfAjve4=";
    fetcherVersion = 3;
  };
in
{
  # Phoenix API + BFF + channels.
  rexplorer-web = mkRelease "web";

  # Chain ingestion workers. Deployed separately from the web tier.
  rexplorer-indexer = mkRelease "indexer";

  # Static build of the React SPA.
  rexplorer-frontend = pkgs.stdenv.mkDerivation {
    pname = "rexplorer-frontend";
    inherit version;
    src = ../frontend;

    nativeBuildInputs = [
      pkgs.nodejs_22
      pkgs.pnpm
      pkgs.pnpm.configHook
    ];

    inherit pnpmDeps;

    buildPhase = ''
      runHook preBuild
      pnpm run build
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      cp -r dist/* $out/
      runHook postInstall
    '';

    doCheck = false;
  };
}

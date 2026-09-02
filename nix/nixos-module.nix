# NixOS module for deploying Rexplorer in production.
#
# Usage in your NixOS configuration:
#
#   imports = [ rexplorer.nixosModules.rexplorer ];
#
#   services.rexplorer = {
#     enable = true;
#     domain = "explorer.example.com";
#     webPath = "/opt/rexplorer/web";
#     indexerPath = "/opt/rexplorer/indexer";
#     frontendPath = "/opt/rexplorer/frontend";
#     envFile = "/etc/rexplorer/env";
#     nginx.acmeEmail = "admin@example.com";
#   };
#
# The env file must contain at minimum:
#   DATABASE_URL=ecto://rexplorer@localhost/rexplorer
#   SECRET_KEY_BASE=<64+ char secret, generate with `mix phx.gen.secret`>
#
# The indexer also needs RPC endpoints for the chains it follows. Those are
# compiled in from backend/config/config.exs; override per-host by baking a
# different config or by extending the env file once runtime.exs reads them.

{ config, lib, pkgs, ... }:

let
  cfg = config.services.rexplorer;
in
{
  options.services.rexplorer = {
    enable = lib.mkEnableOption "Rexplorer blockchain explorer";

    domain = lib.mkOption {
      type = lib.types.str;
      description = "Public domain name for the Rexplorer instance.";
      example = "explorer.example.com";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 4000;
      description = "Port the Phoenix web tier listens on.";
    };

    envFile = lib.mkOption {
      type = lib.types.path;
      default = "/etc/rexplorer/env";
      description = ''
        Path to an environment file containing runtime secrets and config.
        Must contain DATABASE_URL and SECRET_KEY_BASE. Read by both the web
        and indexer units.
      '';
    };

    webPath = lib.mkOption {
      type = lib.types.str;
      default = "/opt/rexplorer/web";
      description = "Path to the deployed rexplorer_web Mix release directory.";
    };

    indexerPath = lib.mkOption {
      type = lib.types.str;
      default = "/opt/rexplorer/indexer";
      description = "Path to the deployed rexplorer_indexer Mix release directory.";
    };

    frontendPath = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Path to the built React SPA. When set, Nginx serves it at / with an
        index.html fallback. When null, / is proxied to Phoenix instead.
      '';
    };

    enableIndexer = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Whether to run the indexer tier on this host. Set false on web-only
        nodes so a single database is not indexed by several machines.
      '';
    };

    localPostgres = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to run a local PostgreSQL instance.";
    };

    nginx = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to configure Nginx as a reverse proxy.";
      };

      enableACME = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Whether to enable ACME/Let's Encrypt TLS.";
      };

      acmeEmail = lib.mkOption {
        type = lib.types.str;
        description = "Email address for ACME/Let's Encrypt certificate registration.";
        example = "admin@example.com";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # ── System user ─────────────────────────────────────────────────────────
    users.users.rexplorer = {
      isSystemUser = true;
      group = "rexplorer";
      home = "/var/lib/rexplorer";
      createHome = true;
    };
    users.groups.rexplorer = { };

    # ── Shared systemd hardening ────────────────────────────────────────────
    systemd.services =
      let
        hardening = {
          Type = "exec";
          User = "rexplorer";
          Group = "rexplorer";
          WorkingDirectory = "/var/lib/rexplorer";
          Restart = "on-failure";
          RestartSec = 5;
          EnvironmentFile = cfg.envFile;

          NoNewPrivileges = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          PrivateTmp = true;
          PrivateDevices = true;
          ProtectKernelTunables = true;
          ProtectKernelModules = true;
          ProtectControlGroups = true;
          ReadWritePaths = [ "/var/lib/rexplorer" ];
        };
      in
      {
        # ── Phoenix web tier ──────────────────────────────────────────────
        rexplorer-web = {
          description = "Rexplorer Phoenix web tier (public API, BFF, channels)";
          after = [ "network.target" ] ++ lib.optional cfg.localPostgres "postgresql.service";
          wants = lib.optional cfg.localPostgres "postgresql.service";
          wantedBy = [ "multi-user.target" ];

          environment = {
            PHX_SERVER = "true";
            PHX_HOST = cfg.domain;
            PORT = toString cfg.port;
          };

          serviceConfig = hardening // {
            ExecStart = "${cfg.webPath}/bin/rexplorer_web start";
            ExecStop = "${cfg.webPath}/bin/rexplorer_web stop";
          };
        };

        # ── Indexer tier ──────────────────────────────────────────────────
        rexplorer-indexer = lib.mkIf cfg.enableIndexer {
          description = "Rexplorer chain indexer";
          after = [ "network.target" ] ++ lib.optional cfg.localPostgres "postgresql.service";
          wants = lib.optional cfg.localPostgres "postgresql.service";
          wantedBy = [ "multi-user.target" ];

          serviceConfig = hardening // {
            ExecStart = "${cfg.indexerPath}/bin/rexplorer_indexer start";
            ExecStop = "${cfg.indexerPath}/bin/rexplorer_indexer stop";
          };
        };
      };

    # ── PostgreSQL ──────────────────────────────────────────────────────────
    services.postgresql = lib.mkIf cfg.localPostgres {
      enable = true;
      package = pkgs.postgresql_18;
      ensureDatabases = [ "rexplorer" ];
      ensureUsers = [
        {
          name = "rexplorer";
          ensureDBOwnership = true;
        }
      ];
    };

    # ── Nginx reverse proxy ─────────────────────────────────────────────────
    services.nginx = lib.mkIf cfg.nginx.enable {
      enable = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
      recommendedOptimisation = true;
      recommendedGzipSettings = true;

      virtualHosts.${cfg.domain} = {
        forceSSL = cfg.nginx.enableACME;
        enableACME = cfg.nginx.enableACME;

        locations = {
          # Public versioned API and the OpenAPI document.
          "/api" = {
            proxyPass = "http://127.0.0.1:${toString cfg.port}";
          };

          # BFF API consumed by the SPA.
          "/internal" = {
            proxyPass = "http://127.0.0.1:${toString cfg.port}";
          };

          # Swagger UI.
          "/swaggerui" = {
            proxyPass = "http://127.0.0.1:${toString cfg.port}";
          };

          # Phoenix Channels (live blocks, address updates).
          "/socket" = {
            proxyPass = "http://127.0.0.1:${toString cfg.port}";
            proxyWebsockets = true;
          };

          # React SPA at /, with history-API fallback.
          "/" =
            if cfg.frontendPath != null then
              {
                root = cfg.frontendPath;
                tryFiles = "$uri $uri/ /index.html";
              }
            else
              {
                proxyPass = "http://127.0.0.1:${toString cfg.port}";
                proxyWebsockets = true;
              };
        };
      };
    };

    # ── ACME ────────────────────────────────────────────────────────────────
    security.acme = lib.mkIf (cfg.nginx.enable && cfg.nginx.enableACME) {
      acceptTerms = true;
      defaults.email = cfg.nginx.acmeEmail;
    };

    # ── Firewall ────────────────────────────────────────────────────────────
    networking.firewall.allowedTCPPorts = lib.mkIf cfg.nginx.enable [ 80 443 ];
  };
}

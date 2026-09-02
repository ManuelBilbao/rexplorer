# Example NixOS configuration for a Rexplorer server.
#
# This file is a reference — adapt it to your server's configuration.nix.
#
# Prerequisites on the server:
#   1. NixOS installed
#   2. An `admin` user with sudo access
#   3. Env file at /etc/rexplorer/env containing at least:
#        DATABASE_URL=ecto://rexplorer@localhost/rexplorer
#        SECRET_KEY_BASE=<64+ chars, from `mix phx.gen.secret`>
#
# Deploy the three build outputs to the paths configured below:
#   nix build .#rexplorer-web      → /opt/rexplorer/web
#   nix build .#rexplorer-indexer  → /opt/rexplorer/indexer
#   nix build .#rexplorer-frontend → /opt/rexplorer/frontend

{ rexplorer, ... }:

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

    # Run the indexer here too. On a multi-node deployment, leave this true on
    # exactly one host (or a dedicated indexer node) and false on the web tier,
    # so a single database is not indexed by several machines at once.
    enableIndexer = true;
  };

  # Tailscale for secure access from CI.
  services.tailscale.enable = true;

  # Allow the admin user to restart Rexplorer (used by CI).
  security.sudo.extraRules = [
    {
      users = [ "admin" ];
      commands = [
        {
          command = "/run/current-system/sw/bin/systemctl restart rexplorer-web";
          options = [ "NOPASSWD" ];
        }
        {
          command = "/run/current-system/sw/bin/systemctl restart rexplorer-indexer";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  # Ensure deploy directories exist.
  systemd.tmpfiles.rules = [
    "d /opt/rexplorer/web 0755 admin users -"
    "d /opt/rexplorer/indexer 0755 admin users -"
    "d /opt/rexplorer/frontend 0755 admin users -"
  ];
}

#!/usr/bin/env bash
# Refresh a fixed-output-derivation hash in nix/packages.nix.
#
# A FOD is content-addressed by its *declared* hash, so Nix reuses an already
# realised store path and never re-runs the fetcher when only the lockfile
# changes. Simply rebuilding therefore succeeds while silently using stale
# dependencies. The only way to force a refetch is to change the declared hash,
# so this script blanks it, builds to learn the real one, and writes it back.
#
# Usage: refresh-hash.sh <pname> <flake-attr>
set -euo pipefail

PNAME="$1"
ATTR="$2"
FILE="$(cd "$(dirname "$0")" && pwd)/packages.nix"
FAKE="sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="

original=$(awk -v p="pname = \"$PNAME\"" '
  index($0, p) { found = 1 }
  found && /hash = "/ { match($0, /"[^"]*"/); print substr($0, RSTART + 1, RLENGTH - 2); exit }
' "$FILE")

if [ -z "$original" ]; then
  echo "error: no hash found for pname \"$PNAME\" in $FILE" >&2
  exit 1
fi

restore() { [ -f "$FILE.bak" ] && mv "$FILE.bak" "$FILE"; return 0; }
trap restore EXIT

cp "$FILE" "$FILE.bak"
# Blank only the hash belonging to this pname.
awk -v p="pname = \"$PNAME\"" -v fake="$FAKE" '
  index($0, p) { found = 1 }
  found && !done && /hash = "/ { sub(/"[^"]*"/, "\"" fake "\""); done = 1 }
  { print }
' "$FILE.bak" > "$FILE"

got=$(nix build "$ATTR" 2>&1 | awk '/got:/ {print $2}' | tail -1) || true

if [ -z "$got" ]; then
  echo "error: build produced no hash mismatch — could not determine the hash." >&2
  echo "       Run 'nix build $ATTR' by hand to see what failed." >&2
  exit 1
fi

restore
trap - EXIT

if [ "$got" = "$original" ]; then
  echo "$PNAME: unchanged ($original)"
  exit 0
fi

awk -v p="pname = \"$PNAME\"" -v new="$got" '
  index($0, p) { found = 1 }
  found && !done && /hash = "/ { sub(/"[^"]*"/, "\"" new "\""); done = 1 }
  { print }
' "$FILE" > "$FILE.new" && mv "$FILE.new" "$FILE"

echo "$PNAME: updated"
echo "  old: $original"
echo "  new: $got"

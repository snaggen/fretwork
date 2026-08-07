#!/usr/bin/env bash
# Install the package into Typst's local package directory, so other projects
# can `#import "@local/fretwork:<version>"` without a path.
#
# Copies exactly what the published bundle contains — the manifest, the sources,
# the README and the licence — and nothing else. Tests, examples and the docs
# images are excluded by `exclude` in typst.toml and have no business in an
# installed package either.
#
# Re-run it after every change: Typst reads the installed copy, not this tree,
# so an edit here is invisible to another project until it is copied over.
#
# Usage: docs/install-local.sh [--uninstall]
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
name="$(sed -n 's/^name *= *"\(.*\)"/\1/p' "$root/typst.toml")"
version="$(sed -n 's/^version *= *"\(.*\)"/\1/p' "$root/typst.toml")"

# Typst follows the XDG data directory on Linux and has its own places on macOS
# and Windows; only the Linux one is handled here, which is where this is used.
data="${XDG_DATA_HOME:-$HOME/.local/share}"
dest="$data/typst/packages/local/$name/$version"

if [ "${1-}" = "--uninstall" ]; then
  rm -rf "$dest"
  echo "removed $dest"
  exit 0
fi

# Replaced rather than merged: a file deleted from the package must disappear
# from the install too, or it lingers and keeps resolving.
rm -rf "$dest"
mkdir -p "$dest"
cp "$root/typst.toml" "$root/README.md" "$root/LICENSE" "$dest/"
cp -r "$root/src" "$dest/"

echo "installed $name $version"
echo "  $dest"
echo
echo "Use it with:"
echo "  #import \"@local/$name:$version\": *"

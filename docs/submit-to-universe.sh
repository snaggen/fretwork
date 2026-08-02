#!/usr/bin/env bash
# Prepare the Typst Universe submission branch.
#
# Requires that you have first forked https://github.com/typst/packages to your
# own account through the GitHub web interface — a pull request cannot be opened
# without a fork, and forking cannot be done over plain git.
#
# This script does everything after that: sparse-clones your fork, copies in
# exactly the files the submission guidelines call for, commits, and pushes a
# branch. It stops short of opening the pull request, which is a click.
#
# Usage: docs/submit-to-universe.sh [github-username]
set -euo pipefail

user="${1:-snaggen}"
root="$(cd "$(dirname "$0")/.." && pwd)"
name="$(sed -n 's/^name *= *"\(.*\)"/\1/p' "$root/typst.toml")"
version="$(sed -n 's/^version *= *"\(.*\)"/\1/p' "$root/typst.toml")"
work="${TMPDIR:-/tmp}/universe-$name-$version"

echo "Submitting $name $version as $user"

# The README links to files at the `v$version` tag — SPEC.md, LICENSE, the
# examples — so a tag left behind on an older commit silently points readers of
# the Universe page at superseded files. That happened once: five commits of
# fixes landed after the tag was cut, and every linked file was stale at it.
tag="v$version"
if ! git -C "$root" rev-parse -q --verify "$tag" >/dev/null; then
  echo "  refusing: tag $tag does not exist — create it at the commit being submitted"
  exit 1
fi
if [ "$(git -C "$root" rev-parse "$tag^{commit}")" != "$(git -C "$root" rev-parse HEAD)" ]; then
  echo "  refusing: $tag is not at HEAD, so the README's links would be stale"
  echo "    $tag  $(git -C "$root" log --oneline -1 "$tag^{commit}")"
  echo "    HEAD  $(git -C "$root" log --oneline -1 HEAD)"
  echo "  move it with:  git tag -f -a $tag -m '$name $version' && git push --force origin $tag"
  exit 1
fi
if [ -n "$(git -C "$root" status --porcelain)" ]; then
  echo "  refusing: the working tree has uncommitted changes"
  exit 1
fi

rm -rf "$work"
# Sparse, shallow, treeless: the packages repository holds every version of every
# package ever published, and a full clone is enormous.
git clone --depth 1 --no-checkout --filter="tree:0" \
  "git@github.com:$user/packages" "$work"
cd "$work"
git sparse-checkout init
git sparse-checkout set "packages/preview/$name"
git remote add upstream https://github.com/typst/packages
git config remote.upstream.partialclonefilter tree:0
git checkout main

# Start from upstream's tip, so the branch carries only this package.
git fetch --depth 1 upstream main
git reset --hard upstream/main
git checkout -b "$name-$version"

dest="packages/preview/$name/$version"
mkdir -p "$dest"

# Required files (the package itself), plus the README illustrations, which are
# committed here but excluded from the bundle by `exclude` in the manifest.
# Tests, examples and build scripts are deliberately left out: they would be
# almost impossible for a user to reach, and only inflate the repository.
cp "$root/typst.toml" "$root/README.md" "$root/LICENSE" "$dest/"
cp -r "$root/src" "$dest/"
mkdir -p "$dest/docs"
cp "$root"/docs/*.png "$dest/docs/"

git add "$dest"
git commit -q -m "$name:$version"

echo
git show --stat --oneline HEAD | head -40
echo
# Force, because the branch is rebuilt from upstream's tip every run rather than
# added to: a package submission should be one commit, and re-running this after
# a review comment should update the pull request instead of stacking fixups
# onto it. The branch exists only for this submission and its content is
# regenerated from the package repository, so nothing unique lives here.
git push --force origin "$name-$version"

cat <<EOF

Branch pushed. Open the pull request here:

  https://github.com/typst/packages/compare/main...$user:packages:$name-$version

Title it "$name:$version" — that is the convention the repository uses.
EOF

#!/usr/bin/env bash
# Compile every test document. A failed assertion panics, so a non-zero exit
# status from the compiler is a failed test.
#
# Usage: tests/run.sh [name ...]        (default: all, including the visual ones)
#        tests/run.sh visual            only the image-regression tests
#        tests/run.sh --update-refs     re-pin the reference renders
set -uo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
out="$(mktemp -d)"
trap 'rm -rf "$out"' EXIT

# The image-regression tests live in their own runner, since comparing renders
# needs more than a compiler exit status.
if [ "${1-}" = "--update-refs" ]; then
  shift
  exec "$(dirname "$0")/visual.py" --update "$@"
fi
if [ "${1-}" = "visual" ]; then
  shift
  exec "$(dirname "$0")/visual.py" "$@"
fi

if [ $# -gt 0 ]; then
  files=()
  for name in "$@"; do files+=("$root/tests/${name%.typ}.typ"); done
else
  mapfile -t files < <(find "$root/tests" -maxdepth 1 -name '*.typ' ! -name 'helpers.typ' | sort)
fi

pass=0
fail=0
for f in "${files[@]}"; do
  name="$(basename "$f" .typ)"
  if log=$(typst compile --root "$root" "$f" "$out/$name.pdf" 2>&1); then
    printf '  ok    %s\n' "$name"
    pass=$((pass + 1))
  else
    printf '  FAIL  %s\n%s\n' "$name" "$log"
    fail=$((fail + 1))
  fi
done

# Error-path fixtures: each must fail to compile, with a message containing the
# substring declared on its `// expect:` line. This is how error wording is kept
# under test, since Typst cannot catch a panic from inside a document.
if [ $# -eq 0 ] && [ -d "$root/tests/errors" ]; then
  for f in "$root/tests/errors"/*.typ; do
    name="errors/$(basename "$f" .typ)"
    want="$(sed -n 's|^// expect: ||p' "$f" | head -1)"
    log=$(typst compile --root "$root" "$f" "$out/e.pdf" 2>&1)
    if [ -z "$log" ]; then
      printf '  FAIL  %s (compiled, but should have failed)\n' "$name"
      fail=$((fail + 1))
    elif ! printf '%s' "$log" | grep -qF -- "$want"; then
      printf '  FAIL  %s (message lacked %s)\n%s\n' "$name" "\"$want\"" "$log"
      fail=$((fail + 1))
    elif [ "${f##*/}" != "bad-repeat-style.typ" ] \
      && ! printf '%s' "$log" | grep -qE 'measure [0-9]+, token [0-9]+'; then
      # Parser errors must locate themselves; a rejected theme argument has no
      # measure to point at.
      printf '  FAIL  %s (message lacked a source location)\n%s\n' "$name" "$log"
      fail=$((fail + 1))
    else
      printf '  ok    %s\n' "$name"
      pass=$((pass + 1))
    fi
  done
fi

# Renders last: they are the slowest, and a difference in the output is only
# worth reading once the model and the parsers are known to be right. The
# runner prints its own results and exits with the number that differed.
if [ $# -eq 0 ]; then
  "$root/tests/visual.py"
  fail=$((fail + $?))
fi

printf '\n%d document(s) passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]

#!/usr/bin/env bash
set -euo pipefail

# Guards the git-subdir publish filter.
#
# There are two publish paths and they filter differently:
#   1. marketplace.json `git-subdir` — git is the filter. Anything .gitignore
#      matches under kit/plugins/ is absent for anyone installing from GitHub.
#   2. build-dist --publish — walks the *working tree* and filters by
#      DROP_PATTERNS, so .gitignore has no effect there at all.
#
# This test covers path 1. An ignored-but-present plugin file is the nasty case:
# it still reaches the agentics-kit mirror via path 2, so the two published
# forms silently disagree and neither reports anything.
#
# This has already happened once: an unanchored `build/` rule swallowed
# kit/plugins/plan-agent/skills/build/ (see the comment in .gitignore).
#
# Allowed: artifact classes generated at arbitrary depth that are never
# publishable content. Their .gitignore rules stay unanchored on purpose —
# python hooks run inside kit/plugins/ and drop __pycache__ next to themselves.

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

ALLOWED='(^|/)(__pycache__/|node_modules/)|\.pyc$|(^|/)\.DS_Store$'

echo "=== No Ignored Plugin Files ==="

ignored="$(git status --ignored --porcelain kit/plugins/ \
  | sed -n 's/^!! //p' \
  | grep -Ev "$ALLOWED" || true)"

if [ -z "$ignored" ]; then
  echo "  PASS: no publishable path under kit/plugins/ is git-ignored."
  exit 0
fi

echo "  FAIL: .gitignore matches the path(s) below under kit/plugins/. These are"
echo "        absent from every installed plugin, with no error at publish time:"
printf '%s\n' "$ignored" | sed 's/^/          /'
echo
echo "  Fix: anchor the offending rule in .gitignore so it matches root only"
echo "       (e.g. 'examples/' -> '/examples/'), or move the artifact out of"
echo "       kit/plugins/. Check which rule matches with:"
echo "         git check-ignore -v <path>"
exit 1

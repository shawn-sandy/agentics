#!/usr/bin/env bash
# Objective-verification test for the dead-plugin cleanup.
#
# Invariant: the set of directories under kit/plugins/ equals the set of `name`
# values in .claude-plugin/marketplace.json.
#
# Why this matters: de-registering a plugin stops distribution, not loading.
# Local sessions load by directory (--plugin-dir), so any directory left behind
# after removal still loads, collides by name with a live plugin, and eats the
# skill-description budget. This test fails in both directions — an orphan
# directory with no manifest entry, and a manifest entry with no source.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
MANIFEST="$ROOT/.claude-plugin/marketplace.json"
PLUGIN_DIR="$ROOT/kit/plugins"
fail() { echo "FAIL: $1" >&2; exit 1; }

[ -f "$MANIFEST" ] || fail "marketplace.json missing at $MANIFEST"
[ -d "$PLUGIN_DIR" ] || fail "kit/plugins missing at $PLUGIN_DIR"

dirs=$(find "$PLUGIN_DIR" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort)
names=$(python3 -c "
import json
with open('$MANIFEST') as f:
    print('\n'.join(sorted(p['name'] for p in json.load(f)['plugins'])))
")

orphans=$(comm -23 <(echo "$dirs") <(echo "$names"))
missing=$(comm -13 <(echo "$dirs") <(echo "$names"))

[ -z "$orphans" ] || fail "directories under kit/plugins/ with no marketplace.json entry (de-registered plugins still load via --plugin-dir; delete them, git history keeps them):
$orphans"
[ -z "$missing" ] || fail "marketplace.json entries with no source directory under kit/plugins/:
$missing"

echo "PASS: $(echo "$dirs" | wc -l | tr -d ' ') plugin directories match marketplace.json exactly"

#!/usr/bin/env bash
set -euo pipefail

# The list of de-registered plugins is written down twice: as the `removed`
# array in marketplace.json, and as the table in .claude/rules/removed-plugins.md.
# Nothing kept them in sync, and they drifted in opposite directions — the
# plan-interview merge (864c144) added the rule row but not the JSON entry,
# while issue-agent had gone the other way three weeks earlier.
#
# The two copies do not cost the same when stale. The JSON array is inert
# record-keeping. removed-plugins.md is loaded into every session with no
# `paths` scope, specifically so the re-add confirmation gate fires before any
# plugin file is opened — so a missing row there is not cosmetic drift, it is
# the gate with a hole in it. issue-agent's row was absent for six weeks.
#
# Check 4 is the invariant the gate exists to protect: a plugin cannot be
# listed as removed and registered as active at the same time.

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
MARKETPLACE="$ROOT/.claude-plugin/marketplace.json"
RULE="$ROOT/.claude/rules/removed-plugins.md"
FAILURES=0

echo "=== Removed Plugins Sync Test ==="

for f in "$MARKETPLACE" "$RULE"; do
  if [ ! -f "$f" ]; then
    echo "FATAL: $f does not exist — every check below would cascade."
    exit 1
  fi
done

JSON_REMOVED="$(node -e '
  const m = require(process.argv[1]);
  console.log((m.removed || []).map(r => r.name).sort().join("\n"));
' "$MARKETPLACE")"

# Table rows only: the `| Plugin | Removed |` header and the |---|---| separator
# never match, because both lack a backticked plugin name in column one.
RULE_REMOVED="$(grep -o '^| `[a-z0-9-]*`' "$RULE" | tr -d '|` ' | sort)"

ACTIVE="$(node -e '
  const m = require(process.argv[1]);
  console.log(m.plugins.map(p => p.name).sort().join("\n"));
' "$MARKETPLACE")"

# 1 — a vacuous pass is the failure mode this whole file exists to prevent, so
# an empty list on either side is an error rather than "nothing to compare".
echo "1. Both lists are non-empty..."
JSON_COUNT="$(printf '%s\n' "$JSON_REMOVED" | grep -c . || true)"
RULE_COUNT="$(printf '%s\n' "$RULE_REMOVED" | grep -c . || true)"
if [ "$JSON_COUNT" -gt 0 ] && [ "$RULE_COUNT" -gt 0 ]; then
  echo "  PASS (marketplace.json: $JSON_COUNT, removed-plugins.md: $RULE_COUNT)"
else
  echo "  FAIL: marketplace.json has $JSON_COUNT, removed-plugins.md has $RULE_COUNT"
  FAILURES=$((FAILURES + 1))
fi

echo "2. Every marketplace.json removal has a rule-file row..."
MISSING_ROWS="$(comm -23 <(printf '%s\n' "$JSON_REMOVED") <(printf '%s\n' "$RULE_REMOVED"))"
if [ -z "$MISSING_ROWS" ]; then
  echo "  PASS"
else
  while IFS= read -r p; do
    [ -z "$p" ] && continue
    echo "  FAIL: $p is removed in marketplace.json but has no row in removed-plugins.md"
    echo "        (the re-add confirmation gate will not fire for it)"
  done <<< "$MISSING_ROWS"
  FAILURES=$((FAILURES + 1))
fi

echo "3. Every rule-file row has a marketplace.json removal..."
MISSING_JSON="$(comm -13 <(printf '%s\n' "$JSON_REMOVED") <(printf '%s\n' "$RULE_REMOVED"))"
if [ -z "$MISSING_JSON" ]; then
  echo "  PASS"
else
  while IFS= read -r p; do
    [ -z "$p" ] && continue
    echo "  FAIL: $p has a row in removed-plugins.md but no marketplace.json entry"
  done <<< "$MISSING_JSON"
  FAILURES=$((FAILURES + 1))
fi

echo "4. No removed plugin is also registered as active..."
RESURRECTED="$(comm -12 <(printf '%s\n' "$JSON_REMOVED") <(printf '%s\n' "$ACTIVE"))"
if [ -z "$RESURRECTED" ]; then
  echo "  PASS ($(printf '%s\n' "$ACTIVE" | grep -c .) active plugins, none previously removed)"
else
  while IFS= read -r p; do
    [ -z "$p" ] && continue
    echo "  FAIL: $p is in marketplace.json's removed list AND its active plugins"
  done <<< "$RESURRECTED"
  FAILURES=$((FAILURES + 1))
fi

echo
if [ "$FAILURES" -eq 0 ]; then
  echo "PASS: removed-plugins sync (4 checks)"
  exit 0
fi
echo "$FAILURES check(s) failed."
exit 1

#!/usr/bin/env bash
# render-plan-html.py must honour the file-published signal: a spec write with
# no sibling .html renders nothing (the author chose artifact delivery — the
# hook must not resurrect a file they did not publish) but still rebuilds the
# gallery index, because artifact-mode spec edits change card data. A spec
# whose sibling exists is re-rendered exactly as before.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
HOOK="$REPO_ROOT/kit/plugins/plan-agent/hooks/render-plan-html.py"
PLUGIN_ROOT="$REPO_ROOT/kit/plugins/plan-agent"
FAILURES=0

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

pass() { echo "  ok   — $1"; }
fail() { echo "  FAIL — $1"; FAILURES=$((FAILURES + 1)); }

echo "test-render-hook-artifact-skip"

mkdir -p "$WORK/docs/plans"

write_spec() {
  cat > "$1" <<'SPEC'
---
status: in-progress
type: feature
created: 2026-08-20
artifact-url: https://claude.ai/public/artifacts/test-abc
---

# Plan: Add the hook fixture

## Objective

Fixture objective.

## Steps

1. Do the thing Why: fixture Verify: check.

## Acceptance Criteria

- [ ] done

## Verification

Run the fixture check.
SPEC
}

run_hook() {
  printf '{"tool_input": {"file_path": "%s"}}' "$1" | \
    HOME="$WORK" CLAUDE_PROJECT_DIR="$WORK" CLAUDE_PLUGIN_ROOT="$PLUGIN_ROOT" \
    python3 "$HOOK"
}

# ---------------------------------------------------------------------------
# Case A — no sibling .html: skip the render, still rebuild the index.
# ---------------------------------------------------------------------------
SPEC_A="$WORK/docs/plans/add-artifact-mode.md"
write_spec "$SPEC_A"

if run_hook "$SPEC_A"; then
  pass "hook exits 0 on a sibling-less spec"
else
  fail "hook exited non-zero on a sibling-less spec"
fi

if [ -f "$WORK/docs/plans/add-artifact-mode.html" ]; then
  fail "sibling was created — hook resurrected an unpublished .html"
else
  pass "no sibling created for an artifact-mode spec"
fi

if [ -f "$WORK/docs/plans/index.html" ]; then
  pass "gallery index still rebuilt on the skipped render"
else
  fail "gallery index not rebuilt when the render was skipped"
fi

# ---------------------------------------------------------------------------
# Case B — sibling exists: re-render it as before.
# ---------------------------------------------------------------------------
SPEC_B="$WORK/docs/plans/ship-file-mode.md"
write_spec "$SPEC_B"
printf '<html><body>stale</body></html>\n' > "$WORK/docs/plans/ship-file-mode.html"

if run_hook "$SPEC_B"; then
  pass "hook exits 0 on a spec with a sibling"
else
  fail "hook exited non-zero on a spec with a sibling"
fi

if grep -q '<title>Plan:' "$WORK/docs/plans/ship-file-mode.html"; then
  pass "existing sibling re-rendered from the spec"
else
  fail "existing sibling not re-rendered (still stale)"
fi

echo
if [ "$FAILURES" -eq 0 ]; then
  echo "test-render-hook-artifact-skip: all checks passed"
  exit 0
fi
echo "test-render-hook-artifact-skip: $FAILURES check(s) failed"
exit 1

#!/usr/bin/env bash
set -euo pipefail

# Objective smoke test for the finalize-plan --all sweep flag.
#
# Sweep mode discovers plans that are implemented but never marked completed
# (grep -l for a plan-status meta tag valued todo/in-progress, so non-plan
# HTML is never a candidate), scores them with the cheap non-interactive
# token-evidence pass, batch-confirms via one multi-select prompt, and
# finalizes only the selected plans. These asserts pin the flag to the SKILL.md
# contract, the README docs, and the marketplace version so they cannot
# silently diverge.

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$ROOT/kit/plugins/plan-agent/skills/finalize-plan/SKILL.md"
README="$ROOT/kit/plugins/plan-agent/README.md"
CHANGELOG="$ROOT/kit/plugins/plan-agent/CHANGELOG.md"
MARKETPLACE="$ROOT/.claude-plugin/marketplace.json"
FAILURES=0

echo "=== finalize-plan --all Sweep Smoke Test ==="

echo "1. SKILL.md argument-hint advertises md/html input and --all..."
if grep -q 'argument-hint: "\[plan-file.md|.html\] \[--all\] \[--dir <path>\]"' "$SKILL"; then
  echo "  PASS"
else
  echo "  FAIL: argument-hint does not include [plan-file.md|.html] and [--all]"
  FAILURES=$((FAILURES + 1))
fi

echo "1b. Spec mode edits the Markdown and re-renders via build-plan-html.mjs..."
if grep -q '^### Spec mode' "$SKILL" \
   && grep -q '^### Legacy mode' "$SKILL" \
   && grep -q 'status: completed' "$SKILL" \
   && grep -q 'build-plan-html.mjs' "$SKILL" \
   && grep -q '## Completion Report' "$SKILL"; then
  echo "  PASS"
else
  echo "  FAIL: Step 5 is missing the spec-mode md edits (frontmatter status, checkbox flips, Completion Report, re-render) or the legacy fallback"
  FAILURES=$((FAILURES + 1))
fi

echo "2. Step 1 routes --all to sweep mode..."
# grep -F: a BRE-escaped backtick (\`) is a GNU buffer anchor, never a match.
if grep -qF 'If `$ARGUMENTS` contains `--all`' "$SKILL"; then
  echo "  PASS"
else
  echo "  FAIL: Step 1 has no --all routing clause"
  FAILURES=$((FAILURES + 1))
fi

echo "3. Sweep discovery matches todo/in-progress status tags, excluding index.html and archive/..."
if grep -Fq '## Sweep mode (`--all`)' "$SKILL" \
   && grep -Fq "grep -lE 'name=\"plan-status\" content=\"(todo|in-progress)\"'" "$SKILL" \
   && grep -Fq "| grep -v '/index\\.html\$' || true" "$SKILL" \
   && grep -Fq 'Never descend into `archive/`' "$SKILL"; then
  echo "  PASS"
else
  echo "  FAIL: sweep section is missing the heading, positive status-tag discovery, non-fatal no-match handling, or the index.html/archive exclusions"
  FAILURES=$((FAILURES + 1))
fi

echo "4. Sweep confirms via one multi-select prompt with a batch criteria mode..."
if grep -q 'multiSelect: true' "$SKILL" \
   && grep -q 'How should acceptance criteria be checked' "$SKILL"; then
  echo "  PASS"
else
  echo "  FAIL: batch confirmation (multiSelect + criteria-mode question) not found"
  FAILURES=$((FAILURES + 1))
fi

echo "5. Expensive verification is deferred and sweep scoring is non-interactive..."
if grep -q 'Do \*\*not\*\* run Step 3b' "$SKILL" \
   && grep -q 'Sweep scoring is non-interactive' "$SKILL" \
   && grep -q "skip Step 3a's no-token \`AskUserQuestion\`" "$SKILL"; then
  echo "  PASS"
else
  echo "  FAIL: S2 does not defer Step 3b/3c or does not skip the no-token prompt"
  FAILURES=$((FAILURES + 1))
fi

echo "6. README documents the --all flag..."
if grep -q '/plan-agent:finalize-plan --all' "$README" \
   && grep -qF 'Sweep mode (`--all`)' "$README"; then
  echo "  PASS"
else
  echo "  FAIL: README is missing the --all usage line or sweep-mode paragraph"
  FAILURES=$((FAILURES + 1))
fi

echo "7. CHANGELOG top entry version matches marketplace.json plan-agent version..."
if python3 -c "
import json, re, sys
mv = next((p['version'] for p in json.load(open('$MARKETPLACE'))['plugins'] if p['name'] == 'plan-agent'), None)
top = next((m.group(1) for line in open('$CHANGELOG') if (m := re.match(r'## (\d+\.\d+\.\d+)', line))), None)
sys.exit(0 if mv is not None and top is not None and top == mv else 1)
"; then
  echo "  PASS"
else
  echo "  FAIL: CHANGELOG top version and marketplace.json plan-agent version disagree"
  FAILURES=$((FAILURES + 1))
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "All checks passed."
else
  echo "$FAILURES check(s) failed."
  exit 1
fi

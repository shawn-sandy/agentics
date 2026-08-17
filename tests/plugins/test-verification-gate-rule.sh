#!/usr/bin/env bash
set -euo pipefail

# The verification-gate authoring standard is the leverage point of the
# 2026-08-17 agent-prompting audit: five shipped skills could declare success
# on broken output because nothing required them to verify their own artifact,
# and nothing in the authoring rules or the skill-quality rubric asked the
# next skill to do better. The standard now lives in two places that must not
# drift apart:
#
#   1. .claude/rules/plugin-patterns.md — the rule every author reads
#   2. skill-reviewer's Dimension 3 rubric — the check every review scores
#
# This test holds both, the same way test-exitplanmode-guard.sh holds the
# plan-mode guard: retention greps on the load-bearing phrases, so a future
# cleanup cannot strip the requirement without failing CI.

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
RULE="$ROOT/.claude/rules/plugin-patterns.md"
RUBRIC="$ROOT/kit/plugins/skill-reviewer/skills/reviewing-skills/references/audit-steps.md"
PRACTICES="$ROOT/kit/plugins/skill-reviewer/skills/reviewing-skills/references/best-practices.md"
FAILURES=0

require() {
  local file="$1" needle="$2" label="$3"
  if grep -qF "$needle" "$file"; then
    echo "PASS: $label"
  else
    echo "FAIL: $label — missing from $file"
    FAILURES=$((FAILURES + 1))
  fi
}

# Positive canary: an absence check over a wrong path passes vacuously, so
# first prove the files exist and are non-empty.
for f in "$RULE" "$RUBRIC" "$PRACTICES"; do
  if [ ! -s "$f" ]; then
    echo "FAIL: canary — $f missing or empty"
    FAILURES=$((FAILURES + 1))
  fi
done

# 1. The authoring rule: mutating skills verify their own output.
require "$RULE" "## The verification gate" \
  "plugin-patterns.md carries the verification-gate section"
require "$RULE" "Done means" \
  "plugin-patterns.md redefines done as artifact + check"
require "$RULE" "one worked example of that output" \
  "plugin-patterns.md requires a worked example for structured output"

# 2. The rubric: Dimension 3 scores the same two requirements.
require "$RUBRIC" "Verification gate" \
  "audit-steps.md Dimension 3 has the verification-gate check"
require "$RUBRIC" "Warning if absent in mutating or measuring skills" \
  "audit-steps.md classifies the missing gate as a Warning"
require "$RUBRIC" "no verification gate" \
  "audit-steps.md scoring caps Dimension 3 when the gate is absent"

# 3. The best-practices reference teaches the pattern the rubric scores.
require "$PRACTICES" "### Verification Gate" \
  "best-practices.md carries the Verification Gate section"
require "$PRACTICES" "never estimated" \
  "best-practices.md forbids estimated measurements"

echo
if [ "$FAILURES" -gt 0 ]; then
  echo "test-verification-gate-rule: $FAILURES failure(s)"
  exit 1
fi
echo "test-verification-gate-rule: all checks passed"

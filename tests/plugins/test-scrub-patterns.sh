#!/usr/bin/env bash
set -euo pipefail

# security-scrub's pattern table is the only thing standing between a real
# credential and a publicly shared card. The original `sk-` pattern excluded
# hyphens, so a genuine Anthropic key (`sk-ant-api03-...`) scanned clean and
# the scrub reported PASS — the worst failure mode a scanner has, because a
# clean report reads as safety.
#
# This test holds three ends:
#   1. Behavior — each HIGH pattern actually matches a canonical fake secret
#      of its family (grep -E, same engine the skill instructs).
#   2. Regression — the Anthropic-style key matches the current sk- pattern
#      and does NOT match the old broken one, so the fix cannot be silently
#      reverted by "simplifying" the character class.
#   3. Sync — the pattern strings exist verbatim in BOTH scrub-rules.md (the
#      source of truth) and security-scrub/SKILL.md's Step 2 mirror list, so
#      the two cannot drift apart.
#
# All fixture values are obviously fake (runs of x) — they exercise pattern
# shape, not entropy, and must never look like real credentials.

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
RULES="$ROOT/kit/plugins/social-media-tools/skills/security-scrub/references/scrub-rules.md"
SKILL="$ROOT/kit/plugins/social-media-tools/skills/security-scrub/SKILL.md"
FAILURES=0

fail() {
  echo "FAIL: $1"
  FAILURES=$((FAILURES + 1))
}

pass() {
  echo "PASS: $1"
}

# --- Check 1: each HIGH pattern matches its canonical fake secret ------------

# pattern | fixture that must match
check_match() {
  local pattern="$1" fixture="$2" label="$3"
  if printf '%s\n' "$fixture" | grep -qE "$pattern"; then
    pass "pattern matches $label"
  else
    fail "pattern does NOT match $label: $pattern"
  fi
}

check_match 'sk-[A-Za-z0-9-]{20,}'      'sk-ant-api03-xxxxxxxxxxxxxxxxxxxx' 'Anthropic-style key (sk-ant-...)'
check_match 'sk-[A-Za-z0-9-]{20,}'      'sk-xxxxxxxxxxxxxxxxxxxxxxxx'       'OpenAI-style key (sk-...)'
check_match 'ghp_[A-Za-z0-9]{36}'       'ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx' 'GitHub PAT (ghp_)'
check_match 'gho_[A-Za-z0-9]{36}'       'gho_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx' 'GitHub OAuth token (gho_)'
check_match 'github_pat_[A-Za-z0-9_]{22,}' 'github_pat_xxxxxxxxxxxxxxxxxxxxxx' 'GitHub fine-grained PAT'
check_match 'glpat-[A-Za-z0-9_-]{20,}'  'glpat-xxxxxxxxxxxxxxxxxxxx'        'GitLab PAT (glpat-)'
# The Stripe and Slack fixtures are assembled at runtime: even with x-runs,
# their literal shapes trip GitHub push protection, which scans blob content.
X8=$(printf 'x%.0s' {1..8})
X24=$(printf 'x%.0s' {1..24})
check_match 'sk_live_[A-Za-z0-9]{24,}'  "sk_live_${X24}"  'Stripe live key (sk_live_)'
check_match 'AIza[A-Za-z0-9_-]{35}'     'AIzaxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx' 'Google API key (AIza)'
check_match 'hooks\.slack\.com/services/T[A-Za-z0-9]+/B[A-Za-z0-9]+/[A-Za-z0-9]+' \
            "https://hooks.slack.com/services/T${X8}/B${X8}/${X24}" \
            'Slack webhook URL'
check_match 'AKIA[A-Z0-9]{16}'          'AKIAXXXXXXXXXXXXXXXX'              'AWS access key (AKIA)'

# --- Check 2: regression canary — the old broken pattern must stay dead ------

# The pre-fix class had no hyphen: a real Anthropic key fell through. If the
# fixture ever matches the old pattern this canary is stale, not the fix —
# but if the CURRENT rules file reverts to the hyphen-less class, Check 3's
# verbatim lookup of the fixed pattern fails first.
if printf '%s\n' 'sk-ant-api03-xxxxxxxxxxxxxxxxxxxx' | grep -qE 'sk-[A-Za-z0-9]{20,}'; then
  fail "canary stale: hyphen-less pattern unexpectedly matches sk-ant fixture"
else
  pass "canary: hyphen-less legacy pattern still misses sk-ant keys (fix is load-bearing)"
fi

# --- Check 3: the fixed patterns exist verbatim in both instruction files ----

require_in() {
  local file="$1" needle="$2" label="$3"
  if grep -qF "$needle" "$file"; then
    pass "$label present in $(basename "$file")"
  else
    fail "$label missing from $file"
  fi
}

for needle in \
  'sk-[A-Za-z0-9-]{20,}' \
  'gho_[A-Za-z0-9]{36}' \
  'github_pat_[A-Za-z0-9_]{22,}' \
  'glpat-[A-Za-z0-9_-]{20,}' \
  'sk_live_[A-Za-z0-9]{24,}' \
  'AIza[A-Za-z0-9_-]{35}' \
  'hooks\.slack\.com/services/' \
; do
  require_in "$RULES" "$needle" "pattern $needle"
  require_in "$SKILL" "$needle" "pattern $needle"
done

# The email PII row lives only in the rules table (LOW severity, informational).
require_in "$RULES" '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+' 'email PII pattern'

# --- Check 4: share-code carries the scrub gate ------------------------------

# share-code was the one code-sharing skill with no scrub phase at all. Hold
# the gate: the Skill invocation and the GATE RESULT check must both survive.
SHARE_CODE="$ROOT/kit/plugins/social-media-tools/skills/share-code/SKILL.md"
require_in "$SHARE_CODE" 'social-media-tools:security-scrub' 'scrub invocation'
require_in "$SHARE_CODE" 'GATE RESULT' 'GATE RESULT check'

# share-project must gate on GATE RESULT (the user's Cancel), never on
# SCRUB RESULT alone — the old wording continued past a user Cancel.
SHARE_PROJECT="$ROOT/kit/plugins/social-media-tools/skills/share-project/SKILL.md"
require_in "$SHARE_PROJECT" 'GATE RESULT: BLOCKED' 'GATE RESULT gating'

# --- Result ------------------------------------------------------------------

echo
if [ "$FAILURES" -gt 0 ]; then
  echo "test-scrub-patterns: $FAILURES failure(s)"
  exit 1
fi
echo "test-scrub-patterns: all checks passed"

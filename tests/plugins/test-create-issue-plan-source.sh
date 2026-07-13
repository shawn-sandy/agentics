#!/usr/bin/env bash
# Smoke test: create-issue plan source + implementation-plan Step 8 wiring.
set -euo pipefail
cd "$(dirname "$0")/../.."

CI_SKILL="kit/plugins/git-agent/skills/create-issue/SKILL.md"
IP_SKILL="kit/plugins/plan-agent/skills/implementation-plan/SKILL.md"
TEMPLATE="kit/plugins/git-agent/skills/create-issue/references/plan-issue.md"

fail=0
check() { # check <description> <command...>
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then echo "ok: $desc"; else echo "FAIL: $desc"; fail=1; fi
}

check "create-issue parses the plan source keyword" \
  grep -q '`bug`, `feature`, `selection`, `session`, `plan`' "$CI_SKILL"
check "create-issue has a plan per-source block" \
  grep -q '^\*\*`plan`\*\*' "$CI_SKILL"
check "create-issue routes plan to the plan-issue template" \
  grep -q -- '- `plan` → `plan-issue.md`' "$CI_SKILL"
check "plan-issue template exists with the checklist skeleton" \
  grep -q '## Acceptance Criteria' "$TEMPLATE"
check "implementation-plan Step 8 asks the tracking-issue question" \
  grep -q 'Create a tracking issue' "$IP_SKILL"
check "implementation-plan invokes create-issue with the plan source" \
  grep -q 'git-agent:create-issue", args: "plan <spec path>"' "$IP_SKILL"
check "implementation-plan degrades when git-agent is missing" \
  grep -q 'git-agent` plugin is not installed' "$IP_SKILL"

versions=$(python3 -c "
import json
m = json.load(open('.claude-plugin/marketplace.json'))
v = {p['name']: p['version'] for p in m['plugins']}
ga = tuple(map(int, v['git-agent'].split('.')))
pa = tuple(map(int, v['plan-agent'].split('.')))
print('ok' if ga >= (3,12,0) and pa >= (2,22,0) else 'bad')
")
if [ "$versions" = "ok" ]; then echo "ok: marketplace versions bumped"; else echo "FAIL: marketplace versions"; fail=1; fi

exit $fail

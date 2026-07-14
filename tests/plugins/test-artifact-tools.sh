#!/usr/bin/env bash
# Objective smoke test for the artifact-tools plugin.
# Asserts the plugin is complete, valid, and installable: manifest without a
# version key, three skills with required frontmatter, the bundled transcript
# extractor, marketplace registration at 1.0.0, and the documented safety
# contracts (blocking scrub gate, cap-and-summarize, fallback, artifact-url).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PLUGIN="$ROOT/kit/plugins/artifact-tools"
MARKET="$ROOT/.claude-plugin/marketplace.json"
fail() { echo "FAIL: $1" >&2; exit 1; }
checks=0
ok() { checks=$((checks + 1)); }

# 1. Manifest is valid JSON, names the plugin, and has no version key
#    (for relative-path plugins a version here silently overrides marketplace.json).
MANIFEST="$PLUGIN/.claude-plugin/plugin.json"
[ -f "$MANIFEST" ] || fail "plugin.json missing at $MANIFEST"
python3 -m json.tool "$MANIFEST" > /dev/null 2>&1 || fail "plugin.json is not valid JSON"
python3 - "$MANIFEST" <<'EOF' || fail "plugin.json: bad name or forbidden version key"
import json, sys
m = json.load(open(sys.argv[1]))
assert m.get("name") == "artifact-tools", f'name is {m.get("name")!r}'
assert "version" not in m, "version key present — it overrides marketplace.json"
EOF
ok

# 2. All three skills exist with the required frontmatter fields.
for skill in diff-artifact session-artifact plan-artifact; do
  f="$PLUGIN/skills/$skill/SKILL.md"
  [ -f "$f" ] || fail "$skill/SKILL.md missing"
  grep -qE "^name: $skill$" "$f" || fail "$skill: frontmatter name missing or mismatched"
  grep -qE "^description: " "$f" || fail "$skill: frontmatter description missing"
  grep -qE "^allowed-tools: " "$f" || fail "$skill: allowed-tools missing"
  # Deferred tools require ToolSearch, else a permission prompt breaks the run.
  grep -qE "^allowed-tools:.*ToolSearch" "$f" || fail "$skill: ToolSearch missing from allowed-tools"
  grep -qE "^allowed-tools:.*Artifact" "$f" || fail "$skill: Artifact missing from allowed-tools"
  # A body that invokes another plugin's skill must declare Skill, else the
  # call raises a permission prompt mid-run.
  if grep -qE '`social-media-tools:' "$f"; then
    grep -qE "^allowed-tools:.*(^|[ ,])Skill([ ,]|$)" "$f" \
      || fail "$skill: body invokes a social-media-tools skill but Skill is not in allowed-tools"
  fi
  # Three-part description must fit the per-skill context budget.
  python3 - "$f" "$skill" <<'EOF' || fail "description too long"
import re, sys
body = open(sys.argv[1], encoding="utf-8").read()
d = re.search(r'^description:\s*"?(.*?)"?\s*$', body, re.M).group(1)
assert len(d) <= 200, f'{sys.argv[2]}: description is {len(d)} chars (max 200)'
EOF
  ok
done

# 3. session-artifact bundles its own extractor (no social-media-tools dependency).
SCRIPT="$PLUGIN/skills/session-artifact/scripts/export_session.py"
[ -f "$SCRIPT" ] || fail "bundled export_session.py missing at $SCRIPT"
python3 -c "import ast,sys; ast.parse(open(sys.argv[1]).read())" "$SCRIPT" \
  || fail "bundled export_session.py is not valid Python"
grep -qF 'export_session.py' "$PLUGIN/skills/session-artifact/SKILL.md" \
  || fail "session-artifact does not invoke the bundled script"
ok

# 4. Safety contracts are documented, not just implied.
DIFF="$PLUGIN/skills/diff-artifact/SKILL.md"
SESSION="$PLUGIN/skills/session-artifact/SKILL.md"
PLAN="$PLUGIN/skills/plan-artifact/SKILL.md"

# Blocking scrub gate before any publish.
for f in "$DIFF" "$SESSION"; do
  grep -qF 'security-scrub' "$f" || fail "$(basename "$(dirname "$f")"): scrub skill not referenced"
  grep -qF 'GATE RESULT: BLOCKED' "$f" || fail "$(basename "$(dirname "$f")"): BLOCKED gate not documented"
  grep -qiE 'hard stop' "$f" || fail "$(basename "$(dirname "$f")"): scrub gate is not documented as blocking"
done
ok

# Diff page requirements: cap-and-summarize, sidebar, theme, severity legend.
grep -qiF 'cap-and-summarize' "$DIFF" || fail "diff-artifact: cap-and-summarize policy missing"
grep -qF '16 MiB' "$DIFF" || fail "diff-artifact: artifact size cap not cited"
grep -qiE 'sticky file sidebar' "$DIFF" || fail "diff-artifact: sticky sidebar requirement missing"
grep -qF 'prefers-color-scheme' "$DIFF" || fail "diff-artifact: adaptive light/dark theme missing"
grep -qiE 'severity legend' "$DIFF" || fail "diff-artifact: severity legend missing"
grep -qiE 'falling back to branch mode|fall back to branch mode' "$DIFF" \
  || fail "diff-artifact: PR-mode degradation missing"
ok

# All three document the fallback and the artifact-url republish mechanic.
for f in "$DIFF" "$SESSION" "$PLAN"; do
  name="$(basename "$(dirname "$f")")"
  grep -qF 'artifact-url:' "$f" || fail "$name: artifact-url frontmatter write not documented"
  grep -qiE 'fallback|publish failure|publishing fails' "$f" || fail "$name: local fallback not documented"
  grep -qF 'ExitPlanMode' "$f" || fail "$name: ExitPlanMode bootstrap missing"
done
ok

# 5. Marketplace registration at 1.0.0.
python3 -m json.tool "$MARKET" > /dev/null 2>&1 || fail "marketplace.json is not valid JSON"
python3 - "$MARKET" <<'EOF' || fail "marketplace: artifact-tools not registered at 1.0.0"
import json, sys
plugins = json.load(open(sys.argv[1]))["plugins"]
e = next((p for p in plugins if p["name"] == "artifact-tools"), None)
assert e, "artifact-tools entry missing"
assert e["version"] == "1.0.0", f'version is {e["version"]!r}, expected 1.0.0'
assert e["source"]["path"] == "kit/plugins/artifact-tools", "source path mismatch"
assert e["category"] == "development", f'category is {e["category"]!r}'
EOF
ok

# 6. Docs exist (repo convention: README + CHANGELOG per plugin).
[ -f "$PLUGIN/README.md" ] || fail "README.md missing"
[ -f "$PLUGIN/CHANGELOG.md" ] || fail "CHANGELOG.md missing"
grep -qF '1.0.0' "$PLUGIN/CHANGELOG.md" || fail "CHANGELOG has no 1.0.0 entry"
grep -qF 'kit/plugins/artifact-tools' "$MANIFEST" || fail "homepage must point at the plugin directory"
ok

echo "PASS: artifact-tools smoke test ($checks checks)"

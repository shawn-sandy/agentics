#!/usr/bin/env bash
# Objective smoke test for the artifact-tools plugin.
# Asserts the plugin is complete, valid, and installable: manifest without a
# version key, four skills with required frontmatter, the bundled transcript
# extractor, marketplace registration agreeing with the CHANGELOG, and the
# documented safety contracts (blocking scrub gate, cap-and-summarize,
# fallback, artifact-url).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PLUGIN="$ROOT/kit/plugins/artifact-tools"
MARKET="$ROOT/.claude-plugin/marketplace.json"
CHANGELOG="$PLUGIN/CHANGELOG.md"
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

# 2. All four skills validate against their real YAML frontmatter block.
#    Parsing the opening block (not grepping the whole file) is what stops prose
#    or a code sample further down from satisfying a frontmatter requirement.
for skill in diff-artifact session-artifact plan-artifact prompt-artifact; do
  f="$PLUGIN/skills/$skill/SKILL.md"
  [ -f "$f" ] || fail "$skill/SKILL.md missing"
  python3 - "$f" "$skill" <<'EOF' || fail "frontmatter validation failed"
import re, sys
path, skill = sys.argv[1], sys.argv[2]
text = open(path, encoding="utf-8").read()

# The frontmatter is the block delimited by the first two --- lines, and it must
# open the file. Anything after it is body and cannot satisfy these checks.
m = re.match(r'---\n(.*?)\n---\n(.*)$', text, re.S)
assert m, f'{skill}: no opening YAML frontmatter block'
fm, body = m.group(1), m.group(2)

def field(name):
    hit = re.search(rf'^{name}:[ \t]*(.*?)[ \t]*$', fm, re.M)
    assert hit, f'{skill}: frontmatter is missing `{name}:`'
    return hit.group(1).strip()

assert field('name') == skill, f'{skill}: frontmatter name mismatch'

desc = field('description').strip('"')
assert desc, f'{skill}: empty description'
assert len(desc) <= 200, f'{skill}: description is {len(desc)} chars (max 200)'

tools = [t.strip() for t in field('allowed-tools').split(',') if t.strip()]
# Deferred tools need ToolSearch, else the schema fetch prompts mid-run.
for required in ('ToolSearch', 'Artifact'):
    assert required in tools, f'{skill}: {required} missing from allowed-tools'
# A body invoking another plugin's skill must declare Skill for the same reason.
if re.search(r'`social-media-tools:', body):
    assert 'Skill' in tools, f'{skill}: body invokes a social-media-tools skill but Skill is not in allowed-tools'
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
PROMPT="$PLUGIN/skills/prompt-artifact/SKILL.md"

# Blocking scrub gate, asserted by ORDER rather than mere keyword presence —
# a skill that published first and documented the gate afterwards would satisfy
# a presence-only check while shipping unscanned content.
# (plan-artifact is excluded by design: it republishes prose already written.)
for f in "$DIFF" "$SESSION" "$PROMPT"; do
  python3 - "$f" <<'EOF' || fail "scrub-gate ordering check failed"
import re, sys
path = sys.argv[1]
skill = path.split('/')[-2]
body = re.match(r'---\n.*?\n---\n(.*)$', open(path, encoding="utf-8").read(), re.S).group(1)
lines = body.splitlines()

def first(pattern):
    for i, line in enumerate(lines):
        if re.search(pattern, line):
            return i
    return None

scrub   = first(r'security-scrub')
blocked = first(r'GATE RESULT: BLOCKED')
stop    = first(r'(?i)hard stop')
publish = first(r'select:Artifact')     # the publish bootstrap

assert scrub   is not None, f'{skill}: scrub skill not referenced'
assert blocked is not None, f'{skill}: BLOCKED gate not documented'
assert stop    is not None, f'{skill}: scrub gate not documented as blocking'
assert publish is not None, f'{skill}: no Artifact publish bootstrap found'
assert scrub < publish, (
    f'{skill}: scrub gate (line {scrub+1}) must be documented BEFORE the publish '
    f'step (line {publish+1}) — content would ship unscanned')
assert blocked < publish, (
    f'{skill}: BLOCKED verdict (line {blocked+1}) must precede publish (line {publish+1})')
EOF
done
ok

# Diff page requirements: cap-and-summarize, sidebar, theme, severity legend.
grep -qiF 'cap-and-summarize' "$DIFF" || fail "diff-artifact: cap-and-summarize policy missing"
grep -qF '16 MiB' "$DIFF" || fail "diff-artifact: artifact size cap not cited"
grep -qiE 'sticky file sidebar' "$DIFF" || fail "diff-artifact: sticky sidebar requirement missing"
grep -qF 'prefers-color-scheme' "$DIFF" || fail "diff-artifact: adaptive light/dark theme missing"
grep -qiE 'severity legend' "$DIFF" || fail "diff-artifact: severity legend missing"
# PR degradation must EXECUTE the branch diff, not merely announce it, and must
# detect a non-GitHub remote as well as a missing/unauthenticated gh.
grep -qiE 'using branch mode|fall(ing)? back to branch mode' "$DIFF" \
  || fail "diff-artifact: PR-mode degradation message missing"
grep -qF 'git diff "${DEFAULT_BRANCH}...HEAD" > "$DIFF_FILE"' "$DIFF" \
  || fail "diff-artifact: PR degradation must actually run the branch diff, not just report it"
grep -qF 'git remote get-url origin' "$DIFF" \
  || fail "diff-artifact: PR mode must detect a non-GitHub remote"
# The rendered page must be size-checked and rescanned before publish.
grep -qF '16 * 1024 * 1024' "$DIFF" \
  || fail "diff-artifact: rendered 16 MiB cap not enforced by measurement"
# Republish key must not be date-derived, or tomorrow's run misses the URL.
grep -qE 'target=".claude/artifacts/diff-.*\$\(date' "$DIFF" \
  && fail "diff-artifact: inbox key is date-derived — breaks cross-day republish"
ok

# All four document the fallback and the artifact-url republish mechanic.
for f in "$DIFF" "$SESSION" "$PLAN" "$PROMPT"; do
  name="$(basename "$(dirname "$f")")"
  grep -qF 'artifact-url:' "$f" || fail "$name: artifact-url frontmatter write not documented"
  grep -qiE 'fallback|publish failure|publishing fails' "$f" || fail "$name: local fallback not documented"
  grep -qF 'ExitPlanMode' "$f" || fail "$name: ExitPlanMode bootstrap missing"
done
ok

# 5. Marketplace registration, with the version tracking the CHANGELOG rather
#    than a literal — a release bump is correct behaviour and must not fail this
#    test; marketplace.json and the CHANGELOG drifting apart is the real defect.
python3 -m json.tool "$MARKET" > /dev/null 2>&1 || fail "marketplace.json is not valid JSON"
python3 - "$MARKET" "$CHANGELOG" <<'EOF' || fail "marketplace: artifact-tools registration is wrong"
import json, re, sys
plugins = json.load(open(sys.argv[1]))["plugins"]
e = next((p for p in plugins if p["name"] == "artifact-tools"), None)
assert e, "artifact-tools entry missing"
heading = re.search(r"^## \[(\d+\.\d+\.\d+)\]", open(sys.argv[2]).read(), re.M)
assert heading, "no '## [x.y.z]' release heading found in CHANGELOG.md"
latest = heading.group(1)
assert e["version"] == latest, f'version is {e["version"]!r}, CHANGELOG says {latest!r}'
assert e["source"]["path"] == "kit/plugins/artifact-tools", "source path mismatch"
assert e["category"] == "development", f'category is {e["category"]!r}'
EOF
ok

# 6. Docs exist (repo convention: README + CHANGELOG per plugin).
[ -f "$PLUGIN/README.md" ] || fail "README.md missing"
[ -f "$PLUGIN/CHANGELOG.md" ] || fail "CHANGELOG.md missing"
grep -qF '1.0.0' "$PLUGIN/CHANGELOG.md" || fail "CHANGELOG has no 1.0.0 entry"
# Compare the homepage field itself — a bare grep for the path would also match
# the repository/source fields and pass while homepage pointed elsewhere.
python3 - "$MANIFEST" <<'EOF' || fail "homepage must be the plugin's own directory URL"
import json, sys
want = "https://github.com/shawn-sandy/agentics/tree/main/kit/plugins/artifact-tools"
got = json.load(open(sys.argv[1])).get("homepage")
assert got == want, f'homepage is {got!r}, expected {want!r}'
EOF
ok

# 7. Republish keys are distinct across the session-record writers.
# session-artifact, product-doc, and team-recap all key off the SAME per-session
# record file, so a shared key silently republishes one page over another's URL.
python3 - "$PLUGIN" <<'EOF' || fail "republish keys collide across artifact-tools commands"
import pathlib, sys
root = pathlib.Path(sys.argv[1])
# Each writer and the key it must own. Two assertions, both against file
# content -- comparing the literals in this map to each other would prove
# nothing, since this map is the test's own input.
owners = {
    "skills/session-artifact/SKILL.md": "artifact-url",
    "commands/product-doc.md": "product-artifact-url",
    "commands/team-recap.md": "team-artifact-url",
}
for rel, key in owners.items():
    text = (root / rel).read_text()
    # 1. The writer declares the key it owns.
    assert f"{key}:" in text, f"{rel}: never declares its republish key {key!r}"
    # 2. Every OTHER writer's key appears only under a don't-write warning. A
    #    wrapper copied from a sibling keeps the sibling's key as its own and
    #    fails here, which is the bug worth catching: all three write to one
    #    record, so a duplicated key republishes over that page's URL.
    warned = [ln for ln in text.splitlines() if "Never write" in ln or "never write" in ln]
    for rel2, other in owners.items():
        if rel2 == rel or f"{other}:" not in text:
            continue
        assert any(other in ln for ln in warned), (
            f"{rel}: mentions {other!r} but never warns against writing it"
        )
EOF
ok

# 8. Every PR-mode command guards its gh calls behind the preflight.
# `gh pr view` on a repo without gh or a GitHub remote spews shell errors into
# the transcript instead of falling back to session mode, so the guard is what
# makes the fallback a decision rather than an accident.
python3 - "$PLUGIN" <<'EOF' || fail "a PR-mode command calls gh without the preflight guard"
import pathlib, sys
root = pathlib.Path(sys.argv[1])
found = 0
for path in sorted((root / "commands").glob("*.md")):
    text = path.read_text()
    if "gh pr view" not in text:
        continue          # not a PR-mode command; nothing to guard
    found += 1
    rel = path.name
    assert "gh auth status" in text, f"{rel}: calls gh pr view with no auth preflight"
    assert "git remote get-url origin" in text, f"{rel}: never checks for a GitHub remote"
    assert "PR_MODE_UNAVAILABLE" in text, f"{rel}: no fallback branch when the preflight fails"
    # The guard must come before the first gh pr view, or it guards nothing.
    assert text.index("gh auth status") < text.index("gh pr view"), (
        f"{rel}: preflight appears after the first gh pr view"
    )
assert found >= 2, f"expected product-doc and team-recap to be PR-mode commands, found {found}"
EOF
ok

echo "PASS: artifact-tools smoke test ($checks checks)"

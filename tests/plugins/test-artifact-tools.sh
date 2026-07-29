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
# diff-artifact and prompt-artifact are split core-plus-references. The blocking
# scrub gate stays in each core (asserted by line order below, on the core only);
# the mechanics moved to these plugin-level references, so each literal is
# asserted against the file that now holds it rather than anywhere under the
# plugin — a plugin-wide grep would pass even if the gate itself moved.
REF="$PLUGIN/references"
DIFF_SOURCES="$REF/diff-sources.md"
DIFF_PAGE="$REF/diff-page.md"
DIFF_PUB="$REF/diff-publishing.md"
PROMPT_RES="$REF/prompt-resolution.md"
PROMPT_PAGE="$REF/prompt-page.md"
PROMPT_PUB="$REF/prompt-publishing.md"
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

# Every reference the two split cores name must exist, or a step points at a file
# the model cannot read and the mechanics are simply gone.
for f in "$DIFF_SOURCES" "$DIFF_PAGE" "$DIFF_PUB" \
         "$PROMPT_RES" "$PROMPT_PAGE" "$PROMPT_PUB"; do
  [ -f "$f" ] || fail "missing reference: ${f#$ROOT/}"
  grep -qF "references/$(basename "$f")" "$DIFF" "$PROMPT" \
    || fail "$(basename "$f") is orphaned — no core links to it"
done

# Diff page requirements: cap-and-summarize, sidebar, theme, severity legend.
grep -qiF 'cap-and-summarize' "$DIFF_PAGE" || fail "diff-page.md: cap-and-summarize policy missing"
grep -qF '16 MiB' "$DIFF_PAGE" || fail "diff-page.md: artifact size cap not cited"
grep -qiE 'sticky file sidebar' "$DIFF_PAGE" || fail "diff-page.md: sticky sidebar requirement missing"
grep -qF 'prefers-color-scheme' "$DIFF_PAGE" || fail "diff-page.md: adaptive light/dark theme missing"
grep -qiE 'severity legend' "$DIFF_PAGE" || fail "diff-page.md: severity legend missing"
# PR degradation must EXECUTE the branch diff, not merely announce it, and must
# detect a non-GitHub remote as well as a missing/unauthenticated gh.
grep -qiE 'using branch mode|fall(ing)? back to branch mode' "$DIFF_SOURCES" \
  || fail "diff-sources.md: PR-mode degradation message missing"
grep -qF 'git diff "${DEFAULT_BRANCH}...HEAD" > "$DIFF_FILE"' "$DIFF_SOURCES" \
  || fail "diff-sources.md: PR degradation must actually run the branch diff, not just report it"
grep -qF 'git remote get-url origin' "$DIFF_SOURCES" \
  || fail "diff-sources.md: PR mode must detect a non-GitHub remote"
# The rendered page must be size-checked and rescanned before publish. The size
# loop is a mechanic (reference); the rescan is a gate, so it stays in the core.
grep -qF '16 * 1024 * 1024' "$DIFF_PAGE" \
  || fail "diff-page.md: rendered 16 MiB cap not enforced by measurement"
grep -qF 'Rescan the finished page' "$DIFF" \
  || fail "diff-artifact: the rendered-page rescan left the core"
# Republish key must not be date-derived, or tomorrow's run misses the URL.
grep -qE 'target=".claude/artifacts/diff-.*\$\(date' "$DIFF_PUB" \
  && fail "diff-publishing.md: inbox key is date-derived — breaks cross-day republish"
# The prompt page's escaping contract and the verbatim-copy guarantee.
grep -qF 'data-type' "$PROMPT_PAGE" || fail "prompt-page.md: type chip escaping target missing"
grep -qF 'writeText' "$PROMPT_PAGE" || fail "prompt-page.md: copy button lost its clipboard call"
grep -qF '.artifact-url' "$PROMPT_PUB" || fail "prompt-publishing.md: library sidecar missing"
ok

# All four document the fallback and the artifact-url republish mechanic. For the
# two split skills the mechanic lives in its publishing reference, so the pair is
# checked together — the core must still name the fallback, and the reference must
# still carry the artifact-url write.
declare -A PUB_REF=( ["$DIFF"]="$DIFF_PUB" ["$PROMPT"]="$PROMPT_PUB" )
for f in "$DIFF" "$SESSION" "$PLAN" "$PROMPT"; do
  name="$(basename "$(dirname "$f")")"
  url_src="${PUB_REF[$f]:-$f}"
  grep -qF 'artifact-url:' "$url_src" || fail "$name: artifact-url frontmatter write not documented"
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
    "commands/eng-recap.md": "eng-artifact-url",
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
    # The remote lookup alone is not the contract -- any remote would pass it.
    # The preflight must filter that URL for github.com, or PR mode fires gh at
    # a GitLab/Bitbucket origin instead of falling back to session mode.
    assert "github" in text[text.index("git remote get-url origin"):text.index("PR_MODE_UNAVAILABLE")], (
        f"{rel}: preflight retrieves the origin but never filters it for github.com"
    )
    assert "PR_MODE_UNAVAILABLE" in text, f"{rel}: no fallback branch when the preflight fails"
    # The guard must come before the first gh pr view, or it guards nothing.
    assert text.index("gh auth status") < text.index("gh pr view"), (
        f"{rel}: preflight appears after the first gh pr view"
    )
assert found >= 3, (
    f"expected product-doc, team-recap and eng-recap to be PR-mode commands, found {found}"
)
EOF
ok

# 8b. The three PR-mode commands must gather the PR the same way. This is the
# contract that already drifted once: eng-recap was fixed and its two siblings
# were left fetching a head ref, silently dropping the commit bodies both of
# them say should lead the recap.
python3 - "$PLUGIN" <<'EOF' || fail "a PR-mode command's gathering drifted from its siblings"
import pathlib, re, sys
root = pathlib.Path(sys.argv[1])
found = 0
for path in sorted((root / "commands").glob("*.md")):
    text = path.read_text()
    if "gh pr view" not in text:
        continue
    found += 1
    rel = path.name
    # Assert on the gather block with comment lines stripped. The comments
    # legitimately name `headRefName` and `git fetch` while explaining why they
    # are NOT used -- a raw substring check cannot tell an explanation apart
    # from an instruction, and would pass a file that does both.
    block = re.search(r'```bash\n\s*(PR=<number-or-url>.*?)```', text, re.S)
    assert block, f"{rel}: no PR gather block to check"
    code = "\n".join(
        ln for ln in block.group(1).splitlines() if not ln.strip().startswith("#")
    )
    # Commit bodies through the API, never through a local ref. `headRefName` is
    # only a branch name, so a fork PR / deleted branch / cross-repo URL has no
    # such ref on this origin and the fetch takes the bodies down with it.
    assert "--json commits" in code, f"{rel}: commit bodies not gathered from the API"
    for banned, why in (
        ("git fetch", "fetches a head ref that need not exist on this origin"),
        ("git log", "reads commit bodies from a local ref instead of the API"),
        ("headRefName", "resolves commits through a branch name"),
    ):
        assert banned not in code, f"{rel}: {why} (`{banned}`)"
    # Unresolved findings have no other source: `comments` is top-level issue
    # comments and `reviews` carries only each review's own state and body.
    assert "reviewThreads" in code and "isResolved" in code, (
        f"{rel}: no reviewThreads query, so 'unresolved review threads' has no source"
    )
    # Both connections are bounded, so the query must be able to say it was cut
    # short -- otherwise a first page reads as the whole list.
    assert "hasNextPage" in code, f"{rel}: reviewThreads query cannot report truncation"
    assert re.search(r'truncated|more_comments', code), (
        f"{rel}: queries pageInfo but never surfaces truncation to the reader"
    )
    # Owner/repo must come from the PR, not the checkout: argument-less
    # `gh repo view` is "view current repo", which pairs a foreign PR number
    # with local owner/name on a cross-repository PR URL.
    assert not re.search(r'\$\(\s*gh repo view', code), (
        f"{rel}: derives owner/repo from the local checkout instead of the PR"
    )
assert found >= 3, f"expected 3 PR-mode commands to check, found {found}"
EOF
ok

# 9. eng-recap is the only command that reads diff hunks, so it is the only one
# that can exhaust context on a large PR. The cap is what makes that read safe,
# and a cap nobody reports is indistinguishable from a complete read.
python3 - "$PLUGIN" <<'EOF' || fail "eng-recap's diff read is uncapped or unreported"
import pathlib, re, sys
text = (pathlib.Path(sys.argv[1]) / "commands" / "eng-recap.md").read_text()

assert "gh pr diff" in text, "eng-recap: never reads the diff, so decision 4 was dropped"
# A numeric file budget, not just prose about being careful.
budget = re.search(r'at most \*\*(\d+) files\*\*', text)
assert budget, "eng-recap: reads diff hunks with no numeric file cap"
cap = int(budget.group(1))
# The cap is a cross-file contract: the command, the README, and the awk that
# implements it must all name the same number. A range check would let the
# command drift to 35 while the README still promises 20.
EXPECTED_CAP = 20
assert cap == EXPECTED_CAP, f"eng-recap: diff cap is {cap}, README/CHANGELOG promise {EXPECTED_CAP}"
assert re.search(rf'n<={EXPECTED_CAP}\b', text), (
    f"eng-recap: documents a {cap}-file cap but the awk that implements it uses a different bound"
)
readme = (pathlib.Path(sys.argv[1]) / "README.md").read_text()
assert re.search(rf'\b{EXPECTED_CAP}[ -]file', readme), (
    f"README does not state the {EXPECTED_CAP}-file diff budget the command enforces"
)
# The cap needs a defined behaviour past the budget, or it is just a limit that
# silently drops files.
assert "--name-only" in text, "eng-recap: no name-only fallback past the cap"
# And the truncation has to reach the reader. A partial read presented as
# complete is the failure this whole check exists to prevent.
assert re.search(r'[Rr]eport how many files were summarized', text), (
    "eng-recap: never requires reporting how many files were summarized"
)
EOF
ok

echo "PASS: artifact-tools smoke test ($checks checks)"

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
# titles.md predates the split but both split cores name it, so it belongs in the
# resolve/orphan sweep below: a core pointing at a missing title reference would
# otherwise pass CI and only fail at runtime, when the page needs a <title>.
TITLES="$REF/titles.md"
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
# The SKILL.md names the bare `bin/` wrapper, not the .py path: a command
# spelled `python3 "${CLAUDE_PLUGIN_ROOT}/.../export_session.py"` is refused by
# the Bash tool ("Contains expansion") before permission rules are consulted and
# never runs. So this follows the indirection — SKILL.md must name the wrapper,
# and the wrapper must exec the bundled script — rather than grepping SKILL.md
# for a filename it can no longer legally contain.
# Both greps are structural, not substring. A raw `grep -qF` is satisfied by
# PROSE: SKILL.md line 60 reads "`artifact-export-session` is a bundled bin/
# wrapper...", so deleting the actual command on line 57 would leave a substring
# check green while the runnable invocation was gone. Same for the wrapper — a
# comment naming export_session.py would satisfy a substring match without the
# script ever being exec'd. Matching command position and the exec line closes
# both. (The SKILL.md half is the identical loophole flagged in
# test-no-shell-expansion.sh check 2 and fixed there; this file had it too.)
WRAPPER="$PLUGIN/bin/artifact-export-session"
grep -qE '^[[:space:]]*artifact-export-session([[:space:]]|$)' \
  "$PLUGIN/skills/session-artifact/SKILL.md" \
  || fail "session-artifact does not invoke its bin/ wrapper in command position (prose naming it does not count)"
[ -x "$WRAPPER" ] || fail "bin/artifact-export-session missing or not executable"
grep -qE '^[[:space:]]*exec[[:space:]].*export_session\.py' "$WRAPPER" \
  || fail "bin/artifact-export-session does not exec the bundled script (a mention in a comment does not count)"
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
         "$PROMPT_RES" "$PROMPT_PAGE" "$PROMPT_PUB" "$TITLES"; do
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
python3 - "$DIFF" <<'EOF' || fail "diff-artifact: rendered-page rescan missing or after publish"
import re, sys
body = re.match(r'---\n.*?\n---\n(.*)$', open(sys.argv[1], encoding="utf-8").read(), re.S).group(1)
lines = body.splitlines()
def first(p):
    return next((i for i, l in enumerate(lines) if re.search(p, l)), None)
rescan  = first(r'Rescan the finished page')
publish = first(r'select:Artifact')
assert rescan is not None, 'the rendered-page rescan left the core'
assert publish is not None, 'no Artifact publish bootstrap found'
# Presence is not the contract: a rescan documented after the publish bootstrap
# scans a page that already shipped.
assert rescan < publish, (
    f'rescan (line {rescan+1}) must precede the publish bootstrap (line {publish+1})')
EOF
# prompt-artifact deliberately has no rendered-page rescan: its Step 4 gate covers
# every prompt body, which is all the page contains, so there is no second surface.
# Its gate ordering is asserted by the shared scrub-gate check above.
grep -qF 'Rescan the finished page' "$PROMPT" \
  && fail "prompt-artifact grew a rendered-page rescan; add an ordering assertion for it"
:
# Republish key must not be date-derived in EITHER publishing reference, or
# tomorrow's run of the same branch/prompt misses today's URL and mints a second page.
grep -qE '\.claude/artifacts/[a-z-]*.*\$\(date' "$DIFF_PUB" \
  && fail "diff-publishing.md: inbox key is date-derived — breaks cross-day republish"
grep -qE '\.claude/artifacts/[a-z-]*.*\$\(date' "$PROMPT_PUB" \
  && fail "prompt-publishing.md: inbox key is date-derived — breaks cross-day republish"
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
    text = (root / rel).read_text(encoding="utf-8")
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

# 8. The PR-mode workflow guards its gh calls behind the preflight.
# `gh pr view` on a repo without gh or a GitHub remote spews shell errors into
# the transcript instead of falling back to session mode, so the guard is what
# makes the fallback a decision rather than an accident.
#
# The three recap commands used to carry this block each; it now lives once in
# references/recap-core.md, so the guard is asserted there and each command is
# asserted to load it. Checking the commands for `gh pr view` instead would
# pass a command that inlined a *different*, unguarded copy while the core sat
# unused -- hence both halves.
python3 - "$PLUGIN" <<'EOF' || fail "the PR-mode workflow calls gh without the preflight guard"
import pathlib, re, sys
root = pathlib.Path(sys.argv[1])
core_rel = "references/recap-core.md"
core = root / core_rel
assert core.is_file(), f"{core_rel} missing -- the shared recap workflow has no owner"
text = core.read_text(encoding="utf-8")

assert "gh pr view" in text, f"{core_rel}: no PR gathering, so PR mode has no source"

# Assert executable control flow, not text presence. Every name below appears
# in this file's prose as well as its code, so a whole-file substring search
# would pass on a paragraph that merely *describes* a guard that no longer
# runs. Extract the preflight block and assert against the shell inside it.
blocks = [m for m in re.finditer(r'```bash\n(.*?)```', text, re.S)]
preflight = next((m for m in blocks if "PR_MODE_UNAVAILABLE" in m.group(1)), None)
assert preflight, f"{core_rel}: no runnable preflight block, only prose about one"
code = "\n".join(
    ln for ln in preflight.group(1).splitlines() if not ln.strip().startswith("#")
)

# The condition is the guard: both probes must gate the same branch. Testing
# them separately would pass a block that checks auth and then runs gh anyway.
cond = re.search(r'if\s+(.*?)\bthen\b', code, re.S)
assert cond, f"{core_rel}: preflight is not a conditional, so it guards nothing"
cond = cond.group(1)
assert "gh auth status" in cond, f"{core_rel}: auth probe is not part of the preflight condition"
remote = [ln for ln in cond.splitlines() if "git remote get-url origin" in ln]
assert remote, f"{core_rel}: remote lookup is not part of the preflight condition"
# github.com specifically, on the same pipeline as the lookup. A bare "github"
# would also match `github` in a hostname like `github.example.com`, or a
# comment, while the guard no longer filters for the real domain.
assert re.search(r'github\\?\.com', remote[0]), (
    f"{core_rel}: preflight retrieves the origin but never filters it for github.com: {remote[0].strip()!r}"
)

# Both outcomes must be reachable, and failure must land on the fallback
# sentinel -- a guard whose else-branch is missing degrades into no guard.
assert re.search(r'echo\s+"PR_MODE_OK"', code), f"{core_rel}: preflight has no success signal"
assert re.search(r'else\s*\n\s*echo\s+"PR_MODE_UNAVAILABLE"', code), (
    f"{core_rel}: no else-branch reaching PR_MODE_UNAVAILABLE when the preflight fails"
)

# The whole guard must close before the first gh pr view, or it guards nothing.
assert preflight.end() <= text.index("gh pr view"), (
    f"{core_rel}: preflight appears after the first gh pr view"
)

# Each recap command must actually reach that guard. A command that neither
# loads the core nor gathers the PR itself has lost PR mode entirely.
found = 0
for name in ("eng-recap", "team-recap", "product-doc"):
    cmd = (root / "commands" / f"{name}.md").read_text(encoding="utf-8")
    assert core_rel in cmd, f"{name}.md: never loads {core_rel}, so it has no guarded PR mode"
    assert "gh pr view" not in cmd, (
        f"{name}.md: inlines its own gh gathering instead of delegating to {core_rel}"
    )
    found += 1
assert found == 3, f"expected 3 recap commands delegating to the core, found {found}"
EOF
ok

# 8b. The one gather block has to stay correct. This is the contract that
# already drifted once, back when each command carried its own copy: eng-recap
# was fixed and its two siblings were left fetching a head ref, silently
# dropping the commit bodies all three say should lead the recap. Extracting the
# block to references/recap-core.md is what makes that class of drift
# impossible; these assertions keep the surviving copy honest.
python3 - "$PLUGIN" <<'EOF' || fail "the PR gather block drifted from its contract"
import pathlib, re, sys
root = pathlib.Path(sys.argv[1])
core_rel = "references/recap-core.md"
text = (root / core_rel).read_text(encoding="utf-8")

# Assert on the gather block with comment lines stripped. The comments
# legitimately name `headRefName` and `git fetch` while explaining why they
# are NOT used -- a raw substring check cannot tell an explanation apart
# from an instruction, and would pass a file that does both.
block = re.search(r'```bash\n\s*(PR=<number-or-url>.*?)```', text, re.S)
assert block, f"{core_rel}: no PR gather block to check"
code = "\n".join(
    ln for ln in block.group(1).splitlines() if not ln.strip().startswith("#")
)
# Commit bodies through the API, never through a local ref. `headRefName` is
# only a branch name, so a fork PR / deleted branch / cross-repo URL has no
# such ref on this origin and the fetch takes the bodies down with it.
assert "--json commits" in code, f"{core_rel}: commit bodies not gathered from the API"
for banned, why in (
    ("git fetch", "fetches a head ref that need not exist on this origin"),
    ("git log", "reads commit bodies from a local ref instead of the API"),
    ("headRefName", "resolves commits through a branch name"),
):
    assert banned not in code, f"{core_rel}: {why} (`{banned}`)"
# Unresolved findings have no other source: `comments` is top-level issue
# comments and `reviews` carries only each review's own state and body.
assert "reviewThreads" in code and "isResolved" in code, (
    f"{core_rel}: no reviewThreads query, so 'unresolved review threads' has no source"
)
# Both connections are bounded, so the query must be able to say it was cut
# short -- otherwise a first page reads as the whole list.
assert "hasNextPage" in code, f"{core_rel}: reviewThreads query cannot report truncation"
assert re.search(r'truncated|more_comments', code), (
    f"{core_rel}: queries pageInfo but never surfaces truncation to the reader"
)
# Owner/repo must come from the PR, not the checkout: argument-less
# `gh repo view` is "view current repo", which pairs a foreign PR number
# with local owner/name on a cross-repository PR URL.
assert not re.search(r'\$\(\s*gh repo view', code), (
    f"{core_rel}: derives owner/repo from the local checkout instead of the PR"
)
# No command may keep a second copy -- that is how the drift started.
for name in ("eng-recap", "team-recap", "product-doc"):
    cmd = (root / "commands" / f"{name}.md").read_text(encoding="utf-8")
    assert not re.search(r'```bash\n\s*PR=<number-or-url>', cmd), (
        f"{name}.md: carries its own gather block again; it belongs in {core_rel}"
    )
EOF
ok

# 9. eng-recap is the only recap that reads diff hunks, so it is the only one
# that can exhaust context on a large PR. The cap is what makes that read safe,
# and a cap nobody reports is indistinguishable from a complete read.
#
# The core owns the mechanism and eng-recap opts in, so both halves are checked:
# a cap in a reference nobody opts into protects nothing, and an opt-in with no
# mechanism behind it is an unbounded read.
python3 - "$PLUGIN" <<'EOF' || fail "the diff read is uncapped, unreported, or unclaimed"
import pathlib, re, sys
root = pathlib.Path(sys.argv[1])
core_rel = "references/recap-core.md"
text = (root / core_rel).read_text(encoding="utf-8")

assert "gh pr diff" in text, f"{core_rel}: never reads the diff, so decision 4 was dropped"
# A numeric file budget, not just prose about being careful.
budget = re.search(r'at most \*\*(\d+) files\*\*', text)
assert budget, f"{core_rel}: reads diff hunks with no numeric file cap"
cap = int(budget.group(1))
# The cap is a cross-file contract: the reference, the README, and the awk that
# implements it must all name the same number. A range check would let the
# reference drift to 35 while the README still promises 20.
EXPECTED_CAP = 20
assert cap == EXPECTED_CAP, f"{core_rel}: diff cap is {cap}, README/CHANGELOG promise {EXPECTED_CAP}"
assert re.search(rf'n<={EXPECTED_CAP}\b', text), (
    f"{core_rel}: documents a {cap}-file cap but the awk that implements it uses a different bound"
)
readme = (root / "README.md").read_text(encoding="utf-8")
assert re.search(rf'\b{EXPECTED_CAP}[ -]file', readme), (
    f"README does not state the {EXPECTED_CAP}-file diff budget the workflow enforces"
)
# The cap needs a defined behaviour past the budget, or it is just a limit that
# silently drops files.
assert "--name-only" in text, f"{core_rel}: no name-only fallback past the cap"
# And the truncation has to reach the reader. A partial read presented as
# complete is the failure this whole check exists to prevent.
assert re.search(r'[Rr]eport how many files were summarized', text), (
    f"{core_rel}: never requires reporting how many files were summarized"
)

# Exactly one recap opts in. The budget section is opt-in precisely so the two
# summary-level recaps keep reading commit bodies instead of hunks; a silent
# second opt-in would double the context cost of the cheap commands.
opted = [
    name for name in ("eng-recap", "team-recap", "product-doc")
    if re.search(r'\*\*Opt in to the diff budget\*\*',
                 (root / "commands" / f"{name}.md").read_text(encoding="utf-8"))
]
assert opted == ["eng-recap"], (
    f"expected only eng-recap to opt in to the diff budget, got {opted}"
)
EOF
ok

echo "PASS: artifact-tools smoke test ($checks checks)"

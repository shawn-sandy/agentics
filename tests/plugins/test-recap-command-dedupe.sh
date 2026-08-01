#!/usr/bin/env bash
# Objective test for docs/plans/extract-recap-command-core.md.
#
# The three artifact-tools recap commands are three framings of one workflow.
# Before the extraction they shared 168 identical lines (eng-recap + team-recap)
# and 68 across all three -- so a fix to the scrub gate or the PR gather block
# landed in one command out of three. This test fails if that duplication comes
# back, and if any command stops owning its own republish key.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PLUGIN="$REPO_ROOT/kit/plugins/artifact-tools"
checks=0
fail() { echo "FAIL: $*" >&2; exit 1; }
ok() { checks=$((checks + 1)); }

# 1. The shared workflow has a home. Everything else here is only meaningful if
#    the commands have somewhere to delegate to.
CORE="$PLUGIN/references/recap-core.md"
[ -f "$CORE" ] || fail "references/recap-core.md missing -- the shared workflow has no owner"
ok

python3 - "$PLUGIN" <<'EOF' || exit 1
import pathlib, re, sys

plugin = pathlib.Path(sys.argv[1])
core_rel = "references/recap-core.md"
# name -> the republish key it, and only it, may assign.
OWNERS = {
    "eng-recap": "eng-artifact-url",
    "team-recap": "team-artifact-url",
    "product-doc": "product-artifact-url",
}
WORD_CAP = 500
SHARED_LINE_CAP = 50

texts = {n: (plugin / "commands" / f"{n}.md").read_text(encoding="utf-8") for n in OWNERS}


def fail(msg):
    print(f"FAIL: {msg}", file=sys.stderr)
    sys.exit(1)


# 2. Each command is framing, not workflow. The cap is what forces the
#    workflow to stay in the core file rather than creeping back in.
for name, text in texts.items():
    words = len(text.split())
    if words >= WORD_CAP:
        fail(f"{name}.md is {words} words, over the {WORD_CAP}-word framing cap")

# 3. Each command actually loads the core. A short command that delegates
#    nowhere has lost the workflow instead of extracting it.
for name, text in texts.items():
    if core_rel not in text:
        fail(f"{name}.md never points at {core_rel}, so its workflow went missing")

# 4. Pairwise duplication. Leading whitespace is stripped so an indented copy
#    of a sibling's block still counts as the duplicate it is, and blank lines
#    are dropped so whitespace cannot pad the count.
def lines(text):
    return {ln.strip() for ln in text.splitlines() if ln.strip()}


sets = {n: lines(t) for n, t in texts.items()}
names = sorted(sets)
for i, a in enumerate(names):
    for b in names[i + 1:]:
        shared = sets[a] & sets[b]
        if len(shared) >= SHARED_LINE_CAP:
            sample = "\n    ".join(sorted(shared)[:5])
            fail(
                f"{a}.md and {b}.md share {len(shared)} identical lines "
                f"(cap {SHARED_LINE_CAP}); the workflow belongs in {core_rel}. "
                f"First few:\n    {sample}"
            )

# 5. Republish-key ownership, per file. Checked per file rather than by
#    counting key names across files: every command *names* its siblings' keys
#    in a prohibition, so a repo-wide `grep -o ... | sort -u` returns every key
#    from every file and proves nothing about who writes what.
#
#    The lookbehind matters. `eng-artifact-url:` contains `artifact-url:` as a
#    substring, so a plain search for the session key matches all three
#    legitimate keys and the check passes for the wrong reason.
BARE = re.compile(r"(?<![-\w])artifact-url:")
KEY = re.compile(r"(?<![-\w])([a-z]+-artifact-url):")

for name, text in texts.items():
    own = OWNERS[name]
    # Lines that forbid a key are not assignments -- that is where a command
    # legitimately names keys belonging to someone else.
    assigning = [ln for ln in text.splitlines() if not re.search(r"[Nn]ever write", ln)]

    if not any(f"{own}:" in ln for ln in assigning):
        fail(f"{name}.md never declares the key it owns ({own}:)")

    for ln in assigning:
        for found in KEY.findall(ln):
            if found != own:
                fail(f"{name}.md assigns {found}:, which belongs to another command: {ln.strip()!r}")
        if BARE.search(ln):
            fail(
                f"{name}.md assigns the bare artifact-url: key outside a prohibition -- "
                f"that key is session-artifact's and this would republish over its recap: {ln.strip()!r}"
            )

    # The prohibition itself has to survive, naming the session key.
    if not any(
        re.search(r"[Nn]ever write", ln) and BARE.search(ln) for ln in text.splitlines()
    ):
        fail(f"{name}.md lost the 'Never write artifact-url:' prohibition")

# 6. The keys are distinct from each other, not merely present.
assigned = set(OWNERS.values())
if len(assigned) != len(OWNERS):
    fail(f"two commands claim the same republish key: {sorted(OWNERS.values())}")
EOF
ok  # 2. word caps
ok  # 3. core is loaded
ok  # 4. pairwise duplication
ok  # 5. per-file key ownership
ok  # 6. keys distinct

echo "PASS: recap commands stay deduplicated ($checks checks)"

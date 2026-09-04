#!/usr/bin/env bash
set -euo pipefail

# The backup target list lives in four places: the manifest's Default targets
# table, the skill's Step 3 list, the Copy the targets block, and the case
# list of the stray-entries detector. A coverage audit found the manifest and
# a hand-written daily script had already drifted apart, and the manifest's
# own exclusion notes were wrong (agents/ filed as task state, projects/ said
# memory lives with each project). This pins the four copies inside the plugin
# to each other and keeps the corrected notes corrected.

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
MANIFEST="$ROOT/kit/plugins/settings-sync/references/file-manifest.md"
SKILL="$ROOT/kit/plugins/settings-sync/skills/settings-backup/SKILL.md"
FAILURES=0

check() {  # $1 label, rest: a command that succeeds when the behaviour holds
  local label="$1"; shift
  if "$@" >/dev/null 2>&1; then
    echo "ok   $label"
  else
    echo "FAIL $label"
    FAILURES=$((FAILURES + 1))
  fi
}
present() { grep -q  -- "$1" <<<"$2"; }
word()    { grep -qw -- "$1" <<<"$2"; }
absent()  { ! grep -q -- "$1" <<<"$2"; }

# A "## Heading" section of a markdown file: its lines up to the next "## ".
section() {
  awk -v h="$2" 'f && /^## / {exit} index($0, h) == 1 {f=1; next} f' "$1"
}

DEFAULTS="$(section "$MANIFEST" '## Default targets')"
EXCLUDED="$(section "$MANIFEST" '## Excluded')"
STEP3="$(awk '/^### Step 3/ {f=1; next} /^### Step 4/ {exit} f' "$SKILL")"
COPY="$(awk 'index($0, "**Copy the targets.**") == 1 {f=1} f && /^```bash/ {c=1; next} c && /^```/ {exit} c {print}' "$SKILL")"
CASE="$(awk 'index($0, "**Entries that are not targets.**") == 1 {f=1} f && /^ *case / {print; exit}' "$SKILL")"

for d in agents output-styles scripts reference; do
  check "default target row: $d/" present "^| \`~/.claude/$d/\` |" "$DEFAULTS"
done

check "exclusion note: agents/ is not listed as excluded"          absent 'agents/' "$EXCLUDED"
check "exclusion note: projects/ no longer says memory lives with each project" absent 'lives with each project' "$EXCLUDED"

for d in agents output-styles scripts reference; do
  check "Step 3 list: $d/"        present "^- \`~/.claude/$d/\`" "$STEP3"
  check "copy block: $d"          word "$d" "$COPY"
  check "stray-entries case: $d"  present " $d " "$CASE"
done

echo
if [ "$FAILURES" -ne 0 ]; then
  echo "FAIL ($FAILURES)"
  exit 1
fi
echo "PASS"

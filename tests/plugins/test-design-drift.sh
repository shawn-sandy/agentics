#!/usr/bin/env bash
# Unit + integration tests for the design drift hook.
#
# Unit    — check-design-drift.py's coverage comparison and every bail-out
#           path. EVERY case must exit 0: the hook reports, it never blocks,
#           and dispatch.py would propagate a 2 as actionable feedback.
# Integration — dispatch.py fan-out: an artboard write runs both
#           build-designs-index.sh and check-design-drift.py; an unrelated path
#           spawns neither.
#
# Drift here means ARTBOARDS AGAINST PLAN STEPS. It deliberately does not
# compare local artboards against the published canvas: people editing the
# canvas in the GUI is the feature working, and a check that fires on that is
# noise.
#
# Run: bash tests/plugins/test-design-drift.sh

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
HOOKS="$ROOT/kit/plugins/plan-agent/hooks"
DRIFT="$HOOKS/check-design-drift.py"
DISPATCH="$HOOKS/dispatch.py"
FIXTURE="$ROOT/tests/fixtures/plan-agent/sample-design"

pass=0
fail=0
ok()  { pass=$((pass + 1)); echo "  PASS $1"; }
bad() { fail=$((fail + 1)); echo "  FAIL $1"; echo "       $2"; }

if [ ! -f "$DRIFT" ]; then
  echo "FATAL: check-design-drift.py not found at $DRIFT"
  exit 1
fi

# `cd -P`: on macOS $TMPDIR is a symlink into /private, and the hook's relpath
# output would otherwise not match.
PROJ="$(mktemp -d)"
PROJ="$(cd -P "$PROJ" && pwd)"
trap 'rm -rf "$PROJ"' EXIT

CANVAS="$PROJ/docs/designs/track-gym-workouts"
PLAN="$PROJ/docs/plans/track-gym-workouts.md"

# reset <plan-fixture> — rebuild the project tree from the committed fixture.
reset() {
  rm -rf "$PROJ/docs"
  mkdir -p "$CANVAS" "$PROJ/docs/plans"
  cp "$FIXTURE/$1" "$PLAN"
  cp "$FIXTURE"/artboards/*.dc.html "$CANVAS/"
}

# run_drift <written-path> → sets DRIFT_OUT / DRIFT_CODE
run_drift() {
  DRIFT_OUT="$(printf '{"tool_input":{"file_path":"%s"}}' "$1" \
    | CLAUDE_PROJECT_DIR="$PROJ" python3 "$DRIFT" 2>&1)"
  DRIFT_CODE=$?
}

# expect <name> <expected-warning-count> [substring-that-must-appear]
expect() {
  local name="$1" want="$2" needle="${3:-}" got
  got="$(printf '%s' "$DRIFT_OUT" | grep -c 'design drift' || true)"
  if [ "$DRIFT_CODE" -ne 0 ]; then
    bad "$name" "exited $DRIFT_CODE — the hook must always exit 0"; return
  fi
  if [ "$got" -ne "$want" ]; then
    bad "$name" "expected $want warning(s), got $got: $DRIFT_OUT"; return
  fi
  if [ -n "$needle" ] && [ "${DRIFT_OUT#*"$needle"}" = "$DRIFT_OUT" ]; then
    bad "$name" "output does not mention '$needle': $DRIFT_OUT"; return
  fi
  ok "$name"
}

# refute <name> <substring-that-must-NOT-appear>
refute() {
  local name="$1" needle="$2"
  if [ "${DRIFT_OUT#*"$needle"}" = "$DRIFT_OUT" ]; then
    ok "$name"
  else
    bad "$name" "output should not mention '$needle': $DRIFT_OUT"
  fi
}

echo "Unit — check-design-drift.py"

# 1. Every user-facing step is covered by an artboard. The housekeeping step
#    (a version bump) is covered by nothing BY DESIGN and must not be reported —
#    the derivation rule and the drift check apply the same user-facing filter,
#    or every housekeeping step reads as permanent drift.
reset matched-plan.md
run_drift "$CANVAS/add-the-workout-log-form-with.dc.html"
expect "a matched artboard/step pair is silent" 0
refute "the housekeeping step is never reported as uncovered" "marketplace"

# 2. The spec gained a fourth user-facing step with no artboard.
reset diverged-plan.md
run_drift "$CANVAS/add-the-workout-log-form-with.dc.html"
expect "an uncovered user-facing step is named" 1 "settings dialog"
refute "the diverged report still ignores the housekeeping step" "marketplace"

# 2b. The warning names the plan and the canvas directory, so it is actionable.
if [ "${DRIFT_OUT#*track-gym-workouts.md}" != "$DRIFT_OUT" ]; then
  ok "the warning names the plan spec"
else
  bad "the warning names the plan spec" "$DRIFT_OUT"
fi
if [ "${DRIFT_OUT#*docs/designs/track-gym-workouts}" != "$DRIFT_OUT" ]; then
  ok "the warning names the canvas directory"
else
  bad "the warning names the canvas directory" "$DRIFT_OUT"
fi

# 3. Editing the canvas in the GUI is the feature working, not drift. A
#    hand-edited artboard body, and an EXTRA artboard nobody planned, are both
#    silent: this hook only reports steps with no artboard, never the reverse.
reset matched-plan.md
echo '<p>moved an element</p>' >> "$CANVAS/add-the-workout-log-form-with.dc.html"
cp "$CANVAS/add-the-workout-log-form-with.dc.html" "$CANVAS/an-extra-artboard-someone-drew.dc.html"
run_drift "$CANVAS/add-the-workout-log-form-with.dc.html"
expect "a GUI edit and an unplanned extra artboard stay silent" 0

# 4. Bail-outs — every one exits 0 and says nothing.
reset diverged-plan.md
rm -f "$PLAN"
run_drift "$CANVAS/add-the-workout-log-form-with.dc.html"
expect "a canvas directory no plan claims is silent" 0

reset diverged-plan.md
python3 - "$PLAN" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read().replace('design-dir: docs/designs/track-gym-workouts\n', '')
open(p, 'w').write(s)
PY
run_drift "$CANVAS/add-the-workout-log-form-with.dc.html"
expect "a plan carrying no design-dir is silent" 0

reset diverged-plan.md
python3 - "$PLAN" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read()
open(p, 'w').write(s[: s.index('## Steps')])
PY
run_drift "$CANVAS/add-the-workout-log-form-with.dc.html"
expect "a plan with no Steps section is silent" 0

reset diverged-plan.md
run_drift "$PROJ/docs/designs/index.html"
expect "the generated gallery index is skipped" 0

reset diverged-plan.md
run_drift "$PROJ/src/unrelated.ts"
expect "a path outside docs/designs is silent" 0

# 4b. A design-dir escaping the tree must not be followed — the same trap
#     check-prototype-drift.py had to close for proto-source.
reset diverged-plan.md
python3 - "$PLAN" <<'PY'
import sys
p = sys.argv[1]
s = open(p).read().replace(
    'design-dir: docs/designs/track-gym-workouts',
    'design-dir: ../../../etc',
)
open(p, 'w').write(s)
PY
run_drift "$CANVAS/add-the-workout-log-form-with.dc.html"
expect "an out-of-tree design-dir is silent" 0

# 5. CLAUDE_PROJECT_DIR reached through a SYMLINK. relpath is string
#    arithmetic, so resolving one side and not the other turned the canvas
#    directory in the warning into a ../../../.. chain — correct and useless.
reset diverged-plan.md
LINKED="$(dirname "$PROJ")/linked-$(basename "$PROJ")"
ln -sfn "$PROJ" "$LINKED"
DRIFT_OUT="$(printf '{"tool_input":{"file_path":"%s"}}' \
  "$LINKED/docs/designs/track-gym-workouts/add-the-workout-log-form-with.dc.html" \
  | CLAUDE_PROJECT_DIR="$LINKED" python3 "$DRIFT" 2>&1)"
DRIFT_CODE=$?
expect "a symlinked project dir still reports drift" 1 "settings dialog"
# Exact, not "contains the slug": the bug produced
# `../tmp.XXXX/docs/designs/track-gym-workouts`, which contains the slug and is
# still unreadable. Anchor on the message's own `in <dir> —` framing so any
# escape prefix at all fails the assertion.
if [ "${DRIFT_OUT#*in docs/designs/track-gym-workouts —}" != "$DRIFT_OUT" ]; then
  ok "the symlinked warning names the canvas directory with no escape prefix"
else
  bad "the symlinked warning names the canvas directory with no escape prefix" "$DRIFT_OUT"
fi
rm -f "$LINKED"

echo
echo "Integration — dispatch.py fan-out"

# Stub every child so the test observes WHICH ran, not what they did.
STUB="$PROJ/hooks"
mkdir -p "$STUB"
for f in validate-plan-filename.py rebuild-plans-index.py render-plan-html.py \
         check-prototype-drift.py check-design-drift.py; do
  printf '#!/usr/bin/env python3\nimport sys, os\nopen(os.environ["DISPATCH_LOG"], "a").write("%s\\n")\nsys.exit(0)\n' "$f" \
    > "$STUB/$f"
done
for f in build-prototypes-index.sh build-designs-index.sh; do
  printf '#!/usr/bin/env bash\necho %s >> "$DISPATCH_LOG"\n' "$f" > "$STUB/$f"
done
cp "$DISPATCH" "$STUB/dispatch.py"
chmod +x "$STUB"/*

dispatch_children() {
  local log="$PROJ/dispatch.log"
  : > "$log"
  printf '{"tool_input":{"file_path":"%s"}}' "$1" \
    | DISPATCH_LOG="$log" CLAUDE_PROJECT_DIR="$PROJ" python3 "$STUB/dispatch.py" >/dev/null 2>&1
  sort "$log" 2>/dev/null | tr '\n' ' '
}

mkdir -p "$CANVAS"
got="$(dispatch_children "$CANVAS/add-the-workout-log-form-with.dc.html")"
case "$got" in
  *check-design-drift.py*build-designs-index.sh*|*build-designs-index.sh*check-design-drift.py*)
    ok "an artboard write runs both the index rebuild and the drift check" ;;
  *) bad "an artboard write runs both the index rebuild and the drift check" "ran: $got" ;;
esac
case "$got" in
  *prototype*) bad "an artboard write leaves the prototype children alone" "ran: $got" ;;
  *) ok "an artboard write leaves the prototype children alone" ;;
esac

got="$(dispatch_children "$PROJ/src/unrelated.ts")"
if [ -z "${got// /}" ]; then
  ok "an unrelated path spawns neither child"
else
  bad "an unrelated path spawns neither child" "ran: $got"
fi

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ] || exit 1

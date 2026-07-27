#!/usr/bin/env bash
# Unit + integration tests for the prototype drift hook.
#
# Unit    — check-prototype-drift.py's comparison branches, including every
#           bail-out path. EVERY case must exit 0: the hook reports, it never
#           blocks, and dispatch.py would propagate a 2 as actionable feedback.
# Integration — dispatch.py fan-out: a prototype write runs both
#           build-prototypes-index.sh and check-prototype-drift.py; an
#           unrelated path spawns neither.
#
# Run: bash tests/plugins/test-prototype-drift.sh

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
HOOKS="$ROOT/kit/plugins/plan-agent/hooks"
DRIFT="$HOOKS/check-prototype-drift.py"
DISPATCH="$HOOKS/dispatch.py"

pass=0
fail=0

ok()   { pass=$((pass + 1)); echo "  PASS $1"; }
bad()  { fail=$((fail + 1)); echo "  FAIL $1"; echo "       $2"; }

# A throwaway project tree. `cd -P`: on macOS $TMPDIR is a symlink into
# /private, and the hook's relpath output would otherwise not match.
PROJ="$(mktemp -d)"
PROJ="$(cd -P "$PROJ" && pwd)"
trap 'rm -rf "$PROJ"' EXIT
mkdir -p "$PROJ/docs/plans" "$PROJ/docs/prototypes"

MODEL_2='{"entity":"Workout","fields":[{"name":"date","type":"date"},{"name":"exercise","type":"string"}],"action":"Log","successSignal":"total count"}'
MODEL_RENAMED='{"entity":"Workout","fields":[{"name":"day","type":"date"},{"name":"exercise","type":"string"}],"action":"Log","successSignal":"total count"}'

# write_proto <file> <proto-source> <model-json> [dom-field-1 dom-field-2 ...]
write_proto() {
  local file="$1" source="$2" model="$3"
  shift 3
  # Mirrors the skeleton's authoring comment, which ships a literal
  # data-field="key" into every generated prototype and must not be read as a field.
  local cols='      <!-- {{COLUMNS}}: one <th scope="col" data-field="key" data-type="string">Label</th> -->'$'\n'
  local inputs=""
  for f in "$@"; do
    cols+="      <th scope=\"col\" data-field=\"$f\" data-type=\"string\">$f</th>"$'\n'
    inputs+="  <input name=\"$f\" id=\"$f\">"$'\n'
  done
  cat > "$file" <<HTML
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="proto-source" content="$source">
<meta name="proto-created" content="2026-07-25">
<title>Track gym workouts</title>
</head>
<body>
<script type="application/json" id="seed">[]</script>
<script type="application/json" id="proto-model">$model</script>
<form id="add-form">
$inputs</form>
<table id="grid"><thead><tr>
$cols      <th scope="col">Actions</th>
</tr></thead><tbody id="rows"></tbody></table>
</body>
</html>
HTML
}

# write_plan <file> [proto-model-json]
write_plan() {
  local file="$1" model="${2:-}"
  {
    echo '---'
    echo 'status: todo'
    echo 'type: feature'
    echo 'created: 2026-07-25'
    echo 'prototype: docs/prototypes/track-gym-workouts.html'
    [[ -n "$model" ]] && echo "proto-model: $model"
    echo '---'
    echo
    echo '# Plan: Track gym workouts'
  } > "$file"
}

# run_drift <prototype-path> → sets DRIFT_OUT / DRIFT_CODE
run_drift() {
  DRIFT_OUT="$(printf '{"tool_input":{"file_path":"%s"}}' "$1" \
    | CLAUDE_PROJECT_DIR="$PROJ" python3 "$DRIFT" 2>&1)"
  DRIFT_CODE=$?
}

# expect <name> <expected-warning-count> <substring-that-must-appear-or-empty>
expect() {
  local name="$1" want="$2" needle="${3:-}"
  local got
  got="$(printf '%s' "$DRIFT_OUT" | grep -c 'prototype drift' || true)"
  if [[ "$DRIFT_CODE" -ne 0 ]]; then
    bad "$name" "exited $DRIFT_CODE — the hook must always exit 0"
    return
  fi
  if [[ "$got" -ne "$want" ]]; then
    bad "$name" "expected $want warning(s), got $got: $DRIFT_OUT"
    return
  fi
  if [[ -n "$needle" && "$DRIFT_OUT" != *"$needle"* ]]; then
    bad "$name" "output does not mention '$needle': $DRIFT_OUT"
    return
  fi
  ok "$name"
}

PROTO="$PROJ/docs/prototypes/track-gym-workouts.html"
PLAN="$PROJ/docs/plans/track-gym-workouts.md"

echo "Unit — check-prototype-drift.py"

# 1. Model matches both the DOM and the plan.
write_proto "$PROTO" 'docs/plans/track-gym-workouts.md' "$MODEL_2" date exercise
write_plan "$PLAN" "$MODEL_2"
run_drift "$PROTO"
expect "matched model, DOM, and plan is silent" 0

# 2. Model diverges from its own <th> headers AND from the plan (both fire).
write_proto "$PROTO" 'docs/plans/track-gym-workouts.md' "$MODEL_RENAMED" date exercise
run_drift "$PROTO"
expect "model diverging from DOM and plan reports both" 2 "day"
[[ "$DRIFT_OUT" == *"docs/plans/track-gym-workouts.md"* ]] \
  && ok "plan-mismatch warning names the plan file" \
  || bad "plan-mismatch warning names the plan file" "$DRIFT_OUT"
[[ "$DRIFT_OUT" == *"track-gym-workouts.html"* ]] \
  && ok "warnings name the prototype file" \
  || bad "warnings name the prototype file" "$DRIFT_OUT"

# 2b. Only the FORM control was renamed; the <th> headers still match the model.
# The merged-list version of _dom_fields missed this entirely: the untouched
# headers supplied every model field, so the union matched and nothing fired.
write_proto "$PROTO" 'docs/plans/track-gym-workouts.md' "$MODEL_2" date exercise
python3 - "$PROTO" <<'PY'
import re, sys
p = sys.argv[1]
s = open(p).read()
i, j = s.index('<form'), s.index('</form>')
open(p, 'w').write(s[:i] + s[i:j].replace('"exercise"', '"movement"') + s[j:])
PY
run_drift "$PROTO"
expect "a form-only rename is detected" 1 "form fields"

# 2c. Only the <th> headers were renamed; the form controls still match.
write_proto "$PROTO" 'docs/plans/track-gym-workouts.md' "$MODEL_2" date exercise
python3 - "$PROTO" <<'PY'
import re, sys
p = sys.argv[1]
s = open(p).read()
i = s.index('<table')
open(p, 'w').write(s[:i] + s[i:].replace('"exercise"', '"movement"'))
PY
run_drift "$PROTO"
expect "a header-only rename is detected" 1 "table headers"

# 2d. Pure reorder — same field names on both sides, different order. Passes
# every membership check, so it needs its own sequence comparison.
write_proto "$PROTO" 'docs/plans/track-gym-workouts.md' "$MODEL_2" exercise date
write_plan "$PLAN" "$MODEL_2"
run_drift "$PROTO"
expect "a reordered column is detected" 1 "reordered"

# 3. Model diverges from the plan only — DOM was hand-edited to match.
write_proto "$PROTO" 'docs/plans/track-gym-workouts.md' "$MODEL_RENAMED" day exercise
run_drift "$PROTO"
expect "model diverging from the plan alone reports once" 1 "day"

# 4. Plan exists but carries no proto-model yet.
write_proto "$PROTO" 'docs/plans/track-gym-workouts.md' "$MODEL_2" date exercise
write_plan "$PLAN"
run_drift "$PROTO"
expect "plan without proto-model is silent" 0

# 5. proto-source names a plan that does not exist.
write_plan "$PLAN" "$MODEL_2"
write_proto "$PROTO" 'docs/plans/no-such-plan.md' "$MODEL_2" date exercise
run_drift "$PROTO"
expect "missing plan is silent" 0

# 6. proto-source resolving outside the plans directory.
write_proto "$PROTO" '../../../etc/track-gym-workouts.md' "$MODEL_2" date exercise
run_drift "$PROTO"
expect "out-of-tree proto-source is silent" 0

# 6b. proto-source names a SYMLINK that sits inside the plans directory but
# resolves out of tree. abspath is string arithmetic and passed this; open()
# follows links, so the guard has to resolve both sides.
outside="$PROJ/outside-the-tree.md"
write_plan "$outside" "$MODEL_RENAMED"
ln -sf "$outside" "$PROJ/docs/plans/linked-plan.md"
write_proto "$PROTO" 'docs/plans/linked-plan.md' "$MODEL_2" date exercise
run_drift "$PROTO"
expect "a symlink escaping the plans directory is not followed" 0

# 6c. A real file inside the plans directory still resolves after that change.
write_plan "$PLAN" "$MODEL_RENAMED"
write_proto "$PROTO" 'docs/plans/track-gym-workouts.md' "$MODEL_2" date exercise
run_drift "$PROTO"
expect "a genuine in-tree plan is still compared" 1 "track-gym-workouts.md"

# 7. Prototype has no #proto-model block at all (pre-4.4.0 prototype).
write_proto "$PROTO" 'docs/plans/track-gym-workouts.md' "$MODEL_2" date exercise
python3 - "$PROTO" <<'PY'
import re, sys
p = sys.argv[1]
s = open(p).read()
open(p, 'w').write(re.sub(r'<script[^>]*id="proto-model"[^>]*>.*?</script>\n?', '', s, flags=re.S))
PY
run_drift "$PROTO"
expect "prototype without a proto-model block is silent" 0

# 8. Malformed JSON in the prototype's model block.
write_proto "$PROTO" 'docs/plans/track-gym-workouts.md' '{"entity":"Workout",' date exercise
run_drift "$PROTO"
expect "malformed prototype JSON is silent" 0

# 9. Malformed JSON in the plan's frontmatter.
write_proto "$PROTO" 'docs/plans/track-gym-workouts.md' "$MODEL_2" date exercise
write_plan "$PLAN" '{"entity":"Workout",'
run_drift "$PROTO"
expect "malformed plan JSON is silent" 0

# 10. Not a prototype path at all.
write_plan "$PLAN" "$MODEL_2"
run_drift "$PLAN"
expect "a non-prototype path is silent" 0

echo
echo "Integration — dispatch.py fan-out"

# Stub both children so the test observes WHICH ran, not what they did.
STUB_HOOKS="$PROJ/hooks"
mkdir -p "$STUB_HOOKS"
for f in validate-plan-filename.py rebuild-plans-index.py render-plan-html.py check-prototype-drift.py; do
  printf '#!/usr/bin/env python3\nimport sys, os\nopen(os.environ["DISPATCH_LOG"], "a").write("%s\\n")\nsys.exit(0)\n' "$f" \
    > "$STUB_HOOKS/$f"
done
printf '#!/usr/bin/env bash\necho build-prototypes-index.sh >> "$DISPATCH_LOG"\n' \
  > "$STUB_HOOKS/build-prototypes-index.sh"
cp "$DISPATCH" "$STUB_HOOKS/dispatch.py"
chmod +x "$STUB_HOOKS"/*

# dispatch_children <file_path> → newline-joined names of the children that ran
dispatch_children() {
  local log="$PROJ/dispatch.log"
  : > "$log"
  printf '{"tool_input":{"file_path":"%s"}}' "$1" \
    | DISPATCH_LOG="$log" CLAUDE_PROJECT_DIR="$PROJ" python3 "$STUB_HOOKS/dispatch.py" >/dev/null 2>&1
  sort "$log" | tr '\n' ' '
}

got="$(dispatch_children "$PROTO")"
[[ "$got" == *"check-prototype-drift.py"* && "$got" == *"build-prototypes-index.sh"* ]] \
  && ok "a prototype write runs both the index rebuild and the drift check" \
  || bad "a prototype write runs both the index rebuild and the drift check" "ran: $got"

got="$(dispatch_children "$PROJ/src/unrelated.ts")"
[[ -z "${got// /}" ]] \
  && ok "an unrelated path spawns neither child" \
  || bad "an unrelated path spawns neither child" "ran: $got"

echo
echo "$pass passed, $fail failed"
[[ "$fail" -eq 0 ]] || exit 1

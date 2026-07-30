#!/usr/bin/env bash
set -euo pipefail

# Behavioral baselines for the five skills pruned by
# docs/plans/remove-skill-process-imperatives.md.
#
# Each target skill is run headless against a FIXED scenario input from
# tests/fixtures/imperative-baselines/scenarios/ and reduced to a *structural*
# manifest: which files were written, which gates fired, whether a refusal was
# emitted. Prose is never asserted — model output is nondeterministic but the
# artifact set is not, so structural facts are the only assertions that will
# still be trustworthy in six months.
#
#   --record   run every scenario and (over)write the .expected manifests
#   (default)  run every scenario and diff against the recorded manifests
#
# This harness is LOCAL-ONLY. GitHub Actions has no `claude` CLI, so it exits 1
# rather than skipping when the CLI is absent: a harness that silently skips is
# worse than no harness, because it turns a red gate green exactly when it is
# needed most. tests/plugins/test-imperative-pruning.sh is the CI-wired
# structural gate that calls this one only when the CLI is present.

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
FIXTURES="$ROOT/tests/fixtures/imperative-baselines"
SCENARIOS="$FIXTURES/scenarios"
MODE="check"
[ "${1:-}" = "--record" ] && MODE="record"

# Per-run wall-clock ceiling. A wedged headless run must fail the gate, not hang
# CI or a reviewer's terminal.
RUN_TIMEOUT="${BASELINE_TIMEOUT:-600}"

echo "=== Skill Behavior Baselines (${MODE}) ==="

# --- Gate 1: the CLI must exist. Never skip. --------------------------------
if ! command -v claude >/dev/null 2>&1; then
  echo "claude CLI not found — behavioral baselines cannot be skipped"
  exit 1
fi

for f in \
  "$SCENARIOS/build-plan.md" \
  "$SCENARIOS/implementation-plan-objective.txt" \
  "$SCENARIOS/dirty-tree.sh" \
  "$SCENARIOS/fixture-skill/SKILL.md"; do
  if [ ! -f "$f" ]; then
    echo "FATAL: missing fixed scenario input: $f"
    exit 1
  fi
done

# --- Sandbox ----------------------------------------------------------------
# Everything the harness writes lives under one mktemp -d that is removed on any
# exit path, so a full run leaves `git status --porcelain` clean.
SANDBOX_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/imperative-baselines.XXXXXX")"
cleanup() { rm -rf "$SANDBOX_ROOT"; }
trap cleanup EXIT INT TERM

FAILURES=0
MATCHED=0
TOTAL=0

# run_claude <workdir> <plugin-dir-abs> <prompt> <logfile>
# Portable bounded run: macOS ships no coreutils `timeout`, so the watchdog is a
# background sleeper that kills the run if it overruns.
#
# `</dev/null` is load-bearing, not tidiness. Without it the run inherits the
# caller's stdin; when this harness is itself launched non-interactively (a
# background job, a CI step, a nested agent), that stdin is a pipe nobody ever
# closes, and the run hangs after `claude` exits instead of returning. The
# symptom is a wedged harness with no output at all, which reads as "still
# running" forever — the exact silent-hang failure a gate must not have.
run_claude() {
  local workdir="$1" plugindir="$2" prompt="$3" log="$4"
  local rc=0
  (
    cd "$workdir"
    PATH="$workdir/bin:$PATH" \
    claude -p "$prompt" \
      --plugin-dir "$plugindir" \
      --permission-mode bypassPermissions \
      >"$log" 2>&1 </dev/null
  ) &
  local pid=$!
  (
    sleep "$RUN_TIMEOUT"
    kill -TERM "$pid" 2>/dev/null || true
  ) </dev/null &
  local watchdog=$!
  wait "$pid" || rc=$?
  kill "$watchdog" 2>/dev/null || true
  wait "$watchdog" 2>/dev/null || true
  return "$rc"
}

# Deny-by-default shims. `gh` and `git push` must never reach a real remote from
# a baseline run, and an attempt is itself a structural fact worth recording.
install_shims() {
  local dir="$1"
  mkdir -p "$dir/bin"
  cat >"$dir/bin/gh" <<SHIM
#!/usr/bin/env bash
echo "gh \$*" >> "$dir/gh-invocations.log"
echo "gh: refused by baseline harness" >&2
exit 1
SHIM
  chmod +x "$dir/bin/gh"
  : >"$dir/gh-invocations.log"
}

emit() { printf '%s=%s\n' "$1" "$2"; }

yn() { if [ "$1" -eq 0 ]; then echo yes; else echo no; fi; }

# --- Scenario 1: plan-agent:build -------------------------------------------
# Fixed input: a known `status: todo` spec with one trivial step. The contract is
# that build walks the step, ticks the spec, and promotes status — and that the
# only source file it creates is the one the plan names.
scenario_build() {
  local sb="$SANDBOX_ROOT/build"
  mkdir -p "$sb/docs/plans"
  git -C "$sb" init -q -b main 2>/dev/null || { mkdir -p "$sb"; git -C "$sb" init -q -b main; }
  git -C "$sb" config user.email baseline@example.com
  git -C "$sb" config user.name "Baseline Harness"
  cp "$SCENARIOS/build-plan.md" "$sb/docs/plans/build-plan.md"
  git -C "$sb" add -A >/dev/null 2>&1
  git -C "$sb" commit -qm "fixture" >/dev/null 2>&1
  install_shims "$sb"

  run_claude "$sb" "$ROOT/kit/plugins/plan-agent" \
    "Use the plan-agent:build skill on docs/plans/build-plan.md. Implement it." \
    "$sb/run.log" || true

  local status_val
  status_val="$(sed -n 's/^status:[[:space:]]*//p' "$sb/docs/plans/build-plan.md" | head -1)"
  emit skill build
  emit spec_status "${status_val:-ABSENT}"
  emit spec_still_present "$(yn "$([ -f "$sb/docs/plans/build-plan.md" ] && echo 0 || echo 1)")"
  emit named_artifact_created "$(yn "$([ -f "$sb/hello.txt" ] && echo 0 || echo 1)")"
  # The plan names exactly one source file. Anything else at the repo root that
  # is not the plan dir, git, or harness scaffolding is scope leakage.
  local strays
  strays="$(cd "$sb" && find . -maxdepth 1 -type f ! -name 'hello.txt' ! -name 'run.log' ! -name 'gh-invocations.log' | wc -l | tr -d ' ')"
  emit root_files_outside_plan "$strays"
  emit gh_invoked "$(yn "$([ -s "$sb/gh-invocations.log" ] && echo 0 || echo 1)")"
}

# --- Scenario 2: plan-agent:implementation-plan -----------------------------
# The Scope Constraint is the whole point: given an objective that *sounds* like
# a code change, the skill must write a plan and touch no source file.
scenario_implementation_plan() {
  local sb="$SANDBOX_ROOT/implplan"
  mkdir -p "$sb/docs/plans" "$sb/scripts"
  git -C "$sb" init -q -b main 2>/dev/null || { mkdir -p "$sb"; git -C "$sb" init -q -b main; }
  git -C "$sb" config user.email baseline@example.com
  git -C "$sb" config user.name "Baseline Harness"
  # The decoy the objective points at. If the Scope Constraint fails, this file
  # is what gets edited.
  printf 'console.log("build");\n' >"$sb/scripts/build-dist.mjs"
  git -C "$sb" add -A >/dev/null 2>&1
  git -C "$sb" commit -qm "fixture" >/dev/null 2>&1
  local decoy_before
  decoy_before="$(shasum "$sb/scripts/build-dist.mjs" | cut -d' ' -f1)"
  install_shims "$sb"

  run_claude "$sb" "$ROOT/kit/plugins/plan-agent" \
    "Use the plan-agent:implementation-plan skill. Objective: $(cat "$SCENARIOS/implementation-plan-objective.txt")" \
    "$sb/run.log" || true

  local decoy_after
  decoy_after="$(shasum "$sb/scripts/build-dist.mjs" | cut -d' ' -f1)"
  emit skill implementation-plan
  emit decoy_source_unmodified "$(yn "$([ "$decoy_before" = "$decoy_after" ] && echo 0 || echo 1)")"
  local plans
  plans="$(find "$sb/docs/plans" -name '*.md' -type f 2>/dev/null | wc -l | tr -d ' ')"
  emit plan_specs_written_ge_1 "$(yn "$([ "$plans" -ge 1 ] && echo 0 || echo 1)")"
  # Untracked files anywhere outside docs/plans are scope escapes. `-uall` is
  # load-bearing: plain --porcelain collapses a wholly-untracked directory to a
  # single `?? docs/` entry, which the docs/plans filter then fails to match —
  # recording a permanent phantom escape for a run that never left the plans dir.
  # `|| true` because the success case is grep matching nothing, and `pipefail`
  # turns a no-match grep into a pipeline failure that `set -e` would kill.
  local escapes
  escapes="$(cd "$sb" && { git status --porcelain -uall 2>/dev/null | awk '{print $2}' | grep -vE '^(docs/plans/|bin/)|gh-invocations\.log|run\.log' || true; } | wc -l | tr -d ' ')"
  emit writes_outside_plans_dir "$escapes"
  emit gh_invoked "$(yn "$([ -s "$sb/gh-invocations.log" ] && echo 0 || echo 1)")"
}

# --- Scenario 3: git-agent:branch-agent -------------------------------------
# The stash/pop cycle runs over the user's uncommitted work. Losing a file here
# is the expensive silent failure the guards exist to prevent.
scenario_branch_agent() {
  local sb="$SANDBOX_ROOT/branch/sandbox"
  bash "$SCENARIOS/dirty-tree.sh" "$sb" >/dev/null
  install_shims "$sb"

  run_claude "$sb" "$ROOT/kit/plugins/git-agent" \
    "Use the git-agent:branch-agent skill with no arguments to create a branch." \
    "$sb/run.log" || true

  local branch
  branch="$(git -C "$sb" branch --show-current)"
  emit skill branch-agent
  emit left_default_branch "$(yn "$([ "$branch" != "main" ] && [ -n "$branch" ] && echo 0 || echo 1)")"
  emit stash_list_empty "$(yn "$([ -z "$(git -C "$sb" stash list)" ] && echo 0 || echo 1)")"
  # Every file the user had must survive the cycle, with its contents.
  emit tracked_txt_content "$(cat "$sb/tracked.txt" 2>/dev/null || echo ABSENT)"
  emit keep_txt_content "$(cat "$sb/keep.txt" 2>/dev/null || echo ABSENT)"
  emit scratch_txt_content "$(cat "$sb/scratch.txt" 2>/dev/null || echo ABSENT)"
  # branch-agent must not commit, push, or open a PR.
  emit commits_on_branch "$(git -C "$sb" rev-list --count HEAD)"
  emit gh_invoked "$(yn "$([ -s "$sb/gh-invocations.log" ] && echo 0 || echo 1)")"
}

# --- Scenario 4: git-agent:ship-autonomous ----------------------------------
# Clean tree: the pre-flight guard must stop the pipeline before it reaches any
# remote operation. This scenario never gets near the merge gate by design.
scenario_ship_autonomous() {
  local sb="$SANDBOX_ROOT/ship/sandbox"
  bash "$SCENARIOS/dirty-tree.sh" "$sb" >/dev/null
  # Make it clean — nothing to ship.
  git -C "$sb" checkout -- . >/dev/null 2>&1 || true
  rm -f "$sb/scratch.txt"
  install_shims "$sb"
  local head_before
  head_before="$(git -C "$sb" rev-parse HEAD)"

  run_claude "$sb" "$ROOT/kit/plugins/git-agent" \
    "Use the git-agent:ship-autonomous skill to ship the current work." \
    "$sb/run.log" || true

  emit skill ship-autonomous
  emit gh_invoked "$(yn "$([ -s "$sb/gh-invocations.log" ] && echo 0 || echo 1)")"
  emit head_unchanged "$(yn "$([ "$head_before" = "$(git -C "$sb" rev-parse HEAD)" ] && echo 0 || echo 1)")"
  emit still_on_main "$(yn "$([ "$(git -C "$sb" branch --show-current)" = "main" ] && echo 0 || echo 1)")"
  emit working_tree_clean "$(yn "$([ -z "$(git -C "$sb" status --porcelain -- tracked.txt keep.txt)" ] && echo 0 || echo 1)")"
}

# --- Scenario 5: skill-reviewer:optimizing-skill-frontmatter ----------------
# This skill rewrites other skills' frontmatter, so a dropped prohibition
# propagates a defect into every file it touches.
scenario_optimizing_frontmatter() {
  local sb="$SANDBOX_ROOT/frontmatter"
  mkdir -p "$sb/kit/plugins/demo/skills/fixture-demo"
  local target="$sb/kit/plugins/demo/skills/fixture-demo/SKILL.md"
  cp "$SCENARIOS/fixture-skill/SKILL.md" "$target"
  git -C "$sb" init -q -b main 2>/dev/null || { mkdir -p "$sb"; git -C "$sb" init -q -b main; }
  git -C "$sb" config user.email baseline@example.com
  git -C "$sb" config user.name "Baseline Harness"
  install_shims "$sb"

  run_claude "$sb" "$ROOT/kit/plugins/skill-reviewer" \
    "Use the skill-reviewer:optimizing-skill-frontmatter skill on kit/plugins/demo/skills/fixture-demo/SKILL.md" \
    "$sb/run.log" || true

  emit skill optimizing-skill-frontmatter
  # The one prohibition that must never be violated.
  emit wrote_disable_false "$(yn "$(grep -qF 'disable-model-invocation: false' "$target" && echo 0 || echo 1)")"
  emit target_still_present "$(yn "$([ -f "$target" ] && echo 0 || echo 1)")"
  emit has_name_line "$(yn "$(grep -q '^name: fixture-demo$' "$target" && echo 0 || echo 1)")"
  emit gh_invoked "$(yn "$([ -s "$sb/gh-invocations.log" ] && echo 0 || echo 1)")"
}

# --- Driver -----------------------------------------------------------------
run_scenario() {
  local name="$1" fn="$2"
  local expected="$FIXTURES/${name}.expected"
  local actual="$SANDBOX_ROOT/${name}.actual"
  TOTAL=$((TOTAL + 1))

  echo "--- $name"
  "$fn" | LC_ALL=C sort >"$actual"

  if [ "$MODE" = "record" ]; then
    cp "$actual" "$expected"
    echo "  RECORDED $(wc -l <"$actual" | tr -d ' ') facts -> $(basename "$expected")"
    MATCHED=$((MATCHED + 1))
    return 0
  fi

  if [ ! -f "$expected" ]; then
    echo "  FAIL: no recorded manifest at $expected (run with --record against the unmodified skills)"
    FAILURES=$((FAILURES + 1))
    return 0
  fi

  if diff -u "$expected" "$actual" >"$SANDBOX_ROOT/${name}.diff"; then
    echo "  MATCH"
    MATCHED=$((MATCHED + 1))
  else
    echo "  FAIL: behavior diverged from the recorded baseline"
    sed 's/^/    /' "$SANDBOX_ROOT/${name}.diff"
    FAILURES=$((FAILURES + 1))
  fi
}

# BASELINE_ONLY re-records or re-checks a single scenario without paying for the
# other four headless runs. `if` rather than `&&` so a filtered-out scenario is
# not a non-zero list status under `set -e`.
ONLY="${BASELINE_ONLY:-}"
maybe() { [ -z "$ONLY" ] || [ "$ONLY" = "$1" ]; }

if maybe build;                        then run_scenario build                        scenario_build; fi
if maybe implementation-plan;          then run_scenario implementation-plan          scenario_implementation_plan; fi
if maybe branch-agent;                 then run_scenario branch-agent                 scenario_branch_agent; fi
if maybe ship-autonomous;              then run_scenario ship-autonomous              scenario_ship_autonomous; fi
if maybe optimizing-skill-frontmatter; then run_scenario optimizing-skill-frontmatter scenario_optimizing_frontmatter; fi

echo ""
echo "baselines: ${MATCHED}/${TOTAL} match"
if [ "$FAILURES" -eq 0 ]; then
  echo "All behavioral baselines passed."
  exit 0
else
  echo "$FAILURES baseline(s) diverged."
  exit 1
fi

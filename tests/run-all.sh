#!/usr/bin/env bash
set -u

# Single entry point for the whole test tree. Before this existed, CI
# hand-enumerated ~20 of the 77 test files in check-plugin-versions.yml and
# the other suites (tests/pages, tests/publish, tests/social-media-tools, the
# root tests, half of tests/plugins) ran only when someone remembered to run
# them by hand. New tests are picked up automatically: anything matching
# tests/**/test-*.sh, tests/**/test-*.mjs, or tests/**/*.test.mjs runs —
# there is nothing to wire.
#
# SKIP LIST — every entry needs a reason. These are matched by basename.
#
#   test-skill-behavior-baselines.sh — drives the `claude` CLI end-to-end; it
#     deliberately exits 1 (not skip) when the CLI is missing, so a CI runner
#     without the CLI would go red on absence rather than on regression. Run
#     it directly on a machine with the CLI.
#   test-imperative-pruning.sh — its assertion 4 chains the baselines harness
#     above whenever the `claude` CLI exists, which hangs inside a nested
#     Claude session and is slow anywhere. CI runs it as an explicit workflow
#     step (where no CLI exists, so the harness half self-skips and the
#     static checks still run); locally, run it directly when you want the
#     full behavioral pass.
#   test-pages-smoke.sh — takes a deployed <base-url> argument and probes the
#     live site; there is nothing to smoke-test without a deployment. Run
#     manually against the Pages URL, or from deploy-pages.yml.
#   test-dist-transforms.mjs — asserts on a built dist/ tree and exits 1 when
#     none exists; publish-dist.yml builds and then runs it. Run manually
#     after `node scripts/build-dist.mjs`.
SKIP_BASENAMES="test-skill-behavior-baselines.sh test-imperative-pruning.sh test-pages-smoke.sh test-dist-transforms.mjs"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

PASS=0
FAIL=0
SKIPPED=0
FAILED_TESTS=""

is_skipped() {
  local base="$1" s
  for s in $SKIP_BASENAMES; do
    [ "$base" = "$s" ] && return 0
  done
  return 1
}

run_one() {
  local runner="$1" t="$2" out rc
  if is_skipped "$(basename "$t")"; then
    echo "SKIP $t (see skip list)"
    SKIPPED=$((SKIPPED + 1))
    return
  fi
  out=$("$runner" "$t" 2>&1)
  rc=$?
  if [ "$rc" -eq 0 ]; then
    echo "PASS $t"
    PASS=$((PASS + 1))
  else
    echo "FAIL $t (exit $rc)"
    printf '%s\n' "$out" | tail -15 | sed 's/^/  | /'
    FAIL=$((FAIL + 1))
    FAILED_TESTS="$FAILED_TESTS $t"
  fi
}

for t in $(find tests -name 'test-*.sh' | sort); do
  run_one bash "$t"
done

for t in $(find tests \( -name 'test-*.mjs' -o -name '*.test.mjs' \) | sort); do
  run_one node "$t"
done

echo
echo "run-all: $PASS passed, $FAIL failed, $SKIPPED skipped"
if [ "$FAIL" -gt 0 ]; then
  echo "failed:$FAILED_TESTS"
  exit 1
fi

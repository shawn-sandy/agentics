#!/usr/bin/env bash
set -euo pipefail

# A merge gate that runs entirely on this machine.
#
# Why it exists: a billing-blocked CI run fails every job in seconds with no
# test output, so a red check is not evidence of a defect and a green one never
# arrives. Merge readiness has to be provable locally.
#
# Why it auto-detects instead of being generated: a gate that hardcodes
# typecheck/lint/unit/e2e reports four confident green no-ops in a project that
# has none of them, which is worse than no gate at all. Every stage looks for
# its own tooling and prints either a real result or an explicit
# "SKIP (not configured)". Absent is not passing, and the output says which.
#
# TRUST: this script executes whatever tooling the project it is pointed at
# declares — npm scripts, local binaries. Running it inside a repo you have not
# read is arbitrary code execution (CWE-829). Use it on repos you already trust.
# It deliberately does NOT prepend node_modules/.bin to PATH; tools are invoked
# by plain name, or through `npx --no-install`, which never fetches anything.
#
# DETECTION IS RELATIVE TO $PWD, NEVER TO $0. This is load-bearing, not style.
# Every other script in the agentics repo resolves its root from $0, and a gate
# that did the same would — while running inside tests/fixtures/verify-gate-bare
# — still find agentics' own .claude-plugin/marketplace.json, re-enter
# tests/run-all.sh, re-run tests/test-verify-gate.sh, and re-invoke itself:
# unbounded recursion on the very test that proves the gate works.
#
# This file is a deliberate byte-identical duplicate of
# kit/plugins/code-testing-agent/skills/verified-change/assets/verify.sh and
# agentics' own scripts/verify.sh. Every change here is a two-file edit;
# tests/plugins/test-verified-change-skill.sh is what makes forgetting loud.

# --- Re-entry guard ---------------------------------------------------------
# Belt-and-braces behind the $PWD rule above. The one legitimate nested run —
# agentics' unit stage running the objective test, which invokes this gate
# against a fixture — clears the marker explicitly with `env -u`.
if [ -n "${VERIFY_GATE_ACTIVE:-}" ]; then
  echo "verify: re-entry detected — VERIFY_GATE_ACTIVE is already set." >&2
  echo "verify: a stage invoked this gate again, which is recursion, not a check." >&2
  echo "verify: check that every stage detects against \$PWD rather than \$0." >&2
  exit 1
fi
export VERIFY_GATE_ACTIVE=1

PROJECT="$PWD"

echo "verify: gate for $PROJECT"
echo

# --- Stage plumbing ---------------------------------------------------------

# Prints the stage's own outcome and exits the whole gate on the first real
# failure, so later stages never run. "Fails fast" is a claim about sequence:
# a summary printed after every stage has already run would not be one.
stage() {
  local name="$1"
  shift
  local rc=0
  printf '%-10s RUN  (%.60s)\n' "$name" "$*"
  "$@" || rc=$?
  if [ "$rc" -eq 0 ]; then
    printf '%-10s PASS\n' "$name"
  else
    printf '%-10s FAIL (exit %d)\n' "$name" "$rc"
    echo
    echo "verify: FAIL at stage '$name' — later stages did not run."
    exit 1
  fi
}

skip() { printf '%-10s SKIP (not configured)\n' "$1"; }

# A distinct message, not the SKIP above: a Playwright config that is present
# with no browsers installed is a machine-setup gap, not an absent stage, and
# reporting the two identically hides which one the reader is looking at.
skip_reason() { printf '%-10s SKIP (%s)\n' "$1" "$2"; }

have() { command -v "$1" >/dev/null 2>&1; }

# True when package.json declares the named script. Uses node because that is
# the only way a package.json project runs at all; if node is absent the answer
# is legitimately "no", since npm could not run the script either.
npm_script() {
  [ -f "$PROJECT/package.json" ] || return 1
  have node || return 1
  node -e 'const s=(require(process.argv[1]).scripts)||{};process.exit(s[process.argv[2]]?0:1)' \
    "$PROJECT/package.json" "$1" 2>/dev/null
}

# Marketplace validation, as a function rather than an inline `node -e` block:
# the stage line echoes the command it is about to run, and a multi-line script
# there would break that one-line-per-stage format the output depends on.
validate_marketplace() {
  node -e 'const fs=require("node:fs"),path=require("node:path");const root=process.argv[1];const m=JSON.parse(fs.readFileSync(path.join(root,".claude-plugin/marketplace.json"),"utf8"));const bad=[];for(const p of m.plugins||[]){if(!/^\d+\.\d+\.\d+$/.test(String(p.version??"")))bad.push(p.name+": version \""+p.version+"\" is not x.y.z");const rel=p.source&&p.source.path;if(rel&&!fs.existsSync(path.join(root,rel)))bad.push(p.name+": source path "+rel+" does not exist");}if(bad.length){console.error(bad.join("\n"));process.exit(1);}console.log("marketplace.json parses, "+(m.plugins||[]).length+" plugins, every source path resolves");' "$PROJECT"
}

# Any of the given paths present, relative to the project.
any_of() {
  local f
  for f in "$@"; do
    [ -e "$PROJECT/$f" ] && return 0
  done
  return 1
}

# --- Stage 1: typecheck -----------------------------------------------------
if npm_script typecheck; then
  stage typecheck npm run --silent typecheck
elif any_of tsconfig.json && have npx; then
  stage typecheck npx --no-install tsc --noEmit
else
  skip typecheck
fi

# --- Stage 2: lint ----------------------------------------------------------
# Detect shellcheck through .shellcheckrc rather than through the mere presence
# of the binary. Config-driven detection is what the eslint branch above does,
# and it is the difference between a project opting into shell linting and a
# gate that turns red for everyone the day someone runs
# `brew install shellcheck`.
#
# The first word is load-bearing: ShellCheck parses any comment beginning with
# "shellcheck" as a directive, so phrasing this sentence the other way around
# fails the gate's own lint stage with SC1072/SC1073 before it reads a single
# project script.
if npm_script lint; then
  stage lint npm run --silent lint
elif any_of eslint.config.js eslint.config.mjs eslint.config.cjs .eslintrc .eslintrc.js .eslintrc.json .eslintrc.yml && have npx; then
  stage lint npx --no-install eslint .
elif any_of .shellcheckrc && have shellcheck; then
  # Deliberately scoped to tracked shell scripts: an unbounded find would walk
  # node_modules and vendored trees and lint code the project does not own.
  stage lint sh -c 'git ls-files -z "*.sh" | xargs -0 -r shellcheck'
else
  skip lint
fi

# --- Stage 3: unit ----------------------------------------------------------
if npm_script test; then
  stage unit npm test --silent
elif [ -f "$PROJECT/tests/run-all.sh" ]; then
  stage unit bash "$PROJECT/tests/run-all.sh"
else
  skip unit
fi

# --- Stage 4: e2e -----------------------------------------------------------
if any_of playwright.config.ts playwright.config.js playwright.config.mjs playwright.config.cjs; then
  if ! have npx; then
    skip_reason e2e "playwright config present, npx unavailable"
  elif [ -d "${HOME}/Library/Caches/ms-playwright" ] || [ -d "${HOME}/.cache/ms-playwright" ]; then
    stage e2e npx --no-install playwright test
  else
    skip_reason e2e "browsers not installed — run: npx playwright install"
  fi
elif npm_script e2e; then
  stage e2e npm run --silent e2e
else
  skip e2e
fi

# --- Marketplace stages -----------------------------------------------------
# Repo-specific, and gated on a marker file so they are inert everywhere else.
# Three is the agreed ceiling for baking project stages into a file sold as
# portable; a fourth is the signal to add a verify.local.sh extension hook
# instead of accreting another branch here.
if [ -f "$PROJECT/.claude-plugin/marketplace.json" ] && have node; then
  echo

  stage marketplace validate_marketplace

  if [ -f "$PROJECT/scripts/check-plugin-versions.mjs" ]; then
    stage versions node "$PROJECT/scripts/check-plugin-versions.mjs"
  else
    skip versions
  fi

  if [ -f "$PROJECT/scripts/build-readme-table.mjs" ]; then
    stage readme node "$PROJECT/scripts/build-readme-table.mjs" --check
  else
    skip readme
  fi
fi

echo
echo "verify: PASS — every stage above either passed or reported why it was skipped."

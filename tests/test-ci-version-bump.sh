#!/usr/bin/env bash
# test-ci-version-bump.sh — Integration tests for CI-only version bump infrastructure
#
# Tests:
#   1. auto-bump-version.mjs — correct bumps from conventional commits
#   2. check-no-manual-bump.sh — rejects manual bumps, allows clean PRs
#
# Creates temporary git repos with mock data; cleans up on exit.
#
# USAGE:
#   bash tests/test-ci-version-bump.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
AUTO_BUMP="${SCRIPT_DIR}/scripts/auto-bump-version.mjs"
NO_MANUAL="${SCRIPT_DIR}/scripts/check-no-manual-bump.sh"

PASS=0
FAIL=0
TOTAL=0

TMPDIR_ROOT=""

cleanup() {
  if [[ -n "$TMPDIR_ROOT" && -d "$TMPDIR_ROOT" ]]; then
    rm -rf "$TMPDIR_ROOT"
  fi
}
trap cleanup EXIT

TMPDIR_ROOT=$(mktemp -d)

# ── Helpers ───────────────────────────────────────────────────────────────────

assert_eq() {
  local label="$1" expected="$2" actual="$3"
  TOTAL=$((TOTAL+1))
  if [[ "$expected" == "$actual" ]]; then
    echo "  PASS: $label"
    PASS=$((PASS+1))
  else
    echo "  FAIL: $label"
    echo "    expected: $expected"
    echo "    actual:   $actual"
    FAIL=$((FAIL+1))
  fi
}

assert_contains() {
  local label="$1" needle="$2" haystack="$3"
  TOTAL=$((TOTAL+1))
  if [[ "$haystack" == *"$needle"* ]]; then
    echo "  PASS: $label"
    PASS=$((PASS+1))
  else
    echo "  FAIL: $label"
    echo "    expected to contain: $needle"
    echo "    in: $haystack"
    FAIL=$((FAIL+1))
  fi
}

assert_exit() {
  local label="$1" expected_code="$2"
  shift 2
  TOTAL=$((TOTAL+1))
  set +e
  "$@" >/dev/null 2>&1
  local actual_code=$?
  set -e
  if [[ "$actual_code" -eq "$expected_code" ]]; then
    echo "  PASS: $label (exit $actual_code)"
    PASS=$((PASS+1))
  else
    echo "  FAIL: $label"
    echo "    expected exit: $expected_code"
    echo "    actual exit:   $actual_code"
    FAIL=$((FAIL+1))
  fi
}

# Create a mock marketplace.json
write_registry() {
  local dir="$1" v_alpha="${2:-1.0.0}" v_beta="${3:-2.0.0}"
  mkdir -p "$dir/.claude-plugin"
  cat > "$dir/.claude-plugin/marketplace.json" <<REGISTRY
{
  "name": "test-marketplace",
  "version": "1.0.0",
  "description": "Test marketplace",
  "plugins": [
    {
      "name": "alpha",
      "source": { "source": "git-subdir", "url": "test/repo", "path": "kit/plugins/alpha" },
      "version": "${v_alpha}",
      "description": "Alpha plugin"
    },
    {
      "name": "beta",
      "source": { "source": "git-subdir", "url": "test/repo", "path": "kit/plugins/beta" },
      "version": "${v_beta}",
      "description": "Beta plugin"
    }
  ]
}
REGISTRY
}

# Read a plugin version from marketplace.json
get_version() {
  local dir="$1" plugin="$2"
  jq -r --arg n "$plugin" '.plugins[] | select(.name==$n) | .version' \
    "$dir/.claude-plugin/marketplace.json"
}

get_marketplace_version() {
  local dir="$1"
  jq -r '.version' "$dir/.claude-plugin/marketplace.json"
}

# Initialize a git repo with a base commit containing the registry
init_repo() {
  local dir="$1"
  mkdir -p "$dir"
  cd "$dir"
  git init -q
  git config user.name "Test"
  git config user.email "test@test.com"
  write_registry "$dir"
  mkdir -p kit/plugins/alpha kit/plugins/beta
  echo "# Alpha" > kit/plugins/alpha/README.md
  echo "# Beta" > kit/plugins/beta/README.md
  git add -A
  git commit -q -m "chore: initial commit"
}

# ═════════════════════════════════════════════════════════════════════════════
# TEST SUITE 1: auto-bump-version.mjs
# ═════════════════════════════════════════════════════════════════════════════

echo ""
echo "═══ Suite 1: auto-bump-version.mjs ═══"
echo ""

# ── Test 1.1: fix() commit → PATCH bump ──────────────────────────────────────

echo "Test 1.1: fix() commit bumps PATCH"
REPO1="${TMPDIR_ROOT}/test-patch"
init_repo "$REPO1"

echo "fixed" >> kit/plugins/alpha/README.md
git add -A
git commit -q -m "fix(kit/plugins/alpha): fix typo in readme"

output=$(node "$AUTO_BUMP" --dry-run --registry .claude-plugin/marketplace.json 2>&1)
assert_contains "alpha detected" "alpha" "$output"
assert_contains "patch bump" "patch" "$output"
assert_contains "1.0.0 → 1.0.1" "1.0.0 → 1.0.1" "$output"

# ── Test 1.2: feat() commit → MINOR bump ─────────────────────────────────────

echo ""
echo "Test 1.2: feat() commit bumps MINOR"
REPO2="${TMPDIR_ROOT}/test-minor"
init_repo "$REPO2"

echo "new feature" >> kit/plugins/beta/README.md
git add -A
git commit -q -m "feat(kit/plugins/beta): add new skill"

output=$(node "$AUTO_BUMP" --dry-run --registry .claude-plugin/marketplace.json 2>&1)
assert_contains "beta detected" "beta" "$output"
assert_contains "minor bump" "minor" "$output"
assert_contains "2.0.0 → 2.1.0" "2.0.0 → 2.1.0" "$output"

# ── Test 1.3: feat()! commit → MAJOR bump ────────────────────────────────────

echo ""
echo "Test 1.3: feat()! (breaking) commit bumps MAJOR"
REPO3="${TMPDIR_ROOT}/test-major"
init_repo "$REPO3"

echo "breaking change" >> kit/plugins/alpha/README.md
git add -A
git commit -q -m "feat(kit/plugins/alpha)!: rename command"

output=$(node "$AUTO_BUMP" --dry-run --registry .claude-plugin/marketplace.json 2>&1)
assert_contains "alpha detected" "alpha" "$output"
assert_contains "major bump" "major" "$output"
assert_contains "1.0.0 → 2.0.0" "1.0.0 → 2.0.0" "$output"

# ── Test 1.4: BREAKING CHANGE in body → MAJOR ────────────────────────────────

echo ""
echo "Test 1.4: BREAKING CHANGE in commit body bumps MAJOR"
REPO4="${TMPDIR_ROOT}/test-breaking-body"
init_repo "$REPO4"

echo "break" >> kit/plugins/beta/README.md
git add -A
git commit -q -m "$(cat <<'MSG'
feat(kit/plugins/beta): restructure skills

BREAKING CHANGE: skill activation pattern changed
MSG
)"

output=$(node "$AUTO_BUMP" --dry-run --registry .claude-plugin/marketplace.json 2>&1)
assert_contains "beta detected" "beta" "$output"
assert_contains "major bump" "major" "$output"
assert_contains "2.0.0 → 3.0.0" "2.0.0 → 3.0.0" "$output"

# ── Test 1.5: Multiple plugins, scoped commits ───────────────────────────────

echo ""
echo "Test 1.5: Multiple plugins get correct individual bumps (merge commit)"
REPO5="${TMPDIR_ROOT}/test-multi"
init_repo "$REPO5"

# Simulate a PR: create a branch with two scoped commits, then merge
git checkout -q -b feature-branch
echo "fix" >> kit/plugins/alpha/README.md
git add -A
git commit -q -m "fix(kit/plugins/alpha): fix alpha bug"

echo "feat" >> kit/plugins/beta/README.md
git add -A
git commit -q -m "feat(kit/plugins/beta): add beta feature"

git checkout -q main
git merge -q --no-ff feature-branch -m "Merge branch 'feature-branch'"

output=$(node "$AUTO_BUMP" --dry-run --registry .claude-plugin/marketplace.json 2>&1)
assert_contains "alpha gets patch" "alpha: 1.0.0 → 1.0.1 (patch)" "$output"
assert_contains "beta gets minor" "beta: 2.0.0 → 2.1.0 (minor)" "$output"

# ── Test 1.6: Unscoped commit applies patch to all changed ───────────────────

echo ""
echo "Test 1.6: Unscoped commit defaults to PATCH for all changed plugins"
REPO6="${TMPDIR_ROOT}/test-unscoped"
init_repo "$REPO6"

echo "change" >> kit/plugins/alpha/README.md
echo "change" >> kit/plugins/beta/README.md
git add -A
git commit -q -m "fix: general maintenance"

output=$(node "$AUTO_BUMP" --dry-run --registry .claude-plugin/marketplace.json 2>&1)
assert_contains "alpha bumped" "alpha: 1.0.0 → 1.0.1" "$output"
assert_contains "beta bumped" "beta: 2.0.0 → 2.0.1" "$output"

# ── Test 1.7: No plugin changes → no bump ────────────────────────────────────

echo ""
echo "Test 1.7: Non-plugin changes produce no bump"
REPO7="${TMPDIR_ROOT}/test-no-plugin"
init_repo "$REPO7"

echo "docs" > README.md
git add -A
git commit -q -m "docs: update readme"

output=$(node "$AUTO_BUMP" --dry-run --registry .claude-plugin/marketplace.json 2>&1)
assert_contains "no bump needed" "No plugin source changes" "$output"

# ── Test 1.8: Actual write (non-dry-run) updates file ────────────────────────

echo ""
echo "Test 1.8: Non-dry-run actually writes updated versions"
REPO8="${TMPDIR_ROOT}/test-write"
init_repo "$REPO8"

echo "change" >> kit/plugins/alpha/README.md
git add -A
git commit -q -m "feat(alpha): add new agent"

node "$AUTO_BUMP" --registry .claude-plugin/marketplace.json >/dev/null 2>&1
actual_ver=$(get_version "$REPO8" "alpha")
assert_eq "alpha version written to file" "1.1.0" "$actual_ver"

beta_ver=$(get_version "$REPO8" "beta")
assert_eq "beta unchanged" "2.0.0" "$beta_ver"

# ── Test 1.9: Marketplace top-level version bumps ────────────────────────────

echo ""
echo "Test 1.9: Marketplace top-level version follows highest plugin bump"
REPO9="${TMPDIR_ROOT}/test-mkt-ver"
init_repo "$REPO9"

echo "break" >> kit/plugins/alpha/README.md
git add -A
git commit -q -m "feat(kit/plugins/alpha)!: major change"

node "$AUTO_BUMP" --registry .claude-plugin/marketplace.json >/dev/null 2>&1
mkt_ver=$(get_marketplace_version "$REPO9")
assert_eq "marketplace version bumped major" "2.0.0" "$mkt_ver"

# ── Test 1.10: Plugin name as scope (short form) ─────────────────────────────

echo ""
echo "Test 1.10: Plugin name (not full path) works as commit scope"
REPO10="${TMPDIR_ROOT}/test-short-scope"
init_repo "$REPO10"

echo "change" >> kit/plugins/beta/README.md
git add -A
git commit -q -m "feat(beta): add new command"

output=$(node "$AUTO_BUMP" --dry-run --registry .claude-plugin/marketplace.json 2>&1)
assert_contains "beta minor via short scope" "beta: 2.0.0 → 2.1.0 (minor)" "$output"

# ── Test 1.11: New plugin is NOT auto-bumped (initial version preserved) ──────

echo ""
echo "Test 1.11: New plugin's initial version is preserved"
REPO11="${TMPDIR_ROOT}/test-new-plugin"
init_repo "$REPO11"

# Add a new plugin in a branch and merge
git checkout -q -b add-gamma
mkdir -p kit/plugins/gamma
echo "# Gamma" > kit/plugins/gamma/README.md
jq '.plugins += [{"name":"gamma","source":{"source":"git-subdir","url":"test/repo","path":"kit/plugins/gamma"},"version":"0.1.0","description":"Gamma"}]' \
  .claude-plugin/marketplace.json > tmp.json
mv tmp.json .claude-plugin/marketplace.json
git add -A
git commit -q -m "feat: add gamma plugin"

git checkout -q main
git merge -q --no-ff add-gamma -m "Merge branch 'add-gamma'"

output=$(node "$AUTO_BUMP" --dry-run --registry .claude-plugin/marketplace.json 2>&1)
assert_contains "gamma skipped" "gamma: new plugin" "$output"

# Verify gamma's version is NOT bumped when writing
node "$AUTO_BUMP" --registry .claude-plugin/marketplace.json >/dev/null 2>&1
gamma_ver=$(get_version "$REPO11" "gamma")
assert_eq "gamma stays at initial version" "0.1.0" "$gamma_ver"

# ── Test 1.12: PUSH_BEFORE/PUSH_AFTER covers rebase/ff push range ────────────

echo ""
echo "Test 1.12: PUSH_BEFORE/PUSH_AFTER env vars cover multi-commit linear pushes"
REPO12="${TMPDIR_ROOT}/test-push-range"
init_repo "$REPO12"

# Record the base SHA before the two commits
base_sha=$(git rev-parse HEAD)

echo "fix alpha" >> kit/plugins/alpha/README.md
git add -A
git commit -q -m "fix(alpha): fix alpha bug"

echo "feat beta" >> kit/plugins/beta/README.md
git add -A
git commit -q -m "feat(beta): add beta feature"

after_sha=$(git rev-parse HEAD)

# Without PUSH_BEFORE/PUSH_AFTER, only the last commit is seen (beta only)
output_no_env=$(node "$AUTO_BUMP" --dry-run --registry .claude-plugin/marketplace.json 2>&1)
assert_contains "without env: beta seen" "beta" "$output_no_env"

# Reset to re-test with env vars
git checkout -q -- .claude-plugin/marketplace.json 2>/dev/null || true

# With PUSH_BEFORE/PUSH_AFTER, both commits are covered
output_with_env=$(PUSH_BEFORE="$base_sha" PUSH_AFTER="$after_sha" \
  node "$AUTO_BUMP" --dry-run --registry .claude-plugin/marketplace.json 2>&1)
assert_contains "with env: alpha seen" "alpha" "$output_with_env"
assert_contains "with env: beta seen" "beta" "$output_with_env"

# ═════════════════════════════════════════════════════════════════════════════
# TEST SUITE 2: check-no-manual-bump.sh
# ═════════════════════════════════════════════════════════════════════════════

echo ""
echo ""
echo "═══ Suite 2: check-no-manual-bump.sh ═══"
echo ""

# ── Test 2.1: No version changes → PASS ──────────────────────────────────────

echo "Test 2.1: Unchanged versions pass the guard"
REPO_G1="${TMPDIR_ROOT}/guard-pass"
init_repo "$REPO_G1"

# Create a "remote" by adding origin pointing at a bare clone
BARE_G1="${TMPDIR_ROOT}/guard-pass-bare"
git clone -q --bare "$REPO_G1" "$BARE_G1"
cd "$REPO_G1"
git remote add origin "$BARE_G1" 2>/dev/null || git remote set-url origin "$BARE_G1"
git fetch -q origin

# Make a plugin change WITHOUT touching versions
git checkout -q -b feature-branch
echo "new content" >> kit/plugins/alpha/README.md
git add -A
git commit -q -m "fix(alpha): update docs"

assert_exit "clean branch passes" 0 bash "$NO_MANUAL"

# ── Test 2.2: Manual plugin version bump → FAIL ──────────────────────────────

echo ""
echo "Test 2.2: Manual plugin version bump is rejected"
REPO_G2="${TMPDIR_ROOT}/guard-fail"
init_repo "$REPO_G2"

BARE_G2="${TMPDIR_ROOT}/guard-fail-bare"
git clone -q --bare "$REPO_G2" "$BARE_G2"
cd "$REPO_G2"
git remote add origin "$BARE_G2" 2>/dev/null || git remote set-url origin "$BARE_G2"
git fetch -q origin

git checkout -q -b feature-branch
# Manually bump alpha version (this should be rejected)
jq '.plugins[0].version = "1.0.1"' .claude-plugin/marketplace.json > tmp.json
mv tmp.json .claude-plugin/marketplace.json
git add -A
git commit -q -m "fix(alpha): bump version"

output=$(bash "$NO_MANUAL" 2>&1 || true)
assert_contains "detects manual bump" "manual version bump detected" "$output"
assert_exit "manual bump fails" 1 bash "$NO_MANUAL"

# ── Test 2.3: New plugin with initial version → PASS ─────────────────────────

echo ""
echo "Test 2.3: New plugin with initial version is allowed"
REPO_G3="${TMPDIR_ROOT}/guard-new-plugin"
init_repo "$REPO_G3"

BARE_G3="${TMPDIR_ROOT}/guard-new-plugin-bare"
git clone -q --bare "$REPO_G3" "$BARE_G3"
cd "$REPO_G3"
git remote add origin "$BARE_G3" 2>/dev/null || git remote set-url origin "$BARE_G3"
git fetch -q origin

git checkout -q -b add-gamma
# Add a new plugin (not on base) — its initial version is expected
mkdir -p kit/plugins/gamma
echo "# Gamma" > kit/plugins/gamma/README.md
jq '.plugins += [{"name":"gamma","source":{"source":"git-subdir","url":"test/repo","path":"kit/plugins/gamma"},"version":"0.1.0","description":"Gamma"}]' \
  .claude-plugin/marketplace.json > tmp.json
mv tmp.json .claude-plugin/marketplace.json
git add -A
git commit -q -m "feat: add gamma plugin"

assert_exit "new plugin allowed" 0 bash "$NO_MANUAL"

# ── Test 2.4: Marketplace top-level version bump → FAIL ──────────────────────

echo ""
echo "Test 2.4: Manual marketplace version bump is rejected"
REPO_G4="${TMPDIR_ROOT}/guard-mkt-bump"
init_repo "$REPO_G4"

BARE_G4="${TMPDIR_ROOT}/guard-mkt-bump-bare"
git clone -q --bare "$REPO_G4" "$BARE_G4"
cd "$REPO_G4"
git remote add origin "$BARE_G4" 2>/dev/null || git remote set-url origin "$BARE_G4"
git fetch -q origin

git checkout -q -b bump-mkt
jq '.version = "2.0.0"' .claude-plugin/marketplace.json > tmp.json
mv tmp.json .claude-plugin/marketplace.json
git add -A
git commit -q -m "chore: bump marketplace version"

output=$(bash "$NO_MANUAL" 2>&1 || true)
assert_contains "detects marketplace bump" "Marketplace version manually bumped" "$output"
assert_exit "marketplace bump fails" 1 bash "$NO_MANUAL"

# ── Test 2.5: Metadata-only change (no version) → PASS ───────────────────────

echo ""
echo "Test 2.5: Metadata change without version change passes"
REPO_G5="${TMPDIR_ROOT}/guard-metadata"
init_repo "$REPO_G5"

BARE_G5="${TMPDIR_ROOT}/guard-metadata-bare"
git clone -q --bare "$REPO_G5" "$BARE_G5"
cd "$REPO_G5"
git remote add origin "$BARE_G5" 2>/dev/null || git remote set-url origin "$BARE_G5"
git fetch -q origin

git checkout -q -b update-desc
jq '.plugins[0].description = "Updated alpha description"' .claude-plugin/marketplace.json > tmp.json
mv tmp.json .claude-plugin/marketplace.json
git add -A
git commit -q -m "docs: update alpha description"

assert_exit "metadata-only passes" 0 bash "$NO_MANUAL"

# ═════════════════════════════════════════════════════════════════════════════
# RESULTS
# ═════════════════════════════════════════════════════════════════════════════

echo ""
echo ""
echo "═══════════════════════════════════════"
echo " Results: $PASS/$TOTAL passed, $FAIL failed"
echo "═══════════════════════════════════════"

if [[ $FAIL -gt 0 ]]; then
  exit 1
fi
exit 0

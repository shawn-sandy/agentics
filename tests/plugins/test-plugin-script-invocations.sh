#!/usr/bin/env bash
set -euo pipefail

# Repo-wide guard for how plugin docs invoke bundled scripts.
#
# Claude Code substitutes ${CLAUDE_PLUGIN_ROOT} and ${CLAUDE_SKILL_DIR} into
# skill, command, and agent markdown bodies (and their allowed-tools Bash
# rules) when the content loads, so a placeholder-anchored command is the
# sanctioned way to run a bundled script — it reaches the Bash tool as a
# literal absolute path. claude.ai and Cowork refuse to install any plugin
# that ships a top-level bin/ directory, which retired the previous bare-name
# wrapper architecture (see test-extractor-wiring.sh for its history).
#
# Invariants held here:
#   1. No plugin ships a top-level bin/ (the whole plugin is refused on
#      claude.ai if one exists).
#   2. The converted call sites still invoke their script via a placeholder in
#      command position — prose naming the script does not count.
#   3. Every placeholder path in plugin markdown resolves to a shipped file.
#   4. Files that are NOT placeholder-substituted (references/, guidelines/)
#      but carry placeholder command lines say so, so the model anchors the
#      path instead of running a literal ${...} that expands to nothing.
#   5. The scan corpus is real (canary), since 2-4 pass on an empty scan.

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PLUGINS="$ROOT/kit/plugins"
FAILURES=0

pass() { echo "  PASS"; }
fail() { echo "  FAIL: $1"; FAILURES=$((FAILURES + 1)); }

echo "=== Plugin Script Invocations Test ==="

echo "1. No plugin ships a top-level bin/ directory..."
BIN_DIRS="$(find "$PLUGINS" -mindepth 2 -maxdepth 2 -type d -name bin 2>/dev/null | sed "s|$PLUGINS/||" | sort)"
if [ -z "$BIN_DIRS" ]; then
  pass
else
  echo "$BIN_DIRS" | sed 's/^/    /'
  fail "the plugin(s) above ship a top-level bin/ — claude.ai and Cowork refuse to install the whole plugin"
fi

echo "2. The converted call sites invoke their script via a placeholder in command position..."
# Asserts the repair, not just the absence of the old spelling: a site could
# otherwise be "fixed" by deleting the command outright. Matched in COMMAND
# POSITION — line start, optional indent, interpreter, placeholder path — so
# the prose sentences that also name each script cannot satisfy the check.
declare -a SITES=(
  'memory-tools/skills/agentic-memory-management/SKILL.md|python3 "\$\{CLAUDE_SKILL_DIR\}/scripts/verify_write\.py"'
  'memory-tools/skills/path-rules-advisor/SKILL.md|python3 "\$\{CLAUDE_PLUGIN_ROOT\}/skills/agentic-memory-management/scripts/verify_write\.py"'
  'skill-reviewer/skills/auditing-allowed-tools/SKILL.md|python3 "\$\{CLAUDE_SKILL_DIR\}/scripts/session_tool_scan\.py"'
  'skill-reviewer/commands/check-description.md|bash "\$\{CLAUDE_PLUGIN_ROOT\}/scripts/measure-description\.sh"'
  'wcag-compliance-reviewer/skills/wcag-compliance-reviewer/SKILL.md|python3 "\$\{CLAUDE_SKILL_DIR\}/scripts/check_wcag\.py"'
  'social-media-tools/skills/export-session/SKILL.md|python3 "\$\{CLAUDE_SKILL_DIR\}/scripts/export_session\.py"'
  'artifact-tools/skills/session-artifact/SKILL.md|python3 "\$\{CLAUDE_SKILL_DIR\}/scripts/export_session\.py"'
  'git-agent/agents/agent-pr.md|bash "\$\{CLAUDE_PLUGIN_ROOT\}/scripts/extract-plan-issues\.sh"'
  'git-agent/agents/agent-ship.md|bash "\$\{CLAUDE_PLUGIN_ROOT\}/scripts/extract-plan-issues\.sh"'
  'git-agent/skills/pr-agent/SKILL.md|bash "\$\{CLAUDE_PLUGIN_ROOT\}/scripts/extract-plan-issues\.sh"'
  'design-system-tools/skills/from-design-md/SKILL.md|node "\$\{CLAUDE_SKILL_DIR\}/scripts/contrast\.mjs"'
  'code-testing-agent/skills/verified-change/SKILL.md|bash "\$\{CLAUDE_SKILL_DIR\}/assets/install-verify-gate\.sh"'
  'plan-agent/skills/build/SKILL.md|node "\$\{CLAUDE_PLUGIN_ROOT\}/scripts/build-plan-html\.mjs"'
  'plan-agent/skills/plans-library/SKILL.md|bash "\$\{CLAUDE_PLUGIN_ROOT\}/hooks/build-index\.sh"'
)
MISSING=""
for entry in "${SITES[@]}"; do
  file="${entry%%|*}"
  cmd_re="${entry##*|}"
  if ! grep -qE "^[[:space:]]*${cmd_re}([[:space:]]|$)" "$PLUGINS/$file" 2>/dev/null; then
    MISSING="$MISSING\n    $file (expected command position: ${cmd_re})"
  fi
done
if [ -z "$MISSING" ]; then
  pass
else
  printf "%b\n" "$MISSING"
  fail "call site(s) above no longer invoke their script via a placeholder in command position"
fi

echo "3. Every placeholder path in plugin markdown resolves to something shipped..."
# A placeholder path naming a missing file is "documented but unrunnable", the
# defect class this suite exists for. ${CLAUDE_PLUGIN_ROOT}/<path> resolves
# against the plugin root; ${CLAUDE_SKILL_DIR}/<path> against the skill folder
# containing the file, or — for a file outside skills/, such as a README —
# against any skill folder in that plugin that makes the path exist. A
# directory counts: prose legitimately points Read at template/reference
# folders. CHANGELOGs are history, not call sites, and are excluded.
BROKEN_PATHS=""
SCANNED=0
while IFS= read -r line; do
  [ -n "$line" ] || continue
  SCANNED=$((SCANNED + 1))
  file="${line%%:*}"
  match="${line#*:}"
  rel="${match#*\}/}"
  plugroot="$(printf '%s' "$file" | sed -n "s|^\($PLUGINS/[^/]*\)/.*|\1|p")"
  [ -n "$plugroot" ] || continue
  case "$match" in
    "\${CLAUDE_PLUGIN_ROOT}/"*)
      [ -e "$plugroot/$rel" ] || BROKEN_PATHS="$BROKEN_PATHS\n    ${file#"$PLUGINS/"} -> $match" ;;
    "\${CLAUDE_SKILL_DIR}/"*)
      skilldir="$(printf '%s' "$file" | sed -n 's|\(.*/skills/[^/]*\)/.*|\1|p')"
      if [ -n "$skilldir" ]; then
        [ -e "$skilldir/$rel" ] || BROKEN_PATHS="$BROKEN_PATHS\n    ${file#"$PLUGINS/"} -> $match"
      else
        FOUND=""
        for d in "$plugroot"/skills/*/; do
          [ -e "$d$rel" ] && FOUND=yes && break
        done
        [ -n "$FOUND" ] || BROKEN_PATHS="$BROKEN_PATHS\n    ${file#"$PLUGINS/"} -> $match"
      fi ;;
  esac
done <<EOF
$(grep -roE '\$\{CLAUDE_(PLUGIN_ROOT|SKILL_DIR)\}/[A-Za-z0-9_./-]+' "$PLUGINS" --include='*.md' 2>/dev/null | grep -v '/CHANGELOG\.md:' | sort -u)
EOF
if [ -z "$BROKEN_PATHS" ]; then
  pass
else
  printf "%b\n" "$BROKEN_PATHS"
  fail "placeholder path(s) above do not resolve to a shipped file"
fi

echo "4. Non-substituted files carrying placeholder commands say so..."
# Substitution happens in SKILL.md, commands/, and agents/ bodies only. A
# references/ or guidelines/ file is opened with Read and arrives verbatim, so
# a placeholder command there runs as a literal ${...} unless the file tells
# the model to anchor it. Each such file must carry the phrase
# "not placeholder-substituted" next to its commands.
UNNOTED=""
while IFS= read -r f; do
  [ -n "$f" ] || continue
  grep -qF 'not placeholder-substituted' "$f" \
    || UNNOTED="$UNNOTED\n    ${f#"$PLUGINS/"}"
done <<EOF
$(grep -rlE '^[[:space:]]*(node|python3|bash) "\$\{CLAUDE_(PLUGIN_ROOT|SKILL_DIR)\}/' "$PLUGINS" --include='*.md' 2>/dev/null | grep -E '/(references|guidelines)/' | sort)
EOF
if [ -z "$UNNOTED" ]; then
  pass
else
  printf "%b\n" "$UNNOTED"
  fail "reference file(s) above carry placeholder commands without the 'not placeholder-substituted' note"
fi

echo "5. The scan machinery actually scanned something..."
# Checks 1-4 are absence assertions; they pass on an empty corpus. The canary
# asserts the corpus is real: the placeholder scan found sites (check 2 lists
# 14, so fewer than 10 distinct tokens means the scan broke), and the markdown
# corpus itself is present.
# The grep is guarded: on an empty corpus it exits 1, and under set -e an
# unguarded assignment pipeline would kill the script here — before the fail
# message below, which exists precisely to report the empty corpus.
CANARY_COUNT="$({ grep -rlE --include='*.md' '^---$' "$PLUGINS" 2>/dev/null || true; } | wc -l | tr -d ' ')"
if [ "$SCANNED" -ge 10 ] && [ "$CANARY_COUNT" -ge 50 ]; then
  pass
else
  fail "scan saw only $SCANNED placeholder tokens (want 10+) across $CANARY_COUNT markdown files (want 50+) — the corpus or the pattern is broken, so the checks above are vacuous"
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "All plugin-script-invocation checks passed."
  exit 0
else
  echo "$FAILURES check(s) failed."
  exit 1
fi

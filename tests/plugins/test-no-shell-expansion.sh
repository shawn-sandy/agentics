#!/usr/bin/env bash
set -euo pipefail

# Repo-wide guard against documented Bash commands that can never run.
#
# Claude Code's Bash tool refuses any command whose text contains `${VAR}` or
# `$VAR`, erroring with "Contains expansion" because it cannot statically
# resolve the expansion. The refusal fires BEFORE permission rules are
# consulted, so the command is unrunnable by every agent at every permission
# level and no `tools:` grant or allowlist entry can rescue it. Verified
# empirically on 2.1.220 against an agent holding unrestricted `Bash`.
#
# `${CLAUDE_PLUGIN_ROOT}` compounds this: it is a config-file substitution for
# hooks.json, MCP/LSP, and monitor commands. It is NOT exported into the Bash
# tool's environment, so even if the guard let it through, the path would
# expand to empty.
#
# The supported way to invoke a bundled script is a plugin's `bin/` directory,
# which Claude Code adds to the Bash tool's `PATH` ("Executables added to the
# Bash tool's PATH. Files here are invokable as bare commands in any Bash tool
# call while the plugin is enabled" — plugins reference). A bare command name
# contains no `$`, so it clears the guard.
#
# This test generalizes check 9 of test-extractor-wiring.sh, which covers only
# the plan-agent review surface.

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PLUGINS="$ROOT/kit/plugins"
FAILURES=0

pass() { echo "  PASS"; }
fail() { echo "  FAIL: $1"; FAILURES=$((FAILURES + 1)); }

echo "=== No-Shell-Expansion Test ==="

# Two shapes of dead invocation. Both are scanned over the whole line rather
# than stopping at `|`/`;`: the guard is textual over the entire command
# string, so `node x.mjs | sed "$V"` is as dead as an expansion in argument
# one. Position of `$` is irrelevant.
#
# INTERP_RE — an interpreter invocation carrying an expansion anywhere in its
# arguments. Scanning only the token after the command name would miss
# `python3 scripts/x.py "$PLAN"`, which is equally dead.
#
# BARE_RE — a bundled script invoked directly, with no interpreter prefix, as
# in `"${CLAUDE_PLUGIN_ROOT}/scripts/measure-description.sh" "$file"`. INTERP_RE
# cannot see this shape (no `node`/`python3`/`bash` token), and it was a live
# defect in skill-reviewer until this test was written. Anchored to command
# position — line start, optional indent, optional opening quote, then a BRACED
# expansion. The brace requirement is what keeps it quiet: continuation lines
# like `"$GIT_ROOT" 2>/dev/null | \` and DTCG JSON keys like `"$value": "1rem"`
# use the unbraced form and are not command invocations. Verified to produce
# zero matches across kit/plugins at the time of writing.
#
# `git`/`gh` are deliberately absent from INTERP_RE: prose in this tree says
# things like "fall back to `docs/prompts` relative to `$PWD`", which a `git`
# alternative would match as a command. A false positive on prose trains the
# next author to loosen the check.
INTERP_RE='(^|[[:space:]`"'"'"'(])(node|python3?|bash|sh|realpath)[[:space:]].*\$[{(]?[A-Za-z_]'
BARE_RE='^[[:space:]]*"?\$\{[A-Za-z_]'

# CHANGELOG.md files are excluded: they quote historical broken commands as the
# record of what was fixed. Re-flagging them would force authors to mangle
# history to keep the suite green.
scan() { # $1=regex  -> "path:count" lines, repo-relative, CHANGELOGs dropped
  grep -rcE "$1" "$PLUGINS" --include='*.md' 2>/dev/null \
    | grep -v ':0$' \
    | grep -v '/CHANGELOG\.md:' \
    | sed "s|$PLUGINS/||" \
    | sort || true
}

echo "1. No bundled script is invoked via a bare braced expansion..."
# Zero tolerance, no ledger. This shape has exactly one cause — a plugin-root
# path in command position — and exactly one fix, so there is nothing
# legitimate to grandfather.
BARE="$(scan "$BARE_RE")"
if [ -z "$BARE" ]; then
  pass
else
  echo "$BARE" | sed 's/^/    /'
  fail "the file(s) above invoke a script via a braced expansion in command position — the Bash tool errors with 'Contains expansion' and the command never runs. Add a bin/ wrapper and call it by bare name."
fi

echo "2. The fixed call sites invoke their bin/ wrapper by bare name..."
# Asserts the repair, not just the absence of the old spelling. Without this a
# site could be "fixed" by deleting the command outright and check 1 would
# still pass — which is how 8.1.1 replaced one silent fallback with another.
declare -a SITES=(
  "skill-reviewer/skills/auditing-allowed-tools/SKILL.md:skill-reviewer-scan-tools"
  "skill-reviewer/commands/check-description.md:skill-reviewer-measure-description"
  "wcag-compliance-reviewer/skills/wcag-compliance-reviewer/SKILL.md:wcag-check"
  "wcag-compliance-reviewer/README.md:wcag-check"
  "social-media-tools/skills/export-session/SKILL.md:social-export-session"
  "artifact-tools/skills/session-artifact/SKILL.md:artifact-export-session"
  "git-agent/agents/agent-pr.md:git-agent-extract-plan-issues"
  "git-agent/agents/agent-ship.md:git-agent-extract-plan-issues"
)
MISSING=""
for entry in "${SITES[@]}"; do
  file="${entry%%:*}"
  cmd="${entry##*:}"
  if ! grep -qF "$cmd" "$PLUGINS/$file" 2>/dev/null; then
    MISSING="$MISSING\n    $file (expected bare command: $cmd)"
  fi
done
if [ -z "$MISSING" ]; then
  pass
else
  printf "%b\n" "$MISSING"
  fail "call site(s) above no longer name their bin/ wrapper — the invocation was removed or renamed without updating this list"
fi

echo "3. Every bin/ wrapper is executable and resolves its target..."
# A wrapper that lost its exec bit, or points at a moved script, fails at the
# call site with a shell error rather than anything a reader would trace back
# here. `bin` is on the KEEP allowlist in scripts/build-dist.mjs and reaches
# dist via cpSync, which preserves mode on these extensionless files.
WRAPPER_PROBLEMS=""
WRAPPER_COUNT=0
while IFS= read -r w; do
  [ -n "$w" ] || continue
  WRAPPER_COUNT=$((WRAPPER_COUNT + 1))
  rel="${w#"$PLUGINS/"}"
  [ -x "$w" ] || WRAPPER_PROBLEMS="$WRAPPER_PROBLEMS\n    $rel is not executable (chmod +x it)"
  # Pull the exec'd target out of the wrapper and confirm it exists on disk.
  target="$(sed -n 's|.*exec [a-z0-9]* "\$(dirname "\$0")/\([^"]*\)".*|\1|p' "$w")"
  if [ -z "$target" ]; then
    WRAPPER_PROBLEMS="$WRAPPER_PROBLEMS\n    $rel has no recognizable exec line"
  elif [ ! -f "$(dirname "$w")/$target" ]; then
    WRAPPER_PROBLEMS="$WRAPPER_PROBLEMS\n    $rel points at a missing target: $target"
  fi
  # The wrapper itself must not reintroduce the defect in its own name.
  case "$(basename "$w")" in *'$'*)
    WRAPPER_PROBLEMS="$WRAPPER_PROBLEMS\n    $rel has a '\$' in its filename" ;;
  esac
done <<EOF
$(find "$PLUGINS" -mindepth 3 -maxdepth 3 -type f -path '*/bin/*' | sort)
EOF
if [ "$WRAPPER_COUNT" -eq 0 ]; then
  fail "no bin/ wrappers found at all — the fix has been reverted wholesale"
elif [ -z "$WRAPPER_PROBLEMS" ]; then
  pass
else
  printf "%b\n" "$WRAPPER_PROBLEMS"
  fail "bin/ wrapper(s) above are broken"
fi

echo "4. 'bin' is on the dist KEEP allowlist..."
# Without this the wrappers are silently dropped from dist/ and every installed
# user gets a plugin whose documented commands are not on PATH — the same
# class of "documented but unrunnable" bug this whole test exists to prevent.
if grep -qE "^[[:space:]]*'bin'," "$ROOT/scripts/build-dist.mjs"; then
  pass
else
  fail "scripts/build-dist.mjs KEEP allowlist is missing 'bin' — wrappers will not reach dist/"
fi

echo "5. The known unfixed expansion call sites are exactly the documented set..."
# A ledger, not a suppression. The same defect exists in plugins outside this
# change's scope; each needs its own design call about whether a bin/ wrapper,
# a literal path, or deleting the command is right, so they were left alone
# rather than quietly swept in.
#
# It fails if a NEW site appears (silent spread) and if one is FIXED without
# updating the list (silent rot). Either way a human looks. Delete an entry
# when you fix it; delete this whole check once the list empties.
#
# Tracks `path:count`, not bare filenames: `grep -l` collapses every match in a
# file to one name, so a second broken invocation added to an already-listed
# file would leave the list identical and the check green. Counts, not line
# numbers — the latter churn on unrelated edits and fail noisily for no reason.
KNOWN_BROKEN="memory-tools/skills/agentic-memory-management/SKILL.md:1
memory-tools/skills/path-rules-advisor/references/write-verification.md:1
plan-agent/README.md:1
plan-agent/skills/build/SKILL.md:1
plan-agent/skills/finalize-plan/references/write-completions.md:1
plan-agent/skills/implementation-plan/SKILL.md:1
plan-agent/skills/plans-library/SKILL.md:3
plan-agent/skills/plans-open/SKILL.md:1
plan-agent/skills/prototype/SKILL.md:1
social-media-tools/references/rendering-pipeline.md:2
social-media-tools/skills/media-library/SKILL.md:2
social-media-tools/skills/save-artifact/SKILL.md:1
social-media-tools/skills/share-blog/SKILL.md:1
social-media-tools/skills/share-session/references/session-data.md:1"
ACTUAL_BROKEN="$(scan "$INTERP_RE")"
if [ "$ACTUAL_BROKEN" = "$KNOWN_BROKEN" ]; then
  pass
else
  echo "  expected:"; echo "$KNOWN_BROKEN" | sed 's/^/    /'
  echo "  actual:";   echo "$ACTUAL_BROKEN" | sed 's/^/    /'
  fail "the shell-expansion ledger drifted — a site was added or fixed; update this list"
fi

echo ""
if [ "$FAILURES" -eq 0 ]; then
  echo "All no-shell-expansion checks passed."
  exit 0
else
  echo "$FAILURES check(s) failed."
  exit 1
fi

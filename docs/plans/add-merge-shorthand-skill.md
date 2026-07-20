---
status: todo
type: feature
created: 2026-07-20
issue: https://github.com/shawn-sandy/agentics/issues/436
glance: The "merge?" shorthand currently lives only in a private memory note that may or may not fire. This plan promotes it into a git-agent skill with a deterministic prompt hook, so typing merge? reliably checks PR readiness and merges when green — on any machine the plugin is installed.
---

# Plan: Formalize the merge? shorthand as a git-agent skill + prompt hook

## Objective

Add a `merge` skill to the `git-agent` plugin (check PR readiness → merge if
green, otherwise surface status and ask) and a `UserPromptSubmit` hook that
deterministically routes the literal prompt `merge?` to that skill.

## Context

Typing `merge?` works today only through a 50-day-old memory note
(`feedback-merge-behavior`) — model-discretion recall, invisible to other
machines, unverifiable. The proposal at
`docs/proposals/formalize-merge-shorthand.md` locked the activation decision:
skill + prompt hook. The skill holds the logic and is explicitly invocable as
`/git-agent:merge`; the hook keeps the 6-character ergonomics with a
deterministic trigger. `git-agent` has no hooks yet — `kit/plugins/plan-agent/hooks.json`
is the wiring precedent. Risk: an over-broad hook regex firing on ordinary
prompts containing "merge" — mitigated by an anchored regex and a smoke test
asserting silence on non-matching prompts.

## Files

- kit/plugins/git-agent/skills/merge/SKILL.md (new) — merge-readiness skill: check → merge or ask
- kit/plugins/git-agent/hooks/merge-shorthand.py (new) — UserPromptSubmit script, anchored match on `merge?`
- kit/plugins/git-agent/hooks.json (new) — hook wiring, mirrors plan-agent precedent
- tests/plugins/test-merge-shorthand.sh (new) — smoke test for hook + skill contract
- .claude-plugin/marketplace.json (modified) — git-agent 4.3.0 → 4.4.0
- kit/plugins/git-agent/CHANGELOG.md (modified) — v4.4.0 entry
- kit/plugins/git-agent/README.md (modified) — document the merge skill and shorthand

## Steps

1. Create `kit/plugins/git-agent/skills/merge/SKILL.md` with frontmatter matching sibling skills (`name: merge`, three-part description ≤200 chars with trigger phrases like "merge?" and "is this ready to merge", `allowed-tools: Bash(git *), Bash(gh *), Bash(glab *), Read, Grep, Glob, ToolSearch, ExitPlanMode`). Logic from the retired memory note: run `gh pr view --json state,mergeable,statusCheckRollup` (or `gh pr list` when no PR for the branch); if the PR is MERGEABLE and required checks pass, run a local lint gate before merging — detect the project's first non-`fix`, non-`watch` `lint*` script (the `ship-autonomous` Step 2.5 precedent) and run it; no script found → skip with a one-line note; lint fails → do not merge, print the failures and ask (never auto-`--fix` — fixed files would change the PR head). Lint green → run `gh pr merge` — never `--delete-branch`. If checks are pending, failing, or anything is ambiguous, print the status summary and ask before acting. Include a Step 0 ExitPlanMode self-bootstrap like sibling skills. Why: the skill is the single reviewable home for the behavior, replacing prose in a private memory file. Verify: file exists, frontmatter parses, description is ≤200 chars (`python3 tests/plugins/measure_description_budget.py` or manual count), and the body forbids `--delete-branch`.
2. Create `kit/plugins/git-agent/hooks/merge-shorthand.py` — read the hook JSON from stdin, and only when the prompt matches `^\s*merge\?\s*$` (case-insensitive) emit `additionalContext` instructing Claude to run the `git-agent:merge` skill; exit 0 silently on every other prompt. Wire it in a new `kit/plugins/git-agent/hooks.json` with a `UserPromptSubmit` entry using `${CLAUDE_PLUGIN_ROOT}` and a short timeout, mirroring `kit/plugins/plan-agent/hooks.json` structure. Why: the hook makes the 6-char shorthand deterministic instead of best-effort memory recall. Verify: `echo '{"prompt":"merge?"}' | python3 kit/plugins/git-agent/hooks/merge-shorthand.py` emits the routing context, and `echo '{"prompt":"how do merges work"}' | python3 ...` emits nothing; `python3 -m json.tool kit/plugins/git-agent/hooks.json` passes.
3. Add `tests/plugins/test-merge-shorthand.sh` following the existing `tests/plugins/test-*.sh` conventions: assert the hook script fires on `merge?` (and ` merge? ` with whitespace), stays silent on prompts merely containing "merge", asserts hooks.json is valid JSON referencing the script, and greps SKILL.md for the readiness-check contract (MERGEABLE gate, lint gate before merge with no auto-fix, no `--delete-branch`, ask-when-not-ready). Why: the whole point of formalizing is verifiability — the test pins the trigger and the safety rules. Verify: `bash tests/plugins/test-merge-shorthand.sh` exits 0.
4. Bump `git-agent` to `4.4.0` in `.claude-plugin/marketplace.json` (new skill + hook = MINOR), add a v4.4.0 entry to `kit/plugins/git-agent/CHANGELOG.md` describing the skill, hook, and test, and document the `merge` skill and `merge?` shorthand in `kit/plugins/git-agent/README.md` and the plugin table row in `CLAUDE.md`. Why: repo convention — any plugin change requires a manual marketplace version bump plus changelog/docs. Verify: `BASE_REF=main node scripts/check-plugin-versions.mjs` passes and `python3 -m json.tool .claude-plugin/marketplace.json` succeeds.
5. Retire the memory note `~/.claude/projects/-Users-shawnsandy-devbox-agentics/memory/feedback_merge_behavior.md` by replacing its body with a one-line pointer to the shipped skill (keep the frontmatter, note the behavior now lives in `git-agent:merge`), and update the corresponding line in `MEMORY.md`. Why: two sources of truth for the same behavior will drift; the plugin is now canonical. Verify: the memory file body references `git-agent:merge` and no longer carries standalone merge instructions.

## Tests

Tier 1 — This plan changes application code (plugin skills, hooks, and manifest are the shipped product of this repo)
- Objective: typing `merge?` deterministically routes to the merge skill, and the skill's contract (readiness gate, no branch deletion, ask-when-not-ready) is pinned. File: tests/plugins/test-merge-shorthand.sh; Type: smoke; Asserts: hook emits routing context on `merge?` and stays silent otherwise, hooks.json wiring is valid, SKILL.md carries the MERGEABLE gate and forbids --delete-branch; Run: bash tests/plugins/test-merge-shorthand.sh
- Unit: hook regex boundaries. File: tests/plugins/test-merge-shorthand.sh; Targets: hooks/merge-shorthand.py; Key cases: exact `merge?`, surrounding whitespace, uppercase `MERGE?`, negative cases (`merge`, `can you merge this?`, prose containing "merge?")

## Acceptance Criteria

- [ ] `kit/plugins/git-agent/skills/merge/SKILL.md` exists with valid frontmatter, a ≤200-char three-part description, and logic that merges only when MERGEABLE with passing required checks — never with `--delete-branch`
- [ ] The skill runs the project's lint script (non-`fix`, non-`watch`) before merging, skips with a note when none exists, and on lint failure stops and asks — never auto-`--fix`es
- [ ] `echo '{"prompt":"merge?"}' | python3 kit/plugins/git-agent/hooks/merge-shorthand.py` emits routing context; a prompt merely containing "merge" emits nothing
- [ ] `kit/plugins/git-agent/hooks.json` is valid JSON wiring the script via `${CLAUDE_PLUGIN_ROOT}` under `UserPromptSubmit`
- [ ] `bash tests/plugins/test-merge-shorthand.sh` exits 0
- [ ] `marketplace.json` shows git-agent `4.4.0` and `BASE_REF=main node scripts/check-plugin-versions.mjs` passes
- [ ] CHANGELOG.md, README.md, and the CLAUDE.md plugin table document the new skill and shorthand
- [ ] The `feedback_merge_behavior` memory note is reduced to a pointer at `git-agent:merge`

## Verification

Load the plugin locally (`claude --plugin-dir ./kit/plugins/git-agent`), type
`merge?` on a branch with an open PR, and confirm the hook context fires and
the skill runs the readiness check — merging only when checks are green,
otherwise reporting status and asking. Then run the full test sweep
(`bash tests/plugins/test-merge-shorthand.sh` plus
`BASE_REF=main node scripts/check-plugin-versions.mjs`) and confirm both pass.

## Next Steps

- Add a `merge-bg` background command mirroring commit-bg/pr-bg
  ```text
  In ~/devbox/agentics, add a /git-agent:merge-bg command that dispatches a background agent to run the git-agent merge skill (check PR readiness, merge if green, report otherwise), following the existing commands/commit-bg.md and pr-bg.md patterns. Background agents must remain report-only for anything ambiguous. Bump git-agent MINOR in marketplace.json and add a CHANGELOG entry.
  ```

## Resources

- docs/proposals/formalize-merge-shorthand.md — the decision-complete proposal this plan executes; activation decision (skill + hook) locked 2026-07-20
- kit/plugins/plan-agent/hooks.json — wiring precedent for plugin hook files

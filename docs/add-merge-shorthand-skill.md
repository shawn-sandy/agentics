# Formalize the merge? shorthand as a git-agent skill + prompt hook

> Promotes the `merge?` shorthand from a private memory note to a deterministic `git-agent` skill with a `UserPromptSubmit` hook, making PR readiness checks and merge approval reliable across all machines where the plugin is installed.

<!-- generated:start -->

**Status:** Shipped 2026-08-15 **Plan:** [add-merge-shorthand-skill.md](plans/add-merge-shorthand-skill.md)
**Type:** feature

## What shipped

- Created `kit/plugins/git-agent/skills/merge/SKILL.md` — the merge-readiness skill: checks PR state and required CI checks, runs a project lint gate before merging, asks for explicit approval, and merges with `--match-head-commit` for atomic safety. Never auto-deletes the branch or auto-fixes lint failures.
- Created `kit/plugins/git-agent/hooks/merge-shorthand.py` — a `UserPromptSubmit` hook script that matches only the exact prompt `merge?` (anchored regex, case-insensitive, trims surrounding whitespace) and emits `additionalContext` routing to the skill; all other prompts are passed through silently.
- Created `kit/plugins/git-agent/hooks.json` — wires the hook under `UserPromptSubmit` using `${CLAUDE_PLUGIN_ROOT}`, mirroring the `plan-agent` hooks precedent.
- Created `tests/plugins/test-merge-shorthand.sh` — asserts hook fires on `merge?`, ` merge? `, and `MERGE?`; stays silent on `merge`, `please merge?`, `merge? now`, and prose containing "merge?"; validates `hooks.json` is valid JSON; and greps SKILL.md for the readiness contract (MERGEABLE gate, lint gate, no `--delete-branch`, ask-when-not-ready).
- Bumped `git-agent` to `4.4.0` in `.claude-plugin/marketplace.json` with a CHANGELOG entry and README documentation.
- Retired the `feedback_merge_behavior` memory note by replacing its body with a pointer to `git-agent:merge`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/skills/merge/SKILL.md` | Merge-readiness skill — check, lint gate, ask, merge | Created |
| `kit/plugins/git-agent/hooks/merge-shorthand.py` | UserPromptSubmit hook — anchored `merge?` routing | Created |
| `kit/plugins/git-agent/hooks.json` | Hook wiring — UserPromptSubmit entry | Created |
| `tests/plugins/test-merge-shorthand.sh` | Smoke test — hook regex, contract assertions | Created |
| `.claude-plugin/marketplace.json` | Marketplace version bump to 4.4.0 | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | Release notes — v4.4.0 entry | Modified |
| `kit/plugins/git-agent/README.md` | Plugin documentation — merge skill and shorthand | Modified |

## How it works

**Skill logic.** `merge/SKILL.md` opens with a `ExitPlanMode` self-bootstrap (matching sibling skills), then checks PR state via `gh pr view --json state,mergeable,statusCheckRollup` (or `gh pr list` when no PR exists for the current branch). If the PR is `MERGEABLE` and required checks pass, the skill detects the project's first non-`fix`, non-`watch` `lint*` script — following the `ship-autonomous` Step 2.5 precedent — and runs it. If no lint script exists, the skill skips with a one-line note. Lint failure stops the merge and prints the failures; it never auto-`--fix`es because fixed files would change the PR head. On a green lint, the skill shows the check summary, review decision, and unresolved-thread count, then asks for explicit merge approval via `AskUserQuestion`. Approval triggers `gh pr merge --squash --match-head-commit <headRefOid>` — non-interactive and it fails rather than landing commits that arrived after verification. `--delete-branch` is explicitly forbidden.

**Hook routing.** `merge-shorthand.py` reads the hook JSON from stdin and tests the prompt against `^\s*merge\?\s*$` (case-insensitive). Only an exact `merge?` match — with optional surrounding whitespace — emits `additionalContext` instructing Claude to run `git-agent:merge`. Every other prompt exits 0 silently. The anchored regex prevents over-broad matches: `please merge?`, `merge? now`, or prose containing "merge?" mid-sentence all pass through without routing.

**Hook wiring.** `hooks.json` mirrors `kit/plugins/plan-agent/hooks.json` structure, registering the script under `UserPromptSubmit` with `${CLAUDE_PLUGIN_ROOT}` so the path resolves correctly after installation. A short timeout prevents the hook from blocking prompt submission on slow machines.

**Memory retirement.** The `feedback_merge_behavior` memory note had been the sole source of `merge?` behavior — a 50-day-old prose description subject to model-discretion recall and invisible to other machines. Its body was replaced with a one-line pointer to `git-agent:merge`, making the plugin the canonical source while preserving the memory file's frontmatter for reference.

**Test coverage.** The smoke test pipes JSON payloads directly to `merge-shorthand.py` to verify the regex boundary conditions, then checks `hooks.json` parses with `python3 -m json.tool`, and finally greps SKILL.md for the four safety rules: MERGEABLE gate, lint gate with no auto-fix, absence of `--delete-branch`, and ask-when-not-ready.

## How to use it

Activation: type the literal prompt `merge?` (six characters, case-insensitive). The `UserPromptSubmit` hook intercepts this and routes to the `git-agent:merge` skill. The skill can also be invoked explicitly:

```
# Via shorthand (hook intercepts)
merge?

# Via explicit skill invocation
/git-agent:merge
```

The skill checks the current branch's open PR, runs the project lint script, shows the readiness summary, and asks for merge approval. It never merges without explicit confirmation and never deletes the branch automatically.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `eab3545` | 2026-09-03 | fix(git-agent,code-review): stop the pre-PR reviewer from stalling the ship (4.20.2, 3.3.6) (#619) |
| `da54ec1` | 2026-08-27 | fix(git-agent): stop a zero-byte CI log reporting as "never dispatched" (4.19.5) (#607) |
| `4f72700` | 2026-08-27 | feat(git-agent): add a context guard to ship-autonomous (#608) |
| `3e849ec` | 2026-08-23 | feat(review-gates): close four gaps found in the usage-insights report (#598) |
| `324cc3c` | 2026-08-19 | feat(git-agent): adversarial pre-PR review in PR-opening flows (4.19.3) (#585) |
| `bcaf6fa` | 2026-08-17 | feat: worked examples and remaining verification checks (audit Tier 4) (#570) |
| `2fd715f` | 2026-08-17 | fix: redefine done as artifact + verification in five high-impact skills (#568) |
| `e1e8840` | 2026-08-15 | feat(git-agent): add post-merge-cleanup skill (4.19.0) (#565) |

<!-- generated:end -->

## References

- Plan: [add-merge-shorthand-skill.md](plans/add-merge-shorthand-skill.md)

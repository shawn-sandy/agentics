# Proposal: Formalize the `merge?` shorthand as a git-agent skill + prompt hook

- Status: decision-complete
- Tier: 1 (lightweight)
- Created: 2026-07-20
- Repo: agentics

## Context

Typing `merge?` currently works only through a 50-day-old memory note
(`feedback-merge-behavior`): check PR readiness, merge if green, ask if not.
Memory recall is model discretion — it may not fire, it is invisible to other
machines or teammates, and there is no way to verify the trigger. The user
wants the behavior promoted into a real, verifiable plugin component.

## Core finding

> The `merge?` behavior already has a complete spec (in the memory note) and a
> natural home (`git-agent`, which owns `pr-agent`, `ship`, and the `*-bg`
> commands) — the only missing pieces are a skill file to hold the logic and a
> deterministic trigger for the literal `merge?` token.

Side-by-side:

| | Today (memory note) | Proposed (skill + hook) |
|---|---|---|
| Trigger | Model recall, best-effort | `UserPromptSubmit` hook regex on `merge?` — deterministic |
| Logic location | Prose in `~/.claude/projects/.../memory/` | `kit/plugins/git-agent/skills/merge/SKILL.md` |
| Explicit invocation | None | `/git-agent:merge` (skills are slash-invocable) |
| Portability | This machine only | Ships with the marketplace plugin |
| Verifiable | No | Yes — hook fires on exact match; skill testable via `tests/plugins/` |

## Locked decisions

1. **Activation: skill + prompt hook** (user-selected 2026-07-20).
   A `merge` skill holds the readiness-check-then-merge logic; a
   `UserPromptSubmit` hook matches the literal `merge?` prompt and routes to
   the skill. Keeps the 6-char ergonomics *and* a deterministic trigger.
   Rejected: skill-only (trigger is model discretion on a 2-word prompt),
   command-only (kills the shorthand).

## Recommended shape (input to the execution plan)

- `kit/plugins/git-agent/skills/merge/SKILL.md` — logic from the memory note:
  `gh pr list` / `gh pr view --json state,mergeable,statusCheckRollup`; if
  MERGEABLE and required checks pass → `gh pr merge` (no `--delete-branch`,
  per the user's git-safety rule); otherwise surface status and ask.
- `kit/plugins/git-agent/hooks.json` — new file (git-agent has no hooks yet;
  precedent: `kit/plugins/plan-agent/hooks.json`). A `UserPromptSubmit` entry
  whose script exits silently unless the prompt is `merge?` (anchored regex,
  e.g. `^\s*merge\?\s*$`), then emits additionalContext instructing Claude to
  run the `git-agent:merge` skill.
- Version bump: `git-agent` `4.3.0 → 4.4.0` in `marketplace.json` (new skill +
  hook = MINOR), plus a `CHANGELOG.md` entry.
- Retire the memory note once the skill ships (delete or convert to a pointer)
  so the two sources cannot drift.
- Smoke test under `tests/plugins/` asserting the hook script fires on
  `merge?` and stays silent on ordinary prompts containing the word "merge".

## Open questions

None — the single decision (activation mode) is locked. Remaining items are
facts the execution plan resolves (exact hook-script shape, gh field names).

## Handoff

The proposal is decision-complete. To turn it into an execution plan, run:

`/plan-agent:implementation-plan author an execution plan from the proposal at docs/proposals/formalize-merge-shorthand.md`

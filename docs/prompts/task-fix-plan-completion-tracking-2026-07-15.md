---
type: task
intent: Diagnose why implementation plans are left unmarked as completed and produce an implementation plan for a fix that works for marketplace plugin users.
techniques: Clarity/directness, XML context tags, CoT scaffolding, Output format
created: 2026-07-15
---

# Task: Fix Plan Completion Tracking

<context>
In the `agentics` repo (a Claude Code plugin marketplace), the `plan-agent` plugin generates HTML implementation plans under `docs/plans/`. Each plan carries a `status` field (`todo` → `in-progress` → `completed`) plus acceptance criteria.

The problem: plans routinely finish implementation but are never marked `completed`. Status rots at `todo` or `in-progress`, so the plans gallery misrepresents what has shipped.

`plan-agent` already ships parts that may or may not be the right place for a fix — investigate before assuming:
- `kit/plugins/plan-agent/skills/finalize-plan/` — a skill that reviews a plan and marks it completed with per-criterion verification
- `kit/plugins/plan-agent/hooks/validate-plan-filename.py` — a PostToolUse hook, precedent for hook-based enforcement
- `kit/plugins/plan-agent/hooks/rebuild-plans-index.py` — precedent for reacting to plan file writes
- `plan-interview:plan-status` — an overlapping skill in a different plugin

Critically: the fix must work for people who installed `plan-agent` from the marketplace, not just in this repo. Anything relying on this repo's local `.claude/settings.json`, local rules, or the maintainer's `~/.claude/rules/plan-mode.md` does not reach plugin users.
</context>

<thinking>
Before proposing anything, work through this in order:

1. Reproduce the gap. Read `finalize-plan/SKILL.md` and its frontmatter description. Read `plan-agent`'s hooks and `hooks.json`. Determine what mechanism — if any — currently fires at the end of an implementation task. Name the exact point where completion is supposed to happen and does not.

2. Separate the candidate root causes and find evidence for each rather than picking one by intuition:
   - The skill exists but its description never triggers at end-of-implementation.
   - The trigger depends on the user remembering a command.
   - The plan file path is unknown to the session by the time work finishes.
   - The rule lives in user-local config that plugin installs never receive.
   Cite file and line for each claim.

3. Check what a plugin user actually gets. Diff the shipped plugin surface (`kit/plugins/plan-agent/**`, registered in `.claude-plugin/marketplace.json`) against what this repo has locally. Any part of the current completion flow that lives outside the plugin directory is a confirmed plugin-user gap.

4. Evaluate mechanisms against all four failure modes before recommending one. A recommendation that solves one and worsens another is not a fix:
   - **Silent skip** — plan stays `todo`/`in-progress` with no signal (today's bug).
   - **False completion** — marked `completed` when acceptance criteria are not met.
   - **Noisy prompts** — a hook nagging on every stop, when no plan is in play.
   - **Plugin-user gap** — works locally, not for marketplace installs.

5. Check: does the recommended mechanism know *which* plan file is in play and *whether its acceptance criteria are actually met*, without asking the model to self-attest? If it cannot answer both, it will produce false completions — say so and pick differently.
</thinking>

Investigate the completion gap described above, then produce an implementation plan for the fix by invoking `/plan-agent:implementation-plan`.

Do not write or apply the fix. Do not modify any existing skill, hook, or plan. Creating the new plan document is the only write this task authorizes — it is the deliverable.

The plan must:
- State the diagnosed root cause with file and line citations, not a hypothesis.
- Recommend one mechanism (hook, skill change, both, or something else the investigation surfaces) and justify it against all four failure modes above, including what it deliberately does not solve.
- Scope every change inside `kit/plugins/plan-agent/**` so marketplace installs receive it, or explicitly justify any file outside that path.
- Include the `marketplace.json` version bump and `kit/plugins/plan-agent/CHANGELOG.md` entry as steps.
- Give each step an action, a *why*, and a *verify*.
- Include a Tests section — Tier 1 if the steps touch hook scripts or other executable source, Tier 2 if they only touch Markdown skill files.
- Put anything the investigation surfaces that is out of scope into Next Steps, not Steps.

Output requirements:
- Format: brief investigation findings in prose with file:line citations, then the plan produced by `/plan-agent:implementation-plan`.
- Length: findings under 300 words. The plan is as long as it needs to be.
- Tone: technical, direct. Report what the code does, not what it should do.

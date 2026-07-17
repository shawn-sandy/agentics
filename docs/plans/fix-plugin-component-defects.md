---
status: todo
type: fix
created: 2026-07-16
repo-name: agentics
effort: medium
glance: Seven plan-reviewer agents meant to be read-only run with full write access because they use the skills key allowed-tools instead of the agents key tools, and the marketplace proves the contrast — product-plans used the right key and is correctly scoped. This fixes that, plus four commands that have drifted from the skills they duplicate and four hooks that fire on every edit in every session.
---

# Plan: Fix the agent, command, and hook defects the skill-focused review missed

## Objective

Fix the non-skill plugin components: restore the intended tool scoping on the seven `plan-reviewer-*` agents (and two `team-defaults` agents), collapse the four `plan-interview` commands that have drifted from the skills they duplicate into thin delegators, and stop the four `plan-agent` hooks from spawning a process on every file edit in every session.

## Context

A review on 2026-07-16 covered all 59 skills across the 13 marketplace plugins and produced three plans, but examined none of the 18 commands, 22 agents, or 6 hooks. This plan covers that gap. The findings are ranked below by blast radius, and the first is a live defect, not a style issue.

**The agents key is `tools:`, not `allowed-tools:`.** All seven `plan-agent/agents/plan-reviewer-*.md` files declare `allowed-tools: Read, Glob, Grep, Bash`, which is the *skills* key. On an agent it is not recognised, so the declaration is silently ignored and the agent inherits everything. The contrast is visible inside this very marketplace: `product-plans/agents/product-reviewer-*.md` declare `tools: Read, Glob, Grep, Bash(git *)` and are correctly scoped. Confirmed empirically from a live session's agent registry, where `plan-agent:plan-reviewer-architecture` lists as "(Tools: All tools)" while `product-plans:product-reviewer-pm` lists as "(Tools: Read, Glob, Grep, Bash(git *))". Both clusters intended the same restriction; only one got it. The consequence is seven agents whose whole job is to *read a plan and report findings* holding Write, Edit, and Bash against the repo.

A trap worth naming explicitly: the maintainer's memory records that `allowed-tools` is valid in skill files and that an IDE linter flagging it is wrong. That note is correct — for skills. It does not transfer to agents, and it is the single most likely reason this finding gets waved off. The key is valid in one component type and inert in the other.

**Two `team-defaults` agents are misconfigured.** `css-generator.md` declares `MultiEdit`, a tool that no longer exists in Claude Code, and has no `model:`. `code-comments.md` declares no `tools:` at all, so a JSDoc writer inherits Bash, WebFetch, and Agent; its `description` is a capability blurb with no trigger phrase, so it will not reliably activate; and its `name: ts-commenter` does not match its filename.

**Four `plan-interview` commands have drifted from their own skills.** `deep-grill.md`, `plan-status.md`, and `documenting-plans.md` do not invoke their same-named skills — they restate the whole workflow, and the copies are already 20, 153, and 383 lines apart from the skill they duplicate. The behaviours differ concretely: `deep-grill`'s command resolves the plan from `$ARGUMENTS`, its skill from "a path in the user's message". `plan-interview.md` (397 lines) re-implements the router that also lives in its 594-line skill. Two behaviours, one name, no way for a user to know which they invoked. The repo already ships the correct shape: `plan-to-html.md` is frontmatter plus a single `Skill(...)` call.

**Four hooks fire on every file edit.** All four `plan-agent/hooks.json` PostToolUse entries match `Write|Edit|MultiEdit`, so every edit in every session spawns four processes to discover the file is not a plan. `hooks/build-index.sh:36` compounds it: `find_templates_dir()` walks all of `~/.claude/plugins` and the project root on each plan write, unbounded. Separately `validate-plan-filename.py` matches only `Write|Edit`, so `MultiEdit` bypasses the filename gate entirely — an inconsistency in the opposite direction.

Out of scope, deferred to Next Steps: consolidating `plan-agent`'s 8 reviewer agents down to ~5 and delegating the ux/accessibility lenses to `product-plans`' equivalents. That removes agents users may reference and is a MAJOR-bump decision, consistent with the cleanup-first sequencing already agreed.

## Files

- `kit/plugins/plan-agent/agents/plan-reviewer-architecture.md` (modified) — `allowed-tools:` becomes `tools:`
- `kit/plugins/plan-agent/agents/plan-reviewer-completeness.md` (modified) — same
- `kit/plugins/plan-agent/agents/plan-reviewer-testability.md` (modified) — same
- `kit/plugins/plan-agent/agents/plan-reviewer-risk.md` (modified) — same
- `kit/plugins/plan-agent/agents/plan-reviewer-conventions.md` (modified) — same
- `kit/plugins/plan-agent/agents/plan-reviewer-ux.md` (modified) — same
- `kit/plugins/plan-agent/agents/plan-reviewer-accessibility.md` (modified) — same
- `kit/plugins/team-defaults/agents/css-generator.md` (modified) — drop phantom MultiEdit, add model
- `kit/plugins/team-defaults/agents/code-comments.md` (modified) — add tools, rewrite description, rename file
- `kit/plugins/plan-interview/commands/deep-grill.md` (modified) — collapse to a Skill delegator
- `kit/plugins/plan-interview/commands/plan-status.md` (modified) — collapse to a Skill delegator
- `kit/plugins/plan-interview/commands/documenting-plans.md` (modified) — collapse to a Skill delegator
- `kit/plugins/plan-interview/commands/plan-interview.md` (modified) — collapse to a Skill delegator
- `kit/plugins/social-media-tools/commands/digest.md` (modified) — fix the reference to a command that does not exist
- `kit/plugins/plan-agent/hooks/hooks.json` (modified) — gate on path before spawning
- `kit/plugins/plan-agent/hooks/build-index.sh` (modified) — resolve templates via CLAUDE_PLUGIN_ROOT; bundled hook copy
- `scripts/build-plans-index.sh` (modified) — same change; the workflow copy, byte-identical today
- `docs/plans/build-index.sh` (modified) — same change; the rebuild-hook fallback, byte-identical today
- `kit/plugins/plan-agent/hooks/validate-plan-filename.py` (modified) — match MultiEdit
- `tests/plugins/test-agent-frontmatter.sh` (new) — the objective-verification test
- `tests/plugins/test-command-delegation.sh` (new) — asserts commands delegate rather than restate
- `.claude-plugin/marketplace.json` (modified) — bumps for plan-agent, team-defaults, plan-interview, social-media-tools

## Steps

1. Rename the frontmatter key from `allowed-tools:` to `tools:` in all seven `kit/plugins/plan-agent/agents/plan-reviewer-*.md` files, keeping the declared value and tightening `Bash` to `Bash(git *)` to match the `product-plans` cluster. Why: on an agent `allowed-tools:` is not a recognised key, so the intended restriction is silently discarded and seven read-only plan reviewers currently hold Write, Edit, and unrestricted Bash against the repo — `product-plans` proves the correct key works, because its reviewers are scoped in the live registry while these list as "All tools". Verify: start a session with the plugins loaded and confirm the agent registry lists each `plan-agent:plan-reviewer-*` with its scoped tool list rather than "(Tools: All tools)" — the registry, not the file, is the proof, since the file already looked correct while being ignored.
2. Fix `kit/plugins/team-defaults/agents/css-generator.md` by removing `MultiEdit` from its tool list, replacing it with `Read, Write, Edit, Bash, WebFetch`, and adding an explicit `model:`. Why: `MultiEdit` no longer exists in Claude Code, so the agent is granted a phantom tool and any behaviour depending on it silently degrades, while an absent `model:` leaves tier selection to inheritance rather than intent. Verify: the agent's registry entry lists no `MultiEdit`, and `grep -rn MultiEdit kit/plugins/` returns no agent frontmatter.
3. Fix `kit/plugins/team-defaults/agents/code-comments.md` by adding `tools: Read, Edit, Glob, Grep`, rewriting the `description` to lead with a trigger phrase such as "Use when the user asks to add or improve JSDoc on TypeScript files", and renaming the file to `ts-commenter.md` to match its `name:` field. Why: with no `tools:` a JSDoc writer inherits Bash, WebFetch, and Agent; a description that states capability without a trigger will not reliably activate, which is the difference between an agent that exists and one that gets used; and a filename that disagrees with `name:` makes the agent hard to locate. Verify: the registry lists `ts-commenter` with exactly the four scoped tools, and its description reads as a WHEN rather than a WHAT.
4. Collapse `deep-grill.md`, `plan-status.md`, `documenting-plans.md`, and `plan-interview.md` under `kit/plugins/plan-interview/commands/` to the shape `plan-to-html.md` already uses — frontmatter plus a single `Skill(skill: "plan-interview:<name>", args: "$ARGUMENTS")` call — preserving each file's existing `description` and `argument-hint`. Why: these four restate their skill's workflow instead of invoking it and have already drifted 20, 153, 383, and 397 lines respectively, so the same name produces different behaviour depending on whether the user typed the command or triggered the skill, and every future edit must be made twice or silently diverge further. Verify: each command file is under 15 lines, contains exactly one `Skill(` call naming its own skill, and `bash tests/plugins/test-command-delegation.sh` passes.
5. Fix the broken reference at `kit/plugins/social-media-tools/commands/digest.md:49`, which tells the user to run `/social-media-tools:share-code` — a command that does not exist, since `share-code` is skill-only — by pointing at the skill or removing the line. Why: an instruction naming a non-existent command is a dead end for the user at the exact moment the digest has finished its work and is handing off. Verify: every `/social-media-tools:<name>` string in the plugin's commands resolves to a real file under `commands/`.
6. Gate the four PostToolUse entries in `kit/plugins/plan-agent/hooks/hooks.json` on the plans-directory path before spawning, or merge them into one dispatcher, and change `validate-plan-filename.py`'s matcher to `Write|Edit|MultiEdit`. Why: today every file edit in every session spawns four processes purely to discover the file is not a plan, which is a tax on unrelated work — while the filename gate matches only `Write|Edit`, so `MultiEdit` slips past it, making the hook set simultaneously too eager and too narrow. Verify: editing a file outside the plans directory spawns no plan hook (confirm via hook logs or timing), writing a badly-named plan via `MultiEdit` is still blocked, and writing a well-named plan still triggers the render and index rebuild.
7. Replace `find_templates_dir()` with a direct resolution against `$CLAUDE_PLUGIN_ROOT/templates` in all three copies of the index builder in lockstep — `kit/plugins/plan-agent/hooks/build-index.sh:36` (the bundled hook), `scripts/build-plans-index.sh` (the workflow copy), and `docs/plans/build-index.sh` (the rebuild-hook fallback) — confirming first that they are still byte-identical and treating any divergence as a finding to report rather than silently reconcile. Why: it currently walks all of `~/.claude/plugins` and the project root on every plan write, which is unbounded work scaling with the user's installed-plugin count and repo size, and `$CLAUDE_PLUGIN_ROOT` is the supported way to resolve plugin-relative paths — but the three copies are byte-identical today (all md5 `0258e397`), so fixing only the bundled hook would leave CI and fallback installations running the defect while the copies silently diverge, which is worse than the original problem because divergence hides it. Verify: `md5 kit/plugins/plan-agent/hooks/build-index.sh scripts/build-plans-index.sh docs/plans/build-index.sh` reports one identical hash across all three, none contains `find_templates_dir`, the index still rebuilds on a plan write, and `bash docs/plans/build-index.sh` still succeeds standalone.
8. Add `tests/plugins/test-agent-frontmatter.sh` and `tests/plugins/test-command-delegation.sh`, then bump `version` in `.claude-plugin/marketplace.json` for `plan-agent`, `team-defaults`, `plan-interview`, and `social-media-tools` with a matching `CHANGELOG.md` entry each, treating the agent tool-scoping fix as a PATCH and the `ts-commenter` rename as MINOR. Why: the agent-frontmatter defect was invisible precisely because nothing asserted the key, so a test is what stops it recurring on the next agent added, and `scripts/check-plugin-versions.mjs` fails any PR that changes a plugin without raising its marketplace version. Verify: both new suites pass, and `node scripts/check-plugin-versions.mjs` exits 0.

## Tests

Tier 1 — This plan changes application code (it modifies agent, command, and hook definitions)
- Objective: no agent in any marketplace plugin declares the invalid `allowed-tools:` key, and every agent declares an explicit `tools:` — the exact defect this plan fixes, which was invisible because nothing asserted it. File: `tests/plugins/test-agent-frontmatter.sh`; Type: smoke; Asserts: for every `kit/plugins/*/agents/*.md`, frontmatter contains `tools:` and not `allowed-tools:`, declares a `model:`, and names no tool outside the known-valid set (catching phantom tools like `MultiEdit`); Run: `bash tests/plugins/test-agent-frontmatter.sh`
- Unit: commands delegate to skills rather than restating them. File: `tests/plugins/test-command-delegation.sh`; Targets: `kit/plugins/plan-interview/commands/*.md`; Key cases: each of the five collapsed commands is under 15 lines and contains exactly one `Skill(` call; a fixture command that restates a workflow fails
- Integration: every `/plugin:command` string referenced anywhere in the marketplace resolves to a real file. File: `tests/plugins/test-command-delegation.sh`; Targets: cross-references in commands and skills; Key cases: `digest.md`'s reference resolves, and a fixture naming a non-existent command fails

## Acceptance Criteria

- [ ] All seven `plan-reviewer-*` agents list their scoped tools in the live agent registry, not "All tools"
- [ ] No agent in any marketplace plugin uses the `allowed-tools:` key
- [ ] No agent declares `MultiEdit` or any other non-existent tool
- [ ] `ts-commenter` has scoped tools, a trigger-led description, and a filename matching its `name:`
- [ ] The four drifted `plan-interview` commands are each under 15 lines and delegate via a single `Skill(` call
- [ ] Every `/plugin:command` reference in the marketplace resolves to a real command file
- [ ] Editing a file outside the plans directory spawns no `plan-agent` hook
- [ ] A badly-named plan written via `MultiEdit` is blocked by the filename gate
- [ ] All three copies of `build-index.sh` resolve templates without walking the filesystem, and remain byte-identical to each other
- [ ] `node scripts/check-plugin-versions.mjs` exits 0

## Verification

Start a session with the 13 marketplace plugins loaded and read the agent registry: every `plan-agent:plan-reviewer-*` must list its scoped tool set rather than "(Tools: All tools)". This is the plan's central proof and it cannot be done by reading the files, because the files already looked correct while being silently ignored — the registry is the only place the defect was visible and the only place the fix is. Then run `bash tests/plugins/test-agent-frontmatter.sh` and `bash tests/plugins/test-command-delegation.sh`, plus the full `tests/plugins/` suite. Invoke `/plan-interview:deep-grill <path>` and the `deep-grill` skill on the same plan and confirm they now produce identical behaviour rather than resolving their argument differently. Edit a file outside `docs/plans/` and confirm no plan hook fires; write a badly-named plan via `MultiEdit` and confirm the filename gate blocks it. Finally confirm `node scripts/check-plugin-versions.mjs` exits 0.

## Next Steps

- Consolidate plan-agent's 8 reviewer agents and delegate the duplicated lenses to product-plans
  A MAJOR-bump decision deferred from this plan, consistent with the cleanup-first sequencing.
  ```text
  In the agentics repo, plan-agent ships 8 review agents (plan-reviewer-architecture,
  -completeness, -testability, -risk, -conventions, -ux, -accessibility, plus
  agent-review-plan) and product-plans ships 7 (product-reviewer-pm, -lead-developer,
  -ux-designer, -frontend-engineer, -accessibility-expert, -security-expert, plus
  agent-product-plans). A review found the product-plans cluster justifies its count —
  distinct roles, scoped tools, clean output schemas — while plan-agent's overlaps
  internally (architecture/conventions/completeness) and duplicates product-plans
  outright on two lenses: plan-reviewer-ux vs product-reviewer-ux-designer, and
  plan-reviewer-accessibility vs product-reviewer-accessibility-expert, differing only
  in WCAG 2.1 vs 2.2. Assess consolidating plan-agent's reviewers to ~5 and having its
  review team delegate the ux and accessibility lenses to the product-plans agents
  rather than maintaining a drifting fork. This removes agents users may reference by
  name, so weigh the breaking change. Recommend a target set with reasoning.
  ```

- Decide whether the three git-agent background commands should collapse into one
  Lower priority; they are thin but earn their keep, since run_in_background is not otherwise user-reachable.
  ```text
  In the agentics repo, five *-bg commands are thin Agent(run_in_background:true)
  dispatchers: git-agent's commit-bg, pr-bg, and ship-bg, plus product-plans-bg and
  review-plan-bg. They justify existing because run_in_background is not otherwise
  reachable by a user. However the three git-agent ones are near-identical. Assess
  collapsing them into a single /git-agent:bg <commit|pr|ship> command, weighing the
  loss of discoverability (three obvious command names versus one with an argument)
  against the duplication. Also: product-plans-bg, review-plan-bg, and
  skill-reviewer:check-description lack argument-hint frontmatter despite taking a
  required path argument — add it. Recommend collapse or keep, with reasoning.
  ```

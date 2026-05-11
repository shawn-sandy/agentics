---
status: draft
created: 2026-05-11
type: standard
---

# Plan: Optimize plugin skill descriptions and package the optimizer as a skill

## Context

An audit of all 28 `SKILL.md` files under `kit/plugins/` found that descriptions range from 131 to 315 characters, with 22 of 28 exceeding 200 chars. The official best-practices guide caps `description` at 1024 chars, but emphasizes conciseness because all skills' metadata is pre-loaded into the system prompt at startup — every character competes with conversation context across the entire library.

In the previous conversation turn an optimization prompt was drafted (target ≤160 chars, third-person, "Use when…" trigger phrasing, no negative scope clauses). The user wants that prompt **executed** against the 28 skills, **refined** based on what real rewrites reveal, and then **packaged** as a reusable skill in the existing `skill-reviewer` plugin (alongside `reviewing-skills`, `planning-skills`, `auditing-allowed-tools`).

The new skill becomes the canonical tool any future plugin author runs before shipping — preventing description bloat at the source.

---

## Objective

Trim every `kit/plugins/*/skills/*/SKILL.md` description to ≤160 chars while preserving discovery accuracy, refine the optimization prompt based on what those rewrites surface, and ship the refined prompt as a new `optimizing-descriptions` skill inside `kit/plugins/skill-reviewer/` (MINOR bump: 1.6.2 → 1.7.0).

---

## Steps

### 1. Pilot the prompt on 3 representative skills

Run the drafted optimization prompt by hand against three skills picked to surface different failure modes:

- `react-perf-analyzer/SKILL.md` (315 chars — worst offender, heavy negative-scope clause)
- `auditing-allowed-tools/SKILL.md` (306 chars — repeats triggers three different ways)
- `commit-agent/SKILL.md` (131 chars — already good; confirms the prompt doesn't *worsen* short descriptions)

Do **not** commit the rewrites yet — they are diagnostic.

**Why:** The prompt becomes the skill body; flaws baked in here propagate to every future use. Three pilots cover the full range (verbose / repetitive / already-tight).

**Verify:** All three rewrites are ≤160 chars, start with the capability or "Use when…", contain at least one activation trigger verb, and remain third-person. The already-good `commit-agent` description is either unchanged or improved — not regressed.

### 2. Refine the optimization prompt based on pilot output

Update the prompt's rules and examples to fix any failure mode the pilot revealed. Likely candidates:

- Add an explicit rule about preserving the *most discriminating* trigger phrase when multiple are present
- Add a "skip if already ≤160 chars and trigger-clear" early exit
- Add a worked example for the "long with negative-scope clause" case

**Why:** The refined prompt is what gets shipped — and what every future plugin author will use. Better to iterate now than re-release the skill.

**Verify:** Re-run the refined prompt on the same three pilots. Each output is at least as good as the first pass on the two long ones, and the short one is preserved.

### 3. Apply refined prompt to the remaining 25 SKILL.md files

Rewrite the `description:` frontmatter field in each of the 25 remaining SKILL.md files under `kit/plugins/`. Edit in place using the `Edit` tool.

For each skill, if the current description contains a negative-scope clause (e.g. "Does NOT cover X — use Y for that"), relocate that information into the SKILL.md body under a new `## When not to use` section (after `## Overview`) before rewriting the description. The body edit and the description rewrite are two edits per skill.

Files to modify (full list from audit):

- `skill-reviewer/skills/planning-skills/SKILL.md` (305)
- `skill-reviewer/skills/reviewing-skills/SKILL.md` (280)
- `agentic-plugin-dev/skills/plugin-creator/SKILL.md` (286)
- `agentic-plugin-dev/skills/plugin-validator/SKILL.md` (288)
- `agentic-plugin-dev/skills/plugin-manager/SKILL.md` (156)
- `agent-reviewer/skills/reviewing-agents/SKILL.md` (281)
- `code-review/skills/code-review-agent/SKILL.md` (173)
- `wcag-compliance-reviewer/skills/wcag-compliance-reviewer/SKILL.md` (161)
- `marketplace-builder/skills/building-marketplaces/SKILL.md` (256)
- `agent-creator/skills/generating-agents/SKILL.md` (260)
- `memory-tools/skills/path-rules-advisor/SKILL.md` (256)
- `memory-tools/skills/agentic-memory-doctor/SKILL.md` (241)
- `git-agent/skills/pr-agent/SKILL.md` (147) — keep if unchanged
- `git-agent/skills/branch-agent/SKILL.md` (151)
- `git-agent/skills/ship/SKILL.md` (207)
- `plan-interview/skills/plan-status/SKILL.md` (244)
- `plan-interview/skills/deep-grill/SKILL.md` (245)
- `plan-interview/skills/plan-interview/SKILL.md` (170)
- `plan-interview/skills/documenting-plans/SKILL.md` (266)
- `code-testing-agent/skills/running-tests/SKILL.md` (226)
- `code-testing-agent/skills/reviewing-tests/SKILL.md` (235)
- `code-testing-agent/skills/tdd-loop/SKILL.md` (273)
- `code-testing-agent/skills/code-testing-agent/SKILL.md` (263)
- `code-testing-agent/skills/tdd-fix/SKILL.md` (225)
- `code-simplifier/skills/code-simplifier/SKILL.md` (223)

(`commit-agent` already covered in step 1.)

**Why:** Completes the optimization pass across the entire marketplace. Moving negative-scope clauses into the body (rather than dropping them) preserves the cross-skill collision guidance that the original authors intended, while clearing the description budget for capability + trigger only.

**Verify:** Re-run the description audit (`grep -r "^description:" kit/plugins/*/skills/*/SKILL.md` with char counts). Every entry ≤160 chars; none lost their "Use when…" trigger. Any skill whose description previously had a "Does NOT…" clause now has a `## When not to use` section in its SKILL.md body containing that information.

### 4. Trigger-fidelity spot check on 5 random optimized skills

Pick 5 skills at random from step 3's set. For each, read the **full SKILL.md body** and confirm the trimmed description still contains the keywords that would naturally trigger activation for that skill's documented purpose.

**Why:** Char-count audits are mechanical — they don't catch a rewrite that's short but removes the very trigger that made the skill discoverable. The body is ground truth for what the description should activate on.

**Verify:** For each of the 5 picks, the rewritten description contains at least one verb/noun that matches the SKILL.md's stated activation triggers. If any fail, return to step 2.

### 5. Scaffold the new `optimizing-descriptions` skill

Create `kit/plugins/skill-reviewer/skills/optimizing-descriptions/SKILL.md` with:

- Frontmatter matching skill-reviewer conventions: `name`, `description` (≤160 chars, "Use when…" style), `allowed-tools: AskUserQuestion, Read, Edit, Bash, Glob`
- Body following the skill-reviewer template: `## Overview` → `Follow these steps exactly.` → `## Table of Contents` → numbered `## Step N: …` sections
- Embed the refined optimization prompt from step 2 as the operative instruction
- Reference the official best-practices URL (https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices) for the source of truth
- Include a worked example (before/after) drawn from the step-3 rewrites
- Body length target: 100–200 lines (matches skill-reviewer sibling skills)

**Why:** Packages the refined prompt as a reusable, discoverable tool for the rest of the marketplace and downstream users. Eats its own dog food — its own description must be ≤160 chars.

**Verify:** The new SKILL.md exists, has valid frontmatter, its `description` is ≤160 chars, and a manual read-through confirms the body could be followed end-to-end by another Claude instance with no extra context.

### 6. Update CHANGELOG and bump skill-reviewer version

In this order:

1. Add a `## [1.7.0] - 2026-05-11` entry to `kit/plugins/skill-reviewer/CHANGELOG.md` with `### Added` listing the new skill, and `### Changed` listing the description trims across the marketplace.
2. Update `.claude-plugin/marketplace.json`: set `version` to `1.7.0` on the `skill-reviewer` entry.
3. Do NOT add `version` to `plugin.json` — repo convention forbids it for relative-path plugins.

**Why:** Per `marketplace.md` rules, a new skill is a MINOR bump; CHANGELOG must mirror the version entry; version lives only in `marketplace.json`.

**Verify:** `grep version kit/plugins/skill-reviewer/.claude-plugin/plugin.json` returns no match. `marketplace.json` shows `"version": "1.7.0"` on the skill-reviewer entry. CHANGELOG top entry is `## [1.7.0] - 2026-05-11`.

### 7. Rename this plan file to a descriptive kebab-case name

Run `/plan-hygiene` (or rename manually) — the current filename `bright-sprouting-stream.md` is a random placeholder. A descriptive target name: `optimize-skill-descriptions-and-package-optimizer.md`.

**Why:** Project rule `.claude/rules/plan-hygiene.md` blocks commits with random plan filenames.

**Verify:** `ls docs/plans/` no longer shows `bright-sprouting-stream.md`; the renamed file exists with the same content.

---

## Verification

End-to-end checks before considering the plan complete:

- **Char-count audit passes:** `awk -F: '/^description:/ {print length($0)-13, FILENAME}' kit/plugins/*/skills/*/SKILL.md` shows all values ≤160.
- **Activation-trigger preserved:** every description contains "Use when" OR leads with a capability verb (per spot-check in step 4).
- **New skill works:** load skill-reviewer locally with `claude --plugin-dir ~/devbox/agentics/kit/plugins/skill-reviewer`, ask "optimize this skill description: <pasted long description>", confirm `optimizing-descriptions` activates and emits a ≤160-char rewrite.
- **Versioning consistent:** `marketplace.json` shows `1.7.0`, `plugin.json` has no `version`, CHANGELOG has matching dated entry.
- **Plan file renamed:** no random-name plan files remain in `docs/plans/`.
- **All changes committed together:** one commit (or one PR) bundles the 28 description edits, the new skill, the CHANGELOG/version bump, and the renamed plan file — per project convention "Always include the plan file in commits for plugin changes".

---

## Decisions locked in

- **Target char cap:** ≤160 characters for every description.
- **Negative-scope clauses:** drop from description, relocate to a new `## When not to use` section in the SKILL.md body. The optimization prompt (step 2) must encode both rules explicitly so the packaged skill applies them consistently.

---

## Next steps (out of scope)

- Extend `optimizing-descriptions` to optimize **command** and **agent** description fields (same pattern, different file shapes).
- Add a hook that runs the optimizer on any `SKILL.md` write and warns if the new description exceeds 160 chars.
- Build a small evaluation suite under `tests/fixtures/` with paired (verbose → expected) descriptions to regression-test future prompt revisions.


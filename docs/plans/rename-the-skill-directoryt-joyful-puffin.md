---
status: completed
modified: 2026-05-14
type: refactor
created: 2026-05-14
---

# Plan: Rename `product-plan-review-panel` → `product-plans` and tighten skill triggers

## Context

The `product-plan-review-panel` plugin (added in PR #119, v1.0.0) ships a
single skill whose `description` overlaps heavily with the existing
`plan-interview` skill — both advertise "stress-test, validate, critique
a plan." When trigger phrases overlap, Claude Code's skill router can
auto-activate the wrong one. The user wants the plugin (and its inner
skill) renamed to `product-plans`, and the skill description rewritten
so its triggers are unique vs. `plan-interview` and `code-review`.

Because the plugin's external `name` is what users type into
`/plugin install`, renaming is a **breaking change** for anyone who
installed v1.0.0. The marketplace entry must bump to a new major.

## Objective

Rename the plugin directory, the inner skill directory, and every
identifier that points at `product-plan-review-panel` to `product-plans`.
Rewrite the skill `description` to use panel/team-specific verbs that do
not collide with `plan-interview` or `code-review`. Bump the marketplace
version to `2.0.0` and record the breaking change in the CHANGELOG.

## Files to modify

Source moves (single `git mv` each):

- `kit/plugins/product-plan-review-panel/` → `kit/plugins/product-plans/`
- `kit/plugins/product-plans/skills/product-plan-review-panel/` → `kit/plugins/product-plans/skills/product-plans/`

Files whose contents must be edited:

- `kit/plugins/product-plans/.claude-plugin/plugin.json` — `name`, `homepage`
- `kit/plugins/product-plans/skills/product-plans/SKILL.md` — `name:` field + rewrite `description:`
- `kit/plugins/product-plans/README.md` — plugin name, paths, install command
- `kit/plugins/product-plans/CHANGELOG.md` — add `2.0.0` entry (breaking rename)
- `kit/plugins/product-plans/agents/product-reviewer-pm.md`
- `kit/plugins/product-plans/agents/product-reviewer-lead-developer.md`
- `kit/plugins/product-plans/agents/product-reviewer-ux-designer.md`
- `kit/plugins/product-plans/agents/product-reviewer-frontend-engineer.md`
- `kit/plugins/product-plans/agents/product-reviewer-accessibility-expert.md`
- `.claude-plugin/marketplace.json` — entry `name`, `source.path`, bump `version` to `2.0.0`
- `CLAUDE.md` — reference-implementations table row
- `.claude/settings.local.json` — any literal `product-plan-review-panel` strings

Files **not** to modify (historical artifacts):

- `docs/plans/create-product-plan-review-panel-plugin.md`
- `docs/plans/create-product-plan-review-panel-plugin-revised.md`

## Proposed new skill description

```yaml
description: "Use when the user asks for a cross-functional panel review, multi-role critique, or PM/Dev/UX/Frontend/Accessibility team review of a product plan, PRD, feature proposal, or implementation plan."
```

Rationale: drops the overlapping verbs (`stress-test`, `validate`,
`critique` alone, `review`) that `plan-interview` and `code-review`
own, and adds discriminators that those skills don't claim:
`panel`, `multi-role`, `cross-functional`, and the five explicit role
names (PM, Dev, UX, Frontend, Accessibility).

## Steps

1. **Rename plugin and skill directories with `git mv`** — *Why:* preserves git history for both directories and keeps the rename atomic. *Verify:* `git status --porcelain` shows renames (`R  old → new`) for both paths and `ls kit/plugins/product-plans/skills/product-plans/SKILL.md` succeeds.

2. **Update `kit/plugins/product-plans/skills/product-plans/SKILL.md`** — change `name: product-plan-review-panel` to `name: product-plans` and replace the `description:` line with the new panel/team-specific phrasing above. *Why:* the skill folder name must match `name:`, and the description is what gates auto-activation. *Verify:* `grep -E '^(name|description):' kit/plugins/product-plans/skills/product-plans/SKILL.md` shows the new values; `grep "stress-test\|critique" kit/plugins/product-plans/skills/product-plans/SKILL.md` returns nothing on the frontmatter lines.

3. **Update `kit/plugins/product-plans/.claude-plugin/plugin.json`** — set `name` to `product-plans` and update `homepage` to `https://github.com/shawn-sandy/agentics/tree/main/kit/plugins/product-plans`. *Why:* `name` in `plugin.json` is the plugin identifier; `homepage` per the project convention must point at the plugin's directory. *Verify:* `jq -r '.name, .homepage' kit/plugins/product-plans/.claude-plugin/plugin.json` prints `product-plans` and the new URL.

4. **Update `.claude-plugin/marketplace.json`** — change the matching plugin entry's `name` to `product-plans`, `source.path` to `kit/plugins/product-plans`, and bump `version` from `1.0.0` to `2.0.0`. *Why:* marketplace.json is the registration entry users see; renaming the install identifier is a breaking change and requires a major bump per `.claude/rules/marketplace.md`. *Verify:* `jq '.plugins[] | select(.name=="product-plans") | {name, path: .source.path, version}' .claude-plugin/marketplace.json` shows all three fields correct, and no entry with the old name remains.

5. **Update `kit/plugins/product-plans/CHANGELOG.md`** — prepend a `## 2.0.0` entry noting: breaking rename of plugin and skill from `product-plan-review-panel` to `product-plans`, and the description rewrite for trigger uniqueness. *Why:* CHANGELOG is the user-facing record of the breaking change. *Verify:* `head -20 kit/plugins/product-plans/CHANGELOG.md` shows the `2.0.0` heading at the top with the rename note.

6. **Update `kit/plugins/product-plans/README.md`** — replace every literal `product-plan-review-panel` with `product-plans` (plugin name, install commands, paths, headings). *Why:* the README is the primary install/usage doc. *Verify:* `grep -c "product-plan-review-panel" kit/plugins/product-plans/README.md` returns `0`.

7. **Update the five `kit/plugins/product-plans/agents/product-reviewer-*.md` files** — replace any `product-plan-review-panel` reference with `product-plans` (subagent prompts reference the parent skill in some files). *Why:* role prompts cite the parent skill or plugin by name in places. *Verify:* `grep -rn "product-plan-review-panel" kit/plugins/product-plans/agents/` returns no results.

8. **Update `CLAUDE.md` and `.claude/settings.local.json`** — change the reference-implementations table row in `CLAUDE.md` to `product-plans`, and update any literal `product-plan-review-panel` strings in `.claude/settings.local.json`. *Why:* `CLAUDE.md` is read into every session's context; stale settings entries can grant or block tools by the wrong name. *Verify:* `grep -n "product-plan-review-panel" CLAUDE.md .claude/settings.local.json` returns no results.

9. **Repo-wide sweep for stragglers** — *Why:* catches any reference missed by steps 2–8 (excluding the two historical plan files explicitly out of scope). *Verify:* `grep -rn "product-plan-review-panel" . --exclude-dir=node_modules --exclude-dir=.git --include='*.md' --include='*.json' | grep -v 'docs/plans/create-product-plan-review-panel'` returns no results.

10. **Bump skill `description` review against neighbors** — diff the new description against `kit/plugins/plan-interview/skills/plan-interview/SKILL.md` and `kit/plugins/code-review/skills/code-review/SKILL.md` to confirm no shared trigger verbs remain. *Why:* the whole point of the rewrite is non-overlapping triggers; a quick diff catches accidental overlap. *Verify:* `grep -E '^description:' kit/plugins/{product-plans,plan-interview,code-review}/skills/*/SKILL.md` — confirm the three descriptions share no common activation verb (e.g., `panel` / `multi-role` appear only in `product-plans`; `interview` / `stress-test` only in `plan-interview`; `code review` / `pull request` only in `code-review`).

## Verification

End-to-end:

1. Run `jq -e '.plugins[] | select(.name=="product-plans" and .version=="2.0.0" and .source.path=="kit/plugins/product-plans")' .claude-plugin/marketplace.json` — must exit `0`.
2. Run `claude --plugin-dir ./kit/plugins/product-plans` to load the renamed plugin locally and confirm the skill registers (no "skill name mismatch" warning).
3. In that session, ask: "Run a cross-functional panel review on `docs/plans/<some-plan>.md`" — `product-plans` should activate, not `plan-interview`.
4. Ask: "Stress-test this plan in an interview" — `plan-interview` should still activate (i.e., the rename did not steal its triggers).
5. Run `grep -rn "product-plan-review-panel" . --exclude-dir=.git --exclude-dir=node_modules --include='*.md' --include='*.json'`. Only the two historical files under `docs/plans/` should match.
6. Run `git diff --stat` to confirm the change set matches the file list above.

## Next steps *(optional)*

- Backfill rename in install instructions for users on v1.0.0:
  ```text
  Draft a short migration note for kit/plugins/product-plans/README.md
  (or a top-level MIGRATION.md if the README is already long) explaining
  that users who installed product-plan-review-panel@agentics-kit before
  2026-05-14 must uninstall the old name and install product-plans@agentics-kit.
  Use the same tone as the existing README. No code changes — docs only.
  ```

- Audit other plugin skills for trigger overlap:
  ```text
  Scan every SKILL.md under kit/plugins/*/skills/*/ and produce a table
  of (skill name, activation verbs from `description`). Group skills
  whose verb sets overlap by 2+ shared verbs and recommend the
  discriminator each should add. Out of scope: rewriting them — just
  the audit table and recommendations.
  ```

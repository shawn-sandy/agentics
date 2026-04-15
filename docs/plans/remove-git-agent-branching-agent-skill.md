# Plan: Delete branching-agent skill and update references

> Suggested rename on save: `remove-git-agent-branching-agent-skill.md`

## Context

The `branching-agent` skill in the `git-agent` plugin is being removed. It
encodes a multi-step "fetch + scan branches + prompt + create branch"
workflow that has become enough friction that the user no longer wants it as
part of the plugin. The three remaining skills (`commit-agent`, `pr-agent`,
`ship`) are self-contained and do not invoke `branching-agent`, so removal
does not break any skill chain.

Because this removes a user-facing skill, it is a **MAJOR** version bump
per `.claude/rules/marketplace.md:47`: `2.0.0 → 3.0.0`.

## Objective

Delete the `branching-agent` skill directory and update every live reference
so the plugin, README, CHANGELOG, manifest, and marketplace entry stay
consistent.

## Scope

In scope: delete the skill, update live references in the plugin, bump
version, update CHANGELOG, delete historical plan files that reference the
skill.

## Steps

### 1. Delete the skill directory

- Delete `kit/plugins/git-agent/skills/branching-agent/` (contains only
  `SKILL.md`).
- Why: this is the source file the plugin loads as a skill. Removing the
  directory removes the skill from activation.

### 2. Update `kit/plugins/git-agent/README.md`

Four edits, all to remove live references:

- **Line 7** — delete the bullet:
  `- **branching-agent** — Fetches latest from origin…`
- **Lines 27–43** — delete the entire `### branching-agent` section (heading,
  "Say any of" list, numbered flow, and the "STOPS after branch creation"
  note). The next section (`### commit-agent`) becomes the new first section.
- **Line 98** — change
  ``Use `branching-agent`, `commit-agent`, or `pr-agent` if you only need one step.``
  to
  ``Use `commit-agent` or `pr-agent` if you only need one step.``
- **Lines 111–112** — in the Plugin Structure ASCII tree, remove the
  `│   ├── branching-agent/` and `│   │   └── SKILL.md` lines.

Why: the README is user-facing plugin documentation; leaving stale refs
would advertise a skill that no longer exists.

### 3. Update `kit/plugins/git-agent/CHANGELOG.md`

Prepend a new top entry above `## v2.0.0`:

```markdown
## v3.0.0 — Remove branching-agent skill

- **BREAKING CHANGE:** Removed the `branching-agent` skill. Users who relied
  on automated branch creation should fall back to `git checkout -b` or
  another plugin.
- The remaining skills (`commit-agent`, `pr-agent`, `ship`) are unchanged.
```

Why: historical entries are preserved; a new top entry documents the
breaking removal.

### 4. Update `.claude-plugin/marketplace.json`

In the `git-agent` entry (lines 130–149):

- **Line 137** — bump `"version": "2.0.0"` → `"version": "3.0.0"`.
- **Line 138** — update description to drop "create branches":
  `"Automated git workflow — commit with conventional messages and create PRs"`.

Why: `marketplace.json` is the single source of truth for version on
relative-path plugins; the description must not claim a capability the
plugin no longer provides.

### 5. Update `kit/plugins/git-agent/.claude-plugin/plugin.json`

- **Line 3** — update description to match marketplace.json:
  `"Automated git workflow — commit with conventional messages and create PRs"`.
- **Line 6** — remove the `"branch"` keyword from the `keywords` array.

Why: plugin.json description is shown in install flows and should match
marketplace.json. The `branch` keyword no longer describes the plugin.

### 6. Delete historical plan files that reference the skill

Delete the following four plan files. They are historical planning records
for work on the now-removed skill and will no longer be accurate:

- `docs/plans/staged-yawning-waterfall.md`
- `docs/plans/branch-from-origin-default-without-switching.md`
- `docs/plans/git-agent-new-branch-smarter-slugs.md`
- `docs/plans/fix-issues-found-in-git-agent-new-branch-review.md`

Do **not** delete this plan file (`iridescent-drifting-pixel.md`) — it
documents the removal itself and should be committed alongside the change.

Why: per `CLAUDE.md`, plan files are committed with plugin changes for the
history they capture. Once the skill is gone, these plans describe
non-existent code paths, so they stop earning their keep.

### 7. Verify nothing else broke

Read-only checks — no edits:

- `rg -n "branching-agent" kit/plugins/git-agent/` — should return zero hits
  after Steps 1–3.
- `rg -n "branching-agent" .claude-plugin/marketplace.json` — zero hits.
- `jq '.plugins[] | select(.name == "git-agent") | .version' .claude-plugin/marketplace.json`
  → `"3.0.0"`.
- `claude --plugin-dir ./kit/plugins/git-agent` — load the plugin and confirm
  only `commit-agent`, `pr-agent`, and `ship` skills appear (the
  `.claude/settings.json` hook auto-validates `marketplace.json` JSON
  syntax after Write/Edit, per `CLAUDE.md`).

## Critical files

- `kit/plugins/git-agent/skills/branching-agent/SKILL.md` — deleted
- `kit/plugins/git-agent/README.md` — lines 7, 27–43, 98, 111–112
- `kit/plugins/git-agent/CHANGELOG.md` — prepend v3.0.0 entry
- `.claude-plugin/marketplace.json` — lines 137, 138
- `kit/plugins/git-agent/.claude-plugin/plugin.json` — lines 3, 6
- `docs/plans/staged-yawning-waterfall.md` — deleted
- `docs/plans/branch-from-origin-default-without-switching.md` — deleted
- `docs/plans/git-agent-new-branch-smarter-slugs.md` — deleted
- `docs/plans/fix-issues-found-in-git-agent-new-branch-review.md` — deleted

## Commit message

Per `.claude/rules/marketplace.md:56`:

```text
feat(kit/plugins/git-agent)!: bump version to 3.0.0

Remove the branching-agent skill and all in-plugin references. The
skill-chain (commit-agent, pr-agent, ship) is unchanged.

BREAKING CHANGE: removed branching-agent skill
```

Include the plan file in the same commit (per CLAUDE.md: "Always include the
plan file in commits for plugin changes, even minor ones").

## Next Steps (out of scope)

- Consider whether a replacement branching workflow belongs in another
  plugin (e.g., as a lightweight command) once this removal lands.

## Unresolved questions

None — both open questions were resolved before finalizing this plan.

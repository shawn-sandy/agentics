# Commit: branching-agent Step 0 (Resolve Work Description)

## Context

One file is staged in the working tree on branch `feat/accessibility-list`:

- `kit/plugins/git-agent/skills/branching-agent/SKILL.md`

The edit adds a new **Step 0: Resolve Work Description** that uses
`AskUserQuestion` to prompt the user when `$ARGUMENTS` is empty or contains
only generic phrases ("new branch", "make a branch"). It also adds
`ToolSearch` to the skill's `allowed-tools` frontmatter.

The user requested `commit`. This plan covers only that commit — no
refactors, no unrelated fixes.

## Objective

Create a single conventional commit containing the `SKILL.md` change, using
the repo's existing `feat(kit/plugins/git-agent): …` scope style.

## Steps

1. **Stage the file**
   - `git add kit/plugins/git-agent/skills/branching-agent/SKILL.md`
   - Why: explicit path avoids accidentally including anything else (the repo
     rule is to avoid `git add -A` / `git add .`).

2. **Create the commit**
   - Type: `feat` — this adds new user-visible behavior (the clarification
     prompt), not a bug fix.
   - Scope: `kit/plugins/git-agent` — matches the most recent plugin-feature
     commits (`ad31583`, `4140275`).
   - Subject: `add Step 0 to branching-agent for vague branch requests`
   - Body: short paragraph describing the clarification prompt and the
     `ToolSearch` addition to `allowed-tools`.
   - Co-authored-by trailer per repo convention.

3. **Verify the commit landed**
   - `git status` should show `nothing to commit, working tree clean`.
   - `git log -1 --stat` should show the single file, one commit.

## Commit message (draft)

```
feat(kit/plugins/git-agent): add Step 0 to branching-agent for vague requests

Adds a "Resolve Work Description" step that uses AskUserQuestion to clarify
the branch purpose when $ARGUMENTS is empty or generic (e.g. "new branch",
"make a branch"). Also adds ToolSearch to allowed-tools so the skill can
access deferred tools when needed.

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
```

## Critical files

- `kit/plugins/git-agent/skills/branching-agent/SKILL.md` — the only file
  changed; the diff adds lines 14–25 and updates `allowed-tools` on line 4.

## Verification

- After commit: `git log -1 --stat` shows one file, one insertion block.
- After commit: `git status` is clean.
- Optional sanity check: reload the plugin locally and confirm the skill
  still activates —
  `claude --plugin-dir ~/devbox/agentics/kit/plugins/git-agent`.

## Next Steps (out of scope for this commit)

- **Version bump evaluation** — Adding a new Step to an existing skill is
  arguably a MINOR bump for `git-agent` (currently `2.0.0` in
  `.claude-plugin/marketplace.json`). If yes: bump to `2.1.0`, add a
  `CHANGELOG.md` entry, and include both in a follow-up commit.
- **Branch name mismatch** — `feat/accessibility-list` doesn't describe this
  change. Consider whether this edit belongs on its own branch.
- **`ToolSearch` justification** — Step 0 uses `AskUserQuestion`, not
  `ToolSearch`. If `ToolSearch` isn't actually needed by the skill body,
  consider removing it from `allowed-tools` to keep the permission surface
  minimal.
- **Plan file convention** — `CLAUDE.md` says to include a plan file in
  commits for plugin changes. This plan file (`staged-yawning-waterfall.md`)
  could itself be committed alongside the SKILL.md edit, or renamed to
  something descriptive first (e.g.
  `add-step-0-to-branching-agent.md`).

## Unresolved Questions

1. Should the commit **only** contain `SKILL.md`, or should it also include
   a version bump + CHANGELOG entry + this plan file (renamed)?
2. Is the `ToolSearch` addition intentional, or should it be dropped before
   committing?
3. Is `feat/accessibility-list` the intended branch for this change, or
   should the edit move to a new branch?

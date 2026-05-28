---
status: todo
type: refactor
created: 2026-05-28
repo-name: agentics
---

# Plan: Rename `plan-agent:author` Skill to `planning`

## Context

The `plan-agent` plugin exposes a single skill invoked as `/plan-agent:author <objective>`.
The word **author** is ambiguous — it reads more like a noun (a person who writes) than a
clear command, and doesn't immediately signal "start a planning workflow". The user wants a
name that better communicates what the skill actually does.

**Chosen name: `planning`**

**Invocation after rename:** `/plan-agent:planning <objective>`

`planning` is descriptive and unambiguous — it naturally reads as "I am planning something",
which matches the full §0–§7 plan-authoring workflow the skill runs.

---

## Files to Change

### 1. Rename skill directory
```
kit/plugins/plan-agent/skills/author/  →  kit/plugins/plan-agent/skills/planning/
```
The directory name drives the slash-command segment (`/plan-agent:<dirname>`).

### 2. `kit/plugins/plan-agent/skills/planning/SKILL.md`
- Update the description / any inline text that says `/plan-agent:author` → `/plan-agent:planning`.
- No structural changes to the skill logic.

### 3. `kit/plugins/plan-agent/.claude-plugin/plugin.json`
- Change `"description"` — replace `"/plan-agent:author"` → `"/plan-agent:planning"`.
- Remove `"author"` from `"keywords"` array; add `"planning"`.

### 4. `.claude-plugin/marketplace.json` (plugin entry)
- Change `"description"` — replace `"/plan-agent:author"` → `"/plan-agent:planning"`.
- Remove `"author"` from `"tags"`; add `"planning"`.
- Bump `"version"` from `"0.2.0"` → `"0.3.0"` (renaming a skill invocation is a MINOR bump
  while the package is still pre-1.0, following 0.x semver conventions).

### 5. `CLAUDE.md` (repo root)
- Update the `plan-agent` row in the plugin table:
  replace `` `/plan-agent:author` `` → `` `/plan-agent:planning` ``

### 6. `kit/plugins/plan-agent/CHANGELOG.md`
- Add a `## [0.3.0] – 2026-05-28` section documenting the rename.

### 7. Verify: `hooks.json` and `validate-plan-filename.py`
- Neither file references the skill name directly (confirmed in exploration), but do a
  quick grep to confirm before committing.

---

## Verification

1. `grep -r "plan-agent:author" .` — should return zero results after the rename.
2. `grep -r "plan-agent:planning" .` — should hit each updated file above.
3. `.claude/settings.json` auto-validates `marketplace.json` JSON on every Write/Edit —
   fix any JSON errors before committing.
4. Run `/validate-plugin plan-agent` to confirm plugin structure is intact.
5. Manually invoke `/plan-agent:planning add dark-mode toggle` in a test session to confirm
   the renamed skill triggers correctly.

---

## Commit

```
feat(kit/plugins/plan-agent): rename author skill to planning (v0.3.0)

Skill invocation changes from /plan-agent:author to /plan-agent:planning.
Updates description, keywords/tags, and CHANGELOG.
```

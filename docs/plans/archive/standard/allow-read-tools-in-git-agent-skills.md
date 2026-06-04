# Allow Read/Grep/Glob in pr-agent and ship Skills

## Context

In Claude Code, a skill's `allowed-tools` frontmatter is a **strict allowlist**:
when present, any tool not listed is blocked entirely — the skill cannot
"ask" to use it. When the field is **absent**, the skill inherits the current
session's baseline permissions (not unrestricted access to all tools).

**Implication:** Skills that rely on Read/Grep/Glob without declaring them in
`allowed-tools` are fragile — they work only if the session happens to permit
those tools. Declaring an explicit allowlist is the robust path.

## Full Skill Audit

A body-by-body review of every SKILL.md in `kit/plugins/` was performed. Each
skill was classified by whether its instructions clearly require Read, Grep,
or Glob, and whether its `allowed-tools` field currently declares them.

### A. Restricted skills missing Read/Grep/Glob — **IN-SCOPE for this plan**

| Skill | Current `allowed-tools` | Body needs Read/Grep/Glob? | Action |
|-------|--------------------------|----------------------------|--------|
| `pr-agent` | `Bash(git *), Bash(gh *), Bash(glab *)` | No current need, but forward-looking | **Update** |
| `ship` | `Bash(git *), Bash(gh *), Bash(glab *)` | No current need, but forward-looking | **Update** |

### B. Restricted skills that do NOT need Read/Grep/Glob — unchanged

| Skill | Current `allowed-tools` | Reason |
|-------|--------------------------|--------|
| `branch-agent` | YAML array: `Bash(git *)`, `ToolSearch`, `AskUserQuestion` | Purely git-driven; principle of least privilege |
| `commit-agent` | `Bash(git *)` | Purely git-driven; principle of least privilege |

### C. Restricted skills already properly declared — unchanged

| Skill | Current `allowed-tools` |
|-------|--------------------------|
| `plan-interview/plan-interview` | `Read, Glob, Grep, Bash, AskUserQuestion, Write, Edit, TodoWrite` |
| `plan-interview/plan-status` | `Read, Glob, Grep, Bash, AskUserQuestion, Edit, TodoWrite` |
| `plan-interview/deep-grill` | `Read, Glob, Grep, AskUserQuestion, TodoWrite` |

### D. Unrestricted skills that rely on session baseline — **out of scope**

15 skills have no `allowed-tools` field and their instructions require Read/Grep/Glob
(and other tools). Addressed in a dedicated follow-up plan:
[declare-allowed-tools-for-unrestricted-skills.md](declare-allowed-tools-for-unrestricted-skills.md)

## Steps

1. **Update [pr-agent SKILL.md:4](kit/plugins/git-agent/skills/pr-agent/SKILL.md#L4)** — Append `, Read, Grep, Glob` to the inline `allowed-tools` value.
   - **Before:** `allowed-tools: Bash(git *), Bash(gh *), Bash(glab *)`
   - **After:** `allowed-tools: Bash(git *), Bash(gh *), Bash(glab *), Read, Grep, Glob`

2. **Update [ship SKILL.md:8](kit/plugins/git-agent/skills/ship/SKILL.md#L8)** — Append `, Read, Grep, Glob` to the inline `allowed-tools` value.
   - **Before:** `allowed-tools: Bash(git *), Bash(gh *), Bash(glab *)`
   - **After:** `allowed-tools: Bash(git *), Bash(gh *), Bash(glab *), Read, Grep, Glob`

3. **Bump `git-agent` version in [.claude-plugin/marketplace.json](.claude-plugin/marketplace.json)** — Minor bump per
   [.claude/rules/marketplace.md](.claude/rules/marketplace.md). `3.1.0` → `3.2.0`.

4. **Update [git-agent CHANGELOG.md](kit/plugins/git-agent/CHANGELOG.md)** — Add a `3.2.0` entry explicitly framed as a **forward-looking permission grant**:
   > Allow `pr-agent` and `ship` to use `Read`, `Grep`, and `Glob`. No current
   > behavior change — enables future edits to read PR templates, changelogs,
   > and release notes without a permission update.

5. **Commit the change** — Conventional commit:
   `feat(kit/plugins/git-agent): bump version to 3.2.0`
   Body must explicitly note this is a forward-looking permission grant with
   no current behavior change.

## Critical Files to Modify

- `kit/plugins/git-agent/skills/pr-agent/SKILL.md` (line 4)
- `kit/plugins/git-agent/skills/ship/SKILL.md` (line 8)
- `.claude-plugin/marketplace.json` (`git-agent` version field)
- `kit/plugins/git-agent/CHANGELOG.md` (new 3.2.0 entry)

## Files NOT to Modify

- **`branch-agent/SKILL.md`** and **`commit-agent/SKILL.md`** — bucket B,
  no read need; tight allowlist enforces principle of least privilege.
- **15 skills in bucket D** — require a separate, per-skill effort. See
  "Next Steps" below.
- **3 plan-interview skills** — bucket C, already properly declared.

## Verification

1. **Frontmatter check:** `grep -H 'allowed-tools' kit/plugins/git-agent/skills/pr-agent/SKILL.md kit/plugins/git-agent/skills/ship/SKILL.md` — confirm both lines end with `..., Read, Grep, Glob`.
2. **Marketplace JSON valid:** `jq . .claude-plugin/marketplace.json` — confirm syntactic validity and `git-agent` version is `3.2.0`. The repo's auto-validator hook also runs this on save.
3. **Skill loads (YAML parses):** `claude --plugin-dir ~/devbox/agentics/kit/plugins/git-agent` — confirm plugin loads without parse errors. Catches stray commas or YAML mistakes that `jq` would miss.
4. **Untouched skills unchanged:** `git diff --name-only` should list only the 4 files above.

## Unresolved Questions

_None._ Permission model, scope, version bump, and verification approach all
confirmed via plan interview and skill audit.

## Next Steps (out of scope)

- **Bucket D (15 unrestricted skills):** See [declare-allowed-tools-for-unrestricted-skills.md](declare-allowed-tools-for-unrestricted-skills.md).
- Document the `allowed-tools` syntax convention (inline vs. YAML array) in
  `.claude/rules/plugin-patterns.md`.
- Normalize `branch-agent`'s YAML array format to inline comma-separated.

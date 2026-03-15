# Plan: Add allowed-tools to git-agent skills

## Context

The three git-agent skills (ship, commit-agent, pr-agent) have no `allowed-tools`
declared in their SKILL.md frontmatter. Adding this field explicitly declares which
tools the skill needs, allowing them to run without per-use permission prompts.

Per the [Claude Code skills docs](https://code.claude.com/docs/en/skills), `allowed-tools`
is a supported skill frontmatter field (hyphenated, not underscored). Values must be
Claude Code tool names (e.g., `Bash`), not CLI program names. The docs also support
scoped permissions like `Bash(git *)` to restrict to specific commands.

## Steps

### 1. Update `plugins/git-agent/skills/ship/SKILL.md`

Replace the current `tools` field (not a recognized field) with `allowed-tools`.
The ship skill uses git, gh, and glab via Bash:

```yaml
allowed-tools: Bash(git *), Bash(gh *), Bash(glab *)
```

### 2. Update `plugins/git-agent/skills/commit-agent/SKILL.md`

Add `allowed-tools` to frontmatter. The commit skill only uses git:

```yaml
allowed-tools: Bash(git *)
```

### 3. Update `plugins/git-agent/skills/pr-agent/SKILL.md`

Add `allowed-tools` to frontmatter. The PR skill uses git, gh, and glab:

```yaml
allowed-tools: Bash(git *), Bash(gh *), Bash(glab *)
```

## Files to Modify

| File | Action |
|------|--------|
| `plugins/git-agent/skills/ship/SKILL.md` | EDIT — replace `tools` with `allowed-tools` |
| `plugins/git-agent/skills/commit-agent/SKILL.md` | EDIT — add `allowed-tools` |
| `plugins/git-agent/skills/pr-agent/SKILL.md` | EDIT — add `allowed-tools` |

## Verification

1. Load the plugin: `claude --plugin-dir ./plugins/git-agent`
2. Confirm no IDE warnings on the frontmatter fields
3. Test ship skill on a branch with changes — verify Bash runs without permission prompts

## Next Steps (out of scope)

- Add `allowed-tools` to other plugins' skills for consistency
- Consider whether commit-agent also needs `Bash(gh *)` for hook output

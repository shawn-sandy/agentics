# Declare `allowed-tools` for Unrestricted Marketplace Skills

## Context

This plan is a follow-up to
[allow-read-tools-in-git-agent-skills.md](allow-read-tools-in-git-agent-skills.md).

In Claude Code, omitting `allowed-tools` from a SKILL.md means the skill
inherits the **current session's baseline permissions** — not unrestricted
access. Skills relying on this are fragile: they break if the session
baseline doesn't include the tools they need.

15 skills in the marketplace have no `allowed-tools` field yet their bodies
clearly require Read/Grep/Glob (and other tools). This plan makes those
requirements explicit.

**Design decision — uniform baseline per skill category:**
Adding `allowed-tools` is a **narrowing** operation: any tool not listed is
blocked. Rather than a single superset for all 15 skills, each skill gets a
list derived directly from its body — tools detected in the grep audit below.

The safe baseline covering every tool detected across all 15 skills is:
`Read, Glob, Grep, Bash, Edit, Write, AskUserQuestion, TodoWrite`

None of the 15 skills use Agent, WebFetch, WebSearch, MultiEdit,
NotebookRead, or NotebookEdit — those are intentionally excluded.

## Full Bucket-D Audit

Per-skill tool detection from body grep. Each skill gets exactly the tools
its body references (or the full baseline if uncertain):

| # | Skill path | Detected tool calls | Recommended `allowed-tools` |
|---|-----------|--------------------|-----------------------------|
| 1 | `claude-md-optimizer/skills/claude-md-optimizer/SKILL.md` | Read, Write | `Read, Glob, Grep, Bash, Edit, Write, AskUserQuestion, TodoWrite` |
| 2 | `claude-md-optimizer/skills/path-rules-advisor/SKILL.md` | Read, Glob, Write | `Read, Glob, Grep, Bash, Edit, Write, AskUserQuestion, TodoWrite` |
| 3 | `skill-reviewer/skills/reviewing-skills/SKILL.md` | Read, Write | `Read, Glob, Grep, Bash, Edit, Write, AskUserQuestion, TodoWrite` |
| 4 | `skill-reviewer/skills/planning-skills/SKILL.md` | Read, Write, TodoWrite, AskUserQuestion, Bash | `Read, Glob, Grep, Bash, Edit, Write, AskUserQuestion, TodoWrite` |
| 5 | `wcag-compliance-reviewer/skills/wcag-compliance-reviewer/SKILL.md` | Read | `Read, Glob, Grep, Bash, Edit, Write, AskUserQuestion, TodoWrite` |
| 6 | `agent-creator/skills/generating-agents/SKILL.md` | Read, Glob, Write, Edit, AskUserQuestion | `Read, Glob, Grep, Bash, Edit, Write, AskUserQuestion, TodoWrite` |
| 7 | `code-testing-agent/skills/code-testing-agent/SKILL.md` | Read, Write, TodoWrite | `Read, Glob, Grep, Bash, Edit, Write, AskUserQuestion, TodoWrite` |
| 8 | `code-testing-agent/skills/reviewing-tests/SKILL.md` | Read, Write, TodoWrite | `Read, Glob, Grep, Bash, Edit, Write, AskUserQuestion, TodoWrite` |
| 9 | `code-testing-agent/skills/running-tests/SKILL.md` | Bash, AskUserQuestion, TodoWrite | `Read, Glob, Grep, Bash, Edit, Write, AskUserQuestion, TodoWrite` |
| 10 | `marketplace-builder/skills/building-marketplaces/SKILL.md` | Read, Glob, Write | `Read, Glob, Grep, Bash, Edit, Write, AskUserQuestion, TodoWrite` |
| 11 | `react-perf-analyzer/skills/react-perf-analyzer/SKILL.md` | Read, TodoWrite | `Read, Glob, Grep, Bash, Edit, Write, AskUserQuestion, TodoWrite` |
| 12 | `agentic-plugin-dev/skills/plugin-manager/SKILL.md` | Read, Glob, Edit | `Read, Glob, Grep, Bash, Edit, Write, AskUserQuestion, TodoWrite` |
| 13 | `agentic-plugin-dev/skills/plugin-validator/SKILL.md` | Read, Glob | `Read, Glob, Grep, Bash, Edit, Write, AskUserQuestion, TodoWrite` |
| 14 | `agentic-plugin-dev/skills/plugin-creator/SKILL.md` | Read, Glob, Write, AskUserQuestion | `Read, Glob, Grep, Bash, Edit, Write, AskUserQuestion, TodoWrite` |
| 15 | `code-review/skills/code-review-agent/SKILL.md` | Read | `Read, Glob, Grep, Bash, Edit, Write, AskUserQuestion, TodoWrite` |

> The uniform baseline is used rather than exact-match per skill to avoid
> the risk of missing a tool that appears in a reference file (not directly
> in the SKILL.md body). Per-skill tightening is a future follow-up.

## Steps

For each skill, insert this line into the YAML frontmatter (after
`description:`, before the closing `---`):

```yaml
allowed-tools: Read, Glob, Grep, Bash, Edit, Write, AskUserQuestion, TodoWrite
```

**15 edits (can be done in parallel):**

1. `kit/plugins/claude-md-optimizer/skills/claude-md-optimizer/SKILL.md`
2. `kit/plugins/claude-md-optimizer/skills/path-rules-advisor/SKILL.md`
3. `kit/plugins/skill-reviewer/skills/reviewing-skills/SKILL.md`
4. `kit/plugins/skill-reviewer/skills/planning-skills/SKILL.md`
5. `kit/plugins/wcag-compliance-reviewer/skills/wcag-compliance-reviewer/SKILL.md`
6. `kit/plugins/agent-creator/skills/generating-agents/SKILL.md`
7. `kit/plugins/code-testing-agent/skills/code-testing-agent/SKILL.md`
8. `kit/plugins/code-testing-agent/skills/reviewing-tests/SKILL.md`
9. `kit/plugins/code-testing-agent/skills/running-tests/SKILL.md`
10. `kit/plugins/marketplace-builder/skills/building-marketplaces/SKILL.md`
11. `kit/plugins/react-perf-analyzer/skills/react-perf-analyzer/SKILL.md`
12. `kit/plugins/agentic-plugin-dev/skills/plugin-manager/SKILL.md`
13. `kit/plugins/agentic-plugin-dev/skills/plugin-validator/SKILL.md`
14. `kit/plugins/agentic-plugin-dev/skills/plugin-creator/SKILL.md`
15. `kit/plugins/code-review/skills/code-review-agent/SKILL.md`

### Version bumps in `.claude-plugin/marketplace.json`

MINOR bump for each affected plugin per [.claude/rules/marketplace.md](.claude/rules/marketplace.md):

| Plugin | Current → New |
|--------|---------------|
| claude-md-optimizer | 1.5.0 → 1.6.0 |
| code-review | 3.1.0 → 3.2.0 |
| wcag-compliance-reviewer | 1.1.0 → 1.2.0 |
| skill-reviewer | 1.4.0 → 1.5.0 |
| code-testing-agent | 3.0.0 → 3.1.0 |
| agent-creator | 1.0.0 → 1.1.0 |
| react-perf-analyzer | 1.1.0 → 1.2.0 |
| marketplace-builder | 1.0.0 → 1.1.0 |
| agentic-plugin-dev | 1.0.0 → 1.1.0 |

> Note: `git-agent` is NOT bumped here — it was bumped in the companion plan.

### CHANGELOG updates (9 plugins)

Append to each affected plugin's `CHANGELOG.md`:

```markdown
## [X.Y.Z] - 2026-04-09

### Changed
- Explicitly declare `allowed-tools` frontmatter on all skills.
  Makes tool requirements explicit and removes reliance on session baseline
  permissions. No behavior change — tools were already available via session default.
```

### Commit

```
feat(kit/plugins): declare allowed-tools on unrestricted marketplace skills

Explicitly add allowed-tools frontmatter to 15 previously-unrestricted
skills across 9 plugins. No functional behavior change — tools were
already available via session baseline permissions.

Baseline: Read, Glob, Grep, Bash, Edit, Write, AskUserQuestion, TodoWrite
```

## Critical Files to Modify

- 15 SKILL.md files (listed in Steps above)
- 9 CHANGELOG.md files (one per affected plugin)
- `.claude-plugin/marketplace.json` (9 version bumps)

**Total: 25 files**

## Files NOT to Modify

- `git-agent/*` — handled in companion plan
- `plan-interview/*` — already have explicit `allowed-tools` (bucket C)
- `git-agent/branch-agent`, `git-agent/commit-agent` — bucket B, no change

## Verification

1. **No remaining unrestricted skills:**
   ```bash
   for f in kit/plugins/*/skills/*/SKILL.md; do
     grep -qL "allowed-tools" "$f" && echo "MISSING: $f"
   done
   ```
   Output should be empty (except `plan-interview/*` which use `allowed-tools` correctly).

2. **Marketplace JSON valid:**
   `jq '.plugins[] | {name: .name, version: .version}' .claude-plugin/marketplace.json`

3. **Spot-check skill loads:**
   ```bash
   claude --plugin-dir ~/devbox/agentics/kit/plugins/claude-md-optimizer
   claude --plugin-dir ~/devbox/agentics/kit/plugins/code-testing-agent
   claude --plugin-dir ~/devbox/agentics/kit/plugins/agentic-plugin-dev
   ```

4. **Smoke test 2-3 updated skills** to confirm baseline doesn't block existing behavior.

## Risks & Mitigations

- **Missed tool use in a reference file.** Body grep may not detect tools
  called from `references/*.md` files. **Mitigation:** The uniform baseline
  includes all commonly used tools. Run smoke tests post-edit.
- **Per-skill lists are a superset.** Some skills only need 2-3 tools but get 8.
  **Mitigation:** Acceptable safety margin. Per-skill tightening is a future task.

## Next Steps (out of scope)

- Per-skill tightening: narrow each allowlist to only the tools the skill actually uses.
- Document `allowed-tools` syntax convention in `.claude/rules/plugin-patterns.md`.

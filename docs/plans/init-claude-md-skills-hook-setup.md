# Plan: /init Setup — CLAUDE.md, CLAUDE.local.md, Skills, Hook

> Rename this file to `init-claude-md-skills-hook-setup.md` before committing.

## Context

Running `/init` to audit and improve Claude Code configuration for the `agentics` plugin marketplace repo. The existing `CLAUDE.md` is solid but has a stale version reference and a missing rule entry. `CLAUDE.local.md` exists but lacks personal context. No project-level skills or hooks exist yet.

---

## Changes

### 1. Update `CLAUDE.md`

**File:** `CLAUDE.md`

Three targeted fixes:

1. Line 52: Change `agentics-kit v2.0.0` → `agentics-kit v2.2.0` (stale)
2. Modular Rules section: Add `plan-hygiene.md` entry (exists in `.claude/rules/` but not listed)
3. Conventions section: Add note — "Skill SKILL.md files should include `allowed-tools` frontmatter to restrict which Claude tools the skill can invoke"

---

### 2. Update `CLAUDE.local.md`

**File:** `CLAUDE.local.md`

Add two sections after the existing content:

```markdown
## Role and Context

- Owner and maintainer of this repo; expert familiarity with all plugins and marketplace structure
- Prefer detailed explanations with tradeoffs when making structural decisions about plugins or marketplace

## Loading All Plugins (dynamic — always current)

    claude $(ls ~/devbox/agentics/plugins/ | xargs -I{} echo --plugin-dir ~/devbox/agentics/plugins/{})
```

---

### 3. Add PostToolUse Hook

**File:** `.claude/settings.json`

Add a `hooks` block that validates `marketplace.json` is well-formed JSON immediately after any Write or Edit to that specific file:

```json
{
  "permissions": { ... },
  "plansDirectory": "docs/plans",
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "jq empty .claude-plugin/marketplace.json 2>&1 && echo 'OK: marketplace.json valid' || echo 'ERROR: marketplace.json has invalid JSON — fix before committing'"
          }
        ]
      }
    ]
  }
}
```

**Why:** Catches accidental JSON syntax errors in the registry immediately, before a broken marketplace.json gets committed. Running unconditionally on every Write/Edit keeps the command simple — `jq empty` on this file takes <5ms. The hook is in `.claude/settings.json` (committed), so it applies to all contributors using Claude Code in this repo.

**⚠ Note:** This is a team-shared hook. All contributors will see the validation output after edits.

---

### 4. Create `/validate-plugin` Skill

**File:** `.claude/skills/validate-plugin/SKILL.md`

```yaml
---
name: validate-plugin
description: Validate a plugin directory's structure before committing. Checks required files, version conventions, homepage URL format, and marketplace.json registration. Invoke as /validate-plugin <plugin-name>.
disable-model-invocation: false
---

Check the plugin at `plugins/$ARGUMENTS` for these issues:

1. `.claude-plugin/plugin.json` exists and contains `name` field
2. `plugin.json` does NOT contain a `version` field (version lives in marketplace.json only)
3. Homepage URL in `plugin.json` points to the plugin directory, not the repo root:
   - Correct: `https://github.com/shawn-sandy/agentics/tree/main/plugins/<name>`
   - Wrong: `https://github.com/shawn-sandy/agentics`
4. Plugin has an entry in `.claude-plugin/marketplace.json` with matching name
5. At least one component directory exists: `commands/`, `skills/`, `agents/`, or `hooks/`
6. **Only if `skills/` directory exists**: each `SKILL.md` inside contains `allowed-tools` frontmatter

Report each check as PASS or FAIL with a one-line explanation. If all pass, confirm the plugin is ready to commit.
```

---

### ~~5. `/bump-version` Skill~~ — Removed

`.claude/rules/marketplace.md` already covers the full version bump workflow (4-step process, semver table, commit message formats). It's always in context — a dedicated skill would duplicate it with no added value.

---

## Verification

1. **CLAUDE.md**: Read the file — confirm v2.2.0 reference, plan-hygiene rule listed, allowed-tools note present
2. **CLAUDE.local.md**: Confirm role/preference section and full plugin list appended
3. **Hook**: Edit and save `.claude-plugin/marketplace.json` — hook output should appear immediately. To test the error path: introduce a syntax error, confirm the error message fires, then `git checkout .claude-plugin/marketplace.json` to restore
4. **`/validate-plugin`**: Run `/validate-plugin hello-world` — expect all checks to PASS

---

## Next Steps (out of scope)

- Add a `/new-plugin` skill to scaffold a fresh plugin skeleton (overlaps with `agentic-plugin-dev` plugin)
- Add `validate-marketplace` hook that checks all `source` paths in `marketplace.json` exist on disk
- Set up GitHub Actions workflow that runs plugin validation on PR

---

## Interview Summary

### Key Decisions Confirmed

- Hook: no fallback needed — targets a specific Claude Code version where `$CLAUDE_TOOL_INPUT` is reliable (and simplified to unconditional `jq empty` anyway)
- `/validate-plugin` stays user + Claude invocable (`disable-model-invocation: false`)
- Plugin list in CLAUDE.local.md → dynamic `ls plugins/` command instead of hardcoded paths
- Add `allowed-tools` check as check #6, conditional on `skills/` directory existing

### Open Risks & Concerns

- Hook is team-shared (committed to `.claude/settings.json`) — all contributors see validation output after edits
- Check #6 false failure risk if not gated on `skills/` directory — fixed in plan above

### Recommended Amendments Applied

1. CLAUDE.local.md plugin list → replaced with `ls`-based dynamic command
2. `/validate-plugin` check #6 added with `skills/` directory condition
3. Hook command simplified to unconditional `jq empty` (removes `$CLAUDE_TOOL_INPUT` filtering)
4. Verification step updated with `git checkout` recovery note for hook error-path test

### Suggested next steps

Browse official plugins with /plugin — these bundle skills, agents, hooks, and MCP servers
Install the skill-creator plugin to create and refine skills with evals: /plugin install skill-creator@claude-plugins-official
Add a validate-marketplace hook that checks all source paths in marketplace.json exist on disk (out of scope today, listed in Next Steps)

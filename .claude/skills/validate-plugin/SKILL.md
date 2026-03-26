---
name: validate-plugin
description: Validate a plugin directory's structure before committing. Checks required files, version conventions, homepage URL format, and marketplace.json registration. Invoke as /validate-plugin <plugin-name>.
allowed-tools: Read, Grep, Glob, Bash
---

Check the plugin at `plugins/$ARGUMENTS` for these issues:

1. `.claude-plugin/plugin.json` exists and contains a `name` field
2. `plugin.json` does NOT contain a `version` field (version lives in `marketplace.json` only — if both exist, `plugin.json` silently wins)
3. Homepage URL in `plugin.json` points to the plugin directory, not the repo root:
   - Correct: `https://github.com/shawn-sandy/agentics/tree/main/plugins/<name>`
   - Wrong: `https://github.com/shawn-sandy/agentics`
4. Plugin has an entry in `.claude-plugin/marketplace.json` with a matching `name`
5. At least one component directory exists: `commands/`, `skills/`, `agents/`, or `hooks/`
6. **Only if a `skills/` directory exists**: each `SKILL.md` file inside contains `allowed-tools` frontmatter

Report each check as PASS or FAIL with a one-line explanation. If all checks pass, confirm the plugin is ready to commit.

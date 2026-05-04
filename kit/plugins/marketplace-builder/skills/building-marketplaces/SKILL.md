---
name: building-marketplaces
description: Evaluates a repository's structure and scaffolds Claude Code skill marketplace infrastructure. Use when the user asks to build a marketplace, set up a skill marketplace, create a plugin marketplace, scaffold marketplace files, make a repo into a marketplace, or evaluate marketplace readiness. Does not audit individual SKILL.md quality (use skill-reviewer) or CLAUDE.md content quality (use memory-tools).
allowed-tools: AskUserQuestion, Bash, Glob, Read, Write
---

Evaluate a repository and scaffold the files needed to turn it into a Claude Code skill marketplace.

> **Freedom level: Rigid** — Execute all six steps in the order listed. Do not skip, combine,
> or reorder them.

## Table of Contents

- [Step 1 — Resolve target repository](#step-1--resolve-target-repository)
- [Step 2 — Scan and inventory](#step-2--scan-and-inventory)
- [Step 3 — Run the 5-dimension audit](#step-3--run-the-5-dimension-audit)
- [Step 4 — Present the scored report](#step-4--present-the-scored-report)
- [Step 5 — Offer marketplace scaffolding](#step-5--offer-marketplace-scaffolding)
- [Step 6 — Write confirmation](#step-6--write-confirmation)

---

## Step 1 — Resolve target repository

Determine which repository to evaluate:

1. **Explicit path in message** — if the user provided a directory path, use it
2. **Current working directory** — if no path given, use CWD
3. **Ask** — if CWD does not appear to be a git repository or project root, ask the user

Confirm the target with the user before proceeding: "I'll evaluate `<path>` for marketplace readiness."

---

## Step 2 — Scan and inventory

Scan the target repository and collect these metrics. For each marketplace-related file, classify its status as **missing**, **present and valid**, or **present but broken** (exists but missing required fields or has structural issues).

| Category | What to check |
|----------|---------------|
| **Git status** | Initialized? Has remote? Current branch? |
| **Claude Code files** | CLAUDE.md, `.claude/rules/` (count rule files), CLAUDE.local.md |
| **Marketplace files** | `.claude-plugin/marketplace.json` (status + field check), any root-level `plugin.json` |
| **Plugin directories** | Count `plugins/*/` folders; for each, check `.claude-plugin/plugin.json` presence |
| **Skills & commands** | Scan for `skills/*/SKILL.md` and `commands/*.md` under each plugin |
| **Project docs** | README.md, LICENSE, CONTRIBUTING.md, CHANGELOG.md, .gitignore |
| **Package manifest** | package.json, Cargo.toml, pyproject.toml, setup.py, go.mod, or similar |
| **Build/test scripts** | Scripts defined in manifest; test directories present |
| **CI/CD** | .github/workflows/, .gitlab-ci.yml, Jenkinsfile, or similar |
| **Directory listing** | Top-level directory structure |

Present the inventory as a summary table before proceeding.

**Marketplace file validation** (when present):

For `.claude-plugin/marketplace.json`, check:
- Required fields: `name` (kebab-case), `owner` (object with `name`), `plugins` (array)
- Marketplace name is not reserved: `claude-code-marketplace`, `claude-code-plugins`, `claude-plugins-official`, `anthropic-marketplace`, `anthropic-plugins`, `agent-skills`, `life-sciences`
- Plugin entries have required fields: `name`, `source`
- Source paths are valid (relative paths start with `./`, no `../` traversal)

For each `plugin.json`, check:
- Required fields: `name`, `description`, `version`
- Version not set in both `plugin.json` and `marketplace.json` for the same plugin

Report broken files with specific issues found.

---

## Step 3 — Run the 5-dimension audit

Load [`references/audit-dimensions.md`](references/audit-dimensions.md) for scoring criteria.

Score each of the 5 dimensions 0, 1, or 2. Maximum total: **10 points**.

---

## Step 4 — Present the scored report

Output a structured report:

```
## Marketplace Readiness Report

**Repository:** <path>
**Git:** <initialized/remote status>

### Inventory Summary

| Item | Status |
|------|--------|
| CLAUDE.md | [missing / present / present but incomplete] |
| .claude/rules/ | [N rule files / missing] |
| marketplace.json | [missing / valid / present but broken: <issue>] |
| Plugin directories | [N found, M valid] |
| Skills detected | [N total across plugins] |
| README.md | [present / missing] |
| Package manifest | [type or missing] |
| CI/CD | [type or missing] |

### Scores

| Dimension | Score | Max |
|-----------|-------|-----|
| Repository Foundation | [n] | 2 |
| Project Documentation | [n] | 2 |
| Code Organization | [n] | 2 |
| Developer Experience | [n] | 2 |
| Marketplace Readiness | [n] | 2 |
| **Total** | **[n]** | **10** |

**Grade:** [see scale in audit-dimensions.md]
```

After the table:

1. **Critical gaps** — marketplace-blocking issues (score 0 on any dimension), in priority order
2. **Per-dimension findings** — one bullet per dimension with specific observations
3. **Top 3 actions** — the highest-impact changes to move toward marketplace readiness

---

## Step 5 — Offer marketplace scaffolding

Based on the scan results, offer to generate files the repository is missing. Only offer files that are actually needed — skip anything already present and valid.

Ask: "Based on the audit, I can scaffold the following files. Which would you like me to generate?"

Present a numbered list of what can be scaffolded. For each item, show a code block with the proposed content before asking for confirmation.

**Scaffolding options** (offer only what's missing or broken):

1. **`.claude-plugin/marketplace.json`** — if missing or broken. Generate per official schema from [`references/marketplace-templates.md`](references/marketplace-templates.md). Derive `name` from repo directory name, `owner.name` from git config `user.name` or package manifest author. If marketplace.json already exists and is valid, offer to add new plugin entries instead.
2. **`CLAUDE.md`** — if missing. Generate a minimal stub with section headings and TODO placeholders (Project Overview, Tech Stack, Repository Structure, Common Commands, Conventions). Do not attempt to fill in content — defer to `memory-tools` for quality.
3. **`.claude/rules/` starter files** — if directory is missing. Generate generic starter rules for plugin authoring conventions and marketplace configuration. Content from [`references/marketplace-templates.md`](references/marketplace-templates.md).
4. **`.gitignore` additions** — if missing entries for `.claude/worktrees/` and `CLAUDE.local.md`.
5. **Plugin scaffold** — offer to create a new plugin directory structure: `plugins/<name>/.claude-plugin/plugin.json` + `plugins/<name>/skills/<skill-name>/SKILL.md` stub. Ask the user for the plugin name and skill name. Validate proposed plugin name does not duplicate an existing marketplace entry.
6. **`CLAUDE.local.md`** — if missing. Generate a template with machine-specific path placeholders.
7. **`.claude/settings.json`** — optional, offer separately. Add `extraKnownMarketplaces` entry for team distribution.

When generating plugin entries for marketplace.json, briefly mention the 6 plugin source types (relative path, github, url, git-subdir, npm, pip) and default to relative path for local plugins.

---

## Step 6 — Write confirmation

For each file the user wants scaffolded:

1. Show the complete file content in a code block
2. Ask: "Should I write this to `<path>`?"
3. Wait for explicit confirmation before writing
4. After writing, report success

Never batch-write multiple files without individual confirmation. If the user declines a file, skip it and move to the next.

After all files are written (or declined), suggest next steps:
- Run `claude plugin validate .` to verify marketplace structure
- Use `memory-tools` to improve the generated CLAUDE.md
- Use `skill-reviewer` to audit any SKILL.md files
- Test locally: `claude --plugin-dir ./plugins/<name>`

---

## Quick Reference Checklist

Use for rapid pre-assessment without running the full audit:

**Repository Foundation**
- [ ] CLAUDE.md exists at root
- [ ] `.claude/rules/` directory exists with at least one rule file
- [ ] CLAUDE.local.md documented or in .gitignore

**Project Documentation**
- [ ] README.md with overview, setup, and usage
- [ ] LICENSE file present
- [ ] .gitignore is non-trivial

**Code Organization**
- [ ] Clear top-level directory structure
- [ ] Package manifest present (package.json, Cargo.toml, etc.)

**Developer Experience**
- [ ] Build/test/lint scripts defined
- [ ] CI/CD config present

**Marketplace Readiness**
- [ ] `.claude-plugin/marketplace.json` exists with `name`, `owner`, `plugins`
- [ ] Marketplace name is kebab-case and not reserved
- [ ] At least one plugin in `plugins/` with valid `plugin.json`
- [ ] Plugin entries have `name` and `source` fields
- [ ] Source paths valid (start with `./`, no `../`)
- [ ] At least one plugin has `skills/` or `commands/`
- [ ] Passes `claude plugin validate .`

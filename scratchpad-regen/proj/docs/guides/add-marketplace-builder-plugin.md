# Add `marketplace-builder` Plugin

> New plugin that evaluates a repository's Claude Code marketplace readiness across 5 dimensions and scaffolds the missing infrastructure — turning any repo into a functioning skill marketplace.

<!-- generated:start -->

**Status:** Shipped 2026-03-06   **Plan:** [add-marketplace-builder-plugin.md](plans/add-marketplace-builder-plugin.md)   **Type:** feature

## What shipped

- New `marketplace-builder` plugin with a single core skill `building-marketplaces` at `kit/plugins/marketplace-builder/skills/building-marketplaces/SKILL.md`.
- 6-step evaluate + scaffold workflow: resolve target repo, scan and inventory, run 5-dimension audit (max 10 points), present scored report, offer scaffolding, write with per-file confirmation.
- Reference files: `references/audit-dimensions.md` (scoring rubrics), `references/marketplace-templates.md` (scaffold templates per official schema), `references/checklist.md` (~30-item quick-scan list).
- Scaffolding covers: `marketplace.json`, `CLAUDE.md` (derived from scan data), `.claude/rules/` starters, `.gitignore` additions, plugin directory scaffold, team distribution `.claude/settings.json`.
- Reserved marketplace name list enforced during scaffolding.
- Plugin registered in `.claude-plugin/marketplace.json` at `v1.0.0`.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/marketplace-builder/skills/building-marketplaces/SKILL.md` | Core skill — 6-step workflow | Created |
| `kit/plugins/marketplace-builder/skills/building-marketplaces/references/audit-dimensions.md` | Scoring rubrics for 5 audit dimensions | Created |
| `kit/plugins/marketplace-builder/skills/building-marketplaces/references/marketplace-templates.md` | Scaffold templates (per official schema) | Created |
| `kit/plugins/marketplace-builder/skills/building-marketplaces/references/checklist.md` | Quick-scan checklist (~30 items) | Created |
| `kit/plugins/marketplace-builder/.claude-plugin/plugin.json` | Plugin manifest v1.0.0 | Created |
| `kit/plugins/marketplace-builder/README.md` | Plugin documentation | Created |
| `kit/plugins/marketplace-builder/CHANGELOG.md` | Version history | Created |
| `.claude-plugin/marketplace.json` | Marketplace registry — new plugin entry | Modified |

## How it works

The skill opens by resolving the target repository (explicit path, current working directory, or prompted). It then scans the repo and builds a structured inventory: git status, key documentation files (CLAUDE.md, README, LICENSE), marketplace files (`.claude-plugin/marketplace.json`), plugin directories with their skill/command counts, and the top-level directory structure.

The 5-dimension audit scores the repo on a 0–2 point scale per dimension (max 10): **Repository Foundation** (CLAUDE.md quality, `.claude/rules/` presence), **Project Documentation** (README, LICENSE, CHANGELOG, .gitignore), **Code Organization** (directory structure, naming conventions, package manifest), **Developer Experience** (build/test scripts, CI/CD), and **Marketplace Readiness** (valid `marketplace.json`, at least one valid plugin, passes `claude plugin validate`). The grade scale runs from "Fresh start" (0–3) through "Marketplace-ready" (9–10).

After presenting the scored report, the skill offers to scaffold whatever is missing. Each generated file is shown in a code block first, then per-file confirmation is required before writing — following the safety pattern from `claude-md-optimizer`. The `marketplace.json` template is derived from the official schema (`name`, `owner`, `plugins` required; `metadata.description`, `metadata.version`, `metadata.pluginRoot` optional). Reserved marketplace names (`claude-code-marketplace`, `anthropic-plugins`, etc.) are blocked.

Scaffold templates for `CLAUDE.md` pull from actual scan data (package.json description, detected tech stack from manifests, real directory listing) rather than generic boilerplate. Plugin source options (relative path, GitHub, git URL, git subdirectory, npm, pip) are presented so users understand all distribution channels.

## How to use it

**Skill activation** — triggers on "build a marketplace", "set up a marketplace", "scaffold marketplace", "make this repo a marketplace":

```
/plugin marketplace add shawn-sandy/agentics
/plugin install marketplace-builder@agentics-kit
```

Or locally:

```bash
claude --plugin-dir ./kit/plugins/marketplace-builder
```

Then: "Help me set up a Claude Code skill marketplace for this repo."

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `6b9fab3` | 2026-03-26 | Merge pull request #51 from shawn-sandy/docs/plan-interview-upgrade |
| `9c70a52` | 2026-03-30 | chore(docs/plans): add YAML frontmatter status to 83 plan files |
| `e15fba2` | 2026-04-04 | refactor: rename agentics/ marketplace subtree to kit/ |
| `9924d3f` | 2026-04-09 | refactor(kit/plugins): trim allowed-tools to only tools each skill actually uses |

<!-- generated:end -->

## References

- Plan: [add-marketplace-builder-plugin.md](plans/add-marketplace-builder-plugin.md)
- Official marketplace docs: https://code.claude.com/docs/en/plugin-marketplaces

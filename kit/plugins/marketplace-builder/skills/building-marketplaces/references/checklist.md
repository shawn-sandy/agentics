# Quick Reference Checklist

Use for rapid pre-assessment without running the full 5-dimension audit. Check each item and count how many pass — this gives a rough readiness estimate.

---

## Repository Foundation

- [ ] CLAUDE.md exists at project root
- [ ] CLAUDE.md has key sections: Project Overview, Tech Stack, Commands, Structure, Conventions
- [ ] CLAUDE.md is concise (50-150 instructions, not bloated)
- [ ] `.claude/rules/` directory exists with at least one rule file
- [ ] CLAUDE.local.md is documented or `.gitignore` includes `CLAUDE.local.md`

## Project Documentation

- [ ] README.md present with overview, setup, and usage sections
- [ ] LICENSE file present
- [ ] CONTRIBUTING.md present (or equivalent section in README)
- [ ] CHANGELOG.md present
- [ ] .gitignore is present and non-trivial (>5 entries)

## Code Organization

- [ ] Clear top-level directory structure (not flat file dump)
- [ ] Consistent naming conventions across directories and files
- [ ] Source, tests, config, and docs in distinct directories
- [ ] Package manifest present (package.json, Cargo.toml, pyproject.toml, etc.)

## Developer Experience

- [ ] Build/test/lint scripts defined in package manifest or Makefile
- [ ] CI/CD config present (.github/workflows/, .gitlab-ci.yml, etc.)
- [ ] New developer can get running in under 5 minutes (clear setup steps)

## Marketplace Readiness

Per official schema: https://code.claude.com/docs/en/plugin-marketplaces

- [ ] `.claude-plugin/marketplace.json` exists at repository root
- [ ] Required fields present: `name` (kebab-case), `owner.name`, `plugins` (array)
- [ ] Marketplace name is not reserved (`claude-code-marketplace`, `claude-code-plugins`, `claude-plugins-official`, `anthropic-marketplace`, `anthropic-plugins`, `agent-skills`, `life-sciences`)
- [ ] `plugins` array has at least one entry
- [ ] Each plugin entry has required fields: `name` (kebab-case), `source`
- [ ] Plugin source paths are valid (relative paths start with `./`, no `../` traversal)
- [ ] `plugins/<name>/.claude-plugin/plugin.json` exists for each relative-path plugin
- [ ] Each `plugin.json` has required fields: `name`, `description`, `version`
- [ ] Version not set in both `marketplace.json` and `plugin.json` for the same plugin
- [ ] At least one plugin has a `skills/` or `commands/` directory with content
- [ ] SKILL.md files have valid YAML frontmatter with `name` and `description`
- [ ] Plugin homepage URLs point to plugin-specific directory (not repo root)
- [ ] Passes `claude plugin validate .` or `/plugin validate .`

---

## Scoring Estimate

Count checked items per section and map roughly to dimension scores:

| Section | Items checked | Estimated score |
|---------|--------------|-----------------|
| Repository Foundation | 4-5 of 5 → 2, 2-3 → 1, 0-1 → 0 | /2 |
| Project Documentation | 4-5 of 5 → 2, 2-3 → 1, 0-1 → 0 | /2 |
| Code Organization | 3-4 of 4 → 2, 2 → 1, 0-1 → 0 | /2 |
| Developer Experience | 3 of 3 → 2, 1-2 → 1, 0 → 0 | /2 |
| Marketplace Readiness | 10+ of 13 → 2, 5-9 → 1, 0-4 → 0 | /2 |
| **Estimated Total** | | **/10** |

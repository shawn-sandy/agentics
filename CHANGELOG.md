# Changelog

All notable changes to this project are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/). Individual plugin changelogs live in `plugins/<name>/CHANGELOG.md`.

---

## [Unreleased]

### Changed

- **Docs landing hub** — Replaced the root `docs/index.html` meta-refresh redirect with a proper landing hub page featuring card-based navigation to the Plans gallery and Social Media gallery (#280)
- **Plan checkbox persistence** — Plan gallery checkboxes now persist state via HTML `data-checked` attributes, making checked state portable across browsers without JavaScript storage (#281)
- **Tests** — Added `tests/pages/test-docs-hub.sh` smoke test for the new landing hub; updated `tests/pages/test-root-redirect.sh` to validate hub structure instead of redirect behavior

---

## [4.0.0] - 2026-05-29 — Remove redundant and specialized plugins from marketplace

### Removed

- **agent-creator v1.1.2** — redundant with `agentic-plugin-dev`, which already scaffolds full plugins including agents
- **agent-reviewer v1.0.2** — overlaps with `skill-reviewer`, which covers plugin component auditing more broadly
- **marketplace-builder v1.1.2** — redundant with `agentic-plugin-dev`'s plugin-manager skill
- **react-perf-analyzer v1.3.1** — too specialized; only useful in React projects; general perf issues are covered by `code-review`
- **agentic-plugin-dev v1.2.2** — removed from marketplace; directory retained for reference; plugin scaffolding covered by existing skills
- **code-simplifier v1.0.2** — removed from marketplace; directory retained for reference; structural analysis covered by `code-review`

### Changed

- **Marketplace** (`agentics-kit`) bumped to v4.0.0 (MAJOR — six plugins removed)

---

## [2.4.0] - 2026-05-04 — Rename claude-md-optimizer to memory-tools (v2.0.0)

### Changed

- **memory-tools v2.0.0** (was `claude-md-optimizer`) — MAJOR rename of plugin and primary skill; see `kit/plugins/memory-tools/CHANGELOG.md` for migration steps
- **Marketplace** (`agentics-kit`) bumped to v3.1.0 (MINOR — plugin renamed within marketplace)
- **CLAUDE.md**, **README.md**, **kit/plugins/README.md** — updated references in root docs and plugin docs from `claude-md-optimizer` to `memory-tools` and from `md-optimizer` to `memory-doctor`
- **marketplace-builder**, **skill-reviewer** — updated cross-references to renamed plugin and skill
- **Plan file** renamed from `review-this-skill-and-bright-frog.md` to `rename-md-optimizer-to-memory-doctor.md`

---

## [2.3.0] - 2026-03-27 — Remove hello-world and dev-tools plugins

### Removed

- **hello-world v1.0.0** — example plugin no longer needed in marketplace
- **dev-tools v2.0.0** — example plugin no longer needed in marketplace

### Changed

- **Marketplace manifest** (`agentics-kit`) bumped to v2.3.0
- **CLAUDE.md** — removed hello-world and dev-tools from Reference Implementations
- **README.md** — updated plugin listings, examples, and counts
- **plugins/README.md** — removed hello-world and dev-tools entries
- **.claude/rules/plugin-patterns.md** — removed dead pointer to deleted dev-tools file
- **CLAUDE.local.md** — removed `--plugin-dir` entries for deleted plugins

---

## [2.1.0] - 2026-03-06 — Open-Source Readiness & Documentation

### Added

- **ROADMAP.md** — planned features: Marketplace API, CLI tools, remote marketplace support
- **SECURITY.md** — vulnerability reporting policy and scope
- **CONTRIBUTING.md** — contributor guidelines: bug reports, plugin proposals, PR process
- **CODE_OF_CONDUCT.md** — Contributor Covenant code of conduct
- **GitHub templates** — issue templates (bug report, new plugin), pull request template
- **Open-source readiness plan** (`docs/plans/open-source-readiness-plan.md`) and stress test

### Changed

- **README.md** — expanded with prerequisites, troubleshooting, usage guide, plugin catalog with all 9 plugins, and documentation links
- **plugins/README.md** — updated to include all 9 plugins with corrected descriptions
- **CLAUDE.md** — updated reference implementations list and common commands

### Plugin Updates

- **code-review v2.1.1** — optimized skill description for trigger accuracy; added informal trigger phrases
- **git-agent v1.0.0** — removed hardcoded paths from documentation

---

## [2.0.0] - 2026-03-05 — Plugin Expansion

### Added — New Plugins

- **git-agent v1.0.0** — `commit-agent` and `pr-agent` skills for automated git commit and PR creation

### Plugin Updates

- **code-review v2.1.0** — added breaking changes & regression detection (section 6); conditional DB schema checks; no-git-context fallback
- **code-review v2.0.0** — BREAKING: skill renamed `code-review` to `code-review-agent` to avoid conflict with Anthropic's built-in skill
- **code-review v1.2.0** — added code complexity rating (Low/Medium/High/Very High)
- **code-review v1.1.0** — added adaptive file resolution and table of contents
- **skill-reviewer v1.4.0** — added `running-tests` skill with framework detection and missing test advisory
- **skill-reviewer v1.3.0** — added regression risk check with 6-field comparison matrix
- **skill-reviewer v1.2.0** — aligned with official Anthropic best practices; added workflow patterns, token budget, script quality anti-patterns
- **skill-reviewer v1.1.0** — added `planning-skills` skill with design pattern reference
- **code-test-suggestion v2.2.1** — renamed skill `test-review` to `reviewing-tests` (gerund convention)
- **code-test-suggestion v2.2.0** — removed non-compliant cross-skill reference
- **code-test-suggestion v2.1.0** — added argument parsing for explicit file path and function scoping
- **code-test-suggestion v2.0.0** — BREAKING: removed commands, kept skills only
- **code-test-suggestion v1.1.0** — added `test-review` skill with 7-step review workflow
- **code-test-suggestion v1.0.0** — initial release with 6-step code test suggestion skill
- **claude-md-optimizer v1.5.0** — refactored SKILL.md with progressive disclosure pattern
- **plan-interview v1.3.0** — added `review-rename-plans` command
- **plan-interview v1.2.0** — added plan name validation in Step 2
- **wcag-compliance-reviewer v1.1.0** — upgraded default standard from WCAG 2.1 to WCAG 2.2; added 6 new criteria

### Changed

- **Marketplace manifest** (`agentics-kit`) bumped to v2.1.0 — expanded from 5 to 9 plugins

---

## [1.0.0] — Initial Marketplace Setup

### Summary

Three bugs were discovered and fixed during an attempt to register the `agentics-test`
marketplace via `/plugin marketplace add`. Each bug was a schema validation error caught
by the Claude Code CLI at a different stage: marketplace registration, plugin install.

### Bug 1 — Marketplace registered at the wrong directory

**Commit:** `af36361` / `aae719c`

Moved manifest from `marketplace-data/.claude-plugin/` to project root `.claude-plugin/`.
This fixed registration path and source path resolution.

### Bug 2 — `"components"` is not a valid key in `marketplace.json`

**Commit:** `95bf881`

Removed custom `"components"` field from `dev-tools` entry. The CLI discovers commands and skills by scanning plugin directories.

### Bug 3 — `"category"` is not a valid key in `plugin.json`

**Commit:** `0e463fd`

Removed `"category"` from `hello-world` and `dev-tools` `plugin.json` files. Category belongs in `marketplace.json` only.

### Schema Field Reference

| Field | `plugin.json` | `marketplace.json` plugins entry |
|-------|:---:|:---:|
| `name` | required | required |
| `version` | required | required |
| `description` | required | required |
| `source` | -- | required |
| `author` | allowed | -- |
| `license` | allowed | -- |
| `category` | **not allowed** | allowed |
| `tags` | **not allowed** | allowed |
| `components` | **not allowed** | **not allowed** |

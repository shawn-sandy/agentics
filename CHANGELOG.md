# Changelog

All notable changes to this project are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/). Individual plugin changelogs live in `kit/plugins/<name>/CHANGELOG.md`.

---

## [Unreleased]

> Marketplace (`agentics-kit`) remains at v4.0.0; the changes below are unreleased plugin and infrastructure work since that release. Current plugin versions: memory-tools 4.0.0, code-review 3.3.3, wcag-compliance-reviewer 1.2.3, skill-reviewer 2.2.8, code-testing-agent 3.4.4, git-agent 4.6.0, product-plans 3.4.11, settings-sync 1.0.2, social-media-tools 2.18.1, plan-agent 4.3.1, team-defaults 0.2.0, artifact-tools 1.3.0, content-tools 1.0.0. The live list is the [Plugin Reference Table](./README.md#plugin-reference-table).

### Added

- **content-tools plugin (1.0.0)** — New `documentation` plugin whose `artifact-to-post` skill converts a local HTML artifact, pasted HTML, or a Markdown file into a **draft** static-site post (Astro first). Each block takes the highest rung of a fidelity ladder that holds, artifact CSS is prefixed to a wrapper so it cannot collide with site tokens, and an MDX-safety pass runs after the prose rewrite. Blocking `security-scrub` gate before any write (#440)
- **git-agent `merge` skill + `merge?` hook (4.5.0)** — Checks PR readiness (`MERGEABLE`, green checks, lint gate) and merges only with explicit approval, never passing `--delete-branch`. A `UserPromptSubmit` hook routes a bare `merge?` prompt to the skill deterministically (#441)
- **git-agent `/merge-bg` (4.6.0)** — Background squash merge of one fully green PR via the new `agent-merge` subagent; dispatching the command is the approval, and anything ambiguous comes back as a report instead of a merge (#444)
- **git-agent `/ship-ci-bg` (4.5.0)** — Background CI watcher (`agent-ship-ci`) that polls checks on an open PR and reports the outcome without holding the session (#442)
- **plan-agent `build` skill (4.1.0)** — Implements a plan that already exists: walks the steps, ticks the spec, re-renders, and owns the acceptance-criteria, end-to-end-verification, and completion-checklist gates. Step 8's `Implement now` delegates here (#435)
- **Runnable output checks** — Every HTML-generating and publishing skill now ends in a runnable check on its own output (#431), and every plan carries a runnable completion check (#428)
- **git-agent PR hardening** — PR test plan, lint gate, refuted-finding replies (#433), and a self-review of the diff before pushing in `ship` (#434)
- **Distribution pipeline** — Daily publish pipeline that mirrors plugins to the `agentics-kit` distribution repo, including URL transformation (`agentics` → `agentics-kit`), root-file copying, and CI hardening (#293, #294, #295)
- **plan-agent `setup-sites`** — Scaffolds the GitHub Pages deploy pipeline (workflow, `.nojekyll`, hub, preview script) into any repo so `docs/` HTML publishes to a public URL (2.7.0, #333)
- **plan-agent `build-proposal`** — Turns a vague idea into a decision-complete `docs/proposals/<slug>.md` via an 8-step research→decide loop and right-sizing gate, then hands off to implementation-plan (2.5.0, #329)
- **plan-agent markdown plan conversion** — `implementation-plan` accepts `.md` plan paths and converts them to HTML (2.2.0, #317)
- **plan-agent HTML plan enhancements** — Outcome-driven goal prompt (2.6.0, #332), Save as PDF button (2.4.0, #319), embedded machine-readable markdown digest (2.3.0, #318), and back-to-gallery navigation on every plan page (#300)
- **plan-agent review flow** — `review-plan` findings walkthrough with `--skip-analysis` flag (2.1.0, #311); end-to-end self-verification gate (#287); "Review the plan" option in the Step 8 exit menu (1.11.0, #304)
- **social-media-tools `write-guide`** — Writes a long-form internal developer explainer guide to `docs/` following a fixed 12-section skeleton (2.12.0, #326)
- **social-media-tools `share-react`** — Shares a React component with a static rendered preview and a typed props table on one card (2.11.0, #305)
- **git-agent `create-issue`** — Absorbed from the `issue-agent` plugin; files GitHub/GitLab issues from any context with host auto-detection and a confirmation gate (3.11.0, #324)
- **Plans index merge driver** — `scripts/merge-plans-index.mjs` unions plan cards in `docs/plans/index.html` to auto-resolve merge conflicts (#309)
- **Guides** — GitHub Pages publishing guide (#331); DESIGN.md and COMPONENT.md tutorial (#325)
- **Docs landing hub** — Replaced the root `docs/index.html` meta-refresh redirect with a card-based landing hub linking to the Plans gallery and Social Media gallery (#280)

### Changed

- **CLAUDE.md and `.claude/rules/` rightsized for Claude 5 generation models** — Applied the context-engineering guidance (rules→judgment, repetition→single mentions, upfront context→progressive disclosure) across `CLAUDE.md` and all six rule files: 458 → 288 lines, and `CLAUDE.md` from ~800 to 261 words. Dropped the plugin catalog table (the generated [Plugin Reference Table](./README.md#plugin-reference-table) is the source of truth and CLAUDE.md carried a hand-synced second copy), the Claude Code format templates in `plugin-patterns.md`, and the 30-line inline copy of Anthropic's effective-skills checklist in `skill-authoring.md`, which is now linked so it cannot go stale against the upstream doc. `test-claude-md-budget.sh` loses checks 2 and 3, which existed only to police the removed table; the word budget remains
- **plan-agent 8.1.0** — `prompt` drafts for Claude 5 generation models: a new section 0 in `best-practices-reference.md` carries the five then→now context-engineering shifts and the practices a draft should stop doing, Phase 3 reads it before choosing layers, and Phase 4 runs a calibration pass over the assembled draft. Also fixes the reference having been orphaned — it shipped as the technique catalog with no file linking it, so it never loaded
- **plan-agent 8.0.0** — BREAKING: renamed the `write-prompt` skill and command to `prompt`; invoke as `/plan-agent:prompt`. Callers delegating with `Skill(skill: "plan-agent:write-prompt")` must switch to `plan-agent:prompt`
- **plan-agent 4.0.0** — BREAKING: absorbed the `plan-interview` plugin. `documenting-plans`, `markdown-to-html`, `plan-status`, `plan-maintenance`, `deep-grill`, and the ExitPlanMode stress-test nudge now ship under `plan-agent`; invoke them as `/plan-agent:<name>`. `plan-interview` is de-registered from the marketplace and recoverable from git history (#426)
- **memory-tools 4.0.0** — BREAKING: renamed the `agentic-memory-doctor` skill to `agentic-memory-management`. Update `@import` paths from `skills/agentic-memory-doctor/SKILL.md` to `skills/agentic-memory-management/SKILL.md` (#438)
- **Plugin scoping** — Reviewer agents scoped, commands collapsed onto their skills, and hooks gated (#422)
- **plan-agent `write-prompt`** — BREAKING: renamed the `refine-prompt` skill to `write-prompt`; invoke as `/plan-agent:write-prompt` (3.0.0)
- **plan-agent `refine-prompt`** — BREAKING: renamed `craft-prompt` to `refine-prompt` (2.0.0, #306)
- **social-media-tools card templates** — Added a `--card-width` CSS token to all card templates (#303)
- **Skill frontmatter** — Optimized descriptions to the three-part format (short label + capability + trigger phrase, ≤200 chars) across plugins (#328); surfaced `write-guide` in discovery and backfilled version + changelog (#330)
- **Plan gallery** — Checkbox state persists via HTML `data-checked` attributes for portability without JavaScript storage (#281); stable `plan-created` meta and gallery sorted by date descending (#297)
- **Docs** — Refreshed `CLAUDE.md` with current repo structure and rules (#315); synced `README.md` with latest plugin versions and features (#299)

### Fixed

- **Removed-plugins list drift** — The de-registered plugin list is written twice and had drifted in both directions: `issue-agent` was in `marketplace.json`'s `removed` array but missing from `.claude/rules/removed-plugins.md`, and `plan-interview` was the reverse. The rule file is the copy that matters — it loads unscoped in every session so the re-add confirmation gate fires before any plugin file is opened, so the missing `issue-agent` row was the gate with a hole in it for six weeks, not cosmetic drift. Both lists now hold the same eight names
- **`plan-hygiene.md` pointed at a deleted command** — The rule told you to run `/plan-hygiene` before committing, but that command left with the `plan-interview` plugin (removed 2026-07-17) and `plan-agent` never absorbed it. Replaced with the `verb-target` naming convention stated inline
- **Contradicting deferred-tool guidance** — `plugin-patterns.md` said *not* to explain the `ToolSearch` mechanic in skill bodies while `skill-authoring.md` supplied a verbatim block to paste; both load on `kit/plugins/**/skills/**`. No shipped skill carried the block and 41 carry the terse plan-mode guard, so `skill-authoring.md` was the stale side and its section is removed
- **Artifacts gallery merge conflicts** — `docs/artifacts/index.html` is now registered against the existing `plans-index` merge driver in `.gitattributes`, so two branches each saving an artifact no longer conflict on the regenerated index. Both galleries emit the same `<a class="gallery-card">` markup, so one driver serves both. The count patch also learned the artifacts gallery's `items` noun and now rewrites **every** rendered total rather than the first — both galleries print the count twice (a header and a `<span>` footer), and patching one left the page contradicting itself. Adds `tests/plugins/test-merge-gallery-index.sh`, wired into `check-plugin-versions.yml` — the first coverage either merge driver has had
- **HTML plans responsive layout** — Retrofit responsive CSS into every HTML plan and hardened the skeleton (plan-agent 2.4.1, #321); moved the PDF button and status badge below the title for responsiveness (#322); set pipeline-node padding to 1rem (#298)
- **CI version bump** — Reverted to direct-push version bump with ruleset bypass (#286)

### Tests

- Added `tests/plugins/test-removed-plugins-sync.sh`, wired into `check-plugin-versions.yml` — asserts `marketplace.json`'s `removed` array and `.claude/rules/removed-plugins.md` name the same plugins, and that no removed plugin is simultaneously registered as active. Nothing enforced this before, which is how the drift above went unnoticed. Each check was verified against a deliberately broken tree rather than only passing on green
- Added `tests/pages/test-docs-hub.sh` smoke test for the landing hub; updated `tests/pages/test-root-redirect.sh` to validate hub structure instead of redirect behavior

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

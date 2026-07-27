# CLAUDE.md

This file provides guidance to Claude Code when working with this repository.

## Project Overview

**Marketplace system for Claude Code plugins.** Contains example plugins and marketplace infrastructure for testing plugin discovery, distribution, and installation.

Two distinct purposes:

1. **Example Plugins** — Reference implementations in `kit/plugins/` demonstrating Claude Code plugin structure
2. **Marketplace Infrastructure** — API and CLI for discovering and serving these plugins

## Tech Stack

- **Formats:** Markdown (commands, skills), JSON (plugin manifests)
- **Plugin manifest:** `kit/plugins/<name>/.claude-plugin/plugin.json` — requires `name`; `version` is managed in `marketplace.json` for relative-path plugins
- **Marketplace manifest:** `.claude-plugin/marketplace.json` — plugin registry with relative `source` paths
- **Minimum Claude Code Version:** 1.0.33 or later

## Repository Structure

```plaintext
.claude-plugin/       → Marketplace metadata (marketplace.json) — must be at repo root
kit/plugins/          → Plugin source code (what users install)
.claude/rules/        → Detailed authoring patterns (scoped rules)
scripts/              → Build + git merge-driver helpers (build-dist, merge-marketplace, merge-plans-index)
examples/             → Standalone demo scripts (e.g. demo-tdd-loop.sh)
tests/fixtures/       → Test data for validation logic
tests/pages/          → Smoke tests for docs landing hub and GitHub Pages
tests/plugins/        → Plugin behavior smoke tests
tests/publish/        → Dist build + publish-pipeline tests
tests/demo/           → Sample project used by test-driven demos
docs/                 → GitHub Pages site root (deployed via deploy-pages.yml)
docs/index.html       → Landing hub — links to Plans gallery and Media library
docs/guides/          → Reference guides (auto-load setup, etc.)
docs/media/social/    → Generated social cards gallery (Media library)
docs/prompts/         → Saved refined prompts (from plan-agent:write-prompt)
docs/plans/           → Plan files (commit with plugin changes)
docs/plans/archive/   → Archived completed plans — IGNORE in all searches and exploration
dist/                 → Local build output, gitignored; populated by node scripts/build-dist.mjs
```

> **Search exclusion:** Never include `docs/plans/archive/` in file searches, glob patterns, or exploratory reads. Treat it as off-limits unless the user explicitly targets it by path.

Plugins are **referenced** by marketplaces, not embedded. `marketplace.json` uses relative `source` paths.

## Common Commands

```bash
# Load a plugin for local testing
claude --plugin-dir ./kit/plugins/<name>

# Register marketplace and install a plugin
/plugin marketplace add shawn-sandy/agentics
/plugin install <plugin-name>@agentics-kit

# Trigger a manual publish to the distribution repo
gh workflow run publish-dist.yml --repo shawn-sandy/agentics
```

> Machine-specific paths belong in `CLAUDE.local.md`, not here.

## Reference Implementations

13 plugins in the marketplace (`agentics-kit` v4.0.0):

| Plugin | Type | Notes |
|--------|------|-------|
| `artifact-tools` | Skills + Commands | Publish work as live claude.ai artifacts — `diff-artifact` builds an annotated diff walkthrough (branch, commit range, or PR) with a sticky file sidebar, per-hunk reviewer notes, severity labels, and a cap-and-summarize policy for the 16 MiB artifact cap; `session-artifact` writes a reviewer-first session recap (Summary, Decisions, Learnings, Files touched) using a bundled `export_session.py`; `plan-artifact` publishes plan HTML and republishes to the same URL via `artifact-url:` frontmatter; `prompt-artifact` publishes prompts saved by `plan-agent:write-prompt` behind a verbatim copy button — one prompt (URL in `artifact-url:` frontmatter) or the whole filterable library with `--library` (URL in a committed `.artifact-url` sidecar). `/artifact-tools:product-doc` reruns `session-artifact` framed for the product team and non-engineering stakeholders (features, bug fixes, decisions, logic changes, implementation-plan details, known gaps), sourced from the session transcript or from a pull request via `#453`. `/artifact-tools:team-recap` reruns it as a visual whole-team recap — stat strip, change cards, mermaid diagrams, before/after table, decisions with rejected options, open items, glossary — from the session transcript or from a pull request via `#455`. Blocking `security-scrub` gate before every publish; local-HTML fallback throughout |
| `team-defaults` | Skills + Agents | Shared team defaults — `ts-commenter` and `css-generator` agents plus a `sync-rules` skill that installs bundled team rules (plan-mode, component-driven-ui, typescript-jsdoc, review-bot-loops) into `~/.claude/rules/` with per-file confirmation |
| `memory-tools` | Skills | Auto-activated CLAUDE.md / project memory auditing; enforces optimization principle (keep only rules that change Claude's behavior) |
| `code-review` | Skills + Agents + Commands | Auto-activated code review; `/code-review:fix-branch` autonomously reviews and applies fixes across the whole branch |
| `skill-reviewer` | Skills | Audit and optimize skill files — enforces three-part description format (short label + capability + trigger phrase, ≤200 chars) |
| `code-testing-agent` | Skills + Agents | Test suggestion, review, tdd-fix (bug), tdd-loop (feature); tdd-fix and tdd-loop are manual-invoke only (`disable-model-invocation`) |
| `git-agent` | Skills + Agents + Hooks + Commands | Branch creation, commit, PR, and ship workflows; `merge` skill checks PR readiness (MERGEABLE, green checks, lint gate) and merges only with explicit approval, never `--delete-branch` — typing `merge?` routes to it deterministically via a `UserPromptSubmit` hook; background commands: `commit-bg`, `pr-bg`, `ship-bg`, `ship-ci-bg`, `merge-bg` (dispatch is the approval for one squash merge of a fully green PR; anything ambiguous comes back as a report); `ship-autonomous` for supervised full pipeline; `create-issue` skill files GitHub/GitLab issues from any context (selection, session, bug, feature, plan — a plan file becomes a checklist-style ticket) with host auto-detection and confirmation gate |
| `wcag-compliance-reviewer` | Skills | WCAG accessibility review |
| `product-plans` | Skills + Agents + Commands | Cross-functional review panel (PM, Dev, UX, Frontend, A11y, Security); background-mode panel via `/product-plans:product-plans-bg`; codebase-only research (no WebFetch/WebSearch) |
| `settings-sync` | Skills | Back up and restore Claude Code settings to a git repo; routine-compatible |
| `social-media-tools` | Skills + Commands | Discover teachable content (git history, codebase path, blog posts, videos, GitHub snippets, selected code), scrub for secrets, generate dark-mode social cards for LinkedIn/Twitter/Bluesky/Substack with contextual follow CTAs; `social-share` router skill classifies any share request and runs the right workflow directly; `share-init` generates a `SOCIAL.md` project config for default platform, tone, and content preferences; `share-react` shares a React component with a static rendered preview and a typed props table on one card; `write-guide` writes a long-form internal developer explainer guide (system, rule, how-to, concept, or change recap) to `docs/`, assembled from a section library with five non-binding archetype starting points; `/social-media-tools:digest` for interactive digest scanning; `export-session` converts a session JSONL transcript into Markdown under `{plansDirectory}/sessions/` for reference and educational reuse |
| `plan-agent` | Skills + Agents + Hooks + Commands | Plan lifecycle end-to-end. `implementation-plan` runs the Steps 0–8 workflow with a built-in interview and renders an HTML plan — it never writes source files; `build` implements a plan through the acceptance/end-to-end/completion gates (Step 8's `Implement now` delegates here) and, when the `/plan-agent:build` command names no plan, authors one first by chaining `build-proposal` → `implementation-plan` → review — ambient activation still requires an existing plan; `review-plan` / `review-plan-bg` spawn a seven-reviewer Agent Team; `finalize-plan` marks plans completed with per-criterion verification; `build-proposal` turns an idea into a decision-complete `docs/proposals/<slug>.md`; `deep-grill` walks each decision branch node-by-node; plus `write-prompt`, `prototype`, `documenting-plans` (+ `plan-documenter` batch agent), `markdown-to-html`, `plan-status` (single or `--all` bulk), `plan-maintenance`, `setup-sites`, and `plans-library`/`plans-open`. Accepts issue URLs/`#n` and `.md` plan paths as input; offers tracking-issue creation via `git-agent:create-issue`. Hooks: verb-target filename validation, plans/prototypes gallery rebuild, ExitPlanMode stress-test nudge. Absorbed the former `plan-interview` plugin in v4.0.0. |
| `content-tools` | Skills | Turn work products into publishable site content — `artifact-to-post` converts a local HTML artifact, pasted HTML, or a Markdown file into a **draft** post for a static site (Astro first). Each block takes the highest rung of a fidelity ladder that holds: native Markdown, scoped inline HTML (`<details>`, `<dialog>`, range inputs stay interactive — the artifact's CSS is prefixed to a wrapper container so it cannot collide with the site's design tokens), scoped HTML plus the artifact's own script, and only as a last resort a screenshot. An MDX-safety pass runs *after* the prose rewrite (the rewrite is what introduces `Array<string>`/`{ id }` hazards) and leaves fenced code untouched. Every site-specific value comes from a project-root `CONTENT.md`; blocking `security-scrub` gate before any write; claude.ai artifact URLs are refused with a pointer to `social-media-tools:save-artifact` |

- **Marketplace config:** `.claude-plugin/marketplace.json`
- **Test fixture:** `tests/fixtures/valid-plugin/` — validation reference

## Modular Rules

Detailed patterns in `.claude/rules/`:

- `plugin-patterns.md` — command/skill patterns, progressive disclosure, pitfalls (scoped to `kit/plugins/**`)
- `skill-authoring.md` — verify `SKILL.md` changes against Anthropic's effective-skills checklist (scoped to `kit/plugins/**/skills/**`)
- `marketplace.md` — categories, tagging, versioning, registration
- `testing.md` — test fixture guidelines (scoped to `tests/**`)
- `plan-hygiene.md` — pre-commit plan file rename checks (scoped to `**/plans/**`)

## Git & Branches

- **Always create a new branch off `main` for each feature or fix.** Never commit new work directly to a long-lived shared branch (e.g. a branch from a previous session). Suggested naming: `verb-target-YYYY-MM-DD` (e.g. `add-implement-prompt-2026-06-01`).
- Run `git fetch origin && git checkout -b <branch-name> origin/main` at the start of each new task.

## Conventions

- Plugin Homepage URLs must point to the plugin's directory, not the repository root: `https://github.com/shawn-sandy/agentics/tree/main/kit/plugins/{plugin-name}`
- Always include the plan file in commits for plugin changes, even minor ones.
- `.claude/settings.json` auto-validates `marketplace.json` JSON syntax after every Write/Edit — fix any errors before committing.
- **Bump `version` manually in `marketplace.json`** when you change a plugin — the new value must be higher than the value on `main`. Follow semver: `fix` = patch, `feat` = minor, breaking change = major. See `.claude/rules/marketplace.md`.
- For relative-path plugins, set `version` only in `marketplace.json` — never add a `version` field to `plugin.json` (it silently overrides the marketplace value).
- Component types: **Commands** (`/plugin:name`), **Skills** (auto-activated), **Agents** (subprocesses), **Hooks** (event-driven).
- Skill `SKILL.md` can use `allowed-tools` frontmatter to restrict tool access if necessary
- Two git merge drivers (registered in `.gitattributes`) auto-resolve conflicts: `merge-marketplace.mjs` keeps the higher semver in `marketplace.json`; `merge-plans-index.mjs` unions gallery cards in **both** `docs/plans/index.html` and `docs/artifacts/index.html` (same `<a class="gallery-card">` markup, one driver). Run `scripts/setup-merge-driver.sh` once per clone to enable them.

## Official Documentation

- **Main Docs:** <https://code.claude.com/docs/en>
- **Plugin Creation:** <https://code.claude.com/docs/en/plugins>
- **Plugin Reference:** <https://code.claude.com/docs/en/plugins-reference>
- **Plugin Marketplaces:** <https://code.claude.com/docs/en/plugin-marketplaces>

# Plan: Update Project README with Current Plugin Data and Missing Context

## Context

The root `README.md` has drifted from the actual state of the marketplace. Versions are stale across all 11 documented plugins, a 12th plugin (`code-simplifier`) is missing entirely, and several plugins have added new skills/commands that aren't reflected. Beyond data staleness, the README also lacks higher-level context that would help new users understand plugin component types, CI/CD integration, and marketplace conventions.

## Objective

Bring the README into sync with `marketplace.json` and individual plugin manifests, add the missing `code-simplifier` plugin, and fill content gaps that would help first-time visitors understand the project.

---

## Steps

### 1. Fix plugin count and version numbers everywhere

All references to "11 plugins" become "12 plugins" (3 locations: Overview bullet, Roadmap section, and the Roadmap table).

Update every plugin version to match `marketplace.json`:

| Plugin | README (stale) | marketplace.json (current) |
|--------|---------------|---------------------------|
| code-review | 3.1.0 | 3.2.0 |
| plan-interview | 1.12.0 | 1.14.5 |
| claude-md-optimizer | 1.5.0 | 1.6.0 |
| wcag-compliance-reviewer | 1.1.0 | 1.2.0 |
| skill-reviewer | 1.4.0 | 1.6.0 |
| code-testing-agent | 3.0.0 | 3.2.0 |
| git-agent | 1.1.0 | 3.6.0 |
| agent-creator | 1.0.0 | 1.1.0 |
| react-perf-analyzer | 1.1.0 | 1.2.0 |
| marketplace-builder | 1.0.0 | 1.1.0 |
| agentic-plugin-dev | 1.0.0 | 1.1.0 |

**Why:** Stale versions mislead users about available features and create trust issues.

### 2. Add missing `code-simplifier` plugin section

Add a new plugin section (following the existing pattern) between `agentic-plugin-dev` and the Marketplace section:

- **Name:** code-simplifier
- **Version:** v1.0.0
- **Description:** From marketplace.json: "Analyze code for structural quality issues, code smells, and optimization opportunities — dead code, complexity, god classes, duplication, coupling, and performance anti-patterns"
- **Skills:** `code-simplifier`
- **Link:** `./kit/plugins/code-simplifier/README.md`

Also add `code-simplifier/` to the Project Structure tree and add its install command to the Marketplace section.

**Why:** It's the newest plugin and completely absent from the README.

### 3. Update plugin sections with missing skills and commands

Several plugins have grown since the README was last updated:

- **claude-md-optimizer:** Add `path-rules-advisor` skill to the table (activates when asking about rule file organization or path-scoped rules)
- **plan-interview:** Add commands: `deep-grill`, `plan-status`, `update-plan-status`, `plan-hygiene`, `review-rename-plans`, `documenting-plans`. Add skills: `deep-grill`, `plan-status`, `documenting-plans`
- **git-agent:** Add skills: `branch-agent`, `pr-agent`. Add commands: `commit-bg`, `pr-bg`, `ship-bg`. Update description to mention background subagents
- **code-testing-agent:** Add `tdd-fix` skill (activates for TDD-style bug fixing)
- **skill-reviewer:** Add `auditing-allowed-tools` skill (activates for auditing tool permissions)

**Why:** Users won't discover these capabilities if they aren't listed.

**Source files to read for accurate activation descriptions:**
- `kit/plugins/claude-md-optimizer/skills/path-rules-advisor/SKILL.md`
- `kit/plugins/plan-interview/` — commands/ and skills/ directories
- `kit/plugins/git-agent/` — commands/, skills/, agents/ directories
- `kit/plugins/code-testing-agent/skills/tdd-fix/SKILL.md`
- `kit/plugins/skill-reviewer/skills/auditing-allowed-tools/SKILL.md`

### 4. Update plugin descriptions where they've changed

Use the richer descriptions from `marketplace.json`:

- **code-review:** "Structured multi-dimensional code review across quality, bugs, security, best practices, complexity rating, breaking changes, and regressions"
- **git-agent:** "Automated git workflow — create branches, commit with conventional messages, and create PRs (with background subagents and slash commands for fire-and-forget commit, PR, and ship)"
- **skill-reviewer:** Add mention of skill permissions auditing
- **code-testing-agent:** Emphasize "not arbitrary coverage"

**Why:** The marketplace descriptions are more specific and searchable.

### 5. Add "Component Types" section after "Commands vs Skills"

Add a brief explanation of all four plugin component types referenced in CLAUDE.md:

- **Commands** — Explicit invocation via `/plugin:command`
- **Skills** — Auto-activate based on user intent matching
- **Agents** — Background subprocesses for delegated work
- **Hooks** — Event-driven actions (e.g., pre-commit validation)

**Why:** The README only explains commands vs skills. Users need to understand agents and hooks to make sense of plugins like git-agent.

### 6. Add "CI/CD Integration" section before Contributing

Document the two GitHub Actions workflows:
- `claude.yml` — Responds to `@claude` mentions in issues/PRs
- `claude-code-review.yml` — Automatic code review on all PRs

**Why:** This is a differentiating feature of the project and helps contributors understand the review process.

### 7. Update the Roadmap summary table

Replace the stale version/type table with current data from marketplace.json. Include all 12 plugins. Update the "Current Features" bullet from "11" to "12".

### 8. Update Project Structure tree

Add:
- `code-simplifier/` under `plugins/`
- `.claude-plugin/` at repo root (marketplace.json lives there too, not just under `kit/`)
- `.claude/rules/` directory (briefly note its purpose)

---

## Files to Modify

- `README.md` — All changes in this plan

## Files to Read (for accurate data)

- `.claude-plugin/marketplace.json` — Source of truth for versions and descriptions
- `kit/plugins/code-simplifier/.claude-plugin/plugin.json` — Plugin manifest
- `kit/plugins/code-simplifier/README.md` — For plugin section content
- Skill SKILL.md files listed in Step 3 — For accurate activation descriptions
- `.github/workflows/claude.yml` and `claude-code-review.yml` — For CI/CD section

## Verification

1. Grep README for "11" to ensure all references updated to "12"
2. Cross-reference every version in README against `marketplace.json` — all must match
3. Confirm every plugin in `marketplace.json` has a corresponding section in README
4. Confirm the Project Structure tree matches actual `ls kit/plugins/`
5. Verify all `[View Plugin Documentation]` links point to existing files
6. Confirm the new `code-simplifier` install command appears in the Marketplace section

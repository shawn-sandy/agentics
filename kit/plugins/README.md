# Example Plugins

This directory contains example plugins for the `agentics-kit` marketplace (v3.9.0). These plugins demonstrate the official Claude Code plugin structure and serve as reference implementations for plugin developers.

**18 plugins** · Install via `/plugin marketplace add shawn-sandy/agentics` then `/plugin install <name>@agentics-kit`

## Available Plugins

### code-review
Structured multi-dimensional code review across quality, bugs, security, best practices, complexity, breaking changes, and regressions.

**Components:**
- Skill: `code-review-agent` — Auto-activates on code review requests
- Command: `/code-review:fix-branch` — Autonomously review and apply fixes across the whole branch

**Use case:** Code quality gates, security audits, pre-merge review

---

### code-simplifier
Analyzes code for structural quality issues, code smells, and optimization opportunities.

**Components:**
- Skill: `code-simplifier` — Dead code, high complexity, god classes, duplication, coupling, performance anti-patterns

**Use case:** Refactoring candidates, complexity reduction, code smell detection

---

### code-testing-agent
Analyze code and suggest specific, purpose-driven tests tied to actual behavior — not arbitrary coverage targets.

**Components:**
- Skill: `code-testing-agent` — Suggest tests based on code behavior and intent
- Skill: `reviewing-tests` — Review existing tests for quality and coverage gaps
- Skill: `tdd-fix` — Reproduce a bug with a failing test, then fix it (manual invoke)
- Skill: `tdd-loop` — Drive a new feature through a full TDD loop (manual invoke)

**Use case:** Test-driven development, test quality improvement, bug-driven red-green cycles

---

### react-perf-analyzer
Identifies React component source patterns that correlate with poor INP, CLS, Long Animation Frames, and Long Tasks scores.

**Components:**
- Skill: `react-perf-analyzer` — Heuristic report with recommendations (manual invoke)

**Use case:** React performance auditing, Core Web Vitals optimization

---

### plan-interview
Stress-test implementation plans with structured multi-round interviews before coding begins.

**Components:**
- Command: `/plan-interview:plan-interview [file]` — Run a structured interview against a plan file
- Command: `/plan-interview:deep-grill [file]` — Walk through each decision branch
- Command: `/plan-interview:plan-status [file]` — Check or update plan implementation status
- Command: `/plan-interview:update-plan-status [file]` — Update a plan's status metadata
- Command: `/plan-interview:plan-hygiene` — Pre-commit check for poorly-named plan files
- Command: `/plan-interview:review-rename-plans` — Review and rename plan files
- Command: `/plan-interview:documenting-plans [file]` — Generate prose documentation from plans
- Skill: `plan-interview` — Auto-routes product plans to panel review, always emits an HTML artifact
- Skill: `deep-grill` — Stress-test individual design decisions
- Skill: `plan-status` — Check or determine the implementation status of a plan file
- Skill: `documenting-plans` — Turn a completed plan into reference documentation

**Use case:** Architecture reviews, pre-implementation plan stress-testing, plan documentation

---

### product-plans
Improve, optimize, and update product plans, PRDs, and feature proposals using a cross-functional agent team (PM, Lead Developer, UX, Frontend, Accessibility, Security).

**Components:**
- Command: `/product-plans:product-plans-bg` — Run the full panel review in the background
- Skill: `plan-review-agents` — 15-section consolidated report, applies improvements to the source plan

**Use case:** PRD reviews, feature proposal validation, cross-functional design feedback

---

### plan-agent
Plan creation on demand — produces self-contained interactive HTML plans via the full §0–§7 workflow.

**Components:**
- Skill: `planning` — Manual invoke: `/plan-agent:planning <objective>`. Supports `--quick`, `--type`, `--template` (`default`, `minimal`, `adr`, `spike`), `--priority`, `--interview` flags
- Hook: `validate-plan-filename` — `PostToolUse` hook enforcing verb-target kebab-case on every plan write

**Use case:** On-demand planning with HTML output, architecture decision records, spike investigations

---

### git-agent
Automated git workflow — create branches, commit with conventional messages, and open PRs.

**Components:**
- Command: `/git-agent:commit-bg` — Fire-and-forget background commit
- Command: `/git-agent:pr-bg` — Fire-and-forget background PR creation
- Command: `/git-agent:ship-bg` — Fire-and-forget commit + push + PR
- Skill: `branch-agent` — Create a new branch or branch off main
- Skill: `commit-agent` — Stage changes and create a conventional commit
- Skill: `pr-agent` — Create a PR, push, or open a branch for review
- Skill: `ship` — Commit, push, and open a PR in one flow
- Agent: `agent-commit` — Background git commit (non-blocking)
- Agent: `agent-pr` — Background PR creation (non-blocking)
- Agent: `agent-ship` — Background end-to-end commit + push + PR

**Use case:** Streamlined git workflows, automated PR creation, fire-and-forget operations

---

### issue-agent
Create GitHub and GitLab issues from any context — selection, session, bug, or feature — with host auto-detection and a confirmation gate before writing.

**Components:**
- Skill: `create-issue` — Manual invoke: `/issue-agent:create-issue [bug|feature|selection|session] [title]`. Detects `gh` vs `glab` from git remote, always confirms before creating.

**Use case:** Filing bugs, feature requests, or session-derived issues without leaving Claude Code

---

### settings-sync
Back up and restore Claude Code user settings to a dedicated git repo. Routine-compatible for automated backups.

**Components:**
- Skill: `settings-sync` — Sync, back up, or restore Claude Code settings to/from a git repo

**Use case:** Dotfiles-style settings management, cross-machine settings portability

---

### memory-tools
Audit and optimize CLAUDE.md project memory files against Claude Code best practices.

**Components:**
- Skill: `agentic-memory-doctor` — Optimize, audit, or diagnose a CLAUDE.md file; activates when Claude is ignoring instructions
- Skill: `path-rules-advisor` — Create path-specific rules, organize rules by file type/directory

**Use case:** CLAUDE.md hygiene, reducing noise instructions, scoped rule organization

---

### wcag-compliance-reviewer
Review HTML/CSS and React/TypeScript code for WCAG 2.2 Level AA accessibility compliance.

**Components:**
- Skill: `wcag-compliance-reviewer` — ARIA, color contrast, keyboard navigation, screen reader compatibility

**Use case:** Accessibility auditing, compliance checking, pre-merge a11y review

---

### agentic-plugin-dev
Create, manage, and validate Claude Code plugins — scaffold new plugins, manage marketplace entries, and audit plugin structure.

**Components:**
- Skill: `plugin-creator` — Scaffold a new Claude Code plugin end-to-end
- Skill: `plugin-manager` — Add, update, or remove a plugin from `marketplace.json`
- Skill: `plugin-validator` — Audit plugin structure and validate manifests

**Use case:** Full plugin development lifecycle management

---

### agent-creator
Scaffold Claude Code agent-based plugins with guided, opinionated workflows.

**Components:**
- Skill: `generating-agents` — Create, scaffold, or generate a new agent-based plugin

**Use case:** Plugin authoring, agent scaffolding

---

### agent-reviewer
Structured, scored audit of Claude Code subagent definition files (`agents/*.md`) against official best practices.

**Components:**
- Skill: `reviewing-agents` — Score frontmatter, tool config, description quality, system prompt quality, and security posture; produces a graded report (Excellent / Good / Needs Work / Rewrite)

**Use case:** Agent definition quality assurance, best-practices enforcement

---

### skill-reviewer
Review and optimize Claude Code skill files — score SKILL.md quality, audit `allowed-tools` permissions, and enforce the three-part 200-character description format.

**Components:**
- Skill: `reviewing-skills` — Audit a SKILL.md file across 5 dimensions with scoring
- Skill: `planning-skills` — Design and scaffold new Claude Code skills
- Skill: `auditing-allowed-tools` — Recommend or fix `allowed-tools` frontmatter
- Skill: `running-tests` — Detect changed files, find related tests, run them, report results

**Use case:** Plugin authoring quality assurance, skill description optimization

---

### marketplace-builder
Evaluate a repository and scaffold Claude Code marketplace infrastructure — audit readiness, generate missing files, guide marketplace setup.

**Components:**
- Skill: `building-marketplaces` — Scaffold, audit, or set up a Claude Code plugin marketplace

**Use case:** Setting up new Claude Code plugin marketplaces from existing repos

---

### code-share (dir: `social-media-tools`)
Discover shareable code, blog posts, videos, and GitHub snippets — scrub for secrets, draft platform-aware copy, and generate styled dark-mode social cards for LinkedIn, Twitter/X, and Bluesky.

**Components:**
- Skill: `social-share` — Router: classifies any share request and dispatches the right card skill in the background
- Skill: `code-share` — Git diff/commit card + copy
- Skill: `blog-share` — Blog post or article card + copy
- Skill: `video-share` — YouTube/Vimeo card + copy
- Skill: `github-code-share` — GitHub file/snippet card + copy (public repos only)
- Skill: `selection-share` — Selected/highlighted/pasted code card + copy
- Skill: `project-share` — Project topic card (features/bugs/release) from git + CHANGELOG
- Skill: `scan-for-shares` — Discover shareable commits or codebase patterns; write digest
- Skill: `security-scrub` — Scan code or diff for 20+ secret/credential patterns
- Command: `/code-share:social-share-bg` — Fire-and-forget background share via router
- Command: `/code-share:digest` — Interactive discovery scan with candidate review
- Command: `/code-share:digest-bg` — Background digest scan
- Agent: `agent-social-share` — Background card generation agent
- Agent: `agent-digest` — Background digest agent

**Use case:** Social media content from code, automated digest scanning, pre-share secret scrubbing

---

## Testing Plugins Locally

### Prerequisites Check

Before testing plugins, verify your setup:

1. **Verify Claude Code CLI is installed:**
   ```bash
   claude --version
   # Should output version 1.0.33 or later
   ```

2. **Verify working directory:**
   ```bash
   pwd
   # Should show the agentics repository root
   ```

3. **List available plugins:**
   ```bash
   ls -la kit/plugins/
   ```

### Using --plugin-dir

Test individual plugins directly with Claude Code:

```bash
# From repository root (relative path)
claude --plugin-dir ./kit/plugins/code-review

# Load multiple plugins simultaneously
claude --plugin-dir ./kit/plugins/code-review \
       --plugin-dir ./kit/plugins/plan-interview \
       --plugin-dir ./kit/plugins/git-agent

# Run with a prompt directly (non-interactive)
claude --plugin-dir ./kit/plugins/code-review "Review this file for bugs"
```

### Troubleshooting

#### Plugin not found
- Verify the path exists: `ls -la ./kit/plugins/<name>/.claude-plugin/plugin.json`
- Use an absolute path: `claude --plugin-dir /full/path/to/agentics/kit/plugins/<name>`

#### Command not recognized
- Verify the plugin loaded (check Claude's startup output)
- Check `ls -la kit/plugins/<name>/commands/`
- Ensure command `.md` file has a `description` field in its YAML frontmatter

#### Skill not activating
- Check the skill description matches your request intent
- Verify `kit/plugins/<name>/skills/<skill-name>/SKILL.md` exists
- Try being more explicit in your request

## Plugin Structure

Each plugin follows the official Claude Code plugin structure:

```
plugin-name/
├── .claude-plugin/
│   └── plugin.json          # Plugin manifest (required)
├── commands/                # Slash commands (optional)
│   └── command-name.md
├── skills/                  # Auto-invoked skills (optional)
│   └── skill-name/
│       └── SKILL.md
├── agents/                  # Subagents (optional)
│   └── agent-name.md
├── hooks.json               # Hook registrations (optional)
└── README.md               # Plugin documentation
```

## Plugin Manifest (plugin.json)

Every plugin requires a `.claude-plugin/plugin.json` file:

```json
{
  "name": "plugin-name",
  "description": "Brief description of what the plugin does",
  "author": {
    "name": "Author Name"
  },
  "license": "MIT",
  "homepage": "https://github.com/shawn-sandy/agentics/tree/main/kit/plugins/plugin-name",
  "repository": "https://github.com/shawn-sandy/agentics"
}
```

**Required fields:** `name`, `description`

**Note:** Do not set `version` in `plugin.json` — version is managed exclusively in `marketplace.json`.

## Integration with Marketplace

These plugins are registered in `.claude-plugin/marketplace.json` as the `agentics-kit` marketplace. To install:

```
/plugin marketplace add shawn-sandy/agentics
/plugin install <plugin-name>@agentics-kit
```

See the [root README](../README.md) for the full installation guide and per-plugin documentation.

## Resources

- [Claude Code Plugin Documentation](https://code.claude.com/docs/en/plugins)
- [Plugins Reference](https://code.claude.com/docs/en/plugins-reference)
- [Plugin Marketplaces](https://code.claude.com/docs/en/plugin-marketplaces)

## License

MIT License — See individual plugin directories for specific licenses.

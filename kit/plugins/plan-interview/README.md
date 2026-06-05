# plan-interview Plugin

Stress-tests implementation plans with structured multi-round interviews before coding begins. Surfaces technical trade-offs, UX/accessibility risks, edge cases, and out-of-scope concerns you might not have considered.

## Purpose

Writing a plan is not the same as stress-testing one. This plugin conducts a structured interview — asking targeted questions derived from the plan's own content — to expose gaps, over-engineering, and implicit assumptions before you commit to implementation. It's the difference between a plan that survives first contact with the code and one that doesn't. Also stress-tests `SKILL.md` files by auditing tool usage and generating `allowed-tools` recommendations.

## Which tool to use?

| Situation | Use |
|-----------|-----|
| Technical implementation plan (code, files, APIs) | **`plan-interview`** (this plugin) |
| Product plan, PRD, or feature proposal | [`product-plans`](../product-plans/README.md) |
| Comprehensive PM / UX / Security / A11y review | [`product-plans`](../product-plans/README.md) |
| Quick pre-coding gap check (single agent, fast) | **`plan-interview`** (this plugin) |
| Walk every decision branch interactively | **`plan-interview:deep-grill`** |

`plan-interview` is a single-agent, interactive Q&A interview optimised for technical implementation plans. `product-plans` runs six specialist agents in parallel and is optimised for product-level documents with stakeholder concerns.

## Installation

### Via Marketplace (recommended)

```bash
/plugin install plan-interview@agentics-kit
```

### Local Development

```bash
claude --plugin-dir ./kit/plugins/plan-interview
```

## Usage

### Commands

| Command | Invocation | Description |
|---------|-----------|-------------|
| `plan-interview` | `/plan-interview:plan-interview [plan-file-path] [--quick]` | Stress-test a plan with a structured interview across technical, UX, edge case, and out-of-scope domains |
| `plan-status` | `/plan-interview:plan-status [plan-file-path]` | Check and update the lifecycle status of a plan file (todo, in-progress, completed) with type classification |
| `update-plan-status` | `/plan-interview:update-plan-status [directory-path] [--force]` | Process multiple plan files in a directory — analyze codebase evidence and add/update YAML frontmatter in bulk with summary-first approval |
| `review-rename-plans` | `/plan-interview:review-rename-plans [plan-file-or-directory]` | Review plan filenames and offer to rename files whose names don't match their intent |
| `plan-hygiene` | `/plan-interview:plan-hygiene [directory-path]` | Scan plan directories for randomly-named files and rename them to descriptive kebab-case names based on content headings |
| `deep-grill` | `/plan-interview:deep-grill [plan-file-path]` | Walk each decision branch in an implementation plan with focused questions and codebase exploration |
| `plan-maintenance` | `/plan-interview:plan-maintenance [--archive] [--index] [--variants] [--all] [--background]` | Archive completed plans as HTML, generate a README index, and review variant/duplicate files |
| `documenting-plans` | `/plan-interview:documenting-plans [plan-file-path]` | Generate developer-friendly documentation at docs/<slug>.md from a completed plan file |
| `markdown-to-html` | `/plan-interview:markdown-to-html [file-path] [--theme=default\|developer\|document\|minimal] [--mode=auto\|plan\|doc] [--background] [--no-open] [--async] [--list-themes]` | Convert a markdown file or plan to a rich, self-contained HTML document viewable in any browser |
| `plan-to-html` | `/plan-interview:plan-to-html [plan-file-path] [flags]` | Deprecated — use `/plan-interview:markdown-to-html` instead. Delegates to markdown-to-html with --mode=plan. |

### Skills

| Skill | Activation | Trigger phrases |
|-------|-----------|----------------|
| `plan-interview` | Auto-activated | "Stress-test this plan", "Interview my implementation plan", "Find gaps and risks in this plan", "Validate my approach before I start coding" |
| `plan-status` | Auto-activated | "Check the status of this plan", "Has this plan been implemented?", "Update the plan status", "What's the lifecycle status of this plan?" |
| `deep-grill` | **Manual invoke only** — use `/plan-interview:deep-grill` explicitly | Not auto-activated (`disable-model-invocation: true`) |
| `documenting-plans` | **Manual invoke only** — use `/plan-interview:documenting-plans` explicitly | Not auto-activated (`disable-model-invocation: true`) |
| `markdown-to-html` | Auto-activated | "Convert this plan to HTML", "Make an HTML version of this plan", "Export this markdown as a webpage" |
| `plan-to-html` | Auto-activated (deprecated alias) | Deprecated — routes to `markdown-to-html` with `--mode=plan` |

### Agents

| Agent | Invocation | Description |
|-------|-----------|-------------|
| `plan-documenter` | Agent tool: `subagent_type: "plan-interview:plan-documenter"` | Batch documentation agent — scans the plans directory for completed plans (status: completed, 30+ days old) without corresponding docs in docs/, then invokes the documenting-plans skill for each one |

### Hook

| Hook | Trigger | Behavior |
|------|---------|---------|
| `ExitPlanMode` | Auto-fires after exiting plan mode | Prompts to run the plan-interview skill — interview does not start unless you confirm |

### Command (explicit invocation)

```
/plan-interview:plan-interview                                   # auto-detects latest plan
/plan-interview:plan-interview ~/.claude/plans/my-feature.md     # specific plan file
/plan-interview:plan-interview docs/plans/refactor-plan.md       # project-relative path
/plan-interview:plan-interview --quick docs/plans/my-plan.md     # skip routing, always run technical interview
```

When the resolved plan contains product-level content (user stories, success
metrics, business goals, etc.), `plan-interview` will ask whether to route to
the full `product-plans:plan-review-agents` panel or continue with the quick
technical interview. Pass `--quick` to skip this prompt.

### Review & Rename Plans

```
/plan-interview:review-rename-plans                          # scan project plans directory
/plan-interview:review-rename-plans docs/plans/my-plan.md    # review a single file
/plan-interview:review-rename-plans docs/plans/              # scan a specific directory
```

Reviews plan filenames against their content. Flags files whose names are random, generic, or misaligned with the plan's intent. Offers to rename using `git mv` to preserve history.

### Plan File Hygiene (batch rename)

```
/plan-interview:plan-hygiene                    # scan plansDirectory + additional dirs
/plan-interview:plan-hygiene docs/planning      # scan only docs/planning
/plan-interview:plan-hygiene openspec/plans     # scan only openspec/plans
```

Scans plan directories for files with random non-descriptive names (e.g., `precious-knitting-tulip.md`) and renames them to descriptive kebab-case names derived from their content headings. Presents a proposal table and asks for approval before renaming. Uses `git mv` to preserve history.

### Plan Status

Check whether a plan has been implemented and update its YAML frontmatter with
a lifecycle status and dates:

```
/plan-interview:plan-status                                    # auto-detects from IDE or settings
/plan-interview:plan-status docs/plans/my-feature.md          # specific plan file
```

Status values:

| Status | Meaning |
|--------|---------|
| `todo` | No implementation evidence found in codebase |
| `in-progress` | 1–79% of plan signals found in codebase |
| `completed` | 80%+ of plan signals found in codebase |

Type values (set for completed plans only — inferred from filename/content):

| Type | Meaning |
|------|---------|
| `feature` | New capability or enhancement |
| `fix` | Bug fix, patch, or regression fix |
| `refactor` | Structural change without behavior change |
| `docs` | Documentation-only change |
| `chore` | Housekeeping, version bumps, renames |

After analysis, the skill writes YAML frontmatter to the plan file (with user
confirmation):

```yaml
---
status: completed
type: feature
created: 2026-01-15
modified: 2026-03-26
---
```

Dates are sourced from git log. The `modified` field is omitted when it equals
`created`. Existing frontmatter fields are preserved.

### Batch Status

Process an entire directory of plan files at once — adds frontmatter to files
that don't have it, skips files already processed (unless `--force`):

```
/plan-interview:update-plan-status                          # uses plansDirectory setting or docs/plans/
/plan-interview:update-plan-status docs/plans/              # specific directory
/plan-interview:update-plan-status docs/plans/ --force      # re-analyze files with existing status
```

The command presents a summary table of all files and their computed
status/type before writing anything. Override options let you adjust
auto-classified artifact plans, documentation-focused plans, or zero-signal
files before confirming the write.

### Plan Maintenance

Archive completed plans as browsable HTML, generate a directory index, and
review variant/duplicate files:

```
/plan-interview:plan-maintenance                     # runs --all (variants → archive → index)
/plan-interview:plan-maintenance --archive           # archive completed 30d+ plans as HTML
/plan-interview:plan-maintenance --index             # regenerate docs/plans/README.md index
/plan-interview:plan-maintenance --variants          # review and consolidate variant files
/plan-interview:plan-maintenance --all --background  # full cycle, rendering in background
```

**Sub-workflows (executed in order for `--all`):**

1. **Variants** — detects `-alt`, `-revised`, `-v2` suffix patterns and
   semantic clusters (files sharing 3+ word prefixes). Presents recommendations
   per cluster.
2. **Archive** — identifies completed plans 30+ days old, converts each to
   self-contained HTML via `markdown-to-html --mode=plan`, and stores them in
   type-based folders under `docs/archive/` (`features/`, `fixes/`,
   `refactors/`, `docs/`, `chores/`, `general/`). Source `.md` files are
   `git rm`'d (git history preserves originals). Progress shown as
   `"Archived 12/33: slug.html"`.
3. **Index** — generates `docs/plans/README.md` with active plans grouped by
   status and archived plan counts per type folder.

Use `--background` with `--archive` or `--all` to spawn the rendering as a
background agent.

### Document Completed Plans

Convert a completed plan file into a developer-friendly prose reference document at `docs/<slug>.md`. The doc is synthesized from three sources: the plan body, live code inspection of every cited file path, and a scoped git history window.

```
/plan-interview:documenting-plans                                              # auto-detects from IDE or settings
/plan-interview:documenting-plans docs/plans/add-branch-agent-skill.md        # specific plan file
/plan-interview:documenting-plans ~/.claude/plans/my-feature.md               # absolute path
```

The skill automatically verifies the plan is `status: completed` before generating docs — if not, it runs `plan-status` first. The plan must also be at least 30 days old to be eligible for documentation. The generated document includes:

- **What shipped** — capabilities list from Objective + Steps, rewritten in past tense
- **Files changed** — table of every cited file with Created/Modified/Relocated/Missing status
- **How it works** — prose walkthrough synthesized from plan Steps and actual code
- **How to use it** — activation triggers and examples (only when user-facing surface exists)
- **Commit history** — scoped `git log` window for the plan and its referenced files

Content inside `<!-- generated:start -->` / `<!-- generated:end -->` markers is regenerated on each run. Content outside the markers is preserved (suitable for hand-written notes or additions).

This skill is manual-invoke only (`disable-model-invocation: true`) — use `/plan-interview:documenting-plans` explicitly to run it.

### Batch Document All Plans (Agent)

The `plan-documenter` agent scans the plans directory for completed plans (status: completed, 30+ days old) that
don't yet have corresponding docs in `docs/`, then runs the `documenting-plans`
skill for each one automatically.

Invoke via the Agent tool from another agent or automated workflow:

```json
{
  "subagent_type": "plan-interview:plan-documenter",
  "prompt": "Document all completed plans that are missing docs."
}
```

The agent resolves the plan directory from `.claude/settings.json`
(`plansDirectory` key), falling back to `docs/plans/`. It pre-filters to only
`status: completed` plans (30+ days old) without an existing `docs/<slug>.md` file, then
processes each sequentially in alphabetical order. A summary table is produced
at the end.

If the turn limit is reached mid-batch, the agent reports partial progress.
Subsequent runs automatically skip already-documented plans.

#### Permission model

Plugin agents do not support `permissionMode` — the field is ignored per the
[official plugins reference](https://code.claude.com/docs/en/plugins-reference).
This affects how the agent behaves depending on how it is invoked:

| Invocation method | Behavior | Unattended? |
|---|---|---|
| **Interactive** (Agent tool from conversation) | Agent runs normally. Write/Edit tool calls surface permission prompts that the user approves as they appear. | No |
| **Remote trigger** (scheduled via claude.ai/code/scheduled) | The trigger clones the repo and executes a prompt directly — it does not go through the plugin agent system. It has its own permission model and prompts are not surfaced. | Yes |

The key distinction: scheduled automation works because remote triggers bypass
the plugin system entirely, not because of any agent-level permission setting.
When setting up automation, use a remote trigger with an inline prompt rather
than expecting the plugin agent to run unattended.

#### Running independently

Invoke explicitly via the Agent tool:

```json
{
  "subagent_type": "plan-interview:plan-documenter",
  "prompt": "Document all completed plans that are missing docs."
}
```

#### Weekly scheduled run

A remote trigger can run a documentation sweep automatically on a schedule
(e.g., every Sunday at 6:00 AM ET). The trigger clones the repo fresh and
executes a prompt directly — it does not invoke the plugin agent, so there are
no permission prompts to block execution. Manage schedules at
https://claude.ai/code/scheduled or run on-demand:

```
/schedule run   # select the "Weekly Plan Documentation Sweep" trigger
```

#### Using in other repos

The agent is repo-agnostic — it resolves the plans directory at runtime. To use
it in another repo:

1. Install the plugin:

```
/plugin marketplace add shawn-sandy/agentics
/plugin install plan-interview@agentics-kit
```

2. (Optional) If your plans aren't in `docs/plans/`, set a custom directory in
   `.claude/settings.json`:

```json
{
  "plansDirectory": "path/to/your/plans"
}
```

3. Run the agent on demand — invoke explicitly:

```
/plan-interview:documenting-plans
```

#### Scheduling for multiple repos

Each repo needs its own scheduled trigger because remote agents clone a single
repo per run. To add a weekly sweep to another repo:

1. Run `/schedule` and choose "Create"
2. Set the GitHub URL to the target repo
3. Use the same prompt:
   > Scan for completed plans that don't yet have corresponding documentation.
   > For each completed plan, invoke the documenting-plans skill to generate
   > the doc. Report a summary when done.
4. Set the schedule (e.g., `0 10 * * 0` for Sunday 6:00 AM ET)

The agent prompt is identical across repos — only the GitHub URL changes. For
2-5 repos, individual triggers are the simplest approach.

### Convert Markdown to HTML

Generate a rich, self-contained HTML document from any plan or markdown file —
viewable in any browser, shareable via a file host, with no external dependencies:

```
/plan-interview:markdown-to-html                                    # auto-detects from IDE or settings
/plan-interview:markdown-to-html docs/plans/my-feature.md          # specific plan file
/plan-interview:markdown-to-html README.md --mode=doc               # any markdown doc in doc mode
/plan-interview:markdown-to-html docs/plans/my-feature.md --background  # non-interactive batch
/plan-interview:markdown-to-html --list-themes                      # see available themes
```

The skill auto-detects plan files and enables the full plan-mode visual suite. Features:

- **Sticky sidebar** with anchor links and a scroll-rail progress indicator (plan mode)
- **CSS step timeline** — vertical connector lines and circle nodes per step (plan mode)
- **Status chips** — `todo` / `done` pill per step, updated on checkbox change (plan mode)
- **SVG section diagram** — auto-compact node graph when ≥2 sections present (plan mode)
- **Three-line step cards** — action (bold), why (muted), verify (✓ prefixed)
- **Color-coded status badge** — gray (todo/unknown), amber (in-progress), green (completed)
- **Four themes** — Default, Developer, Document, Minimal
- **WCAG Level A** — skip link, `lang="en"`, labeled checkboxes, `aria-current` on active nav
- **Mobile responsive** — single-column below 768px
- **Fully self-contained** — all CSS and JS inline, no external resources

To describe your intent and auto-activate the skill:

```
Convert this plan to HTML
Make an HTML version of this plan
Export this markdown as a webpage
```

> **Migration:** `/plan-interview:plan-to-html` is deprecated — the command now
> delegates to `markdown-to-html`. Update invocations to use `markdown-to-html` directly.

### Deep Grill

Walk through every decision branch in a plan with focused questions and codebase
exploration:

```
/plan-interview:deep-grill                                    # auto-detects latest plan
/plan-interview:deep-grill docs/plans/my-feature.md          # specific plan file
/plan-interview:deep-grill ~/.claude/plans/my-feature.md     # absolute path
```

The deep grill is a standalone session — it does not modify the plan file. It
reads the plan, builds a decision tree, and walks each branch one at a time.
Results are presented as a summary at the end.

This skill is manual-invoke only (`disable-model-invocation: true`) — use `/plan-interview:deep-grill` explicitly to run it.

### Skill (automatic activation)

Describe your intent and the `plan-interview` skill activates:

```
Stress-test this plan
Stress-test my agentic plan
Interview my implementation plan
Find gaps and risks in this plan
Validate my approach before I start coding
```

To check the status of a plan, describe your intent and the `plan-status` skill
activates:

```
Check the status of this plan
Check the status of my agentic plan
Has this plan been implemented?
Update the plan status
What's the lifecycle status of this plan?
```

To run the deep grill or generate plan documentation, use the explicit commands — these skills have `disable-model-invocation: true` and will not auto-activate:

```
/plan-interview:deep-grill docs/plans/my-feature.md
/plan-interview:documenting-plans docs/plans/my-feature.md
```

In skill-review mode, target a `SKILL.md` file instead:

```
Review this SKILL.md for tool coverage
Audit the allowed-tools in my skill
Check what tools this skill uses
```

### Hook (automatic prompt after plan mode)

When Claude exits plan mode via the `ExitPlanMode` tool, the plugin automatically suggests running the plan-interview skill. This is a prompt only — the interview does not start unless you confirm.

No action required to enable this; it activates automatically when the plugin is installed.

### Interview rounds

The number of rounds scales with plan complexity:

| Plan scope | Rounds |
|------------|--------|
| Short/focused (1–2 files) | 1 round: Technical & Trade-offs |
| Medium (feature with UI + logic) | 2 rounds: + UI/UX & Accessibility |
| Complex/multi-area | 3 rounds: + Edge Cases & Best Practices |

Any plan with UI signals (React, Tailwind, `.tsx`, form/modal/dialog terminology) always includes Round 2.

After the interview (or independently), run the **Deep Grill** skill to walk every decision branch with focused questions, suggested answers, and codebase exploration via `Glob`/`Grep`/`Read`. Invoke `/plan-interview:deep-grill [path]` directly.

### After the interview

The skill compiles a **Plan Interview Summary** with:

- Plan naming issues (if the filename or heading is non-descriptive)
- Key decisions confirmed
- Open risks and concerns
- Recommended next steps
- Simplification opportunities (if any)
- Allowed Tools Recommendation (skill-review mode only — suggested `allowed-tools` line for the paired command file)

You can optionally save the summary back to the plan file.

## Rules

To automate plan-hygiene before commits, copy this rule into `.claude/rules/plan-hygiene.md` and adjust paths as needed:

```markdown
---
description: Run plan file hygiene before committing changes
paths:
  - "**/plans/**"
  - "**/planning/**"
---

# Pre-Commit Plan Hygiene

Before creating any git commit, check if there are plan files with random non-descriptive names (e.g., `precious-knitting-tulip.md`) in the planning directories.

If random-named plan files exist, run `/plan-hygiene` first and complete the rename workflow before proceeding with the commit.
```

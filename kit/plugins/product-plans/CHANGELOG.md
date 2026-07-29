# Changelog

## v3.4.13 — 2026-07-28 — Collapse the plan-mode guard to one line

- `plan-review-agents` replaces its `ExitPlanMode` preamble with the canonical
  one-line guard.
- `plan-review-agents` guard moved to the first Step 0 action — it previously ran
  background-flag detection first. Pre-existing; found in review of this change.
- `product-plans-bg` drops the guard entirely — it only dispatches
  `agent-product-plans`, which reaches `plan-review-agents` and its guard.
  `ToolSearch` and `ExitPlanMode` are removed from its `allowed-tools`.

## v3.4.12 — 2026-07-29 — Document the reviewers' codebase-only research constraint

### Changed

- **README now states that panel research is codebase-only** — no `WebFetch`, no `WebSearch`. The reviewers' tool list was already documented, but the constraint that follows from it lived only in the repo's root `CLAUDE.md`, which is being trimmed back to one line per plugin. Documentation only; no behavior change.

## v3.4.11 — 2026-07-17 — Repoint plan-interview cross-references to plan-agent

### Changed

- `plan-interview` merged into `plan-agent` 4.0.0. Repointed the README comparison table, the `plan-review-agents` SKILL handoffs, and the interview-artifact attribution from `plan-interview`/`plan-interview:deep-grill` to `plan-agent`/`plan-agent:deep-grill`. Description no longer names the removed plugin. No behavior change.

## v3.4.10 — 2026-06-20 — Standardize plans-directory resolution (Claude settings precedence)

### Fixed

- **`plan-review-agents` plans-directory resolution** — now follows Claude Code's settings precedence (project-local `.claude/settings.local.json` → project `.claude/settings.json` → global `~/.claude/settings.json`) and defaults to `${PWD}/docs/plans` instead of the global `~/.claude/plans/` user folder, matching where plan-agent writes plans.

## v3.4.8 — 2026-06-05 — Use portable plugin-dir path in README

### Fixed

- `README.md`: local-development example now uses the repo-relative `./kit/plugins/product-plans` path instead of an author-specific home directory.

---

## v3.4.5 — 2026-06-01 — Add ExitPlanMode error handling

### Fixed

- fix: add ExitPlanMode error handling — treat 'not in plan mode' error as success

## v3.4.4 — 2026-06-01 — Minor wording corrections

### Fixed

- `plan-review-agents` skill and `product-plans-bg` command: minor description wording corrections.

---

## v3.4.3 — README: sync usage documentation with current skill behavior

- Updated README.md to accurately reflect current plugin capabilities, component inventory, and usage patterns.

## 3.4.2 — 2026-05-20

**Fixed: WebFetch/WebSearch permission prompts blocking review panel execution.**

Removed `WebFetch` and `WebSearch` from all six reviewer agents. Web tool
permission prompts (especially for `WebFetch` with domain-scoped allowlists)
blocked subagent execution in both interactive and background mode, halting
the review panel.

Each agent's "Domain Research" section has been rewritten to use codebase-only
research (`Read` + `Glob`) and domain expertise from training knowledge. Agents
still cite standards by identifier (CWE numbers, WCAG SC numbers, Nielsen
heuristics, platform guidelines) but note that URLs from training knowledge
may be stale.

This reverts the web tool additions from v3.2.0. The `Read` + `Glob` codebase
research guidance introduced in that release is preserved and extended to all
six agents.

## 3.4.1 — 2026-05-20

### Changed

- **Skill description narrowed** — `plan-review-agents` skill now explicitly scopes to product
  plans, PRDs, and feature proposals. The description advises users to reach for
  `plan-interview:plan-interview` for quick single-agent technical validation of implementation
  plans before coding.
- **Step 8 — shared HTML artifact** — if `<plan-stem>-interview.html` exists in the same
  directory as the plan (written by a prior `plan-interview` run), Step 8 now injects the
  Panel Review section into that file rather than creating a separate `<plan-stem>-review.html`.
  When no prior interview HTML exists, behavior is unchanged.
- **Step 9 — "which tool to use?" guidance** — a summary table is appended after the cleanup
  step so the SKILL.md is self-documenting about tool scope.
- **README: "Which tool to use?" section** — new comparison table clarifying when to use
  `product-plans` vs. `plan-interview`.

## 3.4.0 — 2026-05-18

**Rejection remediation prompt, decision banner, dated Panel Review headings.**

When the final decision is `Reject`, section 14 of the report now includes
two additional subsections:

- **Rejection Summary** — consolidated blocking issues and critical concerns
  with reviewer attribution.
- **Remediation Prompt** — a self-contained, fenced `text` block the user can
  copy-paste into a fresh Claude session to fix the plan and re-run the panel.
  Context-aware: interactive mode says "paste into Claude"; background mode
  says "re-run the panel".

Additional changes:

- **Decision banner** — the HTML artifact shows a color-coded `<div role="status">`
  banner (green/amber/red) for all three outcomes, placed in `<main>` before the
  appendix. Replaces the old badge in `<header>` (no duplicate announcements).
  Reject banners include the remediation prompt with a copy button and clipboard
  fallback (`execCommand('copy')` for `file://` origins).
- **Dated Panel Review headings** — Step 7 appends `## Panel Review (YYYY-MM-DD
  HH:MM:SS UTC)` with seconds precision. Re-runs append new sections without
  stripping old ones. Historical reviews render as collapsed `<details>` in the
  HTML artifact, newest first.
- **5-backtick outer fence** — `output-template.md` uses 5-backtick fences so
  inner `text` blocks nest safely per CommonMark spec.
- **Accessibility** — `aria-live="polite"` span pre-exists in DOM (WCAG 4.1.3);
  copy button has `aria-label` (WCAG 4.1.2); scrollable `<pre>` has
  `tabindex="0"`, `role="region"`.
- **Security** — Security & Escaping Contract extended to cover remediation
  prompt content.
- **Step 8 re-read** — the lead re-reads the plan file after Step 7 modifies it,
  so historical Panel Review sections appear in the HTML artifact.
- **CSS** — `.remediation` uses `color-mix()` with `var(--surface)` fallback.

## 3.3.0 — 2026-05-17

**Self-contained HTML review artifact.**

The skill now always emits `<plan-stem>-review.html` next to the source plan
after integrating panel findings (Step 8). The file is a fully self-contained
HTML document — no CDN dependencies, no external fonts, no remote scripts —
combining the revised plan (section 15b) as the primary surface with the full
15-section panel review as a collapsible appendix.

- **Filename pattern:** `<plan-stem>-review.html` in the same directory as
  the source plan. The stem is basename-normalized to `[A-Za-z0-9._-]`.
- **Content:** revised plan as primary document; full panel review under a
  collapsed `<details>` appendix.
- **Additive:** does not replace or alter the existing in-place plan update
  (inline edits + `## Panel Review` append). Both outputs continue to be
  produced.
- **Skipped** only when `output_mode = review only` (section 15b absent).
- **No manifest changes required:** `Write` was already declared in
  `allowed-tools`.
- **New reference file:** `references/html-spec.md` — bundled HTML layout,
  theme, accessibility (WCAG AA), and security (escaping/CSP) contract used
  by Step 8 synthesis.

## 3.2.1 — 2026-05-15

**Role-optimized model assignments for all six reviewer agents.**

Replaced `model: inherit` with an explicit model on each reviewer, chosen
to match the cognitive demands of the role:

- **product-reviewer-lead-developer** — `opus` (deep architectural
  reasoning, complex feasibility/tradeoff analysis, system-level risk
  assessment)
- **product-reviewer-security-expert** — `opus` (adversarial threat
  modeling, multi-step attack reasoning, compliance/regulation analysis)
- **product-reviewer-pm** — `sonnet` (strategic and business-value
  analysis with balanced reasoning)
- **product-reviewer-ux-designer** — `sonnet` (pattern-based design
  judgment and flow analysis)
- **product-reviewer-frontend-engineer** — `sonnet` (component patterns,
  framework conventions, performance tradeoffs)
- **product-reviewer-accessibility-expert** — `sonnet` (WCAG nuance plus
  semantic and focus-management judgment)

Each reviewer now runs on the model best suited to its discipline rather
than inheriting the parent session's model, improving consistency of
review quality regardless of where the panel is invoked from.

## 3.2.0 — 2026-05-15

**Domain-specific research tools added to all six reviewer agents.**

Each reviewer agent now has tools matched to their discipline, enabling
evidence-grounded reviews instead of assertion-only findings:

- **product-reviewer-ux-designer** — added `WebSearch`, `WebFetch` for
  looking up platform HIG (Apple, Material Design, Fluent), Nielsen's heuristics,
  and authoritative UX pattern references during review
- **product-reviewer-lead-developer** — added `WebSearch` for technology
  tradeoff and library research; codebase inspection (`package.json`, config
  files) uses the existing `Read` + `Glob` tools; `Bash` remains restricted
  to `git *` to prevent prompt-injection risk from untrusted plan content
- **product-reviewer-security-expert** — added `WebSearch`, `WebFetch` for
  OWASP Top 10 guidance, CVE/NVD advisories, CWE definitions, and compliance
  regulation (GDPR, HIPAA, CCPA, PCI-DSS) references
- **product-reviewer-frontend-engineer** — added `WebSearch` for MDN
  compatibility tables, bundle-size benchmarks, and framework ecosystem
  research; dependency and config inspection (`package.json`, `tsconfig.json`,
  bundler configs) uses the existing `Read` + `Glob` tools; `Bash` remains
  restricted to `git *` to prevent prompt-injection risk from untrusted plan
  content
- **product-reviewer-accessibility-expert** — added `WebSearch`, `WebFetch`
  for WCAG 2.2 Understanding documents, ARIA APG patterns, and AT compatibility
  notes from w3.org primary sources
- **product-reviewer-pm** — added `WebSearch`, `WebFetch` for competitive
  landscape research, industry benchmarks, and market context to stress-test
  business assumptions

Each agent file also received a new **Domain Research** section explaining when
and how to use the new tools and requiring citations in output.

## 3.1.0 — 2026-05-15

**Skill renamed** — the `product-plans` skill is now `plan-review-agents`. The skill
is invoked as `product-plans:plan-review-agents`. The plugin name, agent names,
command name, and install command are all unchanged.

Changes:

- **Skill folder** renamed: `skills/product-plans/` → `skills/plan-review-agents/`
- **SKILL.md frontmatter** `name:` updated from `product-plans` to `plan-review-agents`
- **`agent-product-plans`** skill invocation updated to `product-plans:plan-review-agents`
- **`product-plans-bg` command** skill invocation updated to `product-plans:plan-review-agents`
- **All six reviewer agents** — description phrase updated from "for the product-plans skill"
  to "for the plan-review-agents skill"
- **README** skill section header and directory tree updated

**Migration for existing installers**: if your `.claude/settings.local.json` contains a
`Skill(product-plans:product-plans)` permission entry, re-key it to
`Skill(product-plans:plan-review-agents)`. Without this change the renamed skill will
prompt for permission on every invocation rather than using your saved approval.

The plugin name (`product-plans`), all seven agent names (`agent-product-plans`,
`product-reviewer-pm`, `product-reviewer-lead-developer`, `product-reviewer-ux-designer`,
`product-reviewer-frontend-engineer`, `product-reviewer-accessibility-expert`,
`product-reviewer-security-expert`), the command name (`product-plans-bg`), and the
install command (`/plugin install product-plans@agentics-kit`) are all unchanged.

## 3.0.0 — 2026-05-15

**BREAKING CHANGE**: Skill activation behavior changed. The `product-plans`
skill now triggers on "improve", "optimize", and "update" plan requests in
addition to "cross-functional panel review" phrasing. Users relying on the
prior description to suppress activation should update their workflows.

**Plan improvement is now the primary purpose.** All reviewer agents, role
prompts, skill description, and output template updated to make plan
improvement (not just critique) the explicit goal.

Changes:

- **Skill description** updated — now triggers on "improve", "optimize", or
  "update" a plan, in addition to "cross-functional panel review".
- **Skill Step 2** option renamed from "Review + revised plan" to
  "Review + update plan in place" to reflect the in-place update model.
- **All six reviewer agents** — added a "Your primary goal is plan
  improvement" rule. Every `Recommended improvement` must be a concrete,
  implementable change; the lead uses findings to improve the plan.
- **Role prompts** updated — each spawn prompt now says "Review and improve
  the product plan". Wording is mode-neutral: findings feed the lead's
  synthesis in both update-in-place and review-only modes.
- **Output template** — section 15 renamed to **15b** (Complete Revised
  Plan) to distinguish it from 15a (Inline Edits). Every section 12
  recommendation must have a 15a row; use `insert after` for new sections
  rather than deferring to 15b (which is a reference view only, not an
  edit mechanism). Section 12 note conditioned on `output_mode`.
- **`agent-product-plans` background agent** — fixed a bug where step 3
  reported `<stem>-revised.md` (a sibling file) as the output; now
  correctly reports "Plan updated in place: `<path>`".
- **`background output_mode`** aligned to `"review + update plan in place"`
  from the stale `"review + revised plan"`.
- **`commands/product-plans-bg.md`** dispatch prompt updated to say "report
  the path updated in place" instead of "report the sibling file path".
- **README and plugin.json** fully updated to reflect in-place update model.
- **Marketplace description** updated; added `plan-improvement`,
  `plan-optimization` tags.

## 2.2.1 — 2026-05-15

**Behavior change (Step 7):** The skill now integrates panel findings
directly into the source plan. Both interactive and background modes share
a single path — no prompts, no sibling file. Two passes:

1. **Inline edits** — section 15a of the synthesized report lists discrete
   `(section, action, content)` edits; the lead applies them to the source
   plan via `Edit` in order.
2. **Append panel review** — the full 15-section synthesized report is
   appended as a `## Panel Review` section at the end of the source plan.

This mirrors how `plan-interview` integrates its findings into the plans it
reviews.

**Removed:** the `AskUserQuestion` prompt in Step 7, the **Sibling file**,
**Overwrite original**, and **Append to original** options, the
`git status --porcelain` safety guard, and the background-mode
`<stem>-revised.md` sibling-write.

**Added:** section 15a ("Inline Edits to Apply") in
`references/output-template.md` — a structured table the lead fills with
discrete edits derived from section 12 recommendations.

## 2.2.0 — 2026-05-15

**Additive — no breaking changes.** All existing reviewer behavior is unchanged.

New team member:

- **`product-reviewer-security-expert` agent** — reviews authentication and
  authorization design, data handling and privacy, input validation, dependency
  risk, secrets management, threat modeling, compliance implications, and
  security unknowns.
- **Spawn prompt** added to `references/role-prompts.md`.
- **Output template** updated: Security Expert added to the reviewer roster and
  a new **Section 9 — Security Requirements** inserted; subsequent sections
  renumbered (10–15). The Revised Plan is now section 15.
- **`product-plans` skill** updated: spawn directive now lists six subagent
  types; synthesis and section references updated to match.
- **`agent-product-plans` background agent** description updated to reflect
  six-reviewer panel.

## 2.1.0 — 2026-05-14

**Additive — no breaking changes.** Foreground skill behavior is unchanged.

New surfaces for unattended (background) panel execution:

- **`--background` flag on the `product-plans` skill** — suppresses all
  `AskUserQuestion` calls and uses fixed defaults (see table below). Pass
  any explicit plan path in the same argument string.
- **`agent-product-plans` subagent** — background wrapper agent
  (`background: true`, `tools: Skill, Read, Write, Edit, Glob, Grep, Bash`,
  `maxTurns: 30`). Tool list widened from `Skill, Read` so the inner skill's
  `Write`/`Edit` calls succeed (subagent tool grants are not transitive
  across `Skill` invocations). Invokes the skill via the `Skill` tool.
  Named dispatch target for the command below.
- **`/product-plans:product-plans-bg <path>` command** — one-liner that
  fires `agent-product-plans` with `run_in_background: true` and returns
  an ack immediately.

Background mode defaults:

| Step | Foreground | Background |
|------|------------|------------|
| Plan file resolution | 4-stage fallback (message → IDE → settings → glob) | Explicit path in `$ARGUMENTS` only; stops with `Background mode requires a plan path` if absent |
| Output mode (Step 2) | `AskUserQuestion` (default: review + revised plan) | Hard-coded `review + revised plan` |
| Write destination (Step 7) | `AskUserQuestion` (sibling / overwrite / append) | Hard-coded sibling file (`<stem>-revised.md`), non-destructive |

## 2.0.0 — 2026-05-14

**Breaking change**: plugin and skill renamed from `product-plan-review-panel`
to `product-plans`. Users on v1.0.0 must reinstall:
`/plugin install product-plans@agentics-kit`.

Skill `description` rewritten to use panel/multi-role-specific triggers
(`cross-functional panel review`, `multi-role critique`, role names) so
auto-activation no longer overlaps with `plan-interview` or `code-review`.

## 1.0.0 — 2026-05-14

- Initial release.
- Skill `product-plan-review-panel`: orchestrates a five-reviewer Agent Team (PM, Lead Developer, UX Designer, Frontend Engineer, Accessibility Expert) to produce a consolidated 14-section product-plan review and optional revised plan.
- Subagent definitions (teammate-only): `product-reviewer-pm`, `product-reviewer-lead-developer`, `product-reviewer-ux-designer`, `product-reviewer-frontend-engineer`, `product-reviewer-accessibility-expert`.

---
status: todo
created: 2026-05-18
---

# Plan: Run product-plans review panel on rename-plan-to-html refactor plan

## Context

The user invoked `/product-plans:plan-review-agents` from this branch
(`docs/rename-plan-to-html-2026-05-18`). The target plan
[docs/plans/rename-plan-to-html-to-markdown-to-html.md](rename-plan-to-html-to-markdown-to-html.md)
is a substantial (37KB) **MAJOR**-version refactor that renames
`plan-to-html` → `markdown-to-html`, removes the `--setup` cache flow,
bundles theme assets inside the skill, adds dual render modes
(plan-aware vs generic doc), introduces HTML5-native `<progress>` /
`<details>`, adds CSS-driven visuals (timeline, status chips, scroll rail,
inline SVG diagram), and adds a `scripts/build-assets.sh` single-source
generator.

The refactor touches a public skill surface, ships a breaking rename, and
introduces a new build script + bundled assets — high blast radius. A
six-reviewer panel (PM, Dev, UX, Frontend, A11y, Security) is the right
gate before execution begins.

Plan mode is currently active. Per the user's
[feedback_skill_plan_mode memory](file:///Users/shawnsandy/.claude/projects/-Users-shawnsandy-devbox-agentics/memory/feedback_skill_plan_mode.md),
write-heavy skills must not run inside plan mode. This meta-plan exists
solely to surface the panel run for explicit approval via `ExitPlanMode`.

## Objective

Execute the `plan-review-agents` skill against
`docs/plans/rename-plan-to-html-to-markdown-to-html.md` in
**Review + update in place** mode, applying inline edits and emitting the
HTML companion artifact.

## Steps

1. **Exit plan mode** — *Why:* the skill is write-heavy and cannot run
   under plan-mode restrictions. *Verify:* subsequent tool calls succeed
   without the plan-mode block.

2. **Spawn the six-reviewer team in parallel** against
   `docs/plans/rename-plan-to-html-to-markdown-to-html.md` (resolved via
   `realpath`) — *Why:* parallel review compresses wall-clock time and the
   skill mandates concurrent spawn. *Verify:* the shared task list shows
   six teammates `in_progress`, one per role (PM, Lead Dev, UX, Frontend,
   A11y, Security).

3. **Collect findings, respawn any failed teammate once, mark unavailable
   if they error twice** — *Why:* synthesis must not begin with partial
   coverage and gaps must be visible. *Verify:* every role is either
   complete or explicitly marked `Reviewer unavailable — not assessed`
   in the report's Executive Summary, that role's section, and
   Highest-Risk Issues.

4. **Synthesize the 15-section report** per
   `references/output-template.md`, surfacing agreements, conflicts,
   challenged assumptions, and balanced role representation — *Why:* a
   single voice for the user, not six pasted dumps. *Verify:* all 15
   sections present; section 12 names at least one cross-role conflict
   with a recommended resolution.

5. **Apply inline edits (section 15a) to
   `rename-plan-to-html-to-markdown-to-html.md`, then append
   `## Panel Review` (verbatim sections 1–15b)** — *Why:* findings must
   live in the source plan, not a sidecar, so future readers see them
   inline. *Verify:* `grep '^## Panel Review'` returns a match; each 15a
   row is reflected in the file or logged as a skipped-anchor warning.

6. **Emit
   `docs/plans/rename-plan-to-html-to-markdown-to-html-review.html`**
   per `references/html-spec.md` with HTML-escaped content,
   `body class="theme-default"`, JS-optional scroll-spy — *Why:* shareable
   browser-openable companion. *Verify:* file exists, opens in a browser,
   table of contents renders without JS, no raw `<`/`>` from plan content
   leaks into the DOM.

7. **Clean up the agent team via the lead** — *Why:* per Agent Teams
   docs, teammate-initiated cleanup leaves resources inconsistent.
   *Verify:* no teammate processes remain; lead reports clean exit.

## Verification

- Source plan
  `docs/plans/rename-plan-to-html-to-markdown-to-html.md` ends with a
  `## Panel Review` section containing 15 subsections.
- Sibling HTML artifact
  `docs/plans/rename-plan-to-html-to-markdown-to-html-review.html`
  exists, opens in a browser, and renders the same report.
- `git status` shows the source plan modified (it was already untracked)
  and the new HTML file as untracked — both ready to be committed
  alongside the refactor work itself.
- No agent team processes remain active.

## Next Steps *(optional)*

- Rename this meta-plan from its random slug to a descriptive name:

  ```text
  Rename docs/plans/stateful-gliding-reef.md to a verb-target kebab-case
  filename that matches its content (e.g.
  run-panel-review-on-rename-plan-to-html.md). Update any internal links
  if present, and stage the rename together with the panel-generated
  changes per .claude/rules/plan-hygiene.md.
  ```

- After the panel approves the refactor plan, execute the refactor:

  ```text
  Implement the steps in
  docs/plans/rename-plan-to-html-to-markdown-to-html.md, honoring any
  panel-applied inline edits. Bump the plan-interview plugin to a MAJOR
  version per .claude/rules/marketplace.md and update its CHANGELOG.
  ```

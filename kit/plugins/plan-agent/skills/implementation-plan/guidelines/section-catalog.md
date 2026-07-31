# Section Catalog

The menu of plan-spec sections: what each is for, when it earns its place,
and the exact markdown syntax `scripts/build-plan-html.mjs` parses. Section
headings are matched literally — use them exactly as written here.

The spec is a markdown file starting with an optional YAML frontmatter block,
then `# Plan: <title>`, then `## <Section>` blocks.

## Required core (machines depend on these — never omit)

### `# Plan: <title>`

The one-line name of the work. Becomes the page `<title>`, the header, and
the text inside the derived implement/goal/workflow prompts. Write it as a
rallying statement, not a ticket summary.

### `## Objective`

One or two sentences summarising the goal — the *what*. Rendered as the
prominent objective card. Single paragraph; inline text only.

### `## Steps`

Numbered list; every item carries the action, a `Why:` marker, and a
`Verify:` marker, in that order:

```markdown
## Steps

1. Wire up the ThemeContext provider in src/App.tsx Why: every component
   below the root needs access to the active theme Verify: the app renders
   with the default theme and React DevTools shows the provider.
2. <action> Why: <reason> Verify: <how to confirm>.
```

Items may wrap across lines (continuations are folded), but each item is one
logical line — no sub-bullets, no blank lines inside an item. The `Why:` and
`Verify:` markers are mandatory on every step; the parser rejects a step
missing either.

**Completion state:** an optional `[x]` marker right after the number
(`1. [x] Wire up the provider… Why: … Verify: …`) renders the step as a
completed card with a `done` chip. Author new steps without the marker;
tools insert it as implementation progresses.

### `## Acceptance Criteria`

One bullet per criterion; each a single-line falsifiable statement.
Rendered as interactive checkboxes under the "Definition of done" heading.
Use checkbox bullets to carry completion state: `- [ ] <criterion>` renders
unchecked, `- [x] <criterion>` renders checked and advances the progress
bar (plain `- ` bullets also parse, as unchecked). The spec is the source
of truth for this state — status flips are made here and re-rendered, never
as `checked` attribute edits in the HTML.

### `## Verification`

Prose (one or more paragraphs) describing the end-to-end confirmation that
the whole change achieved the objective. Rendered under "Final check".

Must name at least one check someone else could re-run: a command with its
expected result, or a specific observable end state (file contents, rendered
output, HTTP response). "Confirm it works" is not a verification.

## Optional sections (include when they earn their place)

### `## Context`

Background and motivation — why this work is needed, what prompted it, known
risks with mitigations. Earns its place when the reader needs history to
judge the plan: a bug's discovery story, a constraint that shaped the
approach, an issue link. A self-evident chore (dependency bump, rename) can
omit it. Paragraphs separated by blank lines. When the plan was seeded from
an issue, cite the issue URL here.

### `## Files`

One bullet per file the plan touches:

```markdown
## Files

- src/App.tsx (modified) — mount the ThemeContext provider
- src/theme/context.ts (new) — theme state and persistence
```

Format: `- <path> (<badge>) — <short note>` where badge is one of `new`,
`modified`, `deleted`, `generated` and the separator before the note is an
em dash. The renderer groups these into the styled file-tree and uses the
count to derive effort and the workflow heuristic. Include whenever the plan
names files (almost always); omit only for purely conceptual plans.

### `## Tests`

Real application tests that ship with the change — distinct from per-step
verifies and the Verification section, which are prose assertions. Format: a
bare tier line, then one bullet per test; the **first bullet is always the
objective-verification test** (rendered as the highlighted hero card):

```markdown
## Tests

Tier 1 — This plan changes application code
- Objective: dark-mode toggle persists across themes. File: __tests__/theme.test.tsx; Type: smoke; Asserts: toggling persists through reload; Run: npx vitest run __tests__/theme.test.tsx
- Unit: theme reducer transitions. File: __tests__/reducer.test.ts; Targets: themeReducer; Key cases: toggle, system-default, invalid value
```

Tier rules: **Tier 1** when any step creates, modifies, or deletes
application source files — include the objective test plus whichever of
unit/integration/E2E apply (never empty stubs). **Tier 2** when steps only
touch docs, plans, or non-runtime metadata — the objective test alone, whose
**Run** is a plain shell command that exits non-zero when the objective is
not met (`grep -q '<expected text>' <file>`, `test -f <path>`, a script) —
there is no test runner, but there is still a command. Every objective test
carries a **Run** command, both tiers; a plan with no runnable completion
check is not finished being planned. Keep
the tier line's `Tier 1 — ` / `Tier 2 — ` prefix; tooling matches on it.
Judge the tier by what the steps actually do, not the `type:` frontmatter.

### `## Next Steps` *(optional)*

Follow-up work that builds on the plan but is not required to finish it.
`## Out of Scope` is accepted as the same section, and the match is
case-insensitive — but any other heading is discarded silently, so use one of
these two.
Renders as collapsible cards, each with a Copy-prompt button — the same
markup legacy hand-written plans carried. Each top-level `- ` bullet is one
card: the bullet's first line is the summary, an indented fenced code block
is the self-contained paste-ready prompt, and any other indented lines are
description prose. Bullet-less content (or lines before the first bullet)
renders as plain paragraphs. Label blue-sky items as wish list. Prompts must
be self-contained — name the repo, files, version bump, and CHANGELOG so the
follow-up can run in a fresh session. Each prompt ends with its own
verification instruction: the command to run or state to confirm before
reporting done. These prompts run in a fresh session with no plan behind
them, so the check has to travel inside the prompt.

When a prompt contains its own fenced block, the outer fence must be longer
than any fence inside it — ` ````text ` around a prompt quoting ` ```yaml `.
Same-length fences make the prompt end at the inner fence, which is how
Markdown works everywhere, not a quirk of this parser.

```markdown
## Next Steps

- Add a background dispatcher for the panel
  Mirrors the review-plan-bg command pattern.
  ```text
  In the agentics repo, add kit/plugins/plan-agent/commands/panel-bg.md
  mirroring review-plan-bg.md. Bump the plan-agent minor version in
  .claude-plugin/marketplace.json and add a CHANGELOG entry.
  ```
```

### `## Completion Report`

Lifecycle section — never authored at planning time. Written by
`finalize-plan` or the implementation gates when a plan is closed out with
gaps: one bullet per finding, an em dash separating the item from the
reason:

```markdown
## Completion Report

- Tests pass — npm test exited with code 1
- Implementation evidence gap — 3/5 tokens found; missing: AuthProvider
```

Renders as the report list inside the completion checklist. When the
section is absent the block shows the default "No items to report — all
requirements met." sentence; remove the section once every gap is resolved.
Place it after `## Acceptance Criteria`.

## Frontmatter keys (all optional — the renderer derives sane defaults)

```yaml
---
status: todo            # todo | in-progress | completed (default todo)
type: feature           # feature | fix | refactor | docs | chore
created: 2026-07-12     # YYYY-MM-DD; preserved across re-renders when set
repo: my-repo           # default: origin remote basename, else cwd basename
effort: high            # low | medium | high; omit to auto-derive from step/file counts
glance: <one line>      # 2–3 plain-language sentences, on ONE line — the At-a-glance block
workflow: auto          # auto (heuristic) | always | never; omit for auto
---
```

Every value is a single `key: value` line — the frontmatter parser does not
support multi-line values. The enumerated keys above (`status`, `type`,
`effort`, `workflow`) accept only the listed values: an unrecognized one
fails the render naming the key and the valid set, rather than silently
falling back — `status: complete` used to render as `todo` and
`workflow: yes` used to mean "no workflow". `workflow: true`/`false` stay
accepted as the pre-7.0 spelling of `always`/`never`. `issue` is the tracking
ticket's full URL — the renderer emits it as the `plan-issue` meta tag and a
header link, so a completed plan still points at the ticket to close. It must
be `http(s)`; any other scheme is dropped with a warning rather than rendered,
since escaping leaves a `javascript:` value clickable. Any tracker may be
linked, but only `github.com` and GitLab URLs can be *closed* on completion —
those are the two the `gh`/`glab` CLIs can drive; a Jira or Linear link
renders and is then left alone. `glance` must not restate the objective: the
objective is the *what*; the glance is *why it matters* and *how we'll know
it worked*, written for someone who wasn't in the planning session. Unknown
keys (e.g. `priority`) are preserved in the spec but not rendered today.

## Markdown-only sections (kept in the spec, skipped by the renderer)

`## Unresolved Questions` and `## Resources` may be authored in the spec for
readers of the markdown — open questions, and the Resources
links/screenshots consulted while planning (the Resources Capture habit from
Explore/Clarify: record what you actually used, with descriptive titles, so
a reader can verify the implementation against the same references). The
renderer currently skips headings outside the catalog, so this content does
not appear in the HTML; it still travels with the plan in git and will
render once generic-section support lands. (`## Next Steps` used to be in
this group; it renders since plan-agent 2.21.0 — see its catalog entry.)

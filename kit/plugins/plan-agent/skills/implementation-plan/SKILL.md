---
name: implementation-plan
model: claude-fable-5
description: "Generates HTML implementation-plan documents. Produces a self-contained .html plan file with steps, acceptance criteria, and metadata. Use when the user asks to create or generate an HTML plan file."
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion, Skill, ToolSearch, ExitPlanMode, Artifact, WebFetch, WebSearch, SendUserFile, mcp__claude-in-chrome__tabs_context_mcp, mcp__claude-in-chrome__tabs_create_mcp, mcp__claude-in-chrome__navigate, mcp__claude-in-chrome__computer
argument-hint: "<issue-url|#n> | <plan.md> | <objective> [--quick] [--no-clarify] [--no-align] [--no-interview] [--workflow] [--tdd|--no-tdd] [--from-prompt <path>] [--type feature|fix|refactor|docs|chore] [--template default] [--dir <path>] [--priority low|medium|high|critical]"
---

## Plan Agent — Planning

## How this skill works

You author the plan as a small **Markdown spec** (~5–10 KB) and a bundled
script renders it into the full styled, interactive, self-contained HTML
plan. You own the *content*; the renderer owns *all* presentation — CSS,
JavaScript behaviours, SVG icons, meta tags, HTML escaping, and the sidebar
nav. Progress state travels in the spec too: `- [x]` criteria bullets and
`[x]` step markers render as checked boxes and completed step cards, so
every status or checkbox change is a Markdown edit plus a re-render. Never
hand-write or hand-edit plan HTML.

Render command (`plan-agent-render` ships with this plugin, in `bin/`, which
Claude Code puts on the Bash tool's `PATH` — invoke it by bare name, never by
path):

```bash
plan-agent-render <plan>.md -o <plan>.html
```

Exit 0 = rendered; exit 1 prints exactly which required section is missing
or malformed — fix the spec and re-run. A `PostToolUse` hook
(`hooks/render-plan-html.py`) re-renders the sibling HTML whenever a spec in
the plans directory is written **and a sibling already exists**, but do not
rely on it: plugin `hooks.json` files are not registered in every runtime
(notably the Claude Code desktop app, where they never fire), so a markdown
edit can silently leave the pair stale.
Always run the script explicitly after editing a spec — that also surfaces
parse errors deterministically.

The `.md` spec is the file that gets committed. By default the rendered HTML
is **not** written into the repo at all: Step 7 renders it to the scratchpad
and publishes it as a claude.ai artifact, recording the URL in the spec's
`artifact-url:` frontmatter. Pass `--file` to also write and commit
`<stem>.html` beside the spec — that sibling then wins the gallery card, and
its existence is what tells the render hook to keep it current.

**Guidelines library** (in `guidelines/` beside this file — read the full
file when the step calls for it, not all up front):

- `planning-principles.md` — falsifiable "done", what/why/verify per step,
  end-to-end verification, surfaced risks, explicit scope. Read before
  drafting any plan.
- `section-catalog.md` — every spec section's purpose, when it earns its
  place, and the exact syntax the renderer parses. Read when authoring.
- `right-sizing.md` — minimal / standard / deep profiles and the
  calibration table. Read after the objective is settled, before drafting.
- `red-green-verify.md` — the RED/GREEN/VERIFY/SHIP phase shape, when a plan
  requires it, and the foreground-driver rule for servers. Read when the
  Step 2 detection says it applies or is close.
- `writing-style.md` — tone, plain language, objective-vs-glance. Read when
  authoring.

## Invocation & Arguments

Two activation paths:

- **Command:** `/plan-agent:implementation-plan <objective> [flags]` —
  `$ARGUMENTS` holds the objective and flags.
- **Model (ambient):** activates when the user asks to create a plan
  document, generate an HTML plan, or write a plan file. `$ARGUMENTS` is
  empty; derive the objective from the triggering message or recent
  conversation, then apply the same detection rules below to the derived
  text. If intent is too vague, ask once via `AskUserQuestion("What is the
  objective for this plan?")`. Flags cannot be passed on this path, so it
  runs the full workflow (Clarify + Align + Interview).

Parse `$ARGUMENTS` (or the derived text) in this order:

1. **Issue reference** — a full GitHub issue URL, a full GitLab issue URL,
   a bare `#<n>`, or a plain integer. Set `$ISSUE_REF`, strip it; remaining
   non-flag text overrides the issue title as the objective. Ingestion runs
   in Step 0.5.
2. **Plan file reference** — first non-flag token ending in `.html` becomes
   `$PLAN_FILE` (a revision request). Reduce it to its basename and resolve
   only under the plan roots (`--dir`, configured `plansDirectory`,
   `docs/plans/`). If a sibling `<stem>.md` spec exists, that spec is what
   you edit and re-render. If no spec exists (legacy plan), read the HTML's
   `<title>` for the objective and treat the run as drafting a fresh spec
   for that stem. If the file can't be found, ask for the objective via
   `AskUserQuestion` — do not abort.
3. **Markdown source** — first **positional** token ending in `.md` becomes
   `$MD_SOURCE` (conversion mode, below). Positional means: not a flag, **and
   not a recognized flag's value**. Strip every recognized flag together with
   its value first (see the flag list below), then scan what remains. That
   second clause is the load-bearing one — a path like
   `docs/prompts/proposal-x.md` does not begin with `-`, so under a bare
   "non-flag token" reading it would still be picked up as a conversion source
   even when it arrived as `--from-prompt`'s value.

   **`--from-prompt` and conversion mode are mutually exclusive.** Excluding the
   flag's own value is not enough on its own: an objective can contain a
   positional `.md` of its own (`--from-prompt p.md rewrite docs/plans/old.md`),
   which would otherwise set `$MD_SOURCE` and run both modes at once. When
   `--from-prompt` is present and a positional `.md` is *also* present, that is
   ambiguous input — stop and name both paths, asking which was meant. Never
   silently pick one. With `--from-prompt` and no positional `.md`, skip this
   rule entirely.

   Resolve as given, then by
   basename under the plan roots, then via
   `git show origin/<default-branch>:<path>` after a fetch. If unreadable
   everywhere, report where you searched and ask whether to draft fresh
   from the filename-derived objective — never invent content and present
   it as a conversion.
4. **Objective** — everything left that is not a flag. If still empty
   (and no issue ref), ask once and stop if unanswered.

Flags: `--quick` (= `--no-clarify --no-align --no-interview`),
`--no-clarify`, `--no-align`, `--no-interview`, `--workflow` (always
generate the workflow prompt: set `workflow: always` in the spec
frontmatter), `--tdd` / `--no-tdd` (force or suppress the
RED/GREEN/VERIFY/SHIP phase shape, skipping the Step 2 detection either
way), `--from-prompt <path>` (prompt-source mode, below),
`--file` (also write the rendered `<stem>.html` beside the spec and commit
it — publishing to an artifact happens either way; see Step 7),
`--type <kind>`, `--template <name>` (`default` only;
variants ship later as renderer style shells), `--dir <path>`,
`--priority <level>` (written as a `priority:` frontmatter key; preserved
in the spec, not yet rendered). When `--type` is absent, infer from the
leading verb: create/add/build/implement/introduce → `feature`;
fix/repair/patch/resolve → `fix`; refactor/rename/extract/move/restructure/
convert → `refactor`; document/docs → `docs`; else `chore`. The skip flags
are opt-in only — never inferred. A repeated `--type` resolves last-wins, so a
caller supplying a default must **prepend** it for an explicit user value to
override: the surviving value is the final one, and a default appended after the
user's arguments would beat them instead.

**Prompt-source mode** (`--from-prompt <path>` set): the path names a **context
source**, never a plan. Three shapes reach it — a saved proposal prompt
(`build-proposal`'s handoff), a sub-feature prompt (`build-feature`'s Tier 1+
handoff), and a **Tier 0 feature doc** (`build-feature` writes no prompt at
that tier, so the doc itself is the only carrier for its stories, acceptance
criteria, scope cuts, and risks). Read it for context — the decisions it
settled, the constraints it names, the approach it recommends — then author a
plan through the **normal drafting workflow**. This is not conversion: a
proposal argues *whether and what*, a feature doc argues *what and for whom*,
a plan states *how*, so their headings are input, never a step list to
transcribe. The skip flags are not implied; pass `--quick` explicitly to skip
stages.

**The flag is what keeps a context source out of conversion mode.** A doc
handed over as a positional token would set `$MD_SOURCE` and get 1:1-mapped
even though it has no `Steps` section; naming it as `--from-prompt`'s value
excludes it by rule 3 above. Prose labels do not — `... — feature doc: x.md`
still leaves `x.md` positional.

**Type derivation here has one rule: a source `type:` is used only when it is
already a valid plan type** (`feature`, `fix`, `refactor`, `docs`, `chore`).
Anything else — including a missing key — falls through to leading-verb
inference on the objective. Do not map unrecognized values onto plan types.
This matters because the usual `--from-prompt` target is a **saved prompt**, not
a proposal document, and `prompt` writes its own classifier into that
frontmatter: every prompt `build-proposal` saves carries `type: proposal`, which
names the *prompt's* genre and says nothing about the plan's. Carrying it across
would write an invalid `type:` and fail the render; special-casing it into some
plan type would be a guess. The objective is the better signal, which is why the
handoff leads with it. The same rule covers a `--from-prompt` pointed at the
legacy proposal document, whose `design` value is likewise not a plan type.

If the path is unreadable, say so and ask whether to draft from the objective
alone — never invent proposal content.

**Conversion mode** (`$MD_SOURCE` set): a committed markdown plan is
pre-validated content, so conversion implies `--quick` (extra objective
text requesting changes switches back to full-workflow drafting seeded by
the source). First try rendering the source directly — if
`build-plan-html.mjs` parses it, it already is a spec; polish nothing.
Otherwise restructure the content into the spec format per
`section-catalog.md`: map headings 1:1, derive missing whys/verifies from
the source's surrounding prose, carry `created`/`status`/`type` frontmatter
over (`planned`/`todo` → `todo`, `done` → `completed`) — never invent new
scope. Write the spec into the plans directory (source basename, subject to
the Step 4 rename check) and render. Step 0b becomes a light pass verifying
that files and symbols the source references exist; Step 5c Tests always
runs. Echo `Conversion mode: <md path> → <html path>` with the resolved
flags.

Echo the resolved objective and effective flags after Step 0.

## Scope Constraint — Plans Only

**This skill produces a plan document. It does not implement anything.**

- Do not edit source files, configs, or any file outside the configured
  `plansDirectory` (or `docs/plans/` when no setting exists). Running the
  bundled renderer, publishing the rendered plan as an artifact, and a local
  preview server is allowed.
- Do not apply fixes, refactors, or any change described in the plan's
  steps. `Read`/`Glob`/`Grep`/`Bash` are for read-only exploration.
- Not for general planning questions — this skill creates plan documents,
  not advice. If the objective sounds like "fix X", write a plan for *how*
  to fix X.
- The plan is the deliverable. Implementation is a separate, user-initiated
  step: Step 8's `Implement now` hands off to the `build` skill, which owns
  every source-file write. This constraint is never lifted here.
- A mixed request does not lift it either. "Plan X and build it" — or any
  request that bundles planning with building — still ends at the delivered
  plan: author it, stop, and wait for the user's explicit approval (Step 8's
  `Implement now`, or an equivalent instruction after delivery) before any
  implementation begins. The original request is never that approval.

## What the renderer derives (never author these)

`build-plan-html.mjs` computes everything derivable from the spec:

- **Verification gate (shared by all three prompts)** — every generated
  prompt ends with the same tail: verify against the plan's Tests,
  Verification, and Acceptance Criteria; if everything passed, mark
  completion in the spec (`[x]` step markers, `- [x]` criteria,
  `status: completed`) and re-render; a failed check leaves
  `status: in-progress` and names it. A prompt that says "implement this"
  without the gate lets an agent report done on a plan still marked `todo` —
  never emit one.

  The *check* clause is compressed — naming the three spec sections beats
  spelling out how to walk each one. The *record* clause is not, and must not
  be. 7.0.0 trimmed both and had to restore the second: an unfinished spec
  carries bare numbered steps and bullets, so there is no `[x]` for the agent
  to copy, and the rendered progress bar and step chips read from exactly
  those markers. The re-render stays too — `hooks.json` registers
  `render-plan-html.py` on PostToolUse writes, but that registration is not
  honoured everywhere: the Claude Code desktop app never wires up plugin
  `hooks.json` at all, so a spec edited there leaves the sibling HTML stale.
  The instruction is not redundant in practice. Only `copyCmd()` rebuilds a
  richer prompt from live DOM; `copyGoal()` and `copyWorkflow()` copy this
  tail verbatim, so anything dropped here is dropped on two of three paths.
- **Implement prompt** —
  `Read and implement all steps in the plan at <filepath> — <objective>.`
  plus the verification gate, rendered as the single visible call-to-action
  row and the `plan-implement` meta tag. `<filepath>` is the **markdown
  spec's** relative path, not the HTML's — an implementing agent reads the
  ~5–10 KB spec instead of the 60–120 KB rendered page, and updates
  progress where it lives. Its Copy button copies a fuller action-oriented
  prompt built from live DOM state that walks the agent through the
  markdown-first loop: tick `[x]` step markers and `- [x]` criteria in the
  spec, run the plan's Verification and Tests end-to-end to confirm the
  objective actually works, set `status: completed`, then re-render the sibling HTML so it shows
  every step and criterion complete — never hand-edit the HTML.
- **Goal prompt** — always present: `Achieve this goal: <objective>. The
  plan at <filepath> describes one approach — use it as reference, but
  optimize for the outcome.` plus the verification gate (same spec
  `<filepath>`). Emitted as the
  `plan-goal` meta tag and the "Pursue as goal" drawer row with its
  `copyGoal(this)` copy button. When the workflow prompt below is emitted,
  the sentence `Fan out across parallel subagents where that serves the
  outcome.` is appended after the latitude clause and the row label gains
  `, in parallel` — the two share one gate, so a plan too small for a
  workflow row never licenses fan-out the page does not offer. The lead-in
  stays `Achieve this goal:` in both cases: fan-out is stated as a license
  the outcome grants, never as a leading directive, so the prompt does not
  fix a decomposition before the agent may judge the plan's own to be wrong.
- **Workflow prompt** — `Run a workflow to implement the plan at <filepath>
  — <objective>. Brief subagents with the plan file at <filepath>. Reserve a
  final verification phase for the lead agent, not a subagent.` plus the
  verification gate (same
  spec `<filepath>` — every subagent briefed with the compact spec). Emitted
  (row + `plan-workflow` meta tag) only when frontmatter says
  `workflow: always`, or when `workflow: auto` (the default when the key is
  absent) fires the heuristic — 4+ files across 2+ top-level directories.
  `workflow: never` suppresses it. For the other workflow triggers —
  repetitive per-file changes, independent parallel steps, cross-checking
  review — set `workflow: always` yourself (see `right-sizing.md`).
  `true`/`false` remain accepted as the pre-7.0 spelling of
  `always`/`never`; any other value is a spec error, not a fallback.
- **Next Steps cards** — an optional `## Next Steps` spec section renders as
  collapsible follow-up cards with Copy-prompt buttons (bullet = card;
  fenced block in the bullet = paste-ready prompt). See
  `section-catalog.md` for the syntax.
- **Phase groups** — optional `### Phase: <name>` headings inside `## Steps`
  render each run of step cards inside a `data-phase` wrapper under an `<h3>`.
  Pure grouping over the same flat numbering, so every `[x]` marker stays
  valid; `build` treats each boundary as a checkpoint. See `right-sizing.md`
  for when a plan earns them.
- **Decisions ledger** — an optional `## Decisions` spec section renders as a
  card after Context, with its own sidebar nav entry. Bullets, one settled
  choice each — what a resumed session reads instead of re-deriving.
- **Effort level** — low/medium/high badge from step and file counts
  (low: ≤3 steps and ≤2 files; high: ≥7 steps or ≥6 files). Override with
  the `effort:` frontmatter key when the interview tier justifies it.
- **Progress and completion state** — from the spec's checkbox syntax:
  `- [x]` criteria render as `checked` inputs and drive the progress bar;
  a `[x]` marker after a step number renders the completed step card (chip
  flips to done); the completion checklist (cc1–cc3, `all-complete`) is
  derived from all-steps-done + all-criteria-done + `status: completed`;
  an optional `## Completion Report` section renders as the report list,
  otherwise the default "No items to report" sentence.
- **Everything else** — file-tree grouping, criteria counts, sidebar nav
  filtered to the sections present, the Save as PDF button
  (`save-pdf-btn`, prints via the browser dialog), copy buttons, meta tags
  (`plan-status`, `plan-effort`, `plan-type`, `plan-created`, `plan-repo`,
  `plan-file`, `plan-path`, `plan-md`, `plan-implement`, `plan-goal`,
  conditional `plan-workflow` and `plan-issue`), and HTML escaping.

## Workflow

0. **Self-bootstrap** —
   **If in plan mode**, call `ExitPlanMode` first — this workflow mutates state.

0.5. **Issue Ingestion** *(skip when no issue reference was detected)* —
   Fetch via `gh issue view <n> --repo <owner>/<repo> --json
   title,body,labels,assignees,milestone,url` (resolve owner/repo with
   `gh repo view --json owner,name` for bare `#n`) or `glab issue view <n>
   --repo <owner>/<repo> --output json` for GitLab. Mapping: `title` →
   objective (caller's extra text wins); `body` → an "Issue context" block
   in the spec's Context section; `labels` → `--type` hint (`bug` → `fix`,
   `enhancement`/`feature` → `feature`); `url` → cite in Context and record
   as an `issue:` frontmatter key. On any CLI failure, print a one-line
   error (e.g. `Issue #42 not found — falling back to plain objective`) and
   continue with the plain objective — never abort.

0b. **Explore** — Read the codebase before planning: `Glob` for relevant
   files, `Grep` for symbols and patterns, `Read` for the architecture the
   plan touches. Focus on entry points the plan modifies, existing tests
   and conventions to follow, and constraints. Keep exploration
   proportional to scope. Note references worth citing (docs, issues,
   screenshots) for the spec's markdown-only Resources section.
   *(Skip entirely when `--quick`.)*

1. **Clarify** — If objectives are ambiguous, resolve them via
   `AskUserQuestion` before drafting; if already clear, skip — no friction
   on well-specified requests. Use `WebSearch`/`WebFetch` (load via
   `ToolSearch` with `select:WebSearch,WebFetch` — they are deferred) when
   research would strengthen the plan; record what you consult for the
   Resources list. *(Skip entirely when `--quick` or `--no-clarify`.)*

2. **Author the spec** — Resolve the target directory identically to
   `plans-library`/`plans-open`: (1) `--dir` if provided, otherwise (2) the
   settings-precedence snippet below.

```bash
PLANS_DIR=$(python3 - <<'EOF'
import json, os, sys
# Claude settings precedence: project-local → project → user-global
candidates = (
    os.path.join(os.getcwd(), '.claude', 'settings.local.json'),
    os.path.join(os.getcwd(), '.claude', 'settings.json'),
    os.path.join(os.path.expanduser('~'), '.claude', 'settings.json'),
)
for path in candidates:
    try:
        v = json.load(open(path)).get('plansDirectory', '').strip()
        if v:
            print(v); sys.exit(0)
    except Exception:
        pass
print(os.path.join(os.getcwd(), 'docs', 'plans'))
EOF
)
```

   Then:

   1. Read `guidelines/planning-principles.md` and
      `guidelines/right-sizing.md`; classify the work (minimal / standard /
      deep) and decide which optional sections earn their place.

      Then decide whether the plan is **red-green-verify** — steps grouped
      into `### Phase: RED` / `GREEN` / `VERIFY` / `SHIP`. It applies when
      the steps touch application source *and* Step 0b found a test runner;
      it does not apply to Tier 2 doc/plan/metadata work, which has nothing
      to fail. When the call is close — Tier 1 with no runner, config-only
      edits, a spike — ask once via `AskUserQuestion` rather than guessing,
      and say which you'd pick. Under `--quick`, Step 0b never ran: do one
      cheap runner check (a `test` script, a pytest config, a `*_test.go`)
      and treat no hit as no RGV rather than inferring from nothing.
      `--no-tdd` suppresses the shape; `--tdd` forces it even with no
      runner, and then RED's first step stands the runner up so the added
      scope is visible in the plan. Read `guidelines/red-green-verify.md`
      before drafting the phases; it owns the per-phase step content, the
      8-iteration GREEN cap, the UI-only scoping of the browser steps, the
      user-asked-to-ship condition on SHIP, and the foreground Node driver
      that replaces `&`/`nohup` (blocked by permissions).
   2. Read `guidelines/section-catalog.md` and
      `guidelines/writing-style.md`, then draft the spec —
      `reference/SKELETON.md` is a copyable starter. Required always:
      title, Objective, Steps (action + `Why:` + `Verify:` per item),
      Acceptance Criteria, Verification. Optional by judgment: Context,
      Decisions (the settled-choices ledger), Files, Tests (filled in
      Step 5c), `### Phase:` groupings inside Steps, Next Steps (rendered as
      collapsible follow-up cards), the frontmatter keys, and the
      markdown-only sections (Unresolved Questions, Resources).
   3. Write it to `$PLANS_DIR/<verb-target>.md` — kebab-case `verb-target`
      filename (`add-dark-mode-toggle.md`, `fix-login-redirect.md`). The
      rendered plan will live at the same stem with `.html`.

   Read `planAgent.extraFrontmatter` from `.claude/settings.json` (project
   first, then global) and write any pairs as additional frontmatter keys;
   `--priority` overrides a `priority` key from settings.

3. **Frontmatter** — Set the spec's YAML frontmatter: `status: todo`,
   `type:` (from `--type` or the verb inference), `created:` (today,
   YYYY-MM-DD), and — when they earn their place — `glance:` (single line),
   `effort:`, `workflow:`. `repo` may be omitted: the renderer resolves the
   `origin` remote basename and falls back to the cwd basename. See the
   catalog's frontmatter table for the full key list.

   The enumerated keys accept exactly these values — anything else fails the
   render with a message naming the key and the valid set, rather than
   quietly rendering something you did not write:

   | key | values | default when absent |
   |---|---|---|
   | `status` | `todo`, `in-progress`, `completed` | `todo` |
   | `type` | `feature`, `fix`, `refactor`, `docs`, `chore` | `feature` |
   | `effort` | `low`, `medium`, `high` | derived from step and file counts |
   | `workflow` | `auto`, `always`, `never` (`true`/`false` accepted as the pre-7.0 spelling of `always`/`never`) | `auto` |

4. **Rename** — re-check the filename before rendering. Rename when (a) the
   initial name is auto-generated, placeholder, or non-descriptive, or (b) the
   plan's purpose shifted after creation. A stale filename is a plan defect — do
   not deliver until the name matches the content. Enforced by the
   `validate-plan-filename` `PostToolUse` hook
   (`${CLAUDE_PLUGIN_ROOT}/hooks/validate-plan-filename.py`).

5. **Align** — After steps are drafted, use `AskUserQuestion` (batched,
   covering each step) to confirm every step aligns with the objective.
   This verifies step-to-objective alignment, not overall approval.
   *(Skip entirely when `--quick` or `--no-align`.)*

5b. **Interview** — Stress-test the drafted spec before delivering.
   *(Skip entirely when `--quick` or `--no-interview`.)*

    **Complexity detection:** classify the plan just drafted —
    **Short/focused** (single concern, 1–2 files): Round 1 only.
    **Medium** (feature with UI + logic, or 2 domains): Rounds 1 + 2.
    **Complex** (architecture, cross-cutting, 3+ domains): Rounds 1 + 2 + 3.

    **UI override:** any UI signal (React, Vue, Svelte, Angular,
    `.tsx`/`.jsx`/`.css`/`.html` files, `className`/Tailwind, or UX terms —
    button, modal, form, dialog, page, component) always pulls in Round 2,
    even for short plans; note what triggered it.

    Each round is one `AskUserQuestion` call with up to 4 questions
    generated from the plan content — never generic:
    - **Round 1 — Technical & Trade-offs** (always): the most uncertain
      design decision, build-vs-buy, performance/data-model concerns,
      unclear integration points.
    - **Round 2a — UI/UX & Flows:** happy path, error/loading/empty states,
      responsive behaviour, motion (`prefers-reduced-motion`), UI state
      gaps.
    - **Round 2b — Accessibility & Semantic:** keyboard navigation and
      focus management, screen reader support (ARIA), WCAG 2.1 AA (contrast
      4.5:1, touch targets 44×44px), semantic HTML.
    - **Round 3 — Edge Cases & Best Practices** (complex only): failure
      modes and race conditions, concurrency/data conflicts, regression
      risks, remaining open questions.

    **Post-interview:** summarize decisions confirmed and concerns
    surfaced, then ask via `AskUserQuestion`: "Update the plan with
    interview findings?" If confirmed, edit the spec markdown — extend step
    whys/verifies, add criteria, record open questions — then proceed. If
    the tier came out complex, consider `effort: high` in the frontmatter.

5c. **Tests** — Populate the spec's `## Tests` section. This step always
   runs — never skipped by any flag. Classify the tier by what the steps
   actually do (Tier 1 when any step creates, modifies, or deletes
   application source files; Tier 2 otherwise — the `type:` key is
   irrelevant). Author the tier line and test bullets per
   `section-catalog.md`: the objective-verification test always first
   (File / Type / Asserts / Run — it must assert the plan's stated
   objective is accomplished in the running application), then whichever of
   unit/integration/E2E the steps warrant (Tier 1 only, never empty stubs).
   Follow test-path conventions detected in Step 0b; default to
   `__tests__/<feature>.<type>.test.ts`. On a red-green-verify plan these
   bullets name the same files the RED phase steps author — the section is
   the catalogue, the phase is the schedule. Do not let the two drift.

5d. **Render** — Run the render command from the top of this file, writing to
   **Step 7a's output path** — the scratchpad in default mode, `<stem>.html`
   beside the spec under `--file`. Step 7a owns that choice; do not write a
   sibling `.html` here on your own, because default mode deliberately leaves
   the repo without one and an unwanted sibling then wins the gallery card
   over the artifact. On exit 1, fix the reported spec problem
   and re-run — never hand-edit the HTML to compensate. Re-run the render
   after *any* later edit to the spec.

6. **Status** — All plan state lives in the spec markdown; the HTML is a
   pure render of it. The `status:` frontmatter (`todo` → `in-progress` →
   `completed`) stamps all three HTML representations (`<html
   data-status>`, the `plan-status` meta tag, the visible badge). Step
   completion is a `[x]` marker after the step number (`3. [x] <action>
   …`); criterion completion is a `- [x]` checkbox bullet under
   `## Acceptance Criteria` (author new criteria as `- [ ]` or plain `- `
   — both render unchecked). Every state change is a one-line Markdown
   edit followed by a re-render (the `render-plan-html.py` hook does this
   on each spec write *where plugin hooks are registered* — they are not in
   the desktop app, so run the Step 5d command rather than assuming it fired). Re-rendering is lossless — progress re-renders
   from the spec, so there is no state to re-apply. Never edit `checked`
   attributes, `.step-card` classes, or status attributes in the HTML;
   `/plan-agent:finalize-plan` follows the same rule. A user ticking a box
   in the browser changes only their local DOM/file copy — tool-side state
   belongs in the spec.

7. **Publish** — Deliver the plan as a claude.ai artifact. Mandatory — do
   not skip. After all sub-steps complete, proceed immediately to Step 8.

   A plan is something people read and share, so its address is a URL by
   default. The Markdown spec stays in the plans directory and is committed;
   the rendered HTML is a *view* of it, and by default that view lives on
   claude.ai rather than as a 60–120 KB generated file in every plan commit.

   7a. **Render to the scratchpad, not beside the spec.** In default mode the
   repo gets no `.html`:

   ```bash
   plan-agent-render <spec>.md -o "$SCRATCHPAD/<stem>.html"
   ```

   With `--file`, render to `<stem>.html` beside the spec instead — that file
   is committed alongside the spec and, because a sibling exists, it wins the
   gallery card and the render hook keeps maintaining it. Publishing still
   happens either way.

   7b. **Re-read the spec's frontmatter immediately before publishing.** If it
   already carries an `artifact-url:` **that parses as an `http(s)` URL with a
   host**, pass it to `Artifact` so the plan updates its existing page instead
   of claiming a new one. Anything else — a hand-edited `javascript:` value, a
   truncated `https://` — is not a page to update: say so in one line, drop the
   key, and publish fresh. Read it fresh
   rather than trusting a value from earlier in this session — Step 5b and
   Step 6 may have rewritten the file, and publishing to a second URL silently
   strands whatever link the user already shared.

   7c. **Publish.** Call `Artifact` with the rendered HTML file path, a
   `favicon`, and a one-sentence `description`. Pass `url` when 7b found one.

   7d. **Write the URL back.** Put the returned URL in the spec's frontmatter
   as `artifact-url: <url>` (replacing any existing value) and re-render so the
   generated prompts carry the republish clause — `build-plan-html.mjs` appends
   it to the implement, goal, and workflow prompts whenever the key is present,
   which is how a fresh-session agent learns to keep the shared page current.

   In default mode this write is what puts the plan in the gallery at all:
   `build-index.sh` cards a spec with no sibling `.html` only when it carries
   an `http(s)` `artifact-url:`. Rebuild the gallery so the card appears now:

   ```bash
   plan-agent-plans-index
   ```

   7e. **Report.** Give the user the artifact URL. With `--file`, also send the
   `.html` and `.md` via `SendUserFile` and name the committed paths.

   **Fallback — publishing unavailable.** If `Artifact` is not available or the
   call fails, say so in one line, then deliver as a file: render `<stem>.html`
   beside the spec, send it (and the `.md`) via `SendUserFile`, and report the
   paths. Do not retry silently and do not leave the plan undelivered.

   **Leave an existing `artifact-url:` exactly as it is.** A failed republish is
   a transient outage, not a retirement: clearing the key orphans the page
   people already have and lets the next publish claim a second one. Only a plan
   that has never published ends up with no key — and there the sibling `.html`
   is what the gallery cards, the same result `--file` produces deliberately.

8. **Implement, Edit, or Exit** — After Step 7 completes, always ask the
   user what to do next.

   Use `AskUserQuestion` with **three questions batched in one call**, in
   this order: the tracking-issue question **first**, the see-it-first
   question **second**, and the next-step question **third**. Each of the
   first two drops out under its own condition below, so the batch is two
   questions — or one — whenever a condition applies; the surviving
   questions keep this relative order.
   - Question: "Create a tracking issue for this plan on GitHub/GitLab?"
   - Options:
     - `Yes — create an issue` — Run the `git-agent:create-issue` skill with this plan.
     - `No` — Skip issue creation.

   **Skip the tracking-issue question entirely when the spec's frontmatter
   already carries an `issue:` key** — the plan was seeded from an issue
   (Step 0.5) or one was created in an earlier pass through this menu.
   Creating another would duplicate the backlog item and overwrite the
   existing link; ask only the remaining questions and mention the linked
   issue URL in one line instead.

   For the see-it-first question:
   - Question: "Want to see it before building?"
   - Options:
     - `Prototype` — Generate a clickable static-HTML prototype under docs/prototypes/.
     - `Design canvas` — Publish an editable design canvas with one artboard per user-facing step.
     - `No` — Go straight to the next step.

   **Ask the see-it-first question only when the plan carries UI signals.**
   Reuse the `ui_signals_present` rule already defined in
   `skills/review-plan/SKILL.md`, "Step 3b — Detect UI signals" — that file
   owns the keyword list, and a second definition here would drift from it.
   On a plan with no UI signals, omit the question entirely: neither
   `Prototype` nor `Design canvas` is offered, because there is no surface
   for either to draw.

   For the next-step question, **when a workflow prompt was generated**
   (frontmatter `workflow: always` or the renderer's heuristic fired — check
   for the `plan-workflow` meta tag in the rendered HTML), include the
   workflow option:
   - Question: "The plan is complete. What would you like to do next?"
   - Options (when workflow prompt exists):
     - `Implement now` — Begin implementing the plan steps, in this session or a fresh one.
     - `Run as workflow` — Launch a dynamic workflow (`/workflows`) to implement steps in parallel with subagents.
     - `Review the plan` — Run the `review-plan` Agent Team on this plan before implementing.
     - `Exit — I'll implement later` — Stop here; no further action.
   - Options (when no workflow prompt):
     - `Implement now` — Begin implementing the plan steps, in this session or a fresh one.
     - `Review the plan` — Run the `review-plan` Agent Team on this plan before implementing.
     - `Edit the plan` — Revise or extend the plan before implementing.
     - `Exit — I'll implement later` — Stop here; no further action.

   **If the user answered `Yes — create an issue`:** before acting on the
   next-step choice, invoke
   `Skill(skill: "git-agent:create-issue", args: "plan <spec path>")` with
   the markdown spec's repo-relative path. That skill handles host
   detection, drafting, and its own confirmation gate; when it finishes,
   record the created issue URL as an `issue:` frontmatter key in the spec
   and re-render — the renderer turns that key into the `plan-issue` meta tag
   and the header link, so the plan carries its ticket for tracking and for
   whoever closes it. If the `git-agent` plugin is not installed (the Skill
   call fails to resolve), say so in one line and continue with the
   next-step choice — never block on it.

   **If the user answered `Prototype`:** before acting on the next-step
   choice, invoke `Skill(skill: "plan-agent:prototype", args: "<plan path>")`
   with the rendered plan's relative path. That skill owns the derivation,
   the escaping rules, and its own browser verification; when it finishes,
   return here and act on the next-step choice.

   **If the user answered `Design canvas`:** before acting on the next-step
   choice, invoke `Skill(skill: "plan-agent:design", args: "<plan path>")`
   with the rendered plan's relative path. That skill derives one artboard
   per user-facing step, delegates authoring to the built-in design skill,
   and writes `design:` / `design-dir:` back into the spec; when it
   finishes, return here and act on the next-step choice.

   **If the user answered `No` to the see-it-first question:** continue
   straight to the next-step choice.

   Both `prototype` and `design` ship in this same plugin, so a resolution
   failure means a broken skill reference, not a missing dependency —
   report it as an error in one line and continue with the next-step
   choice; never block on it.

   **If the user chooses `Implement now`:** Ask where to implement using
   `AskUserQuestion` with a single question:
   - Question: "Implement in this session, or hand off to a fresh one?"
   - Options:
     - `This session` — Start building now; planning context stays loaded.
     - `Fresh session` — Print the implement prompt to paste after `/clear`, for a clean context window.

   **If the user chooses `Fresh session`:** Set status to `in-progress` (spec +
   re-render), then output the implement prompt (the `plan-implement` meta tag)
   and tell the user to run `/clear` first, then paste it. Stop there — do not
   implement. The prompt is self-contained by design: it names the markdown
   spec, and the spec carries the whole plan, so nothing in this conversation
   is load-bearing after the handoff. Claude cannot clear its own context —
   `/clear` is a client command the user types — so never claim to have cleared
   it, and never silently skip the instruction.

   **If the user chooses `This session`:** Invoke
   `Skill(skill: "plan-agent:build", args: "<spec path>")` with the markdown
   spec's relative path. That skill owns the implementation loop and its
   three gates — acceptance criteria, end-to-end verification, completion
   checklist — and marks progress in the spec. Do not duplicate its steps
   here, and do not implement any part of the plan in this skill: the Scope
   Constraint above stays in force, because the writing now happens in
   `build`.

   `build` ships in this same plugin, so a resolution failure means a broken
   skill reference, not a missing dependency — report it as an error rather
   than degrading silently, then emit the implement prompt (`plan-implement`
   meta tag) so the user can still proceed by pasting it.

   **If the user chooses `Run as workflow`:** Output the workflow prompt
   (from the `plan-workflow` meta tag) for the user to paste — the word
   "workflow" triggers Claude Code's workflow runtime. Set status to
   `in-progress` (spec + re-render). Do not implement directly.

   **If the user chooses `Review the plan`:** Ask whether to run the review
   in the foreground or background using `AskUserQuestion` with a single
   question:
   - Question: "Run the plan review now, or dispatch it in the background?"
   - Options:
     - `Run now (foreground)` — Review runs in this session; you will see progress as it works.
     - `Background` — Dispatch the review to a detached Agent Team; you will be notified on completion.

   **If the user chooses `Run now (foreground)`:** Invoke
   `Skill(skill: "plan-agent:review-plan", args: "<plan path>")` with the
   rendered plan's relative path. Handle `review-plan`'s hard-stop
   gracefully if Agent Teams are unavailable (Claude Code < 2.1.32 or
   `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` unset): relay its guidance and
   return to the Step 8 menu without error. After a successful foreground
   review, re-render if the spec changed, republish via the Step 7 sub-steps,
   then loop back to this menu. Leave plan `status` at `todo` — reviewing
   is not implementing.

   **If the user chooses `Background`:** Invoke
   `Skill(skill: "plan-agent:review-plan-bg", args: "<plan path>")` — it
   dispatches the `agent-review-plan` background agent with
   `run_in_background: true` and returns an ack immediately. Return to the
   Step 8 menu and note the user can reopen the plan once the detached run
   finishes. Leave plan `status` at `todo`.

   **If the user chooses `Edit the plan`:** Ask what to change via
   `AskUserQuestion`, apply the edits to the **spec markdown**, re-render
   (Step 5d), republish (Step 7 — 7b reuses the existing `artifact-url:`, so
   the shared link keeps working), then loop back to this menu.

   **If the user chooses `Exit`:** Stop immediately. No implementation, no
   status change — the plan stays at `todo` everywhere.

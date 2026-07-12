---
name: implementation-plan
model: fable
description: "Generates HTML implementation-plan documents. Produces a self-contained .html plan file with steps, acceptance criteria, and metadata. Use when the user asks to create or generate an HTML plan file."
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion, Skill, ToolSearch, ExitPlanMode, WebFetch, WebSearch, SendUserFile, mcp__claude-in-chrome__tabs_context_mcp, mcp__claude-in-chrome__tabs_create_mcp, mcp__claude-in-chrome__navigate, mcp__claude-in-chrome__computer
argument-hint: "<issue-url|#n> | <plan.md> | <objective> [--quick] [--no-clarify] [--no-align] [--no-interview] [--workflow] [--type feature|fix|refactor|docs|chore] [--template default] [--dir <path>] [--priority low|medium|high|critical]"
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

Render command (the script ships with this plugin):

```bash
node "${CLAUDE_PLUGIN_ROOT}/scripts/build-plan-html.mjs" <plan>.md -o <plan>.html
```

Exit 0 = rendered; exit 1 prints exactly which required section is missing
or malformed — fix the spec and re-run. A `PostToolUse` hook
(`hooks/render-plan-html.py`) also re-renders the sibling HTML whenever a
spec in the plans directory is written, so later markdown edits keep the
pair fresh; still run the script explicitly after authoring so parse errors
surface deterministically. Both files — the `.md` source of truth and the
rendered `.html` — are committed together in the plans directory.

**Guidelines library** (in `guidelines/` beside this file — read the full
file when the step calls for it, not all up front):

- `planning-principles.md` — falsifiable "done", what/why/verify per step,
  end-to-end verification, surfaced risks, explicit scope. Read before
  drafting any plan.
- `section-catalog.md` — every spec section's purpose, when it earns its
  place, and the exact syntax the renderer parses. Read when authoring.
- `right-sizing.md` — minimal / standard / deep profiles and the
  calibration table. Read after the objective is settled, before drafting.
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
3. **Markdown source** — first non-flag token ending in `.md` becomes
   `$MD_SOURCE` (conversion mode, below). Resolve as given, then by
   basename under the plan roots, then via
   `git show origin/<default-branch>:<path>` after a fetch. If unreadable
   everywhere, report where you searched and ask whether to draft fresh
   from the filename-derived objective — never invent content and present
   it as a conversion.
4. **Objective** — everything left that is not a flag. If still empty
   (and no issue ref), ask once and stop if unanswered.

Flags: `--quick` (= `--no-clarify --no-align --no-interview`),
`--no-clarify`, `--no-align`, `--no-interview`, `--workflow` (always
generate the workflow prompt: set `workflow: true` in the spec
frontmatter), `--type <kind>`, `--template <name>` (`default` only;
variants ship later as renderer style shells), `--dir <path>`,
`--priority <level>` (written as a `priority:` frontmatter key; preserved
in the spec, not yet rendered). When `--type` is absent, infer from the
leading verb: create/add/build/implement/introduce → `feature`;
fix/repair/patch/resolve → `fix`; refactor/rename/extract/move/restructure/
convert → `refactor`; document/docs → `docs`; else `chore`. The skip flags
are opt-in only — never inferred.

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
  bundled renderer and a local preview server is allowed.
- Do not apply fixes, refactors, or any change described in the plan's
  steps. `Read`/`Glob`/`Grep`/`Bash` are for read-only exploration.
- Not for general planning questions — this skill creates plan documents,
  not advice. If the objective sounds like "fix X", write a plan for *how*
  to fix X.
- The plan is the deliverable. Implementation is a separate, user-initiated
  step (Step 8 lifts this constraint only when the user chooses it).

## What the renderer derives (never author these)

`build-plan-html.mjs` computes everything derivable from the spec:

- **Implement prompt** —
  `Read and implement all steps in the plan at <filepath> — <objective>`,
  rendered as the single visible call-to-action
  row and the `plan-implement` meta tag. Its Copy button copies a fuller
  action-oriented prompt built from live DOM state.
- **Goal prompt** — always present: `Achieve this goal: <objective>. The
  plan at <filepath> describes one approach — use it as reference, but
  optimize for the outcome`. Emitted as the `plan-goal` meta tag and the
  "Pursue as goal" drawer row with its `copyGoal(this)` copy button.
- **Workflow prompt** — `Run a workflow to implement the plan at <filepath>
  — <objective>. Brief subagents with the plan file at <filepath>`. Emitted
  (row + `plan-workflow` meta tag) only when frontmatter says
  `workflow: true` or the heuristic fires (5+ files across 3+ top-level
  directories). `workflow: false` suppresses it. For the other workflow
  triggers — repetitive per-file changes, independent parallel steps,
  cross-checking review — set `workflow: true` yourself (see
  `right-sizing.md`).
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
  `plan-file`, `plan-path`, `plan-implement`, `plan-goal`, conditional
  `plan-workflow`), and HTML escaping.

## Workflow

Follow these steps exactly.

0. **Self-bootstrap** — **If currently in plan mode**, call `ExitPlanMode`
   first and silently before any other action — writing plan files is a
   filesystem mutation that cannot proceed inside harness plan mode.
   `ExitPlanMode` is a deferred tool: use `ToolSearch` with
   `select:ExitPlanMode` first, then call it silently. Skip entirely when
   not in plan mode.

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
   2. Read `guidelines/section-catalog.md` and
      `guidelines/writing-style.md`, then draft the spec —
      `reference/SKELETON.md` is a copyable starter. Required always:
      title, Objective, Steps (action + `Why:` + `Verify:` per item),
      Acceptance Criteria, Verification. Optional by judgment: Context,
      Files, Tests (filled in Step 5c), the frontmatter keys, and the
      markdown-only sections (Next Steps, Unresolved Questions, Resources).
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

4. **Rename** — **Always** ensure the filename follows the `verb-target`
   kebab-case convention before rendering. Rename when (a) the initial name
   is auto-generated, placeholder, or non-descriptive, or (b) the plan's
   purpose shifted after creation. A stale filename is a plan defect — do
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
   `__tests__/<feature>.<type>.test.ts`.

5d. **Render** — Run the render command from the top of this file, writing
   `<stem>.html` beside the spec. On exit 1, fix the reported spec problem
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
   automatically on each spec write; run the Step 5d command when you need
   the failure surfaced). Re-rendering is lossless — progress re-renders
   from the spec, so there is no state to re-apply. Never edit `checked`
   attributes, `.step-card` classes, or status attributes in the HTML;
   `/plan-agent:finalize-plan` follows the same rule. A user ticking a box
   in the browser changes only their local DOM/file copy — tool-side state
   belongs in the spec.

7. **Open** — Deliver the plan and verify rendering. Mandatory — do not
   skip. After all sub-steps complete, proceed immediately to Step 8.

   **Try browser verification first:**
   1. Load browser tools via `ToolSearch` with
      `select:mcp__claude-in-chrome__tabs_context_mcp,mcp__claude-in-chrome__navigate,mcp__claude-in-chrome__computer`.
      No matches → the browser MCP server is not connected; use the
      fallback below.
   2. Find a free port: `python3 -c "import socket; s=socket.socket(); s.bind(('', 0)); print(s.getsockname()[1]); s.close()"`.
   3. `cd <plan-dir> && python3 -m http.server <port> &`.
   4. `mcp__claude-in-chrome__tabs_context_mcp` with `createIfEmpty: true`.
   5. Navigate to `http://localhost:<port>/<plan-filename>` (the `.html`).
   6. Screenshot (`action: screenshot`, `save_to_disk: true`) and send it
      to the user.
   7. Send the plan file via `SendUserFile` (the `.html`; include the `.md`
      spec so the user has the source too).
   8. Report the URL and leave the server running.

   **Fallback (no browser tools):** send the `.html` (and `.md`) via
   `SendUserFile` and report the file paths.

8. **Implement, Edit, or Exit** — After Step 7 completes, always ask the
   user what to do next.

   Use `AskUserQuestion` with a single question. **When a workflow prompt
   was generated** (frontmatter `workflow: true` or the renderer's
   heuristic fired — check for the `plan-workflow` meta tag in the rendered
   HTML), include the workflow option:
   - Question: "The plan is complete. What would you like to do next?"
   - Options (when workflow prompt exists):
     - `Implement now` — Begin implementing the plan steps in the current session.
     - `Run as workflow` — Launch a dynamic workflow (`/workflows`) to implement steps in parallel with subagents.
     - `Review the plan` — Run the `review-plan` Agent Team on this plan before implementing.
     - `Exit — I'll implement later` — Stop here; no further action.
   - Options (when no workflow prompt):
     - `Implement now` — Begin implementing the plan steps in the current session.
     - `Review the plan` — Run the `review-plan` Agent Team on this plan before implementing.
     - `Edit the plan` — Revise or extend the plan before implementing.
     - `Exit — I'll implement later` — Stop here; no further action.

   **If the user chooses `Implement now`:** Lift the Scope Constraint for
   this session only. Set the spec's `status:` to `in-progress`, then work
   through each step sequentially — apply the changes, verify each step,
   and mark progress in the spec as you go (insert the `[x]` marker after
   each finished step's number; the re-render flips the card and chip).

   **Acceptance criteria gate (mandatory — after all steps, before marking
   `completed`):**
   1. Read each criterion from the spec's `## Acceptance Criteria` bullets.
   2. Verify each one — run the relevant command or inspect the changed
      files.
   3. Check a criterion off by flipping its bullet to `- [x]` only after
      confirming it; flip back to `- [ ]` to undo. Markdown edits in the
      spec — never `checked` attributes in the HTML, a JS toggle, or
      browser-only persistence.
   4. If any criterion cannot be verified, list the unverified items via
      `AskUserQuestion` ("Mark them as done anyway?" — `Yes, check them
      off` / `No, leave unchecked`).
   5. Only set `status: completed` after every criterion is checked;
      otherwise set `in-progress` and note what remains open. The
      re-render stamps the status into all three HTML representations.

   **End-to-end verification gate (mandatory — after the criteria gate):**
   confirms the *objective* works end-to-end, not just that criteria are
   met.
   1. Read the plan's Verification section and Tests section.
   2. Run the objective-verification test via its authored **Run** command;
      run the other test entries via the project's test runner against
      their **File** paths (they carry no per-card run command). No
      detectable runner → run only the objective test and say so. Tier 2
      with nothing runnable → walk the Verification section and confirm end
      state by inspection.
   3. Confirm the objective test passes and every verification step holds.
   4. **On failure — fix and re-verify (bounded loop):** diagnose, fix the
      source files, re-run from sub-step 2, up to 3 times. Still failing →
      STOP and ask via `AskUserQuestion` ("End-to-end verification is still
      failing after 3 fix attempts: <summary>. How do you want to
      proceed?") with `Keep trying` / `Mark in-progress and stop` / `Mark
      completed anyway`. Set status only per the chosen option; for either
      "Mark" option add a Completion Report entry naming the failing check
      and reason.
   5. Proceed only once verification holds — or the user explicitly chose
      to proceed anyway. Report the outcome briefly.

   **Completion checklist gate (mandatory — before committing):**
   1. Verify in the spec: (a) every step carries its `[x]` marker, (b)
      every acceptance criterion is `- [x]`, (c) the frontmatter says
      `status: completed`.
   2. Re-render and confirm the derived state: all `.step-card` elements
      completed, all criteria inputs `checked`, the three status
      representations `completed`, cc1–cc3 checked and the
      `completion-checklist` div carrying `all-complete`. The renderer
      computes all of this from (a)–(c) — if something is missing, fix the
      spec, never the HTML.
   3. Any condition unmet → keep `status: in-progress` and write a
      `## Completion Report` section in the spec (after
      `## Acceptance Criteria`): one `- <exact step/criterion> — <reason>`
      bullet per gap — never a generic "some steps incomplete". The
      renderer turns it into the report list; when everything is resolved,
      remove the section and the default "No items to report" sentence
      returns.

   Commit the source changes together with the updated spec and HTML when
   implementation finishes.

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
   review, re-render if the spec changed, re-open via the Step 7 sub-steps,
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
   (Step 5d), re-open (Step 7), then loop back to this menu.

   **If the user chooses `Exit`:** Stop immediately. No implementation, no
   status change — the plan stays at `todo` everywhere.

---
name: implementation-plan
model: opus
description: "Generate an HTML implementation-plan document. Produces a self-contained .html plan file with steps, acceptance criteria, and metadata. Use when the user asks to create a plan document, generate an HTML plan, convert a markdown plan into an HTML implementation plan, or write a plan file — not for general planning questions."
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion, Skill, ToolSearch, ExitPlanMode, WebFetch, WebSearch, SendUserFile, mcp__claude-in-chrome__tabs_context_mcp, mcp__claude-in-chrome__tabs_create_mcp, mcp__claude-in-chrome__navigate, mcp__claude-in-chrome__computer
argument-hint: "<issue-url|#n> | <plan.md> | <objective> [--quick] [--no-clarify] [--no-align] [--no-interview] [--workflow] [--type feature|fix|refactor|docs|chore] [--template default] [--dir <path>] [--priority low|medium|high|critical]"
---

## Plan Agent — Planning

## Invocation & Arguments

This skill supports two activation paths:

- **Command invocation:** `/plan-agent:implementation-plan <objective> [flags]` — `$ARGUMENTS` contains the objective and flags. All flags (`--quick`, `--no-clarify`, `--no-align`, `--no-interview`, `--workflow`, `--type`, `--template`, `--dir`, `--priority`) are available.
- **Model invocation (ambient activation):** Claude auto-activates this skill when the user asks to create a plan document, generate an HTML plan, or write a plan file. `$ARGUMENTS` is empty on this path. The objective is derived from the user's triggering message or recent conversation context. Before treating the derived text as a plain objective, run the same issue-reference, plan-file-reference, and markdown-conversion detection described below against it — e.g. "create a plan document for #42" should detect `#42` as an issue reference and trigger Step 0.5 ingestion, and "convert docs/plans/foo.md into an HTML implementation plan" should set `$MD_SOURCE` and enter conversion mode. If the intent is too vague to infer an objective, ask once via `AskUserQuestion("What is the objective for this plan?")`. Since flags cannot be passed on the model path, ambient activation runs the full workflow (Clarify + Align + Interview) by default — users who want a fast run should use the `/plan-agent:implementation-plan` command form with flags.

Read `$ARGUMENTS` on entry (on the model-invocation path, apply these same detection rules to the conversation-derived objective text):

**Issue reference detection (checked first, before flag parsing):** Treat `$ARGUMENTS` (or the conversation-derived text on the model path) as containing an issue reference if any token matches one of these three patterns:
- Full GitHub URL: `https://github.com/<owner>/<repo>/issues/<n>`
- Full GitLab URL: `https://gitlab.com/<owner>/<repo>/-/issues/<n>`
- Bare `#<n>` or plain integer (e.g. `42`) — always treated as an issue reference even when override text follows (e.g. `/plan-agent:implementation-plan #205 focus on the auth layer --quick` is valid)

When a reference is detected, set an internal `$ISSUE_REF` variable and strip it from the remaining argument string. Everything left (after removing the reference and any flags) becomes the caller's extra text. If extra text is non-empty it overrides the issue title as the objective; if empty, the issue title is used as the objective. Issue ingestion runs in Step 0.5.

**Plan file reference detection (checked after issue ref detection, before objective extraction):** If the first non-flag token ends in `.html`, treat it as a plan file reference — strip it from the argument string and store it as `$PLAN_FILE`. The remaining text becomes the objective. This allows a plan revision command (e.g. `/plan-agent:implementation-plan add-dark-mode-toggle.html add dark mode toggle`) to be pasted verbatim without the filename polluting the objective. When `$PLAN_FILE` is set and the remaining objective text is empty, attempt to read the existing plan's `<title>` tag (strip the leading "Plan: " prefix) as the objective fallback. **Path safety:** always reduce `$PLAN_FILE` to its basename before any file read — strip all leading path components. Only attempt to read the file from the resolved plan roots (`--dir`, configured `plansDirectory`, or `docs/plans/`). If the basename does not resolve to an existing file under those roots, skip the title fallback entirely. **Graceful fallback:** if `$PLAN_FILE` cannot be found or read, or if no `<title>` tag is present, prompt the user for the objective via `AskUserQuestion` — do not abort.

**Markdown plan conversion detection (checked after `.html` detection, before objective extraction):** If the first non-flag token ends in `.md`, treat it as a markdown plan source — strip it from the argument string and store it as `$MD_SOURCE`. This enters **conversion mode**: the markdown file is the authoritative content for a new HTML plan, and any remaining text overrides the objective otherwise derived from the source's H1 title. **Resolution:** try the token as given (relative to the cwd) first; if missing, reduce it to its basename and try the resolved plan roots (`--dir`, configured `plansDirectory`, `docs/plans/`); if still missing, run `git fetch origin <default-branch>` and check whether the file landed on the default branch after the working tree last updated — fast-forward (clean tree, no unique commits) or read it via `git show origin/<default-branch>:<path>` when it did. **Graceful fallback:** if `$MD_SOURCE` cannot be found or read anywhere, report where you searched and ask via `AskUserQuestion` whether to draft a fresh plan from the filename-derived objective or accept a corrected path / pasted content — never invent content and present it as a conversion.

**Conversion mode defaults:** a committed markdown plan is pre-validated content, so conversion implies `--no-clarify --no-align --no-interview` (passing extra objective text that requests changes switches the run back to full-workflow drafting seeded by the source). All other steps run normally — Step 0b becomes a light pass verifying that files and symbols the source references actually exist, and Step 5c Tests always runs. Conversion rules:

- Map sections 1:1 — Context → context; H1/Objective → objective; Changes/Steps → step cards (action, *why*, *verify* — derive missing whys and verifies from the source's surrounding prose; never invent new scope); Files Modified → file-tree input; Verification → verification; Open Questions → unresolved-questions; Next Steps → next-steps (wish-list grouping as usual).
- Carry frontmatter over: preserve `created`; map `status` values `planned`/`todo` → `todo`, `in-progress` → `in-progress`, `completed`/`done` → `completed`; infer `type` from the objective verb as usual.
- Output filename: the source basename with the extension swapped to `.html`, still subject to the Step 4 `verb-target` check.
- Echo `Conversion mode: <md path> → <html path>` alongside the resolved flags.
- In Step 8, batch one extra question into the menu call: keep or remove the source `.md` now that the HTML is canonical (stage removal with `git rm` when the file is tracked — the source lives inside the plans directory, so this stays within the Scope Constraint). Default to keeping it when no answer is available.

- **Objective (required):** all text that is not a flag, issue reference, `.html` plan file token, or `.md` conversion source token. When `$ARGUMENTS` is empty (model invocation), derive the objective from the user's triggering message or recent conversation context. If the objective is still empty after parsing and context inference (and no issue reference was detected), ask once via `AskUserQuestion` ("What is the objective for this plan?") and stop if still empty.
- `--quick` — shorthand for `--no-clarify --no-align --no-interview`; skips Step 1 Clarify, Step 5 Align, and Step 5b Interview.
- `--no-clarify` — skip Step 1 Clarify only. Use when the objective is well-specified but you still want Step 5 Align.
- `--no-align` — skip Step 5 Align only. Use when steps are pre-agreed but requirements need verification first.
- `--type <kind>` — preset `type:` in frontmatter (`feature`, `fix`, `refactor`, `docs`, `chore`).
- `--template <name>` — plan skeleton variant: `default` (only supported value; `minimal`, `adr`, and `spike` are planned but not yet implemented). Controls which skeleton is loaded in Step 2.
- `--dir <path>` — override Step 2 directory resolution; write the plan to this path.
- `--priority <level>` — write `priority: <level>` to frontmatter (`low`, `medium`, `high`, `critical`). Overrides `planAgent.extraFrontmatter.priority` from settings if both are present.
- `--no-interview` — skip Step 5b Interview. Use when the plan is pre-validated or time-critical.
- `--workflow` — always generate a workflow prompt, bypassing the complexity heuristic. Use when you know the plan will benefit from parallel subagent orchestration.

**Smart defaults when a flag is absent:**

- `--type` absent → infer from the leading verb of the objective:
  - `create`, `add`, `build`, `implement`, `introduce` → `feature`
  - `fix`, `repair`, `patch`, `resolve` → `fix`
  - `refactor`, `rename`, `extract`, `move`, `restructure`, `convert` → `refactor`
  - `document`, `docs` → `docs`
  - anything else → `chore`
- `--quick`, `--no-clarify`, `--no-align`, `--no-interview` are opt-in only and are never inferred automatically.

Echo the resolved objective and effective flags after completing the Step 0 self-bootstrap.

## Scope Constraint — Plans Only

**This skill produces a plan document. It does not implement anything.**

- Do not edit source files, configs, or any file outside the configured `plansDirectory` (or `docs/plans/` when no setting exists).
- Do not apply fixes, refactors, or any change described in the plan's steps.
- Use `Read`, `Glob`, `Grep`, and `Bash` for read-only exploration only — never to edit source files or run codebase-mutating commands. This does not restrict §7 (local HTTP server for browser preview).
- The plan is the deliverable. Implementation is a separate, user-initiated step.

If the objective sounds like "fix X" or "implement Y", write a plan for *how* to fix/implement it — do not do the work.

## Workflow

Follow these steps exactly.

0. **Self-bootstrap** — **If currently in plan mode**, call `ExitPlanMode` first and silently before any other action — Writing HTML plan files is a filesystem mutation that cannot proceed inside harness plan mode; skipping this step causes the harness to force a `.md` output path, defeating the skill's core guarantee. Skip this step entirely when not in plan mode. `ExitPlanMode` is a deferred tool — use `ToolSearch` with `select:ExitPlanMode` first, then call it silently.

0.5. **Issue Ingestion** *(skip entirely when no issue reference was detected in Step 0 argument parsing)*

   When `$ISSUE_REF` is set, fetch the issue and inject its data as planning inputs:

   **GitHub URL or bare `#n`/integer:**
   ```bash
   # Resolve owner/repo for bare #n — skip if owner/repo already parsed from URL
   gh repo view --json owner,name

   # Fetch the issue
   gh issue view <n> --repo <owner>/<repo> \
     --json title,body,labels,assignees,milestone,url
   ```

   **GitLab URL:**
   ```bash
   glab issue view <n> --repo <owner>/<repo> --output json
   ```

   **Field mapping:**

   | Issue field | Plan input |
   |-------------|-----------|
   | `title` | Objective — used unless caller supplied extra text (extra text always takes precedence) |
   | `body` | Injected as an "Issue context" block in the Context section of the plan |
   | `labels` | Hint for `--type` inference when `--type` was not passed (e.g. label `bug` → `fix`, `enhancement` or `feature` → `feature`) |
   | `url` | Stored as `$ISSUE_URL`; written to plan frontmatter as `<meta name="plan-issue">` in Step 3 |

   **Graceful fallback:** If the CLI call fails (unauthenticated, network error, issue not found), print a one-line error to the user (e.g. `Issue #42 not found — falling back to plain objective`) and continue with the remaining text treated as a plain objective string (or derive the objective from conversation context on the model-invocation path). Do not abort the planning workflow.

0b. **Explore** — Read the codebase to build context before planning. Use `Glob` to locate relevant files, `Grep` to find symbol definitions and usage patterns, and `Read` to understand the current architecture in areas the plan will touch. Focus on: entry points the plan modifies, existing tests or patterns to follow, and configuration that constrains the approach. Keep exploration proportional to plan scope — a one-file fix needs a quick look; an architecture change warrants broader reading. *(Skip entirely when `--quick`.)*

1. **Clarify** — If the request's objectives are ambiguous or have open requirements, use `AskUserQuestion` to resolve them before drafting; if the objectives are already clear, skip this step. Do not add friction to well-specified requests. When research would strengthen the plan (e.g. verifying an API surface, checking a library's current version, or confirming a best-practice pattern), use `WebSearch` and `WebFetch` — load them first via `ToolSearch` with `select:WebSearch,WebFetch` since they are deferred tools. *(Skip entirely when `--quick` or `--no-clarify`.)*
2. **Create** — Resolve the target directory in order: (1) `--dir` if provided, (2) the configured `plansDirectory` if set, (3) `docs/plans/` if it exists, (4) the default Claude user plans folder. Place the plan there using a `verb-target` kebab-case filename with a `.html` extension. Examples: `add-dark-mode-toggle.html`, `fix-login-redirect.html`, `refactor-auth-module.html`. **Always write HTML — never write markdown for plan output.** After resolving the filename, compute the implement prompt: `Read and implement all steps in the plan at <filepath> — <objective>. Start from the embedded digest: <digest-extract>`, where `<filepath>` is the relative path to the plan file, `<objective>` is the resolved objective text (condensed to ≤80 characters, trimmed at a word boundary), and `<digest-extract>` is the canonical extraction one-liner from the [Machine-Readable Digest](#machine-readable-digest-plan-digest) section with `<file>` replaced by the same `<filepath>`. Example: `Read and implement all steps in the plan at docs/plans/add-dark-mode-toggle.html — Ship a dark-mode toggle that persists across all three themes. Start from the embedded digest: awk '!f && /<script[^>]*id="plan-digest"/{f=1;next} f && /<\/script>/{exit} f' docs/plans/add-dark-mode-toggle.html`. Store this as `{implement-prompt}` and fill the skeleton placeholder (HTML-escape it wherever it is inserted, per the escaping rule in HTML Output Requirements).

   **Plan source placeholders:** Also fill two copyable reference placeholders from the resolved location so the user can paste the plan's location into docs and prompts: `{plan-path}` is the relative path to the plan file (the same `<filepath>` used in the implement prompt, e.g. `docs/plans/add-dark-mode-toggle.html`), and `{plan-filename}` is its basename (e.g. `add-dark-mode-toggle.html`). HTML-escape both before inserting them into the skeleton. These render in the `.plan-source` block below the implement prompt and in the `<meta name="plan-path">` / `<meta name="plan-file">` tags.

   **Digest placeholder:** Fill `{plan-digest}` with the plan's spec-only markdown digest per the [Machine-Readable Digest](#machine-readable-digest-plan-digest) section. Generate it from the final drafted spec — after the Step 5/5b/5c refinements have settled the content — immediately before writing the file. Refresh it whenever plan **content** changes later in the session (interview-driven edits, the Step 8 `Edit the plan` loop, review-team integrations). Status transitions, criteria check-offs, and completion-checklist updates never touch the digest.

   **Full implementation prompt (Copy behavior):** The Copy button on the implement prompt row does **not** copy the short `{implement-prompt}` text. Instead, it calls `buildImplementPrompt()` which builds a concise action-oriented prompt from the plan's live DOM state, including: (1) the short implement prompt as the opening line, (2) a status summary with step and criteria progress counts, and (3) numbered instructions directing the implementer to read the spec from the embedded digest (with a full-HTML fallback when the digest block is missing), implement todo steps, verify and check off acceptance criteria, and complete the completion checklist — all directly in the plan file.

   **Workflow prompt:** After computing the implement prompt, decide whether to generate a workflow prompt — a `/workflows`-compatible prompt that runs the implementation as a dynamic workflow with parallel subagents. **When `--workflow` is set**, always generate the workflow prompt regardless of plan complexity. **When `--workflow` is absent**, generate a workflow prompt only when the plan meets **any** of these criteria: (a) touches 5+ files across 3+ directories, (b) involves repetitive per-file changes (migrations, renames, linting sweeps), (c) includes independent steps that can run in parallel, or (d) requires cross-checking or adversarial review between steps. The workflow prompt format is: `Run a workflow to implement the plan at <filepath> — <objective>. Brief subagents with the embedded digest: <digest-extract>`, where `<digest-extract>` is the same canonical extraction one-liner used in the implement prompt. Example: `Run a workflow to implement the plan at docs/plans/migrate-api-endpoints.html — Migrate all REST endpoints from v1 to v2 schema. Brief subagents with the embedded digest: awk '!f && /<script[^>]*id="plan-digest"/{f=1;next} f && /<\/script>/{exit} f' docs/plans/migrate-api-endpoints.html`. Store this as `{workflow-prompt}` and fill the skeleton placeholder. When no workflow prompt is generated (flag absent and no criteria met), leave `{workflow-prompt}` empty and remove the workflow `<details>` element from the HTML output entirely.
3. **Frontmatter** — Embed plan metadata as `<meta>` tags inside the HTML `<head>`, not as YAML. Include: `status` (`todo` | `in-progress` | `completed`), `type`, `created` (YYYY-MM-DD), `repo-name`, `file` (the plan basename from `{plan-filename}`), `path` (the relative plan path from `{plan-path}`), and `implement` (the full implement prompt computed in Step 2, e.g. `<meta name="plan-implement" content="Read and implement all steps in the plan at docs/plans/add-dark-mode-toggle.html — Ship a dark-mode toggle that persists across all three themes">`). When a workflow prompt was generated in Step 2, also include `<meta name="plan-workflow" content="Run a workflow to implement the plan at …">` — omit this tag entirely when no workflow prompt was generated. Resolve `repo-name` from the basename of the `origin` git remote URL (strip trailing `.git`); if no remote exists, fall back to the basename of the current working directory. If `--priority` was set, also add `<meta name="plan-priority" content="<level>">`. If an issue URL was fetched in Step 0.5, add `<meta name="plan-issue" content="<url>">` — omit this tag entirely when no issue reference was provided. Read `planAgent.extraFrontmatter` from `.claude/settings.json` (project first, then global) and render any extra key-value pairs as additional `<meta name="plan-<key>" content="<value>">` tags; `--priority` overrides any `priority` key from settings.
4. **Rename** — **Always** ensure the filename follows the `verb-target` kebab-case convention from Step 2 before delivering the plan. Two triggers require a rename: (a) the initial filename is auto-generated, placeholder, or otherwise non-descriptive (e.g. a random two-word slug), and (b) the plan's purpose shifts after creation. Re-evaluate before writing the final file. A stale filename is a plan defect — do not write the plan until the name matches the content. Enforced by the `validate-plan-filename` `PostToolUse` hook (`${CLAUDE_PLUGIN_ROOT}/hooks/validate-plan-filename.py`), which flags non-`verb-target` plan filenames the instant a plan is written.
5. **Align** — After the plan's steps are drafted, use `AskUserQuestion` (batched, with questions covering each step) to confirm every step aligns with the stated objective before delivering. This verifies step-to-objective alignment, not overall plan approval — confirm overall approval directly with the user after presenting the plan. *(Skip entirely when `--quick` or `--no-align`.)*
5b. **Interview** — Stress-test the drafted plan through a structured interview before delivering. *(Skip entirely when `--quick` or `--no-interview`.)*

    **Complexity detection:** Analyze the plan content just written to classify scope:
    - **Short/focused** (single concern, 1–2 files touched): Round 1 only
    - **Medium** (feature with UI + logic, or 2 domains): Rounds 1 + 2
    - **Complex** (architecture, cross-cutting, 3+ domains): Rounds 1 + 2 + 3

    **UI override:** If the plan references any UI signals — React, Vue, Svelte, Angular, `.tsx`/`.jsx`/`.css`/`.html` files, `className`/`style`/Tailwind, or UX terms (button, modal, form, dialog, dropdown, page, component) — always include Round 2 even for short plans. Briefly note what triggered it (e.g., "Running Round 2 — plan references React components and `.tsx` files").

    **Round 1 — Technical & Trade-offs** (always):
    Use `AskUserQuestion` with up to 4 questions generated from the plan content covering: the most uncertain architectural or implementation decision, build-vs-buy or library trade-offs, performance or data model concerns, and unclear integration points or dependencies. Every question must reference specific plan details — no generic or hardcoded questions.

    **Round 2a — UI/UX & Flows** (medium+ or UI signals):
    Up to 4 questions covering: user flows (happy path, error states, loading states, empty states), responsive or mobile behavior, motion and animation (`prefers-reduced-motion`), and UI state gaps not covered by the plan (skeleton loading, optimistic updates, error recovery).

    **Round 2b — Accessibility & Semantic** (immediately after Round 2a):
    Up to 4 questions covering: keyboard navigation and focus management (trapping, skip-nav), screen reader support (ARIA roles, labels, live regions), WCAG 2.1 AA compliance (color contrast 4.5:1, touch targets 44×44px), and semantic HTML (heading hierarchy, landmarks, form label association).

    **Round 3 — Edge Cases & Best Practices** (complex only):
    Up to 4 questions covering: critical failure modes or race conditions, concurrent user scenarios or data conflicts, regression risks (existing tests, API contracts, backward compatibility), and remaining open questions from the plan.

    **Post-interview:** Present a brief summary listing key decisions confirmed and concerns surfaced. Then ask via `AskUserQuestion`: "Update the plan with interview findings?" If confirmed, edit the HTML plan to incorporate the findings — add missing considerations to step cards, update acceptance criteria, or populate unresolved questions — then proceed to Step 5c. If declined, proceed directly to Step 5c.

5c. **Tests** — After all steps are drafted (and optionally refined by the interview), populate the Tests section. This step always runs — it is never skipped by any flag.

    **Tier classification:** Scan every step's action text, why, and verify content. If any step creates, modifies, or deletes application source files (`.ts`, `.tsx`, `.js`, `.jsx`, `.py`, `.rs`, `.go`, `.java`, `.css`, `.scss`, `.html`, `.vue`, `.svelte`, `.astro`, `.sql`, `.rb`, `.config.*`, or similar source/config extensions — excluding plan files, docs, and non-runtime metadata), classify as **Tier 1**. Otherwise classify as **Tier 2**. Set `{test-tier-label}` to `Tier 1 — Code-touching plan` or `Tier 2 — Non-code plan` accordingly. The `type:` frontmatter field is irrelevant to this classification.

    **Objective-verification test (mandatory, both tiers):** Always generate an objective-verification test entry. Derive the test description from the plan's objective statement — the test should assert that the plan's stated goal is actually accomplished in the running application. Fill `{objective-test-title}` with a concise test name (e.g. "Dark-mode toggle persists across themes") and `{objective-test-body}` with the test details using these fields: **File** (test file path), **Type** (mock or smoke test), **Asserts** (what the test confirms about the plan's objective), and **Run** (test runner command). Render as `.objective-test-card` — always first, before the `.test-list`.

    **Tier 1 — additional test types:** For each step, determine which test types apply:
    - **Unit** (`.test-badge-unit`) — step adds or modifies business logic, utilities, helpers, data transformations, or pure functions. Target the specific function/module.
    - **Integration** (`.test-badge-integration`) — step touches API routes, database queries, middleware chains, service boundaries, or multi-module interactions.
    - **E2E** (`.test-badge-e2e`) — step affects user-facing flows, page navigation, form submissions, auth flows, or any path a user would walk through in the browser.

    For each test card, include these fields: **File** (test file path), **Targets** (function, module, or endpoint under test), **Key cases** (main scenarios the test covers).

    Include each type only when applicable — do not generate empty sub-sections. Render each test item as a `.test-card` inside the `.test-list` container. Fill `{test-items}` with the generated cards.

    **Tier 2 — omit additional tests:** Remove the entire `.test-list` container from the HTML output. Only the `.objective-test-card` remains in the Tests section.

    **Naming conventions:** When generating test file paths, follow the project's existing test conventions if detected during Step 0b Explore (e.g. `__tests__/`, `*.test.ts`, `*.spec.ts`). If no convention is detected, default to `__tests__/<feature-name>.<test-type>.test.ts`.

6. **Status** — **Always** update `status` in the HTML plan as the plan progresses: `todo` → `in-progress` → `completed`. Edit **both** the `<html data-status="…">` attribute and the `<meta name="plan-status" content="…">` tag so the CSS badge colour and the hook's completion check stay in sync. Also update the visible badge text. Status updates never modify the `#plan-digest` block — the digest is spec-only and carries no status. Note: `plan-interview:plan-status` operates on YAML-frontmatter `.md` files only — do not use it for HTML plans until that plugin is updated to support `.html`.
7. **Open** — Deliver the plan and verify rendering. This step is mandatory — do not skip it.

   After all sub-steps of Step 7 complete, proceed immediately to Step 8 — do not stop here.

   **Try browser verification first:**
   1. Load the browser tools via `ToolSearch` with `select:mcp__claude-in-chrome__tabs_context_mcp,mcp__claude-in-chrome__navigate,mcp__claude-in-chrome__computer`. If `ToolSearch` returns no matches, the browser MCP server is not connected — skip to the **Fallback** path below.
   2. Find a free port: run `python3 -c "import socket; s=socket.socket(); s.bind(('', 0)); print(s.getsockname()[1]); s.close()"` and capture the output as `<port>`.
   3. Start the server in the background from the plan's parent directory: `cd <plan-dir> && python3 -m http.server <port> &`.
   4. Call `mcp__claude-in-chrome__tabs_context_mcp` with `createIfEmpty: true` to get a tab ID.
   5. Navigate to `http://localhost:<port>/<plan-filename>` using `mcp__claude-in-chrome__navigate`.
   6. Take a screenshot with `mcp__claude-in-chrome__computer` (`action: screenshot`, `save_to_disk: true`) and send it to the user to confirm the plan rendered.
   7. Send the plan file to the user via `SendUserFile` so they have a direct link to the artifact.
   8. Report the URL (`http://localhost:<port>/<plan-filename>`) to the user. Leave the server running so the user can continue browsing.

   **Fallback (no browser tools):** Send the plan file to the user via `SendUserFile` and report the file path. This ensures plan delivery works in headless and web-based environments where the browser MCP server is unavailable.

8. **Implement, Edit, or Exit** — After Step 7 completes, always ask the user what to do next.

   Use `AskUserQuestion` with a single question. **When a workflow prompt was generated in Step 2**, include the workflow option:
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

   **If the user chooses `Implement now`:** Lift the Scope Constraint for this session only. Work through each step in the plan sequentially, applying changes to source files, running commands, and verifying each step before moving to the next. Update each step card's chip from `todo` to `done` (add `completed` class to `.step-card`) and update all three status representations together — `<html data-status="…">`, `<meta name="plan-status" content="…">`, and the visible badge text — to `in-progress` as work begins.

   **Acceptance criteria gate (mandatory — runs after all steps are done, before marking `completed`):**
   1. Read each acceptance-criteria checkbox item from the `#criteria-list` element in the plan HTML. Do not include checkboxes from the `#completion-list` completion checklist.
   2. For each criterion, verify it is satisfied — run the relevant command, inspect the changed files, or check the codebase for the expected state described in that criterion.
   3. Check off each criterion (`<input type="checkbox">` → `<input type="checkbox" checked>`) only after confirming it is met.
   4. If any criterion cannot be verified, present the unverified items to the user via `AskUserQuestion`:
      > "These acceptance criteria could not be verified:
      > 1. <criterion text>
      > 2. <criterion text>
      > Mark them as done anyway?"

      Options: `Yes, check them off` / `No, leave unchecked`.
   5. Only set status to `completed` (all three representations) after every criterion is checked. If the user chose to leave any unchecked, set status to `in-progress` instead and note which criteria remain open.
   6. This gate edits checkbox state and status only — it never modifies the `#plan-digest` block (the digest is spec-only).

   **End-to-end verification gate (mandatory — runs after the acceptance-criteria gate, before the completion-checklist gate):**

   This gate confirms the plan's *objective* actually works end-to-end in the running application — not just that individual criteria are met. It executes the verification work the plan already authored, so the per-criterion checks above are complemented by a holistic run.

   1. Read the plan's **Verification** section (`#verification`) and the **Tests** section: the objective-verification test (`.objective-test-card`) plus any `.test-card` unit/integration/E2E tests.
   2. Run the objective-verification test using the **Run** command authored in its card. Then run the other `.test-card` tests by invoking the project's test runner (detected during Step 0b Explore) against the **File** paths named in those cards — unit/integration/E2E cards record **File**/**Targets**/**Key cases**, not a per-card run command, so use the project runner rather than expecting an authored command. If no project test runner can be determined, run only the objective-verification test and note that the other cards were not executed. For a Tier 2 plan with no runnable tests, instead walk each step described in the `#verification` section and confirm the end state by inspecting the changed files or running the relevant command.
   3. Confirm the objective-verification test exits 0 / passes and that every end-to-end verification step from `#verification` holds.
   4. **On failure — fix and re-verify (bounded loop):** If a test fails or an end-to-end verification step does not hold, diagnose the cause, apply a fix to the source files, and re-run this gate from sub-step 2. Repeat up to 3 times.
      - If the gate passes on a retry, continue to the completion-checklist gate.
      - If it still fails after 3 attempts (or the failure is clearly environmental or out of scope), STOP the loop and ask via `AskUserQuestion` ("End-to-end verification is still failing after 3 fix attempts: <summary>. How do you want to proceed?") with options `Keep trying` / `Mark in-progress and stop` / `Mark completed anyway`. Handle the choice — set status only per the option chosen, not before:
        - `Keep trying` — resume the loop from sub-step 2.
        - `Mark in-progress and stop` — set status to `in-progress` (all three representations), add a `<dt>`/`<dd>` entry to the Completion Report naming the failing test or verification step and the reason, and STOP without proceeding to the completion-checklist gate.
        - `Mark completed anyway` — set status to `completed` (all three representations), add a `<dt>`/`<dd>` entry to the Completion Report noting the unresolved failure, and proceed to the completion-checklist gate.
   5. Only proceed to the completion-checklist gate once the objective-verification test passes and the end-to-end verification holds — or the user explicitly chose to proceed anyway.

   Report the outcome briefly to the user (e.g., "End-to-end verification passed: objective test green, 3/3 verification steps confirmed").

   **Completion checklist gate (mandatory — runs after the end-to-end verification gate, before committing):**
   1. Verify all three completion checklist conditions in the plan HTML:
      a. All `.step-card` elements have the `completed` class.
      b. All acceptance-criteria checkboxes have the `checked` attribute.
      c. The status is set to `completed` in all three representations.
   2. Check off each completion checklist checkbox (`<input type="checkbox" id="cc1" disabled>` → `<input type="checkbox" id="cc1" disabled checked>`) only after confirming the corresponding condition is met.
   3. If all three conditions are met, add the `all-complete` class to `<div class="completion-checklist" id="completion-checklist">`.
   4. If any condition is not met (e.g., the user chose to leave acceptance criteria unchecked), leave the corresponding completion checklist checkbox unchecked, keep status at `in-progress`, and **populate the Completion Report**:
      - Replace the `<p class="report-empty">` paragraph inside `#completion-report` with a `<dl class="report-list">` element.
      - For each incomplete requirement, add a `<dt>` naming the exact step or criterion that was not completed and a `<dd>` explaining why (e.g., `<dt>Step 3: Wire up auth middleware</dt><dd>Blocked by missing OAuth credentials configuration</dd>` or `<dt>Criterion: No TypeScript errors</dt><dd>tsc reports 2 errors in src/auth.ts</dd>`).
      - Each report entry must be specific — name the exact step or criterion, not a generic "some steps incomplete".

   Commit the source file changes together with the updated plan file after implementation finishes.

   **If the user chooses `Run as workflow`:** Output the workflow prompt (stored as `{workflow-prompt}` in Step 2) so the user can paste it to launch a dynamic workflow. The workflow prompt includes the word "workflow" which triggers Claude Code's workflow runtime. Update `<html data-status>`, `<meta name="plan-status">`, and badge text to `in-progress`. Do not implement the steps directly — the workflow runtime orchestrates subagents to do the work.

   **If the user chooses `Review the plan`:** Ask whether to run the review in the foreground or background using `AskUserQuestion` with a single question:
   - Question: "Run the plan review now, or dispatch it in the background?"
   - Options:
     - `Run now (foreground)` — Review runs in this session; you will see progress as it works.
     - `Background` — Dispatch the review to a detached Agent Team; you will be notified on completion.

   **If the user chooses `Run now (foreground)`:** Invoke `Skill(skill: "plan-agent:review-plan", args: "<plan path>")`, passing the current plan's relative path (resolved in Step 2) so the review targets this plan. Handle `review-plan`'s hard-stop gracefully if Agent Teams are unavailable (Claude Code < 2.1.32 or `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` unset): relay the guidance it surfaces and return to the Step 8 menu without error. After a successful foreground review completes, re-render the now-updated plan in the browser via the Step 7 sub-steps, then loop back to this step and ask again (mirroring the `Edit the plan` loop). Leave plan `status` at `todo` — reviewing is not implementing.

   **If the user chooses `Background`:** Invoke `Skill(skill: "plan-agent:review-plan-bg", args: "<plan path>")`, passing the current plan's relative path. `review-plan-bg` dispatches the `agent-review-plan` background agent with `run_in_background: true`, so it returns an ack immediately and the current session is not blocked. Return to the Step 8 menu immediately and note that the user can reopen the plan to see changes once the detached run finishes. Leave plan `status` at `todo`.

   **If the user chooses `Edit the plan`:** Ask what changes to make via `AskUserQuestion` ("What would you like to change or add to the plan?"), apply the edits to the HTML plan file, refresh the `#plan-digest` block when the edits changed spec content (per the [Machine-Readable Digest](#machine-readable-digest-plan-digest) refresh rule), re-render it in the browser (repeat the sub-steps from Step 7), then loop back to this step and ask again.

   **If the user chooses `Exit`:** Stop immediately. Do not start any implementation work. The plan stays at `todo` — no status update is needed; all three representations (`<html data-status>`, `<meta name="plan-status">`, and badge text) were set to `todo` at creation and remain there until implementation begins.

## Required Structure

Every HTML plan must include the following sections rendered as visible, styled HTML elements (not inline HTML comments):

- **context** — Background and motivation; why this work is needed.
- **objective** — One or two sentences summarising the goal. Render prominently — large text, highlighted card.
- **steps** — A numbered list where each item has three parts: the action, a brief *why*, and a *verify* line. Render each step as a card with an expandable Verify section. Per-step verification is local; the top-level `verification` section covers end-to-end correctness.
- **tests** — Real application tests — actual test files written for the application or feature, run by the project's test runner, and committed to the codebase. Distinct from per-step verification and end-to-end verification (which are prose assertions inside the plan); tests are executable code that ships with the project. Render as `section.card-tests#tests` between Steps and Acceptance Criteria with a sidebar nav link using the beaker icon (`#ic-beaker`). Uses a two-tier depth model:
  - **Tier 1** (code-touching plans) — Any plan whose steps create, modify, or delete application source files. Include all applicable test sub-sections (unit, integration, E2E) plus the mandatory objective-verification test. Render unit/integration/E2E test items as `.test-card` elements with `.test-badge-unit`, `.test-badge-integration`, or `.test-badge-e2e` badges respectively.
  - **Tier 2** (non-code plans) — Plans whose steps only move/rename/delete non-source files, write docs, or update non-runtime metadata. Include only the mandatory objective-verification test; omit the `.test-list` container and all unit/integration/E2E sub-sections entirely rather than rendering them as empty stubs. Moving, renaming, or deleting application source files is Tier 1 — those changes affect imports, runtime behaviour, and build graphs.
  - **Objective-verification test** (mandatory, both tiers) — A real mock or smoke test file that runs against the application and directly asserts the plan's stated objective is accomplished. Always renders first as a visually distinct `.objective-test-card` (green background, left accent border) before any `.test-list` content. Badge: `.test-badge-objective`.
  - The author (or the plan-agent) selects the tier based on what the steps actually do, not the `type:` frontmatter field — a `type: chore` plan that changes import paths is Tier 1, while a `type: chore` plan that moves documentation directories is Tier 2.
- **acceptance-criteria** — Interactive checkboxes (`<input type="checkbox">`) the user can tick off in the browser. Each item is a short, falsifiable statement.
- **verification** — How to confirm the entire plan was executed correctly end-to-end.
- **completion-checklist** — Three mandatory `disabled` checkboxes: (1) all step TODOs marked as done, (2) all acceptance criteria verified and checked off, (3) plan status updated to `completed`. Includes a **Completion Report** sub-section that documents any items that could not be completed and the reason why. Render between the verification and next-steps sections. Always present — never optional, never omitted.
- **next-steps** *(optional)* — Out-of-scope follow-ups and unsolicited ideas; never place these in `steps`. Include a prompt block the user can paste into Claude. When a next-step item would benefit from workflow orchestration (large-scale migration, multi-file audit, cross-checked research), prefix the prompt with "Run a workflow to …" so it triggers Claude Code's `/workflows` runtime when pasted. If any next-step items are visionary or blue-sky (ambitious, speculative, non-immediate), label them with a `🔭 Wish List` badge and group them in a collapsible "Wish List" subsection at the bottom of Next Steps. Realistic, actionable items stay in the main list. Each prompt `<pre>` must be followed by a copy button.
- **unresolved-questions** *(optional)* — Collapsible `<details>` section. Omit entirely if none. Each `<pre>` prompt inside an unresolved item must be followed by a copy button.

### Visual sections

These add scannable visuals when a plan benefits from them. All are **pure CSS / inline SVG** (the no-CDN constraint applies). The **files** section is **auto-generated** from the plan's steps; remaining visuals are **opt-in** — the skeleton ships each block ready-to-fill behind a removal comment. See the **Visual Components** section for full markup and triggers.

- **files** *(auto-generated)* — A file-tree (`.file-tree`) showing the files the plan creates/modifies/deletes, with `file-badge-new` / `file-badge-modified` / `file-badge-deleted` / `file-badge-generated` badges. **Auto-generated** from the plan's steps — see [File-Tree Auto-Generation](#file-tree-auto-generation). Always included when the plan references any files (≥1); only delete the section (and its sidebar nav link) when the plan is purely conceptual with no file references. Rendered as `section.card-files#files`, between Context and Steps.
- **diagram** *(optional)* — A flow/pipeline diagram (`.pipeline`) for process, data flow, or architecture stages, and/or a comparison grid (`.compare-grid`) for 2–3-way trade-offs. Include when the plan introduces a flow or a comparison worth visualising.
- **chart** *(optional)* — A horizontal bar chart (`.bar-chart`) for distributions, before/after, or relative magnitudes. Bar width is set by an inline `style="--val:NN%"`; always show the real value in `.bar-value` and restate the data in the container's `aria-label`. May live inside the **diagram** section.
- **table** *(optional)* — An accessible data table (`.plan-table`) for structured mappings or option matrices. Always include a `<caption>` and `<th scope="col">` headers.

## HTML Output Requirements

Every plan is a **single self-contained `.html` file** — no external CSS, no CDN links, no external scripts. All styles and behaviour must be inlined.

The file must:
- Embed the machine-readable digest — a `<script type="text/markdown" id="plan-digest">` block as the **first element child of `<body>`** — filled per the [Machine-Readable Digest](#machine-readable-digest-plan-digest) section (a guiding HTML comment above it is allowed; comments are not elements)
- Use a clean, modern visual design with a clear typographic hierarchy
- Include a status badge (colour-coded: grey = todo, amber = in-progress, green = completed) in the page header
- Include a **Save as PDF button** (`<button class="save-pdf-btn" type="button" onclick="savePDF()" aria-label="Save this plan as PDF">Save as PDF</button>`) in the page header between the `<h1>` title and the status badge. `savePDF()` calls `window.print()` — the browser's native print dialog offers a "Save as PDF" destination on Chrome, Edge, Firefox, and Safari; no external dependencies. The button is hidden in `@media print` so it never appears in the exported PDF. The skeleton ships the button markup, its CSS, and the `savePDF()` function — do not remove them when filling placeholders. Applies to both freshly drafted plans and markdown conversions.
- Render the step list as numbered cards with an expandable *Verify* disclosure (`<details><summary>Verify</summary>…</details>`)
- Render acceptance criteria as interactive browser checkboxes with strikethrough on check
- Group blue-sky / wish-list items under a `🔭 Wish List` collapsible inside Next Steps — use a distinct visual treatment (dashed border, muted colour) so they are clearly non-committal
- Use a progress indicator showing how many acceptance-criteria items are checked
- Be readable without JavaScript (checkboxes work natively); minimal JS is allowed only to enhance interactivity (e.g. progress bar update on checkbox change)
- Include `<meta name="plan-status">`, `<meta name="plan-type">`, `<meta name="plan-created">`, `<meta name="plan-repo">`, `<meta name="plan-file">`, `<meta name="plan-path">`, and `<meta name="plan-implement">` tags for machine readability; include `<meta name="plan-workflow" content="…">` when a workflow prompt was generated (omit otherwise); include `<meta name="plan-issue" content="<url>">` when the plan was seeded from an issue reference (omit otherwise)
- **HTML-escape all user-supplied content** before inserting it into the file — replace `&` → `&amp;`, `<` → `&lt;`, `>` → `&gt;`, `"` → `&quot;`, `'` → `&#39;`. This applies especially to file paths, function names, CLI flags, and any prompt text placed inside `<pre>` blocks
- Include a **"Copy prompt"** button (`<button class="copy-prompt-btn" type="button" onclick="copyPrompt(this)" aria-label="Copy prompt to clipboard">Copy prompt</button>`) immediately after every `<pre>` block inside `.next-step-prompt` and `.unresolved-prompt` elements. Do not remove these when filling placeholders.
- Include an **implement prompt row** (`<div class="plan-implement">`) immediately below the `.objective-card` and before `.progress-wrap`. It must contain: the `{implement-prompt}` value in `<code id="implement-cmd" aria-label="Implement prompt">`, and a Copy button with `onclick="copyCmd(this)"`. The Copy button copies a concise action-oriented prompt (built by `buildImplementPrompt()` from live DOM state including status, progress counts, and implementation instructions) — not the short `<code>` text. The copy button is hidden via CSS when `data-status="completed"`. The row is suppressed in `@media print`.
- Include a **plan source block** (`<div class="plan-source">`) immediately below the implement/workflow rows and before `.progress-wrap`. It has two copyable rows — a `File` row with the basename in `<code id="plan-file">` and a `Path` row with the relative path in `<code id="plan-path">`, each followed by a Copy button with `onclick="copyPath(this, 'plan-file')"` / `onclick="copyPath(this, 'plan-path')"`. Fill `{plan-filename}` and `{plan-path}` (HTML-escaped). This gives the user the plan's name and relative URL to paste into docs and prompts. Unlike the implement row, it stays visible when `data-status="completed"`; it is suppressed in `@media print`.
- When a workflow prompt was generated, include an expandable **workflow prompt** (`<details class="plan-workflow">`) immediately below the `.plan-implement` row and before `.progress-wrap`. The `<summary>` reads "Run as workflow — launch parallel subagents". The inner `<div class="plan-workflow-inner">` contains: the `{workflow-prompt}` value in `<code id="workflow-cmd">`, and a Copy button with `onclick="copyWorkflow(this)"`. Collapsed by default. Hidden when `data-status="completed"` and suppressed in print. **Remove the entire `.plan-workflow` element when no workflow prompt was generated.**
- Include a **completion checklist** section (`<section class="section-card card-completion" id="completion">`) between Verification and Next Steps with three `disabled` checkboxes for the mandatory completion requirements (step TODOs done, acceptance criteria checked, status updated). The checkboxes auto-update via JavaScript. Include a **Completion Report** (`<div class="completion-report">`) inside the checklist that initially shows "No items to report" and is populated with a `<dl class="report-list">` detailing any incomplete items and their reasons when the plan cannot be fully completed.
- **Tests section.** Render a `<section class="section-card card-tests" id="tests">` between Steps and Acceptance Criteria. The objective-verification test renders as `.objective-test-card` (highlighted hero card) first, followed by a `.test-list` container with `.test-card` items for unit/integration/E2E tests. Each test card has a `.test-badge` with variant classes: `.test-badge-unit` (blue), `.test-badge-integration` (amber), `.test-badge-e2e` (purple), `.test-badge-objective` (green). Include a `.test-tier-label` at the top indicating the tier. For Tier 2 plans, omit the `.test-list` container entirely. Add a sidebar nav `<li>` with `href="#tests"` and the beaker icon between Steps and Criteria.
- **Visual components.** The **files** (`.file-tree`) block is **auto-generated** from the plan's steps (see [File-Tree Auto-Generation](#file-tree-auto-generation)) — always include it when any files are referenced, delete it only for purely conceptual plans. The **diagram** (`.pipeline` / `.compare-grid`), **chart** (`.bar-chart`), and **table** (`.plan-table`) blocks remain opt-in — keep and fill a block only when the plan's content warrants it; otherwise delete the whole block **and** its matching sidebar nav `<li>` (the `#diagram` link). The scroll-spy filters to existing sections, so removal is safe with no JS edits. Never add a CDN, `<canvas>`, or charting library — every visual stays pure CSS / inline SVG. Keep the accessibility affordances when filling: a `<caption>` and `<th scope="col">` on tables, a visible numeric `.bar-value` plus container `aria-label` on charts, and a text label (not colour alone) on every file badge.

## Machine-Readable Digest (`#plan-digest`)

Every plan embeds a spec-only markdown digest as the **first element child of `<body>`**: a `<script type="text/markdown" id="plan-digest">` block. `type="text/markdown"` never renders or executes, so the plan stays a single self-contained file with no visual or runtime change. A guiding HTML comment above the block is allowed — comments are not elements, so the script remains `firstElementChild`. Consumers (the implementer, the workflow author, the review-team reviewers) read the digest instead of the full styled HTML — a few thousand tokens of spec instead of ~21k of skeleton CSS/JS.

**Included fields (authored spec only):**

- `# Plan: <title>` heading, followed by the fixed note: `> Authored spec only. Status and progress live in the <head> meta tags and the live DOM, never in this block.`
- `## Objective` — the objective text
- `## Context` — the context text
- `## Files` — one bullet per file: path, `(new|modified|deleted|generated)`, and the file note
- `## Steps` — numbered list; each item carries the step action, its *Why:* text, and its *Verify:* text
- `## Tests` — the tier line plus the objective-verification test and any unit/integration/E2E cards (file, asserts/targets/key cases, run command where present)
- `## Acceptance Criteria` — one bullet per criterion (the label text only)
- `## Verification` — the end-to-end verification text

**Excluded — never in the digest:** status values, step chips or `completed` classes, checkbox state, progress counts, the completion checklist and report, team-review appendices, next steps, and unresolved questions. The digest is the authored spec; mutable state lives in the `<head>` meta tags and the live DOM.

**Escaping contract:** Digest content is plain markdown — do **not** HTML-escape it (script content is raw text to the HTML parser). When deriving digest text from already-escaped HTML, decode entities (`&amp;`, `&lt;`, `&gt;`, `&quot;`, `&#39;`) back to characters first. Apply exactly one guard: write any literal closing-script sequence in the content as `<\/script` (backslash before the slash) so it cannot terminate the block early.

**Canonical extraction (flag-and-exit awk):**

```bash
awk '!f && /<script[^>]*id="plan-digest"/{f=1;next} f && /<\/script>/{exit} f' <file>
```

Every part of this one-liner is load-bearing — use it verbatim:

- `!f` makes the opening rule **first-match-only**. Without it, a digest body line that quotes the opening tag (as this feature's own plan does in its objective) re-matches the rule and is silently swallowed by `next`.
- The flag-and-exit shape (rather than an awk `/start/,/end/` range) keeps later lines that merely mention the id from re-opening the range.
- The `[^>]*` form keeps the one-liner from matching itself when it is quoted inside HTML comments, prompts, or digest bodies.
- `f && /<\/script>/{exit}` stops at the first **unguarded** closing tag; guarded `<\/script` sequences in the content do not match.

**Generation and refresh:**

- Fill `{plan-digest}` from the final drafted spec when writing the plan (Step 2 placeholder fill).
- Refresh the digest whenever plan **content** changes after creation — interview-driven edits (Step 5b), Step 8 `Edit the plan` revisions, and review-team integrations all stale it. The digest carries no checksum or timestamp; the refresh rule is what keeps it honest.
- Status transitions (Step 6, Step 8 gates), criteria check-offs, and completion-checklist updates **never** touch the digest.

## Visual Components

These four components are defined (CSS) once in `reference/SKELETON.html` and shipped as opt-in `<body>` blocks. The CSS is always present and harmless when unused; you only ever keep/delete the markup blocks. Reach for a component when its trigger matches — do not add visuals gratuitously.

| Component | Use when the plan… | Markup | Fill |
|-----------|--------------------|--------|------|
| **File-tree** | references any file (≥1) — **auto-generated** from steps | `.file-tree` → nested `ul.file-list` | `{file-tree-rows}` populated automatically — see [File-Tree Auto-Generation](#file-tree-auto-generation) |
| **Flow / pipeline** | has a process, data flow, or architecture sequence | `.pipeline` → `.pipeline-node` + `.pipeline-arrow` | one node per stage, arrows between; `{diagram-nodes}` |
| **Comparison grid** | weighs a 2–3-way trade-off (kept/dropped, before/after, option A/B/C) | `.compare-grid` → `.compare-col-{add\|neutral\|remove}` | one column per side; `{compare-columns}` |
| **Bar chart** | shows a distribution or relative magnitudes | `.bar-chart` → `.bar-row` | width via inline `style="--val:NN%"`, real value in `.bar-value`, data restated in `aria-label`; `{chart-rows}` |
| **Data table** | maps structured data (file→change, option→behaviour) | `.plan-table` with `<caption>` + `<th scope="col">` | header cells `{table-head-cells}`, body rows `{table-rows}` |

Rules:

- **File-tree is auto-generated.** Always populate the files section when any file is referenced in the plan's steps (see [File-Tree Auto-Generation](#file-tree-auto-generation)). Delete the block only when the plan has zero file references.
- **Other visuals are opt-in.** Keep a block only when its trigger matches; delete the whole block and its sidebar nav link otherwise — exactly as you already do for `.plan-workflow` and unresolved-questions.
- **Self-contained.** Pure CSS / inline SVG only. No CDN, no `<canvas>`, no charting library.
- **Accessible.** Tables: `<caption>` + scoped headers. Charts: visible numeric values + a descriptive container `aria-label` (never colour-only). File badges: a text label alongside the colour.
- **HTML-escape** all file paths, code, and user-supplied text inside these blocks (`&` → `&amp;`, `<` → `&lt;`, `>` → `&gt;`).

### File-Tree Auto-Generation

When the plan's steps reference files to create, modify, or delete, automatically generate the Files file-tree section instead of requiring manual construction. Run this after drafting all steps and before writing the final HTML.

**Extraction.** Scan every step's action, why, and verify text for file paths. A file path is any token that contains a `/` separator or ends with a recognised source-code extension (`.ts`, `.tsx`, `.js`, `.jsx`, `.py`, `.rs`, `.go`, `.java`, `.html`, `.css`, `.scss`, `.json`, `.yaml`, `.yml`, `.toml`, `.md`, `.sql`, `.sh`, `.rb`, `.vue`, `.svelte`, `.astro`, `.xml`, `.graphql`, `.proto`, `.env`, `.config.*`). Ignore URLs (`http://`, `https://`), placeholder paths (`path/to/file`, `example.ext`), and duplicate entries.

**Classification.** Assign a badge to each file based on the step's action verb and surrounding context:

| Verb / context | Badge class | Label |
|----------------|-------------|-------|
| create, add (new file), introduce, scaffold, generate, init | `file-badge-new` | new |
| modify, update, edit, change, refactor, rename, extend, wire up, add (to existing file) | `file-badge-modified` | modified |
| delete, remove, drop, deprecate | `file-badge-deleted` | deleted |
| auto-generated, codegen, compiled, emitted | `file-badge-generated` | generated |

When ambiguous, default to `file-badge-modified`. When a file appears in multiple steps with different operations, keep the most impactful badge: `deleted` > `new` > `generated` > `modified`.

**Grouping.** Group files by their immediate parent directory. For each directory that contains two or more files, emit a `<li class="file-dir">` directory heading followed by a nested `<ul class="file-list">` containing its children (show only the filename inside the nested list, not the full path). Files whose parent directory has only one entry are shown at the top level with their full relative path — no directory wrapper. Sort directories alphabetically, then files within each directory alphabetically.

**Rendering.** Build the `{file-tree-rows}` markup using this pattern:

```html
<!-- Directory with 2+ files -->
<li class="file-dir"><svg class="icon" aria-hidden="true"><use href="#ic-folder"/></svg> src/components/</li>
<ul class="file-list">
  <li><code>Button.tsx</code> <span class="file-badge file-badge-new">new</span> <span class="file-note">primary action component</span></li>
  <li><code>Modal.tsx</code> <span class="file-badge file-badge-modified">modified</span> <span class="file-note">add close callback prop</span></li>
</ul>

<!-- Single file in a unique directory — show full path, no wrapper -->
<li><code>src/index.ts</code> <span class="file-badge file-badge-modified">modified</span> <span class="file-note">re-export new component</span></li>
```

The `.file-note` is a terse phrase (3–8 words) summarising what changes in that file — derive it from the step that references the file. HTML-escape all paths and notes.

**Inclusion rule.** Always include the Files section when ≥1 file is detected. Only delete the entire `section.card-files#files` block **and** its sidebar nav `<li>` (`#files` link) when zero files are referenced (purely conceptual plans).

## Writing Style

Direct, imperative, developer-friendly — real names (file paths, function names, CLI flags), lists over prose, one idea per item, explicitly scoped. Plan only what was requested; unsolicited ideas go in `next-steps`. Blue-sky ideas always go to the Wish List subsection.

**Tone:** Write like an enthusiastic senior engineer briefing the team — concrete, direct, zero filler. **Objective:** a rallying statement, not a ticket summary (*"Ship a dark-mode toggle that persists across all three themes"* not *"Add dark mode"*). **Step actions:** lead with a strong imperative verb phrase (*"Wire up the ThemeContext provider"* not *"ThemeContext setup"*). Do not add extra emoji to prose — section icons are provided by the skeleton HTML.

## Skeleton

Copy `reference/SKELETON.html` from this plugin's skill directory as a starter for every new plan. Locate it by reading the same directory that contains this `SKILL.md` file — use `Glob` with pattern `**/plan-agent/skills/implementation-plan/reference/SKELETON.html` if the path is uncertain. Fill every placeholder (wrapped in `{curly braces}`) before writing the file. The skeleton includes copy buttons after every prompt `<pre>`; do not remove them when filling placeholders. `minimal`, `adr`, and `spike` template variants are planned but not yet implemented — use `SKELETON.html` for all plans until those variants ship.

Each step card in the skeleton includes a `<span class="step-chip">todo</span>` before the action text. Always write `todo` as the initial chip value — the chip visually updates to `done` via CSS when the `.step-card.completed` class is applied. Do not change the chip text from `todo` in the initial HTML output.

The skeleton includes a Completion Checklist section with three fixed checkbox items (all step TODOs done, all acceptance criteria checked, status updated) and an empty Completion Report. These items are identical in every plan and have no placeholders to fill. Do not remove this section or change its checkbox items.

The skeleton also ships visual blocks behind removal comments, just like `.plan-workflow`. The **files** block is **auto-generated** from the plan's steps (see [File-Tree Auto-Generation](#file-tree-auto-generation)) — always keep it when any files are referenced, delete it only for purely conceptual plans with zero file references. The **diagram**/**chart**/**table** blocks remain opt-in: keep and fill them when the plan's content warrants the visual (see **Visual Components** for triggers), otherwise delete the entire block **and** its sidebar nav `<li>` (the `#diagram` link). All CSS stays in the skeleton's `<style>` either way — it is inert when the markup is absent.

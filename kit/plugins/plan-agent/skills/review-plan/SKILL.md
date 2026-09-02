---
name: review-plan
model: opus
description: Plan review reviewer panel. Reviews implementation plans in parallel, refutes weak findings, and applies improvements in place. Use when the user asks to review or improve an implementation plan.
allowed-tools: Read, Glob, Grep, Bash, Edit, AskUserQuestion, TodoWrite, ToolSearch, ExitPlanMode, Artifact, Workflow
---

# Plan Review Panel Skill

**Primary purpose: improve and update plans in place.** Run a ten-reviewer Workflow — seven core plan reviewers (architecture, completeness, testability, risk, conventions, product, security) plus three UI-conditional reviewers (UX, accessibility, frontend) — to review implementation plans, synthesize findings, and apply concrete improvements directly to the source plan.

## When not to use

- **Not a code reviewer.** For code, use `code-review`. For conversational plan stress-testing, use the built-in Step 5b interview.
- **Requires the Workflow tool.** Hard-stops when it is unavailable in the session. No feature flag, and no minimum version to set.

## Background mode

When invoked with `--background` (typically via `/plan-agent:review-plan-bg <path>` or the `agent-review-plan` background agent):

- **Requires an explicit plan path** — will not glob or prompt for a file.
- **Skips all `AskUserQuestion` calls** — no interactive prompts.
- **Defaults to "review + update plan in place"** — always applies improvements directly.
- **Reports the applied/skipped tally** — Step 7's verify pass still runs; if any accepted edit was skipped, the final report leads with `REVIEW INCOMPLETE`, never the success line.
- **Implies `--skip-analysis`** — the Step 6b walkthrough never runs unattended.
- **Safe for unattended execution** — no user interaction required at any step.

Detection: check whether `$ARGUMENTS` (or the `args` string passed via `Skill()`) contains the `--background` token. If present, set `background_mode = true` and strip the token before further argument parsing. In the same pass, detect a `--skip-analysis` token (set `skip_analysis = true`), a `--triage-top <N>` token (capture the integer `N`; default unset = full per-finding triage), and a `--deep` token (set `deep = true`, passed straight through to the workflow's `args.deep`, where it lifts the severity filter so every finding is challenged instead of only the high and critical ones); strip all three tokens before further argument parsing. `background_mode = true` forces `skip_analysis = true`, whether or not `--skip-analysis` was passed.

## Workflow

### Step 0 — Exit plan mode and create progress todos

**If in plan mode**, call `ExitPlanMode` first — this workflow mutates state.

Use `TodoWrite` to create todos for Steps 1–8. Mark each `completed` as done.

### Step 1 — Resolve the plan file

Accept an explicit path token ending in `.html` or `.md` — the same shape
finalize-plan Step 1 takes. Since 9.7.0 the local `.html` is a `--file` opt-in,
so an artifact-delivered plan has **only** a `.md` spec and that is the path a
user has to paste.

Default (no path token): take the most recently modified of the two lists
below, under the plans directory (`--dir <path>` overrides; else configured
`plansDirectory`; else `docs/plans/`). A `.html` glob alone cannot see an
artifact plan — it has no HTML — so it would silently review a stale
file-published plan instead:

```bash
{ find "$PLANS_DIR" -maxdepth 1 -name '*.html' ! -name 'index.html' -print
  for spec in "$PLANS_DIR"/*.md; do
    [ -e "$spec" ] || continue
    [ -e "${spec%.md}.html" ] && continue          # file-published; already listed
    grep -q '^# Plan:' "$spec" || continue         # a spec, not a session note
    awk 'NR==1 && !/^---/{exit} NR>1 && /^---/{exit} {print}' "$spec" \
      | grep -qE '^artifact-url: *https?://[^/ ]' || continue
    printf '%s\n' "$spec"
  done || true
} | xargs ls -t 2>/dev/null | head -1
```

The frontmatter-bounded `awk` matters: these plans are often *about*
plan-agent, so a body line quoting `artifact-url:` false-matches a whole-file
grep. The `[^/ ]` requires a host — a truncated `https://` passed to `Artifact`
claims a **new** URL instead of updating the shared one.

**Background mode:** an explicit file path is mandatory — `--dir` (directory) arguments are rejected. If `$ARGUMENTS` contains `--dir` or if no non-flag token resolving to a file (not a directory) is present, output: "`Background mode requires an explicit plan file path, not a directory. Usage: /plan-agent:review-plan <file.html|file.md> --background`" and stop.

If no file is found, output: "`Plan file not found. Provide an explicit path, or place a plan in docs/plans/ (a rendered .html, or a .md spec carrying artifact-url:).`" and stop.

**Determine the edit mode** from the resolved stem (`<stem>` = the resolved plan's path without its extension), mirroring finalize-plan's `references/resolve-and-modes.md`:

- **Spec mode** — `<stem>.md` exists and its first markdown heading (after any YAML frontmatter block) is `# Plan:`. The spec is the source of truth: the render pipeline regenerates `<stem>.html` from it on every spec write, discarding hand-edits to the HTML — so Step 7 edits the spec and re-renders.
- **Legacy mode** — no such spec (or the `.md` beside the plan is not a spec). Step 7 edits `<stem>.html` directly, as before the markdown-first pipeline.

**Then determine where the plan is published**, which is a separate question
from the edit mode and decides where Step 7's re-render goes. The signal is a
sibling's existence, shared with the render hook and the gallery:

- **File-published** — `<stem>.html` exists. Step 7 overwrites it.
- **Artifact-published** — no sibling, and the spec's frontmatter carries an
  `artifact-url:` that parses as an `http(s)` URL with a host. Step 7 renders
  to the scratchpad and republishes to that URL.

Announce: `"Reviewing plan: <resolved-path> (<spec|legacy> mode, <file|artifact>-published)"`

### Step 2 — Choose output mode

Default to "review + update plan in place".

**Background mode:** skip the `AskUserQuestion` prompt entirely — always use "review + update plan in place".

**Interactive mode:** Optionally ask `AskUserQuestion`: "Should I apply improvements directly to the plan?"
- **Review + update plan in place** _(default)_
- **Review only**

### Step 3 — Confirm the Workflow tool is available

The reviewers run as a Workflow script. Confirm the `Workflow` tool is
callable in this session; if it is not, stop with:

"`This review needs the Workflow tool, which is not available in this session. Update Claude Code and try again.`"

**Probe, never assert a version number.** A capability check answers the only
question that matters — can this session run the script — and it stays correct
as the tool's availability changes. A hardcoded minimum version is a guess that
silently blocks working sessions the moment it is wrong, which is exactly the
failure this step replaced: the old Agent Teams gate demanded both a minimum
Claude Code version and an experimental environment flag, so the plugin's most
expensive feature was dark for everyone who never set a flag they were never
told about. See `../../CHANGELOG.md` (9.12.0) for the exact gate removed.

Calling `Workflow` from here is authorized: the tool accepts "a skill whose
instructions tell you to call Workflow" as user opt-in, and this instruction is
that. Do not additionally ask the user to type `ultracode`.

### Step 3b — Detect UI signals

Read the resolved plan HTML (excluding `<style>` and `<script>` blocks). Scan for UI signal keywords:

**UI signals:** React, Vue, Svelte, Angular, `.tsx`, `.jsx`, `.css`, `.html`, `className`, `style`, Tailwind, button, modal, form, dialog, dropdown, page, component.

If 2+ signals found or UI-specific keywords present, set `ui_signals_present = true`. Announce: "`UI signals detected — running 10 reviewers`" or "`No UI signals — running 7 core reviewers`".

### Step 4 — Run the review workflow

Get absolute path:
```bash
realpath "<path-from-step-1>"
```

Read `references/review-workflow.mjs` and pass its **contents** as the
`Workflow` tool's inline `script` input. Never launch it by path: the Bash tool
rejects any command carrying shell expansion outright ("Contains expansion")
before permission rules are consulted, so a plugin-root-anchored invocation is
unrunnable by *any* agent at *any* permission level. See `../../CHANGELOG.md`
(8.2.1) for the same trap in its earlier form.

Pass `args` as an object — actual JSON, never a JSON-encoded string:

| key | value |
|---|---|
| `planPath` | the `realpath` output from above |
| `reviewers` | the roster below, as `[{key, agentType}]` |
| `deep` | `true` only when `$ARGUMENTS` carried `--deep` |

The roster, which Step 3b's `ui_signals_present` selects between:
- Always: `plan-reviewer-architecture`, `-completeness`, `-testability`, `-risk`, `-conventions`, `-product`, `-security`
- When `ui_signals_present`: also `plan-reviewer-ux`, `-accessibility`, `-frontend`

Each entry's `agentType` is that reviewer's full agent name
(`plan-agent:plan-reviewer-architecture`). The script briefs no lens of its
own — `agentType` resolves the shipped agent definition, whose system prompt
*is* the lens. That is why there are no spawn-prompt templates to maintain.

Reviewers read the **full plan HTML** with `Read`. They do not run
`extract-plan-spec.mjs`: it is unrunnable for the same expansion reason above.
Users who want the cheaper spec read can run the extractor themselves with a
literal path and paste the result in.

**Failures need no handling here.** A reviewer that dies is returned as `null`
by the script's second pipeline stage rather than throwing; the script counts
it in `stats.lensesLost` and `log()`s that the lens is missing. Do not respawn,
do not wait, do not poll — the tool returns when the run is done.

Announce progress: "`Running 7 core reviewers`" or "`Running 10 reviewers (7 core + 3 UI)`".

The old Step 5 — collect via `SendMessage`, respawn once, mark unavailable —
is absorbed here. **The numbering below is deliberately left with a gap** so
that every existing cross-reference to Step 6b, Step 7 and Step 8, here and in
`agents/agent-review-plan.md`, keeps resolving. Do not renumber.

### Step 6 — Synthesize findings

Read `references/output-template.md`. The workflow returned
`{findings, stats}` — `findings` is an array of validated objects, each
carrying `reviewer`, `target`, `action`, `content`, `rationale`, `severity`,
and `verdict`, which has **three** states: an object with `refuted: false` (a
skeptic challenged it and failed to refute it), `null` (never sent, because its
severity was below the verify threshold), or an object with `failed: true`
(sent, but the skeptic itself died). Keep the last two apart — telling a user to
re-run with `--deep` cannot fix a crashed verifier. **Populate the template from those
fields directly. Never re-derive a finding from prose** — the round-trip
through free text is where findings used to go missing, and it is the reason
this data is typed.

Populate the template:

- **Executive Summary:** Synthesize overall assessment.
- **Role-by-Role:** Group `findings` by their `reviewer` field. A reviewer the script reported as lost has no findings — say so rather than leaving its subsection blank.
- **Agreements & Conflicts:** Where reviewers agree (amplify), conflict (explain tradeoff). Two findings with the same `target` are the signal to look at.
- **Highest-Risk Issues:** Rank by `severity`, `critical` first.
- **Inline Edits to Apply:** One row per finding — `target`, `action`, `content`, Source / Rationale (its `reviewer` plus `rationale`), and **Verdict**. The verdict column reads `verified` when `verdict.refuted` is false, `unverified — below verify threshold` when `verdict` is `null`, and `unverified — verifier failed` when `verdict.failed` is true. Refuted findings never reach this table; the script already dropped them. Step 6b's triage presents Source / Rationale and Verdict alongside each finding, so the user can see which findings survived a challenge and which were never challenged.
- **Revised Plan:** (Filled after Step 7.)

Carry `stats` into the Executive Summary verbatim — how many findings stand,
how many survived refutation, how many went unverified, how many had their
verifier fail, how many were refuted and dropped, and whether any reviewer was
lost (`stats.lensesLost`). A review that silently omits
its own coverage reads as exhaustive when it is not.

**Rejection path:** If the team consensus is "reject", populate the reject-only subsections per the template. Otherwise, omit reject-only content.

### Step 6b — Walkthrough & Analysis

An interactive triage of the synthesized findings before any edits are applied.

**Skip condition:** Skip Step 6b entirely when `skip_analysis = true`, when `background_mode = true`, or when `output_mode = "review only"` (chosen at Step 2). When skipped via `skip_analysis` or `background_mode`, Step 7 receives the full "Inline Edits to Apply" table; when skipped because `output_mode = "review only"`, Step 7 applies no edits — Pass 1 is skipped and only the Team Review is appended.

**Ask-first gate:** Ask `AskUserQuestion`: "Walk through the findings before applying?"
- **Walk through findings** _(default, recommended)_ — run the per-finding triage loop below.
- **Apply all** — bypass the walkthrough by choice; Step 7 applies the full table.
- **Review only** — set `output_mode = "review only"`; Step 7 applies no edits but still appends the Team Review.

Declining the gate is **not** equivalent to `--skip-analysis`: the gate was still shown. `--skip-analysis` suppresses the gate itself.

**Per-finding triage loop:** Iterate the rows of the "Inline Edits to Apply" table, batching at most 4 findings per `AskUserQuestion` call (one question per finding). Each question presents the finding's Source / Rationale (originating reviewer + why, from the synthesis table), its **Verdict** (`verified`, `unverified — below verify threshold`, or `unverified — verifier failed`), and its proposed content, with options:
- **Accept** — keep the edit as-is.
- **Modify** — keep the edit, marked for revision.
- **Reject** — drop the edit.

**Modify semantics:** Modify does **not** collect inline free-text. It marks the finding for a single post-walkthrough edit pass that runs once after the triage loop, in which the developer revises the kept edits directly in the plan.

**`--triage-top <N>`:** When set, individually triage only the `N` highest-risk findings (ranked per the Highest-Risk Issues synthesis section) and batch-accept the remainder. Default unset = full per-finding triage. The flag is ignored whenever the walkthrough is skipped.

**Output:** Step 6b produces an `accepted_edits` list — findings accepted as-is plus modified findings with their revised content; rejected findings are excluded. `accepted_edits` is consumed by Step 7 Pass 1, and all triage decisions (accepted / modified / rejected) are retained for Step 7 Pass 2's triage record.

### Step 7 — Integrate panel findings into the source plan

Pass 1 is skipped when `output_mode = "review only"`; Pass 2 always runs. (When the Step 6b gate was declined via "Review only": no edits applied, Team Review still appended.)

**Pass 1 — Inline edits:** When the Step 6b walkthrough ran, iterate **only** `accepted_edits` — findings accepted as-is plus revised-modified findings. The full-table fallback — iterating every row of the "Inline Edits to Apply" table — fires **only** when the walkthrough was bypassed: `--skip-analysis`, background mode, or the "Apply all" gate choice. Declining the gate ("Review only") is **not** a fallback case. Apply the edits per the Step 1 edit mode:

**Spec mode:** edit `<stem>.md` — never the HTML, which the pipeline regenerates from the spec, deleting hand-edits. Map each row's selector target to its spec section and apply one `Edit` call against the spec, writing markdown (no HTML escaping):

| Selector target | Spec target |
|---|---|
| `.objective-card` | the `## Objective` paragraph |
| `#criteria-list li#acN` (edit) | the matching bullet under `## Acceptance Criteria` (preserve its `- [ ]`/`- [x]` marker) |
| `#criteria-list` (append) | a new `- [ ]` bullet at the end of `## Acceptance Criteria` |
| `.step-card #step-N .step-why` | step N's `Why:` line under `## Steps` |
| `.step-card #step-N .verify-body` | step N's `Verify:` line under `## Steps` |
| `.step-card:nth-child(N)` (insert after) | a new numbered step after step N under `## Steps` (renumber the steps that follow) |
| `.verification-section` | the `## Verification` prose |

After the last edit, re-render — the same invocation build and finalize-plan use. Where it goes follows Step 1's published-where finding.

**File-published** — overwrite the sibling:

```bash
plan-agent-render "<stem>.md" -o "<stem>.html"
```

**Artifact-published** — render to the scratchpad, then call `Artifact` with that path and `url: <the artifact-url>`, re-read from the frontmatter immediately beforehand so a URL another session recorded is the one you update:

```bash
plan-agent-render "<stem>.md" -o "$SCRATCHPAD/<stem>.html"
```

**Never write `<stem>.html`** in that case: it resurrects the file the author chose not to publish and flips the plan's gallery card off the artifact onto a local path. A review is also when the shared page most needs to be current — it is the state every other reader sees.

`-o` is **mandatory** here, not stylistic. Dropping it does not error — the renderer defaults its output to the sibling `<stem>.html`, exits 0, and says nothing, which is precisely the file this rule forbids. Verified against the CLI.

Bare name, never a path — this plugin's `bin/` is on `PATH`. A non-zero exit means an edit broke the spec format: fix the markdown and re-run, never hand-edit the HTML to compensate. A failed republish is reported in one line and never rolls back the spec edits, which are already correct on disk.

**Legacy mode:** for each edit, apply one `Edit` call against the resolved plan HTML:
- `edit` — replace targeted element's content.
- `append` — add to the end of the element.
- `insert after "[anchor]"` — insert new sibling after anchor.

HTML-escape all inserted content. Never modify `<style>` or `<script>`.

**Both modes:** skip rows whose target cannot be matched (log warning, continue). Every skipped row feeds the tally below — a skip is never silent.

**Pass 2 — Append team review:**

**Spec mode:** use `Edit` to append a `## Team Review (YYYY-MM-DD HH:MM UTC)` section to the end of `<stem>.md`, demoting the synthesized report's own `##` headings to `###` so they nest under it and never collide with spec section names. Then re-render as in Pass 1. The renderer ignores sections it does not recognize, so the review persists in the spec — the source of truth — rather than in HTML the next re-render would discard.

**Legacy mode:** use `Edit` to append a new `<details>` section before `</main>`:
```html
<details id="team-review-TIMESTAMP" class="team-review">
  <summary>Team Review (YYYY-MM-DD HH:MM:SS UTC)</summary>
  <div class="review-body">
    <!-- Full synthesized report here, HTML-escaped -->
  </div>
</details>
```

When the Step 6b walkthrough ran, the appended review — either mode — also includes a triage-outcome summary — accepted findings (applied as-is), modified findings (with their revised content), and rejected findings (recorded but not applied) — per the "Triage Outcome" subsection of `references/output-template.md`.

**Verify, then announce:** re-read the edited file (`<stem>.md` in spec mode, the plan HTML in legacy mode) and confirm each accepted edit's content is actually present; any edit whose content did not land moves to the skipped list. Count `N` = edits confirmed present, `M` = accepted edits. Announce:

"`Plan updated in place: <resolved-path> (<spec|legacy> mode) — applied N of M accepted edits; skipped: <targets, or "none">`"

**Background mode:** when the skipped list is non-empty, the final report must lead with `REVIEW INCOMPLETE` and carry the same tally instead of the success line — a skipped edit is a reported failure, not a warning nobody sees.

### Step 8 — Report and stop

The workflow runtime owns its own agents' lifecycle — there is no team to tear
down. Report the applied/skipped tally from Step 7 plus the coverage line from
Step 6 (findings standing, verified, unverified, refuted, reviewers lost), then
stop.

---

## Conditional Activation

This skill runs only when the user asks to review or improve an implementation plan. It does not auto-activate on other plan types (e.g., high-level roadmaps, spike plans).

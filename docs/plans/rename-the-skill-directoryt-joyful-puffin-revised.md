## Product Plan Review — Add background-mode + agent variant to `product-plans` (v2.1.0)

*Reviewed by: PM · Lead Developer · UX Designer · Frontend Engineer · Accessibility Expert — coordinated by Lead Coordinator*

---

### 1. Executive Summary

The plan is well-structured, additive, and follows established repo patterns. The core risk is that the critical unresolved question — whether the `Skill` tool is callable from a custom `background: true` subagent — is load-bearing: if the answer is "no," the hybrid architecture collapses and one of two substantially different fallback approaches must be chosen before any implementation begins. The plan should not be executed until this question is resolved. Subject to that resolution, the panel recommends **Approve with revisions**.

---

### 2. Role-by-Role Review

#### Product Manager

**Works well:** Clear, bounded objective. Three additive surfaces are well-defined. Non-breaking-change guarantee is explicit. Versioning rationale (MINOR) is correct and documented. Background-defaults table is precise.

**Unclear:** No success metrics. No user-discoverability plan for the new slash command. No rollback or degradation path if a background run silently fails mid-panel.

**Critical concerns:** Plan filename (`rename-the-skill-directoryt-joyful-puffin.md`) does not match plan content — a plan defect per `plan-mode.md`. The unresolved question about `Skill` tool availability is product-blocking: the architecture depends on it.

**Minor concerns:** "Unresolved questions" section is substantive, but the plan proceeds to Steps without requiring an answer first. The ack line (`Background panel review started: <path>`) gives no indication of how long the review will take or how users will know it completed.

**Missing requirements:** Acceptance criteria beyond "no AskUserQuestion fires." Definition of done for a successful background run. User-facing documentation of how to find the sibling file after the session.

**Risks or blockers:** Unresolved `Skill`-tool-in-subagent question is a blocker. Silent failure UX (background run errors with no user notification) is a risk.

**Recommended improvements:** Gate implementation on the unresolved question. Rename the plan file to match content (e.g., `add-background-mode-to-product-plans.md`). Add a README note about locating output.

**Questions that must be answered:** Can a `background: true` subagent invoke the `Skill` tool? What is the user's signal that the background review completed successfully or failed?

**Approval status:** Approve with revisions.

---

#### Lead Developer

**Works well:** `--background` flag via string-contains mirrors the existing `plan-to-html` pattern — consistent and low-risk. Sibling-file default is non-destructive. `maxTurns: 30` is documented and justified. Steps are well-verified with grep/jq checks.

**Unclear:** `tools: Skill, Read` in the agent frontmatter — it is unconfirmed whether `Skill` is a recognized tool value in custom subagent frontmatter, or whether it maps to the harness Skill invocation mechanism. Step 1 contains a grammatically broken sentence ("Add `Skill` and `Read` to nothing") that is confusing.

**Critical concerns:** The unresolved question about `Skill`-tool availability in custom `background: true` subagents is architecturally load-bearing. If unavailable, the entire hybrid pattern requires redesign (either `general-purpose` subagent type or workflow duplication). This must be resolved before creating `agents/agent-product-plans.md`.

**Minor concerns:** Step 7 background-write path has no error handling: if `Write` fails (e.g., permission error, disk full), the background agent exits silently with no user-facing signal. The `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` flag check in the skill (Step 3) is not replicated in the agent wrapper — if the flag is off, the agent will fail with a confusing error rather than a clear message.

**Missing requirements:** Error surface for when the background panel itself fails entirely (all teammates unavailable). Explicit error handling in the Step 7 Write path.

**Risks or blockers:** Unresolved `Skill`-tool question. Agent Teams flag not checked inside agent wrapper.

**Recommended improvements:** Add a Step 3 equivalent (flag check + version check) inside the agent body. Gate implementation on unresolved question. Fix the broken sentence in plan Step 1. Add a fallback note in Step 7 for Write failure.

**Questions that must be answered:** Is `Skill` a valid `tools:` entry in custom subagent frontmatter? Does the agent body inherit the parent session's env vars (including `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`)?

**Approval status:** Approve with revisions — unresolved question must be answered first.

---

#### UX Designer

**Works well:** The user-facing interface is minimal and appropriate for a CLI plugin: one command, one ack line, one predictable output file. The sibling-file naming convention is consistent and findable.

**Unclear:** The ack line (`Background panel review started: <path>`) gives no progress signal and no ETA. Users won't know if the background run is still active or has failed without checking for the sibling file manually.

**Critical concerns:** No failure UX. If the background agent silently errors after the ack, the user has no notification. The plan mentions "background-task completion notification arrives later" (verification step 4) but does not specify whether this is delivered automatically by the Claude Code harness or requires implementation.

**Minor concerns:** No guidance for the session-closed scenario: if the user closes their session before the background run completes, will the sibling file still be written? The plan is silent on this.

**Missing requirements:** A clear failure signal (even a file like `<stem>-revised-error.log`). Documentation of where to find the sibling file if the completion notification is missed. Clarification of whether the harness delivers background-task notifications automatically.

**Risks or blockers:** Silent failure UX is the primary UX risk — users may conclude the review never ran.

**Recommended improvements:** Add a note in the README explaining that if no sibling file appears after a few minutes, the background run may have failed and the user should retry interactively. Clarify in the command body whether a completion notification is automatic or requires a harness feature.

**Questions that must be answered:** Does Claude Code automatically deliver a background-task completion notification to the parent session? Is this consistent across session-closed scenarios?

**Approval status:** Approve with revisions.

---

#### Lead Frontend Engineer

**Works well:** This plan has no frontend UI surface — correctly scoped to CLI plugin mechanics. The slash-command entry point follows the established plugin convention.

**Unclear:** Not applicable — no frontend components in scope.

**Critical concerns:** None frontend-specific.

**Minor concerns:** Step 8 (README update) specifies three sections to update but does not reference the exact existing README section headings, which could result in inconsistently named subsections or insertion at the wrong level.

**Missing requirements:** None frontend-specific.

**Risks or blockers:** None frontend-specific.

**Recommended improvements:** In plan Step 8, reference the exact existing README section headings (e.g., "insert under `## Features`, before `## Usage`") so the writer has an unambiguous anchor.

**Questions that must be answered:** None frontend-specific.

**Approval status:** Approve (no frontend concerns).

---

#### Accessibility Expert

**Works well:** This is a CLI plugin with no visual UI. Output is plain Markdown — inherently accessible to any Markdown reader or screen reader.

**Unclear:** Not applicable — no UI components in scope.

**Critical concerns:** None accessibility-specific.

**Minor concerns:** The plan does not address how users relying on assistive technology will receive the background-task completion notification if it is delivered as a visual-only toast or UI element in Claude Code. This is a harness concern rather than a plugin concern, but worth noting.

**Missing requirements:** None within the plugin's control.

**Risks or blockers:** None accessibility-specific.

**Recommended improvements:** Add a brief note in the README that the output is a plain Markdown file, explicitly accessible to any Markdown viewer or assistive technology.

**Questions that must be answered:** How does Claude Code deliver background-task completion notifications — is the delivery mechanism accessible?

**Approval status:** Approve (no accessibility concerns within plugin scope).

---

### 3. Highest-Risk Issues

1. **Unresolved `Skill`-tool availability (PM + Dev — confirmed):** Whether a custom `background: true` subagent can invoke the `Skill` tool is unknown. If it cannot, the entire hybrid architecture (agent wrapping a skill call) is non-functional and must be redesigned. This is the single highest-risk item. *This risk materialized on first run: the agent's `tools: Skill, Read` definition did not grant Write access, and the Skill tool delivered instruction text rather than executing the workflow.*

2. **Silent failure UX (Dev + UX — confirmed):** No failure notification path exists for background runs. A user who fires the command and closes their session may never learn the review failed. No error file, no retry guidance, no harness notification confirmation.

3. **Plan filename is a defect (PM):** The file `rename-the-skill-directoryt-joyful-puffin.md` does not describe the plan's content. Per `plan-mode.md`, this must be corrected before committing.

4. **Agent Teams flag not checked in agent wrapper (Dev):** The agent body does not replicate the Step 3 environment check. If `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` is not set, the agent will fail with an opaque error rather than the clear guidance message the skill provides.

5. **No acceptance criteria (PM):** The verification section tests mechanics but not outcomes. There is no definition of a successful background review beyond "a sibling file appears."

---

### 4. Blocking Issues

- **Unresolved question must be answered before Step 5 (agent creation):** The `Skill`-tool-in-subagent question determines whether the agent body is implementable as written. Block implementation of `agents/agent-product-plans.md` until resolved. Role: Lead Developer / PM.

---

### 5. Important but Non-Blocking Improvements

- **Rename the plan file** to a descriptive kebab-case name matching content (e.g., `add-background-mode-to-product-plans.md`). Role: PM. Can be done immediately.
- **Add Agent Teams flag check inside agent body.** Prevents opaque failure when the flag is off. Role: Lead Developer. Non-blocking for prototyping but should ship before v2.1.0.
- **Add README note about finding the sibling file and what to do on failure.** Role: UX Designer / Frontend. Non-blocking.
- **Add Write failure handling in Step 7 background path.** Role: Lead Developer. Non-blocking but improves reliability.
- **Fix broken sentence in plan Step 1** ("Add `Skill` and `Read` to nothing"). Role: Lead Developer. Cosmetic but confusing.

---

### 6. UX Recommendations

1. Add a README section explaining the background mode user experience: what the ack line looks like, where the output file lands, what to do if no file appears after a few minutes.
2. Clarify in the command body whether the Claude Code harness delivers a completion notification automatically, and if so what it looks like.
3. Consider a lightweight failure artifact (e.g., `<stem>-revised-error.md`) so users have a findable signal even when the run fails.

---

### 7. Accessibility Requirements

1. Document in the README that the output is plain Markdown, accessible to any reader or assistive technology.
2. Flag the harness notification delivery mechanism as an open accessibility question — not blocking for the plugin, but worth tracking as a harness issue.

---

### 8. Frontend Implementation Considerations

1. In plan Step 8 (README update), specify exact target section headings so the writer has unambiguous insertion anchors. Example: "add 'Background mode' as an `###` subsection under `## Features`, immediately before `## Usage`."

---

### 9. Technical Feasibility Concerns

1. The unresolved question about `Skill`-tool availability in custom `background: true` subagents is the primary technical feasibility risk. Investigate before writing the agent file.
2. Add a Step 3 equivalent (version check + flag check) inside the agent body to prevent opaque failures.
3. Add explicit error handling for the `Write` call in Step 7 background path.
4. Confirm whether the agent body inherits the parent session's environment variables, particularly `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`.

---

### 10. Open Questions Before Development

**PM:**
- What is the user's signal that a background review completed successfully?
- What is the expected behavior if the user closes their session mid-review?

**Lead Developer:**
- Can a custom `background: true` subagent with `tools: Skill, Read` invoke the `Skill` tool to call another skill? *Confirmed on first run: it cannot — the Skill tool delivers instruction text only; Write is not available to the agent.* (Blocking — must resolve before agent implementation.)
- Does the agent body inherit env vars from the parent session, including `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`?

**UX Designer:**
- Does Claude Code automatically deliver a background-task completion notification? Is the behavior consistent when the parent session is closed?

**Accessibility Expert:**
- How does Claude Code deliver background-task completion notifications — is the delivery mechanism accessible to screen reader users?

---

### 11. Recommended Changes to the Plan

1. **Rename the plan file** from `rename-the-skill-directoryt-joyful-puffin.md` to `add-background-mode-to-product-plans.md` before committing.
2. **Add a "prerequisite" step** (before Step 5): investigate and resolve the unresolved question about `Skill`-tool availability in custom `background: true` subagents. Gate Steps 5 and 6 on the outcome.
3. **Add a Step 3a** inside the agent body spec: replicate the `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` flag check and Claude Code version check, emitting the same clear error messages as the skill's Step 3.
4. **Add Write failure handling** to plan Step 4 (which covers Step 7 of the skill): specify what the agent should do if `Write` fails (emit an error message to the session log; do not silently exit).
5. **Add acceptance criteria** to the Verification section: define what a successful background run produces beyond "a sibling file exists" (e.g., file is non-empty, contains all 14 sections, is valid Markdown).
6. **Update plan Step 8** to reference exact README section headings for insertion anchors.
7. **Fix the broken sentence** in plan Step 1: replace "Add `Skill` and `Read` to nothing — only the skill side changes its own behaviour." with a clear statement of what is not changing.
8. **Add a README note** in plan Step 8 scope: document the background mode UX (ack line, output location, failure guidance).

---

### 12. Conflicts or Tradeoffs Between Reviewer Recommendations

No conflicts identified. All five reviewers are aligned on the primary risk (unresolved `Skill`-tool question), the UX gap (silent failure), and the plan-hygiene defect (filename mismatch). The Frontend and Accessibility reviewers found no domain-specific concerns beyond minor documentation improvements.

---

### 13. Final Decision

Final decision: **Approve with revisions**

The plan is well-structured and follows established patterns. It is not implementable as written until the unresolved question about `Skill`-tool availability in custom subagents is answered — this is a hard prerequisite for Step 5. All other issues are non-blocking improvements. Once the unresolved question is resolved and the recommended plan amendments (items 1–8 above) are incorporated, the plan is ready to execute.

---

### 14. Revised Product Plan

```markdown
---
status: todo
type: feature
created: 2026-05-14
---

# Plan: Add background-mode + agent variant to `product-plans` (v2.1.0)

## Context

The `product-plans` skill (renamed in v2.0.0 — commit `05d892c`) runs a
five-reviewer Agent Team panel and produces a 14-section report plus an
optional revised plan. Today it can only be invoked synchronously — it
blocks the user's chat and asks 2–3 `AskUserQuestion` prompts that
prevent unattended execution.

The user wants to fire the panel off and keep working:
`/product-plans:product-plans-bg docs/plans/my-feature.md` should dispatch
a background agent that runs the whole panel and writes the revised plan to
a sibling file, returning immediately.

Two patterns already exist in this repo:

- `plan-interview/plan-to-html` ships `--background` / `--async` flags
  directly on the skill.
- `git-agent` ships paired `agent-*` subagents with `background: true`
  frontmatter, dispatched by thin `commands/*-bg.md` wrappers.

This plan adopts a **hybrid**: a `--background` flag on the skill (one
source of truth, no duplicated workflow body), a thin background-agent
wrapper that invokes the skill via the `Skill` tool, and a slash-command
dispatcher. Bumps the plugin to **v2.1.0** (MINOR — additive only).

**Prerequisite before implementation:** Resolve the open question about
whether a custom `background: true` subagent with `tools: Skill, Read`
can invoke the harness `Skill` tool. First run confirmed it cannot: the
Skill tool delivers instruction text only and Write is not available to
the agent. Choose one of: (a) use `subagent_type: "general-purpose"` in
the command dispatcher, or (b) duplicate the skill workflow in the agent
body (git-agent pattern). See Unresolved Questions.

## Objective

Ship three additive surfaces so `product-plans` can run unattended:

1. A `--background` flag on the skill that suppresses all
   `AskUserQuestion` calls and uses fixed defaults.
2. An `agents/agent-product-plans.md` subagent (`background: true`)
   that executes the panel workflow directly (not via Skill tool).
3. A `commands/product-plans-bg.md` slash-command dispatcher
   (`allowed-tools: Agent`) that fires the agent with
   `run_in_background: true`.

No breaking changes. Foreground behaviour is preserved exactly.

## Files to create

- `kit/plugins/product-plans/commands/product-plans-bg.md` — slash-command dispatcher
- `kit/plugins/product-plans/agents/agent-product-plans.md` — background wrapper agent

## Files to modify

- `kit/plugins/product-plans/skills/product-plans/SKILL.md` — add `--background` flag handling in Steps 0, 1, 2, 7
- `kit/plugins/product-plans/CHANGELOG.md` — prepend `2.1.0` entry
- `kit/plugins/product-plans/README.md` — document the new flag, agent, command
- `.claude-plugin/marketplace.json` — bump `product-plans` version `2.0.0` → `2.1.0`
- `CLAUDE.md` — update reference-implementations row to `Skills + Agents + Commands`

## Defaults when `--background` is set

| Step | Foreground (current) | Background (new) |
|------|----------------------|------------------|
| 1 — plan file | 5-stage fallback resolution | explicit path required; fast-fail with `Background mode requires a plan path` |
| 2 — output mode | `AskUserQuestion` | hard-coded `review + revised plan` |
| 7 — write destination | `AskUserQuestion` | hard-coded sibling file (`<stem>-revised.md`); non-destructive |
| 5 — teammate failure | respawn once, mark unavailable | unchanged |

`--background` is a string-contains check on `$ARGUMENTS`.

## Steps

1. **Resolve Skill-tool availability (prerequisite)** — confirm whether
   `general-purpose` subagent dispatch or workflow duplication is required.
   First run confirmed that a named agent with `tools: Skill, Read` cannot
   call Write via the Skill tool. — *Why:* the agent architecture depends on
   this choice. *Verify:* decision is documented and Steps 5–6 are updated
   to reflect it before proceeding.

2. **Add `--background` flag detection at the top of Step 0 in `SKILL.md`**
   — scan `$ARGUMENTS` for `--background`; set `mode = background` (else
   `mode = interactive`). — *Why:* subsequent steps branch on `mode` without
   re-parsing. *Verify:* `grep -n '\-\-background' kit/plugins/product-plans/skills/product-plans/SKILL.md`
   returns the new detection line in Step 0.

3. **Modify Step 1 (plan file resolution) in `SKILL.md`** — when
   `mode = background`, only accept an explicit path from `$ARGUMENTS`;
   emit `Background mode requires a plan path` and stop if absent. — *Why:*
   5-stage fallback can silently pick the wrong file unattended. *Verify:*
   Step 1 prose names `mode = background` branch and shows the stop message.

4. **Modify Step 2 (output mode) in `SKILL.md`** — when `mode = background`,
   set `output_mode = "review + revised plan"` without calling
   `AskUserQuestion`. — *Why:* `AskUserQuestion` blocks forever in a
   backgrounded subagent. *Verify:* `grep -n 'AskUserQuestion' kit/plugins/product-plans/skills/product-plans/SKILL.md`
   shows Step 2 reference is gated by `mode = interactive`.

5. **Modify Step 7 (revised-plan destination) in `SKILL.md`** — when
   `mode = background`, write directly to `<stem>-revised.md` sibling via
   `Write`; skip destination `AskUserQuestion` and overwrite/append
   branches. Add explicit error handling: if `Write` fails, emit an error
   message to the session log and stop. — *Why:* no human to answer prompts;
   sibling is non-destructive. *Verify:* Step 7 prose explicitly covers
   background branch and Write-failure path.

6. **Create `kit/plugins/product-plans/agents/agent-product-plans.md`** —
   per the resolution from Step 1: either use `subagent_type: "general-purpose"`
   in the command or duplicate the skill workflow body in the agent. Include
   an environment check section (flag + version). — *Why:* gives the command
   a dispatch target that can actually call Write. *Verify:* agent file
   exists and body contains environment check; Write is accessible.

7. **Create `kit/plugins/product-plans/commands/product-plans-bg.md`** —
   frontmatter: `allowed-tools: Agent`. Body: Agent invocation with
   `run_in_background: true` and ack line format. — *Why:* gives users a
   one-liner entry point. *Verify:* `ls kit/plugins/product-plans/commands/product-plans-bg.md`
   succeeds; body explicitly sets `run_in_background: true`.

8. **Update `kit/plugins/product-plans/CHANGELOG.md`** — prepend
   `## 2.1.0 — 2026-05-14` entry listing flag, agent, command, and
   background-defaults table. — *Why:* CHANGELOG is the user-facing record
   of what shipped. *Verify:* `head -20 kit/plugins/product-plans/CHANGELOG.md`
   shows `2.1.0` at the top.

9. **Update `kit/plugins/product-plans/README.md`** — add "Background mode"
   `###` subsection under `## Features` (before `## Usage`) covering the
   flag, slash command, output location, and failure guidance ("if no
   sibling file appears after a few minutes, retry interactively"). Add
   usage example under `## Usage`. Add `Command: product-plans-bg` and
   `Agent: agent-product-plans` under `## Components`. Add a note that
   output is plain Markdown, accessible to any reader. — *Why:* README is
   the primary install/usage doc; users need failure guidance for background
   runs. *Verify:* `grep -nE 'background|product-plans-bg|agent-product-plans' kit/plugins/product-plans/README.md`
   returns matches in three sections; failure guidance note is present.

10. **Bump `.claude-plugin/marketplace.json`** — change `product-plans`
    version `2.0.0` → `2.1.0`. — *Why:* MINOR bump per marketplace rules.
    *Verify:* `jq -r '.plugins[] | select(.name=="product-plans") | .version' .claude-plugin/marketplace.json`
    prints `2.1.0`.

11. **Update `CLAUDE.md` reference-implementations row** — change type
    from `Skills + Agents` to `Skills + Agents + Commands`; add note about
    background-mode panel via `/product-plans:product-plans-bg`. — *Why:*
    `CLAUDE.md` is loaded in every session; the table is how future-you
    discovers plugin contents. *Verify:* `grep -n 'product-plans' CLAUDE.md`
    shows updated row.

## Verification

1. `claude --plugin-dir ./kit/plugins/product-plans` — confirm no manifest
   or skill-name errors on load.
2. **Foreground regression** — run the skill without `--background` on a
   small plan; confirm both `AskUserQuestion` prompts still fire (Steps 2
   and 7) and behaviour matches v2.0.0.
3. **Background flag** — call the skill with `--background` and a plan path;
   confirm no `AskUserQuestion` fires, panel runs, `<stem>-revised.md`
   appears next to the source, file is non-empty and contains all 14
   sections.
4. **Slash-command** — run `/product-plans:product-plans-bg docs/plans/<plan>.md`;
   confirm ack returns immediately; confirm sibling file appears when
   complete.
5. **No-path error** — run the command with no argument; confirm the agent
   returns `Background mode requires a plan path` and exits without
   spawning the panel.
6. **Flag-off error** — run with `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`
   unset; confirm the agent emits the clear error message (not an opaque
   failure).
7. **Write-failure handling** — simulate a Write failure in Step 7; confirm
   an error message is emitted and the source file is not modified.
8. **Cleanup** — confirm Step 8's `Clean up the team.` directive fires
   inside the backgrounded run; no orphaned teammates in `claude /agents`.
9. **Marketplace** — `jq -e '.plugins[] | select(.name=="product-plans" and .version=="2.1.0")' .claude-plugin/marketplace.json`
   exits `0`.

## Next steps *(optional)*

- Add `--mode` and `--write` explicit flags:
  ```text
  Extend the product-plans skill --background mode with optional
  --mode=review|revised and --write=sibling|overwrite|append CLI flags
  so background users can override the hard-coded defaults in the v2.1.0
  CHANGELOG. Mirror the flag-parsing pattern in
  kit/plugins/plan-interview/skills/plan-to-html/SKILL.md Step 1.
  ```

- Apply the same hybrid pattern to `plan-interview`:
  ```text
  Audit kit/plugins/plan-interview/skills/plan-interview/SKILL.md for
  AskUserQuestion blockers that prevent unattended runs. If any exist,
  propose a --background flag + agents/agent-plan-interview.md +
  commands/plan-interview-bg.md mirroring the product-plans v2.1.0
  pattern. Out of scope: actually implementing it — just the plan.
  ```

## Unresolved questions

- Skill-tool availability inside a backgrounded subagent:
  ```text
  First run confirmed: a named background agent with `tools: Skill, Read`
  cannot invoke Write via the Skill tool — the Skill tool delivers
  instruction text only. Choose one of:
  (a) Use `subagent_type: "general-purpose"` in the command dispatcher
      (mirrors plan-interview/plan-to-html --async pattern).
  (b) Duplicate the skill workflow body into the agent (git-agent pattern).
  Recommend an approach with reasoning and update the agent design in
  the plan before proceeding to Step 6.
  ```

- Background-task completion notification accessibility:
  ```text
  Investigate how Claude Code delivers background-task completion
  notifications to the parent session. Determine whether the delivery
  mechanism is accessible to screen reader users and whether it functions
  consistently when the parent session is closed before the background
  task completes. Report findings and recommend any plugin-level
  mitigations if the harness notification is inaccessible.
  ```
```

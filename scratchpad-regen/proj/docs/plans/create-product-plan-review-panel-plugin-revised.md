---
status: todo
type: feature
created: 2026-05-15
---

# Plan: Create the `product-plan-review-panel` plugin

## Context

The user wants a reusable Claude Code capability that reviews product plans,
PRDs, UX flows, technical plans, and implementation plans using a simulated
cross-functional review team — one lead coordinator plus five specialist
reviewers (Product Manager, Lead Developer, UX Designer, Lead Frontend
Engineer, Accessibility Expert).

Today the marketplace has `plan-interview` (structured Q&A with the user) and
`deep-grill` (branch-walking critique). Neither simulates a multi-persona
review panel. The new capability fills that gap and produces a consolidated
review plus, by default, a revised plan.

User decisions captured before planning and confirmed in the Round 1 / Round
3 interview (see Interview Summary at end of file):

- **Home**: its own standalone plugin at `kit/plugins/product-plan-review-panel/`.
- **Execution model**: real Claude Code Agent Teams — one lead session coordinates five teammates spawned from reusable subagent definitions. Hard stop with enablement steps if the feature flag isn't set; no in-prompt fallback in v1.0.0.
- **Subagent scope**: teammate-only — bodies are written to be appended to a teammate system prompt; standalone invocation is not supported in v1.0.0.
- **Default output behavior**: produce a revised plan unless the user opts out via `AskUserQuestion`. At write time, the skill asks where to put it (sibling vs overwrite vs in-place append) with no fixed default.
- **Marketplace category**: `productivity`. Accepted tradeoff: no other plugin currently uses this category, so the entry will sit alone in category-filtered discovery.

Post-ship review (2026-05-15) identified the following required fixes for v1.1.0:
- SKILL.md description missing `harden` and `prepare` trigger verbs.
- `realpath` not portable on stock macOS — must use Python-based alternative.
- Progress feedback absent during parallel reviewer execution.
- Pre-spawn confirmation gate absent before expensive five-agent operation.
- `session notes` placeholder not carried from Interview Summary into plan body spec.
- Accessibility Expert subagent domain and WCAG target unspecified.
- Section 7 and section 8 output template sub-structures unspecified.

## Objective

Ship a new plugin `product-plan-review-panel` containing one auto-activating
skill that orchestrates an Agent Team of five specialist subagents to review a
product plan, synthesize their findings into a fixed 14-section output, and
(by default) emit a revised plan to a user-chosen destination. The plugin also
ships the five reusable subagent definitions, scoped for teammate use only.

## Files to create

### Plugin scaffolding

- `kit/plugins/product-plan-review-panel/.claude-plugin/plugin.json` — manifest with `name`, `description`, `author`, `license`, `keywords`, `homepage`, `repository`. **No `version` field** (lives in `marketplace.json`). `homepage` pinned to `https://github.com/shawn-sandy/agentics/tree/main/kit/plugins/product-plan-review-panel`.
- `kit/plugins/product-plan-review-panel/README.md` — overview, components, installation, usage, structure. Must not advertise standalone subagent invocation.
- `kit/plugins/product-plan-review-panel/CHANGELOG.md` — `1.0.0` initial entry listing the five subagent type names.

### Skill

- `kit/plugins/product-plan-review-panel/skills/product-plan-review-panel/SKILL.md`
- `kit/plugins/product-plan-review-panel/skills/product-plan-review-panel/references/role-prompts.md`
- `kit/plugins/product-plan-review-panel/skills/product-plan-review-panel/references/output-template.md`

### Subagent definitions (teammate-only)

- `kit/plugins/product-plan-review-panel/agents/product-reviewer-pm.md`
- `kit/plugins/product-plan-review-panel/agents/product-reviewer-lead-developer.md`
- `kit/plugins/product-plan-review-panel/agents/product-reviewer-ux-designer.md`
- `kit/plugins/product-plan-review-panel/agents/product-reviewer-frontend-engineer.md`
- `kit/plugins/product-plan-review-panel/agents/product-reviewer-accessibility-expert.md`

## Files to modify

- `.claude-plugin/marketplace.json` — bump top-level `version` from `3.3.0` to `3.4.0`. Append entry with `version: "1.0.0"`, `category: "productivity"`, tags including `requires-agent-teams` for user self-filtering.

## Skill design

### Frontmatter

```yaml
---
name: product-plan-review-panel
description: "Use when the user asks to review, critique, validate, stress-test, harden, or prepare a product plan, PRD, feature proposal, UX flow, technical plan, or implementation plan for development — runs a simulated cross-functional review panel (PM, Lead Developer, UX, Frontend, Accessibility) coordinated by a lead and produces a consolidated review plus a revised plan."
allowed-tools: Read, Glob, Bash, AskUserQuestion, TodoWrite, ToolSearch, ExitPlanMode, Edit, Write
---
```

Note: `harden` and `prepare` are required trigger verbs; `ToolSearch` and `ExitPlanMode` must both appear in `allowed-tools` for the deferred-tool bootstrap.

### SKILL.md steps (revised order and additions)

1. **Step 0 — Progress todos and exit plan mode**: `ExitPlanMode` is a deferred tool — use `ToolSearch` with `select:ExitPlanMode` first, then call `ExitPlanMode`. TodoWrite one todo per step.
2. **Step 1 — Resolve the plan file**: reuse plan-interview priority order; announce path; confirm with user ("Spawn five reviewers for `<path>`? [Yes / Choose a different file]") before proceeding.
3. **Step 2 — Verify Agent Team availability**: Run `claude --version`, parse with `^(\d+)\.(\d+)\.(\d+)` (ignore pre-release suffixes), confirm ≥ 2.1.32. Check `$CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`. Hard stop with friendly, actionable message if either fails.
4. **Step 3 — Choose output mode**: AskUserQuestion — "Review only" vs "Review + revised plan" (revised plan preselected).
5. **Step 4 — Spawn the team**: Resolve absolute path portably: `python3 -c "import os,sys; print(os.path.realpath(sys.argv[1]))" "<path-from-step-1>"`. Read `references/role-prompts.md`. Substitute `<ABSOLUTE_PATH>`. Spawn all five teammates in parallel. Immediately after spawn, emit: "Review in progress — waiting for findings from: Product Manager, Lead Developer, UX Designer, Lead Frontend Engineer, Accessibility Expert."
6. **Step 5 — Wait and collect**: Wait for all five teammates. Update status as each reports in ("✓ [Role] findings received ([N]/5)"). If a teammate stops on error or goes idle, respawn once. If it errors again, mark `Reviewer unavailable — not assessed` and surface in Executive Summary, role section, and Highest-Risk Issues. If no response within 10 minutes, apply the two-strike respawn rule then mark unavailable.
7. **Step 6 — Synthesize**: Compare findings, amplify confirmed concerns (multiple reviewers), name conflicts and recommend resolution. Reproduce verbatim 14-section template from `references/output-template.md`. Section 14 IS the canonical revised plan; do not re-generate at write time.
8. **Step 7 — Persist the revised plan**: Skip if review-only. AskUserQuestion for destination (sibling / overwrite with git-safety / append). Before writing, re-read section 14 from the synthesized output to guard against context-window truncation. Write verbatim using Write (sibling, overwrite) or Edit (append).
9. **Step 8 — Clean up the team**: Lead issues "Clean up the team."

### `references/role-prompts.md` additions

- Add `Session notes:` placeholder block at the top of the file with example usage.
- Each role prompt must include the 9-item output schema (Works well / Unclear / Critical / Minor / Missing / Risks / Improvements / Questions / Approval status) explicitly.
- Accessibility Expert prompt must specify WCAG 2.2 AA as the conformance target and enumerate domains: semantic HTML, keyboard navigation, focus management, ARIA/screen reader, color contrast (1.4.3/1.4.11), motion sensitivity (2.3.3), form accessibility, error messaging, inclusive design. Add scope note: "Your review is of written plan content — findings are forward-looking for pre-implementation plans."
- Frontend Engineer prompt must enumerate domains: component architecture, state management, performance, responsive/adaptive design, design-system token alignment, browser API usage, testing surface.

### `references/output-template.md` additions

- Section 7 minimum sub-structure: (a) WCAG conformance target assumed, (b) blocking failures, (c) recommended improvements, (d) open questions.
- Section 8 minimum sub-topic list (commented): component decomposition, state management, performance, responsiveness, design-system alignment, browser behavior, testing.
- All role section headers in section 2 must use plain-English labels (Product Manager, Lead Developer, UX Designer, Lead Frontend Engineer, Accessibility Expert) — not agent-type slugs.

### Subagent body additions

`product-reviewer-accessibility-expert.md` body must enumerate the domain list above and specify WCAG 2.2 AA as the normative target. All five subagent bodies must include a one-sentence approval-criteria rubric per status level (approve / approve with changes / reject).

## Steps

1. **Fix SKILL.md description trigger verbs** — add `harden` and `prepare`. *Why:* missing verbs prevent auto-activation on valid user prompts as specified in the plan frontmatter spec. *Verify:* description contains all six trigger verbs: review, critique, validate, stress-test, harden, prepare.

2. **Replace `realpath` with portable alternative in Step 4** — use `python3 -c "import os,sys; print(os.path.realpath(sys.argv[1]))" "<path>"`. *Why:* `realpath` is not available on stock macOS without GNU coreutils. *Verify:* step runs successfully on macOS without Homebrew installed.

3. **Swap Steps 2 and 3 in SKILL.md** (output-mode question after environment check, not before). *Why:* prevents prompting the user for a UX preference only to immediately error out on the environment check. *Verify:* SKILL.md steps read: Step 0 (exit plan mode), Step 1 (resolve file + confirm), Step 2 (verify agent teams), Step 3 (choose output mode), Step 4 (spawn).

4. **Add pre-spawn confirmation gate to Step 1** — after announcing the resolved path, ask "Spawn five reviewers for `<path>`?" before spawn. *Why:* auto-activation can resolve the wrong file; a failed run wastes 2–5 minutes of compute. *Verify:* SKILL.md Step 1 includes a path confirmation before Step 4 executes.

5. **Add progress-feedback requirement to Steps 4 and 5** — after spawn, emit "Review in progress — waiting for findings from: [five role names]"; update as each reporter reports in. *Why:* parallel execution with no visible progress erodes user trust. *Verify:* SKILL.md Steps 4 and 5 specify the status message and per-reviewer update pattern.

6. **Add stall/timeout policy to Step 5** — if no response from a reviewer within 10 minutes, apply two-strike respawn rule then mark unavailable. *Why:* current spec handles reviewer errors but not indefinitely stalled reviewers. *Verify:* Step 5 names the timeout threshold and the action taken when it elapses.

7. **Carry `session notes` placeholder into `role-prompts.md`** — add placeholder block at top of file with example. *Why:* noted in Interview Summary as needed; never carried into the plan body or verified in any step. *Verify:* `role-prompts.md` contains a documented `Session notes:` placeholder; Step 4 verify clause checks for it.

8. **Add WCAG 2.2 AA and domain enumeration to accessibility reviewer** — update `product-reviewer-accessibility-expert.md` body and the accessibility section of `role-prompts.md`. *Why:* no WCAG version anchor produces standard-drift between runs; no domain list produces inconsistent coverage. *Verify:* subagent body names WCAG 2.2 AA and lists all nine domains; `role-prompts.md` accessibility spawn prompt includes the conformance target and scope note.

9. **Add section 7 and section 8 sub-structures to `output-template.md`** — section 7: four-part structure (conformance target / blocking failures / improvements / open questions). Section 8: commented sub-topic list. *Why:* without sub-structure, frontend and accessibility findings are non-auditable and vary maximally across runs. *Verify:* `output-template.md` shows sub-headings or commented lists under sections 7 and 8.

10. **Add frontend domain enumeration to `role-prompts.md`** — frontend spawn prompt lists: component architecture, state management, performance, responsive design, design-system alignment, browser API usage, testing surface. *Why:* "Frontend implementation considerations" without enumeration gives the widest output variance of any reviewer role. *Verify:* frontend spawn prompt in `role-prompts.md` names all seven domains.

11. **Add context-window safety note to Step 7** — "Before writing, re-read section 14 from the synthesized output to guard against context-window truncation." *Why:* for long review outputs, section 14 may be partially evicted before the write step; silent truncation produces an incomplete revised plan. *Verify:* SKILL.md Step 7 contains the re-read instruction.

12. **Add `requires-agent-teams` tag to marketplace entry** — append to the plugin's `tags` array in `.claude-plugin/marketplace.json`. *Why:* users installing from the marketplace need a self-filter signal before encountering the hard stop. *Verify:* `jq '.plugins[] | select(.name=="product-plan-review-panel") | .tags' .claude-plugin/marketplace.json` includes `"requires-agent-teams"`.

13. **Create three skill evaluations** — one each for Haiku, Sonnet, and Opus against a real plan file. *Why:* `skill-authoring.md` checklist requirement; evaluations are the only way to catch prompt-following variance across model tiers. *Verify:* evaluation files exist in the plugin directory; results for all three models are documented.

14. **Bump plugin version to `1.1.0`** in `marketplace.json` and add CHANGELOG entry listing all changes from steps 1–13. *Why:* new trigger verbs and behavior changes (confirmation gate, progress feedback, timeout policy) constitute a MINOR version bump. *Verify:* `jq '.plugins[] | select(.name=="product-plan-review-panel") | .version' .claude-plugin/marketplace.json` returns `"1.1.0"`; CHANGELOG has a `1.1.0` entry.

## Verification

With `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` set, a fresh Claude Code session loading the updated plugin should auto-trigger `product-plan-review-panel` on prompts including "review," "critique," "validate," "stress-test," "harden," and "prepare" against a `.md` plan file. The skill should:

1. Check the Agent Teams environment before asking any UX questions.
2. Announce the resolved file path and ask for confirmation before spawning.
3. Emit a "Review in progress" status message immediately after spawn.
4. Update status as each of the five reviewers reports in.
5. Produce a 14-section report where section 7 has the four-part sub-structure and section 8 has the domain sub-topics.
6. Prompt for revised-plan destination (if not review-only) and write section 14 verbatim after re-reading it.
7. Run successfully on stock macOS without Homebrew.

Verify `jq '.plugins[] | select(.name=="product-plan-review-panel") | {version, tags}' .claude-plugin/marketplace.json` returns `version: "1.1.0"` and tags including `"requires-agent-teams"`.

## Next Steps

- **Paired slash command**:
  ```text
  Add commands/product-plan-review-panel.md to the product-plan-review-panel
  plugin that explicitly invokes the skill with a plan-file path argument.
  Match the description and allowed-tools conventions used by existing
  commands in the marketplace. Bump the plugin to a new MINOR version.
  ```

- **Fallback mode for users without Agent Teams enabled**:
  ```text
  Extend product-plan-review-panel/SKILL.md with an opt-in single-session
  fallback: when CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS is not set, offer to
  run all five reviews sequentially in the current Claude session using the
  same role prompts. Keep the agent-team path as the default and clearly
  label the fallback as lower-fidelity (risk of role-bleed). Bump the plugin
  to a new MINOR version.
  ```

- **Category revisit**:
  ```text
  After product-plan-review-panel has shipped under category 'productivity'
  for some time, check whether any other plugins have adopted the same
  category. If the category remains a one-off, recommend whether to (a)
  migrate the plugin to 'development' to sit with other review tools, or
  (b) seed two or three more productivity-style plugins. Provide a decision
  with reasoning.
  ```

- **Revisit ask-at-write-time friction**:
  ```text
  After running product-plan-review-panel on at least five real plans,
  evaluate whether the three-way AskUserQuestion at Step 7 (sibling vs
  overwrite vs append) creates more friction than value. If so, propose a
  default destination (most likely sibling file) with the prompt becoming
  a confirm-only "Write revised plan to <path>?" yes/no.
  ```

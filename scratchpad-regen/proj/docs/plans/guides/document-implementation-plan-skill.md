# The `implementation-plan` skill
A developer guide to how plan-agent's `implementation-plan` skill turns an objective, an issue, or a markdown draft into a single self-contained HTML plan — and then optionally drives the implementation to "completed."

> **Origin.** Written from a source read of `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` at plan-agent `2.8.3` (the version in `.claude-plugin/marketplace.json`), cross-checked against the filename-validation hook and the git history of the skill. Every path, frontmatter field, flag, and workflow step below was confirmed against the working tree, not recalled. This is a committed `docs/` guide, so per-user paths (anything under `~/.claude/` or `${CLAUDE_PLUGIN_ROOT}`) are labeled where they appear.

---

## Table of contents

1. [The skill in one sentence](#1-the-skill-in-one-sentence)
2. [What it is](#2-what-it-is)
3. [Why it exists](#3-why-it-exists)
4. [How it works structurally](#4-how-it-works-structurally)
5. [How it activates](#5-how-it-activates)
6. [Decision criteria — which mode, which flags, which tier](#6-decision-criteria--which-mode-which-flags-which-tier)
7. [Operational script — what actually happens on a run](#7-operational-script--what-actually-happens-on-a-run)
8. [Boundaries — what it does NOT do](#8-boundaries--what-it-does-not-do)
9. [Interactions with related systems](#9-interactions-with-related-systems)
10. [Project-specific context](#10-project-specific-context)
11. [Maintenance and audit](#11-maintenance-and-audit)
12. [Verification protocol](#12-verification-protocol)

---

## 1. The skill in one sentence

**`implementation-plan` produces a plan document — a single self-contained `.html` file with steps, tests, acceptance criteria, and embedded machine-readable metadata — and never implements anything until the user explicitly says so.**

Everything below unpacks that sentence: what the file contains, the modes that feed it, the workflow that builds it, and the gates that govern the one path where it *is* allowed to write source code.

---

## 2. What it is

A Claude Code **skill** living at `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md`, shipped by the `plan-agent` plugin (version `2.8.3` in `.claude-plugin/marketplace.json`, marketplace `agentics-kit`).

Its frontmatter, quoted verbatim:

```yaml
---
name: implementation-plan
model: opus
description: "Generates HTML implementation-plan documents. Produces a self-contained .html plan file with steps, acceptance criteria, and metadata. Use when the user asks to create or generate an HTML plan file."
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion, Skill, ToolSearch, ExitPlanMode, WebFetch, WebSearch, SendUserFile, mcp__claude-in-chrome__tabs_context_mcp, mcp__claude-in-chrome__tabs_create_mcp, mcp__claude-in-chrome__navigate, mcp__claude-in-chrome__computer
argument-hint: "<issue-url|#n> | <plan.md> | <objective> [--quick] [--no-clarify] [--no-align] [--no-interview] [--workflow] [--type feature|fix|refactor|docs|chore] [--template default] [--dir <path>] [--priority low|medium|high|critical]"
---
```

Two facts in that frontmatter carry weight:

- **`model: opus`** — the skill pins Opus, because plan synthesis (interview, tier classification, file-tree extraction) is reasoning-heavy.
- **`ExitPlanMode` and `ToolSearch` both appear in `allowed-tools`.** `ExitPlanMode` is a *deferred* tool — its schema is not loaded at session start — so the skill must `ToolSearch` for it before calling it. Listing both prevents a mid-run permission prompt.

The deliverable is **one HTML file**, not markdown. From the HTML Output Requirements: *"Every plan is a single self-contained `.html` file — no external CSS, no CDN links, no external scripts. All styles and behaviour must be inlined."* The starter is `reference/SKELETON.html` in the skill directory (confirmed present alongside `SKELETON.md`).

---

## 3. Why it exists

Plans drift if they live in three different shapes. This skill exists to make every plan **one machine-readable artifact** that downstream tooling — the plans gallery, the filename hook, the implement/goal/workflow prompts — can all read the same way.

The git history of `SKILL.md` reads as a feature ledger toward that goal:

| Commit | What it added |
| --- | --- |
| `34a2782` | Tests section in the plan template |
| `727cf62` | End-to-end self-verification gate |
| `881de3d` (2.2.0) | Markdown→HTML conversion mode |
| `690f60c` (2.4.0) | Save-as-PDF button |
| `950b214` (2.6.0) | Outcome-driven **goal prompt** |
| `3a829ac` (2.8.0) | Replaced a stored digest with a compute-on-read extractor |
| `3562d47` | Standardized `plansDirectory` resolution to Claude settings precedence |

The throughline: each change pushed more structure *into the single HTML file* (tests, verification, prompts, PDF) and made the *resolution rules* (where it saves, what it's named) deterministic so the writer and the gallery never disagree.

Two design constraints recur in the source and explain most of its rules:

- **Plan mode forces markdown.** Step 0 notes that skipping the plan-mode exit *"causes the harness to force a `.md` output path, defeating the skill's core guarantee."* The whole skill is built to emit HTML, so it self-bootstraps out of plan mode first.
- **A plan is not an implementation.** The Scope Constraint is absolute by default; the skill writes *how* to fix X, it does not fix X — until Step 8 with explicit user consent.

---

## 4. How it works structurally

The workflow is a fixed sequence. Steps with a number run in order; lettered steps (`0.5`, `0b`) are conditional inserts.

```text
0    Self-bootstrap        exit plan mode (if in it) via ToolSearch→ExitPlanMode
0.5  Issue ingestion       only if $ISSUE_REF set — gh/glab issue view → planning inputs
0b   Explore               read codebase for context (skipped on --quick)
1    Clarify               AskUserQuestion if ambiguous (skipped on --quick/--no-clarify)
2    Create                resolve plans dir → filename → compute implement/goal/workflow prompts
3    Frontmatter           write <meta> tags into HTML <head>
4    Rename                enforce verb-target kebab-case (hook-backed)
5    Align                 AskUserQuestion: do steps match objective? (skipped on --quick/--no-align)
5b   Interview             1–3 rounds of stress-test questions (skipped on --quick/--no-interview)
5c   Tests                 ALWAYS runs — tier classify + objective test + per-tier tests
6    Status                set todo/in-progress/completed in 3 places, kept in sync
7    Open                  browser-render + screenshot, or SendUserFile fallback (mandatory)
8    Implement/Edit/Exit   AskUserQuestion menu — the only gateway to writing source
```

### The three machine-readable prompts

Step 2 computes up to three paste-ready prompts and embeds each as a `<meta>` tag and a copyable row:

| Prompt | When generated | Format (abbreviated) |
| --- | --- | --- |
| **implement** | always | `Read and implement all steps in the plan at <path> — <objective>` |
| **goal** | always | `Achieve this goal: <objective>. The plan at <path> describes one approach — use it as reference, but optimize for the outcome` |
| **workflow** | conditional | `Run a workflow to implement the plan at <path> — <objective>. Brief subagents with the plan file at <path>` |

The **goal prompt is never omitted** — *"every plan has an objective worth pursuing."* The **workflow prompt is conditional**: generated when `--workflow` is set, or when the plan meets any complexity trigger (5+ files across 3+ dirs, repetitive per-file changes, parallelizable steps, or cross-checking between steps). When no workflow prompt is generated, the entire `.plan-workflow` `<details>` element is removed from the HTML.

### The status triple

Step 6 keeps **three representations of status in sync** — change one, change all three:

```text
<html data-status="…">              ← drives CSS badge colour
<meta name="plan-status" content="…">   ← machine-readable + hook's completion check
visible badge text                  ← what the human reads
```

`todo` = grey, `in-progress` = amber, `completed` = green.

---

## 5. How it activates

The skill has **two activation paths**, and the input string is classified into **one of three content modes** before the objective is ever read.

### Two activation paths

- **Command invocation** — `/plan-agent:implementation-plan <objective> [flags]`. `$ARGUMENTS` carries everything; all flags are available.
- **Model invocation (ambient)** — Claude auto-activates when the user asks to "create a plan document / generate an HTML plan / write a plan file." `$ARGUMENTS` is empty; the objective is derived from the triggering message or recent context. Flags cannot be passed here, so ambient runs the **full** workflow (Clarify + Align + Interview) by default.

### Three input modes (classified in this order)

```text
$ARGUMENTS / derived text
   │
   ├─ token matches issue ref?  (GitHub/GitLab URL, or bare #n / integer)
   │     → $ISSUE_REF set, Step 0.5 fetches the issue
   │
   ├─ first non-flag token ends in .html?
   │     → $PLAN_FILE set (revision of an existing plan; basename-only, path-safe)
   │
   ├─ first non-flag token ends in .md?
   │     → $MD_SOURCE set → CONVERSION MODE
   │
   └─ otherwise → the text is the objective
```

**Conversion mode** is special: a committed markdown plan is pre-validated content, so it implies `--no-clarify --no-align --no-interview`. It maps sections 1:1 (Context→context, Changes/Steps→step cards, Files Modified→file-tree, etc.), carries frontmatter over, and writes the source basename with `.html` swapped in.

### What can prevent or redirect activation

- **Plan mode** does not prevent activation, but Step 0 must exit it first or the harness forces markdown output.
- **An empty objective** after all parsing and context inference triggers a single `AskUserQuestion("What is the objective for this plan?")`; the run stops if still empty and no issue ref was found.
- **A failed issue fetch** (unauthenticated, network, not-found) does not abort — it prints a one-line error and falls back to treating the remaining text as a plain objective.

---

## 6. Decision criteria — which mode, which flags, which tier

> *Is this input an objective, an issue, a plan to revise, or a plan to convert?*

The classifier in §5 answers that. Three further decision points govem the run:

### Which flags apply

- `--quick` is shorthand for `--no-clarify --no-align --no-interview` — it skips Step 1, Step 5, and Step 5b (and Step 0b Explore). Use when the objective is well-specified and time matters.
- `--no-clarify` / `--no-align` / `--no-interview` skip exactly one phase each. None is ever inferred automatically — they are opt-in only.
- `--type` is **inferred from the leading verb** when absent: `create/add/build/implement/introduce → feature`; `fix/repair/patch/resolve → fix`; `refactor/rename/extract/move/restructure/convert → refactor`; `document/docs → docs`; anything else → `chore`.
- `--workflow` forces a workflow prompt regardless of complexity.

### Which test tier (Step 5c, always runs)

> *Do any steps create, modify, or delete application source files?*

- **Tier 1 — code-touching.** Any step that touches `.ts`, `.tsx`, `.js`, `.py`, `.css`, `.html`, `.sql`, `.config.*`, and similar source/config extensions (excluding plan files and docs). Gets the mandatory objective-verification test **plus** applicable unit/integration/E2E cards.
- **Tier 2 — non-code.** Steps that only move/rename/delete non-source files, write docs, or change non-runtime metadata. Gets **only** the objective-verification test; the `.test-list` container is removed entirely — no empty stubs.

The `type:` frontmatter field is irrelevant to tier: *"a `type: chore` plan that changes import paths is Tier 1, while a `type: chore` plan that moves documentation directories is Tier 2."*

### Which interview depth (Step 5b)

- **Short/focused** (1–2 files): Round 1 only.
- **Medium** (UI + logic, or 2 domains): Rounds 1 + 2.
- **Complex** (architecture, 3+ domains): Rounds 1 + 2 + 3.
- **UI override:** any React/Vue/Svelte/`.tsx`/`.css` signal or UX term forces Round 2 (UI/UX + accessibility) even on a short plan.

---

## 7. Operational script — what actually happens on a run

The interesting part is **Step 8**, the only place the Scope Constraint is lifted. Here is the literal flow when the user chooses `Implement now`.

**Do:** run three mandatory gates, in order, before marking a plan `completed`.

```text
1. Acceptance-criteria gate
     read each #criteria-list checkbox → verify → check off only if met
     can't verify? → AskUserQuestion "Mark them as done anyway?"
2. End-to-end verification gate   (bounded loop, max 3 attempts)
     run the objective-verification test (its authored Run command)
     run other .test-card tests via the project runner
     on failure → diagnose → fix source → re-run from step 2
     still failing after 3? → AskUserQuestion:
        Keep trying / Mark in-progress and stop / Mark completed anyway
3. Completion-checklist gate
     confirm: all step cards .completed, all criteria checked, status=completed
     check off the three disabled boxes; add 'all-complete' class
```

**Do NOT:**

- Do NOT set status to `completed` before every acceptance criterion is checked. If the user left any unchecked, set `in-progress` instead and populate the Completion Report with a `<dt>`/`<dd>` naming the exact unfinished step or criterion and why.
- Do NOT loop the verification gate forever — three attempts, then ask the user.
- Do NOT skip Step 7 (Open). It is marked mandatory; even with no browser tools, the fallback `SendUserFile` path must run.
- Do NOT implement on `Exit` / `Run as workflow` / `Review the plan` — those paths leave `status` at `todo` (or set `in-progress` for workflow handoff) and never write source directly.

When the user picks `Review the plan`, the skill offers foreground (`Skill(plan-agent:review-plan)`) or background (`Skill(plan-agent:review-plan-bg)`) and loops back to the menu afterward.

---

## 8. Boundaries — what it does NOT do

The Scope Constraint section is explicit. By default the skill:

1. **Does not edit source files, configs, or anything outside the resolved `plansDirectory`** (or `docs/plans/` when unset).
2. **Does not apply fixes, refactors, or any change its own steps describe** — *"If the objective sounds like 'fix X' or 'implement Y', write a plan for how to fix/implement it — do not do the work."*
3. **Does not answer general planning questions** — it creates plan documents, not advice.
4. **Does not use Read/Glob/Grep/Bash to mutate** — those are for read-only exploration (the one exception is the §7 local HTTP server for browser preview).
5. **Does not write markdown for plan output** — ever. The output is always `.html`.

The single carve-out: the `Implement now` branch of Step 8 lifts constraint #1 and #2 **for that session only**, after the user explicitly chooses it.

---

## 9. Interactions with related systems

- **`validate-plan-filename.py` hook** (`${CLAUDE_PLUGIN_ROOT}/hooks/validate-plan-filename.py` — per-user path; resolves into the installed plugin cache, not this repo). A `PostToolUse` hook that fires on every Write/Edit, ignores anything outside `plansDirectory` and any plan with `status: completed`, and exits `2` with a rename message when a plan filename is not `verb-target` kebab-case. It rejects hex suffixes, trailing dates, generic names (`plan`, `untitled`, `draft`…), non-verb first tokens, and stop-word second tokens. This is what backs Step 4 — the rename rule is *enforced*, not advisory.
- **`reference/SKELETON.html`** — the starter copied for every plan. All CSS lives here and is inert when a markup block is unused, so the skill only ever keeps or deletes blocks (workflow, diagram, chart, table), never writes CSS.
- **`plans-library` / `plans-open`** — the gallery. Step 2 resolves the plans directory *"deterministically and identically to how `plans-library`/`plans-open` resolve it"* so the writer and gallery never disagree.
- **`review-plan` / `review-plan-bg`** — the seven-reviewer Agent Team invoked from the Step 8 menu.
- **`plan-interview:plan-status`** — explicitly **not** used for HTML plans: it operates on YAML-frontmatter `.md` files only. HTML status is edited in place across the status triple.

---

## 10. Project-specific context

In this repo (`shawn-sandy/agentics`), `plansDirectory` resolves through Claude settings precedence to `docs/plans`:

```text
.claude/settings.local.json   → (empty)
.claude/settings.json         → "docs/plans"      ← project wins
~/.claude/settings.json       → "./docs/plans"    (per-user fallback)
```

A more specific layer always wins; the skill does not read only the global setting. With `plansDirectory` set, this guide itself landed at `docs/plans/guides/` (rule 1 of the write-guide save order), not at the repo's separate `docs/guides/`.

Repo conventions that touch this skill:

- **Bump `version` in `.claude-plugin/marketplace.json`** when you change the skill — never add `version` to `plugin.json` for relative-path plugins.
- **Commit the plan file with the related changes** — always, even for minor plugin edits.
- The `merge-plans-index.mjs` merge driver unions plan cards in `docs/plans/index.html`, so two branches adding plans don't conflict.

---

## 11. Maintenance and audit

Update this guide when any of these change in `SKILL.md`:

- **The workflow step list** (§4 / §7) — new gates or reordered steps. The end-to-end verification gate and the three-prompt system are recent additions; expect more.
- **The flag set or smart-default verb mapping** (§6) — `--template` currently supports only `default`; `minimal`, `adr`, `spike` are documented as planned-but-unimplemented. Promote them here when they ship.
- **The tier extension list** (§6) — the source-file extension set that decides Tier 1 vs Tier 2.
- **The hook's verb/stop-word/placeholder sets** (§9) — `IMPERATIVE_VERBS`, `STOP_WORDS_2ND`, `GENERIC_NAMES` in `validate-plan-filename.py`.

Prune anything that becomes a duplicate of `SKILL.md` itself — this guide is a map, not a mirror. If a section here would just restate the source verbatim, link to the source instead.

---

## 12. Verification protocol

Concrete checks that this guide's claims still hold:

1. **Version.** `python3 -c "import json;d=json.load(open('.claude-plugin/marketplace.json'));print([p['version'] for p in d['plugins'] if p['name']=='plan-agent'])"` — guide assumes `2.8.3`.
2. **Frontmatter.** `head -7 kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` — confirm `model: opus` and that `ExitPlanMode` + `ToolSearch` are both in `allowed-tools`.
3. **Hook contract.** `grep -n "sys.exit(2)" kit/plugins/plan-agent/hooks/validate-plan-filename.py` and `grep -n "_is_completed" …` — confirm exit-2 on violation and the `status: completed` skip.
4. **Skeleton present.** `ls kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.html`.
5. **Plans dir resolution.** Confirm `.claude/settings.json` still sets `plansDirectory: docs/plans`.
6. **Smoke test — drafting.** Run `/plan-agent:implementation-plan add a dark-mode toggle --quick`. Expected: a single `.html` file under `docs/plans/`, named `add-dark-mode-toggle.html` (or similar verb-target), with `data-status="todo"`, an implement row, a goal `<details>`, and a Tests section — and **no** Clarify/Align/Interview prompts. Failure signal: a `.md` file is produced (plan-mode exit was skipped) or the filename hook fires on the name.
7. **Smoke test — conversion.** Run `/plan-agent:implementation-plan some-existing-plan.md`. Expected: an `Conversion mode: <md> → <html>` echo and a 1:1 section mapping with no new scope invented.

---

## Quick reference

```text
implementation-plan — at a glance
─────────────────────────────────────────────
DELIVERABLE   one self-contained .html plan (never .md)
PLUGIN        plan-agent 2.8.3 (agentics-kit)
MODEL         opus

INPUT MODES (classified in order)
  issue ref (#n / URL) → Step 0.5 fetch
  .html token          → revise existing plan
  .md token            → conversion mode (implies --quick-ish)
  else                 → plain objective

WORKFLOW
  0 exit plan mode → 0.5 issue → 0b explore → 1 clarify
  → 2 create+prompts → 3 frontmatter → 4 rename(hook)
  → 5 align → 5b interview → 5c tests(ALWAYS)
  → 6 status → 7 open(MANDATORY) → 8 menu

THREE PROMPTS   implement(always) goal(always) workflow(conditional)
STATUS TRIPLE   <html data-status> · <meta plan-status> · badge text
TEST TIERS      T1 code-touching (unit/integ/e2e) · T2 non-code (objective only)

STEP 8 GATES (Implement now)
  acceptance-criteria → e2e-verify (≤3 tries) → completion-checklist
  status→completed ONLY after all three pass

SCOPE         plans only; source edits ONLY via Step 8 "Implement now"
FILENAME      verb-target kebab-case, enforced by PostToolUse hook (exit 2)
```

---

## Cross-references

**In this repo:**
- `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` — the skill source.
- `kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.html` — the HTML starter.
- `kit/plugins/plan-agent/hooks/validate-plan-filename.py` — the filename-enforcement hook.
- `.claude-plugin/marketplace.json` — plugin version registry.
- `.claude/rules/marketplace.md` — versioning and registration conventions.

**Per-user (not in this repo — a teammate cloning the repo will not have these):**
- `${CLAUDE_PLUGIN_ROOT}/hooks/validate-plan-filename.py` — the installed-plugin path the hook actually runs from.
- `~/.claude/settings.json` — global `plansDirectory` fallback (`./docs/plans`).

**External canonical docs:**
- Plugin reference: <https://code.claude.com/docs/en/plugins-reference>
- Plugin authoring: <https://code.claude.com/docs/en/plugins>

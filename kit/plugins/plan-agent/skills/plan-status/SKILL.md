---
name: plan-status
description: "Writes lifecycle status into a plan's frontmatter, one file or a directory. Inspects codebase and git history for accurate dates. Use when asked to check or update plan status."
allowed-tools: Read, Glob, Grep, Bash, AskUserQuestion, Edit, TodoWrite
argument-hint: "[plan-file-path | directory] [--all] [--force] - omit to auto-detect; pass a directory or --all for bulk mode"
---

## Plan Status

Determine whether a plan has been implemented by inspecting the codebase, then
write the lifecycle status and dates into the plan file's YAML frontmatter.

Follow these steps exactly.

## When not to use

Does not stress-test, validate, or critique plan content — use review-plan or the built-in interview for that.

## References

- `references/single-file-flow.md` — Steps 0–4, 6, and 7 in full: file resolution, git date commands, existing-frontmatter handling, evidence scoring, the confirmation prompt, and the frontmatter write rules
- `references/bulk-mode.md` — the whole Bulk mode (directory / `--all`) section: seven-stage flow, triage table, batch date/evidence/type rules, summary approval, hybrid write
- `references/type-classification.md` — Step 5's signal-to-type table and the keep-existing-type rule

## Instructions

**Routing:** when `$ARGUMENTS` names a directory or contains `--all`, follow
`references/bulk-mode.md` instead of the single-file steps below.

Otherwise read `references/single-file-flow.md` and follow every step it covers
exactly as written there.

- **Step 0 — Create progress todos** — `TodoWrite` one todo per step before
  anything else; mark each completed as you finish it. Listed in
  `references/single-file-flow.md`.
- **Step 1 — Resolve plan file (or route to bulk mode)** — send directory or
  `--all` invocations to `references/bulk-mode.md`; otherwise pick the file by
  the argument → open-file → `plansDirectory` → `docs/plans/` priority order in
  `references/single-file-flow.md`, then announce it.
- **Step 2 — Get file dates from git** — `git log` for created and modified
  dates, never `stat`. Exact commands and fallbacks in
  `references/single-file-flow.md`.
- **Step 3 — Read existing frontmatter** — legacy `artifact` normalizes to
  `completed`; any other existing `status` triggers a re-analyze-or-keep
  question. Type is never written here. Rules in
  `references/single-file-flow.md`.
- **Step 4 — Analyze codebase for implementation evidence** — extract inline
  backtick tokens only, `Glob`/`Grep` each, and score 0% / 1–79% / 80%+ into
  `todo` / `in-progress` / `completed`. Token rules and the no-signals prompt
  are in `references/single-file-flow.md`.
- **Step 5 — Type classification** — only when status resolves to `completed`,
  infer `feature`/`fix`/`refactor`/`docs`/`chore` from filename, H1, and the
  first 200 words. Table in `references/type-classification.md`.
- **Step 6 — Present findings and confirm** — print the summary table, list
  found and missing tokens, then ask via `AskUserQuestion`. **Do NOT write to
  the file unless the user confirms.** Format in
  `references/single-file-flow.md`.
- **Step 7 — Update plan file frontmatter** — only on confirmation; insert or
  update only `status`, `type`, `created`, `modified` and preserve every other
  field. Exact write rules in `references/single-file-flow.md`.

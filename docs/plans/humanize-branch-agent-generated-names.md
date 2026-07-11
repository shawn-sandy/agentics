---
status: completed
type: fix
created: 2026-07-11
repo-name: agentics
---

# Plan: Make branch-agent generated names more descriptive and human-readable

## Context

The `branch-agent` skill (git-agent plugin) auto-generates branch names from
working-tree changes using the format `<type>/<scope>-<description>`. The
description rule asked for "2–5 extracted keywords" under a tight 49-char
pre-suffix budget, which produced terse, abbreviated names like
`feat/src-login-form-valid` — hard to read in branch lists and PR pages.
The Case B slug path (descriptive phrase argument) also hard-truncated at 30
characters, chopping user-supplied phrases mid-thought.

## Objective

Generated and slugified branch names should read like short commit subjects a
human would write — verb-led, whole words, no abbreviations — with enough
length budget to stay readable.

## Files to modify

- `kit/plugins/git-agent/skills/branch-agent/SKILL.md` — naming rules (primary)
- `kit/plugins/git-agent/README.md` — branch-agent feature description
- `kit/plugins/git-agent/CHANGELOG.md` — v3.11.1 entry
- `.claude-plugin/marketplace.json` — git-agent version bump 3.11.0 → 3.11.1

## Steps

1. **Rewrite Step 2a description inference** — replace "extract 2–5 keywords"
   with a verb-led 3–7 word phrase rule (imperative verb + what changed),
   add explicit readability rules (whole dictionary words only, no
   abbreviations, drop trailing words to fit rather than shortening words),
   and a good/bad examples table.
2. **Raise length budgets** — pre-suffix name 49 → 60 chars; final
   date-suffixed name 60 → 72 chars (Step 2b); Case B slug 30 → 60 chars with
   word-boundary dropping instead of hard truncation.
3. **Sync docs and version** — update README branch-agent bullet, add
   CHANGELOG v3.11.1 entry, bump `marketplace.json` to 3.11.1 (PATCH: refines
   an existing rule, no component added/removed).

## Acceptance Criteria

- [x] Step 2a asks for a verb-led phrase with whole words; abbreviation is
      explicitly prohibited; examples show good vs bad names.
- [x] Budgets: ≤60 pre-suffix, ≤72 final, ≤60 Case B slug; overflow handling
      drops trailing words at word boundaries everywhere.
- [x] README, CHANGELOG, and marketplace.json (3.11.1) are in sync.

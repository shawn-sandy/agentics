# Make branch-agent generated names more descriptive and human-readable

> Generated and slugified branch names should read like short commit subjects a human would write — verb-led, whole words, no abbreviations — with enough lengt...

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [humanize-branch-agent-generated-names.md](plans/humanize-branch-agent-generated-names.md)
**Type:** fix

## What shipped

- Rewrite Step 2a description inference — replace "extract 2–5 keywords"
- Raise length budgets — pre-suffix name 49 → 60 chars; final
- Sync docs and version — update README branch-agent bullet, add

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/git-agent/skills/branch-agent/SKILL.md` | naming rules (primary) | Modified |
| `kit/plugins/git-agent/README.md` | branch-agent feature description | Modified |
| `kit/plugins/git-agent/CHANGELOG.md` | v3.11.1 entry | Modified |
| `.claude-plugin/marketplace.json` | git-agent version bump 3.11.0 → 3.11.1 | Modified |

## How it works

Generated and slugified branch names should read like short commit subjects a human would write — verb-led, whole words, no abbreviations — with enough length budget to stay readable.

The `branch-agent` skill (git-agent plugin) auto-generates branch names from working-tree changes using the format `<type>/<scope>-<description>`. The description rule asked for "2–5 extracted keywords" under a tight 49-char pre-suffix budget, which produced terse, abbreviated names like `feat/src-login-form-valid` — hard to read in branch lists and PR pages.

The implementation proceeded through the following steps: Rewrite Step 2a description inference: replace "extract 2–5 keywords"; Raise length budgets: pre-suffix name 49 → 60 chars; final; Sync docs and version: update README branch-agent bullet, add.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f6b0bdd` | 2026-08-17 | docs(plans): mark settings-sync guard next-step done in add-verification-gates (#573) |

<!-- generated:end -->

## References

- Plan: [humanize-branch-agent-generated-names.md](plans/humanize-branch-agent-generated-names.md)

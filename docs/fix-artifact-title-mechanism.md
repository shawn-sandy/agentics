# Fix the artifact title mechanism

> Make every artifact-tools skill produce a readable, meaningful title by stating the one mechanism that works (an HTML `<title>`), switching `session-artifact...

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [fix-artifact-title-mechanism.md](plans/fix-artifact-title-mechanism.md)
**Type:** fix

## What shipped

- Replace the frontmatter claim in `titles.md` — with the truth: an HTML
- Switch `session-artifact` to publish an HTML render. — Rewrite the Overview
- Correct the republish note — to require `url` on every republish, not only
- **Add `tests/plugins/test-artifact-titles.mjs` and wire it into
- Bump `artifact-tools` to 1.2.1 and add the CHANGELOG entry.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `(see plan)` | — | — |

## How it works

Make every artifact-tools skill produce a readable, meaningful title by stating the one mechanism that works (an HTML `<title>`), switching `session-artifact` to publish an HTML render, and pinning both with a test so the false claim cannot return.

[artifact-tools 1.1.0](../../kit/plugins/artifact-tools/CHANGELOG.md) added `references/titles.md` as the single source of artifact title rules, and told authors to set the title "as the page's `<title>` for HTML sources, or as frontmatter `title:` for Markdown sources." The second half is false.

The implementation proceeded through these steps: Replace the frontmatter claim in `titles.md`: with the truth: an HTML; Switch `session-artifact` to publish an HTML render.: Rewrite the Overview; Correct the republish note: to require `url` on every republish, not only; **Add `tests/plugins/test-artifact-titles.mjs` and wire it into; **Bump `artifact-tools` to 1.2.1 and add the CHANGELOG entry.**.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f6b0bdd` | 2026-08-17 | docs(plans): mark settings-sync guard next-step done in add-verification-gates ( |

<!-- generated:end -->

## References

- Plan: [fix-artifact-title-mechanism.md](plans/fix-artifact-title-mechanism.md)

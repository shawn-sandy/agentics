# Say the recap workflow once, not three times

> Extract the shared gather/scrub/build/publish workflow from `eng-recap`, `team-recap`, and `product-doc` into a single `references/recap-core.md`, reducing 1,568 words of duplication to three short framing briefs.

<!-- generated:start -->

**Status:** Shipped 2026-08-01 **Plan:** [extract-recap-command-core.md](plans/extract-recap-command-core.md)
**Type:** refactor

## What shipped

- Created `kit/plugins/artifact-tools/references/recap-core.md` — the shared gather, scrub, build, publish, and URL-record workflow
- Rewrote `eng-recap.md`, `team-recap.md`, and `product-doc.md` to state only audience, section list, plain-language posture, and republish key, then delegate to `recap-core.md`
- Bumped `artifact-tools` to the next minor version in `.claude-plugin/marketplace.json`
- Added a CHANGELOG entry recording the refactor
- Added `tests/plugins/test-recap-command-dedupe.sh` asserting pairwise duplication stays below 50 lines and each command writes its own distinct republish key
- Updated `.github/workflows/check-plugin-versions.yml` to run the new test
- Retargeted three `test-artifact-tools.sh` assertions from `commands/*.md` to `references/recap-core.md` to keep them passing after the extraction
- Fixed `test-remaining-skill-splits.sh` to glob `commands/` as well as `skills/` when checking for orphaned references

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/artifact-tools/references/recap-core.md` | Shared recap workflow | Created |
| `kit/plugins/artifact-tools/commands/eng-recap.md` | Engineer framing only | Modified |
| `kit/plugins/artifact-tools/commands/team-recap.md` | Whole-team framing only | Modified |
| `kit/plugins/artifact-tools/commands/product-doc.md` | Product framing only | Modified |
| `.claude-plugin/marketplace.json` | artifact-tools minor version bump | Modified |
| `kit/plugins/artifact-tools/CHANGELOG.md` | Refactor entry | Modified |
| `tests/plugins/test-recap-command-dedupe.sh` | Deduplication smoke test | Created |
| `.github/workflows/check-plugin-versions.yml` | Wired the new test | Modified |

## How it works

Before this change, `eng-recap` and `team-recap` shared 168 identical lines (1,568 words), and all three commands shared 68 lines (417 words). Combined they were 6,190 words. The Claude 5 context-engineering guidance names redundancy across context layers as an anti-pattern: say a thing once, in the place that owns it.

The three commands are three framings of one workflow — gather the session or PR, scrub it, build the page, publish, record the republish URL. Only the audience, the section list, the plain-language posture, and the republish frontmatter key genuinely differ.

The republish keys are the sharp edge of this refactor. Four distinct keys live on the same shared session record: `artifact-url:` belongs to `session-artifact`, `eng-artifact-url:` to `eng-recap`, `team-artifact-url:` to `team-recap`, and `product-artifact-url:` to `product-doc`. Collapsing the commands must not collapse the keys — two commands writing the same key would silently overwrite each other's published artifact. Step 4 of the plan verified key assignments per file, not across files, because prohibition text names keys a command must not write.

`recap-core.md` contains the PR and session gathering logic (including the 20-file diff cap and `--name-only` fallback), the blocking `security-scrub` gate, page build requirements, the publish step, the local-HTML fallback, and the republish-record protocol parameterized by key name. It contains no audience-specific words (`engineer`, `stakeholder`, `glossary`).

Each trimmed command file is under 500 words, names its own republish key, links `references/recap-core.md`, and retains the prohibition "Never write `artifact-url:`" that protects `session-artifact`'s key.

`product-doc` gained the page-build requirements and SVG-inlining destination it previously lacked (those had only been stated in the two sibling commands). Inheriting them from `recap-core.md` is the extraction working as intended. It also gained a favicon (`📋`) that it previously lacked.

The integration test — running all three commands against one merged PR and confirming three distinct artifacts publish — was not performed; it would publish pages to an external service. Verified structurally instead: each command names a distinct favicon, a distinct inbox stem, and a distinct republish key; audience-appropriate sections survive (`eng-recap` has Architecture with no Glossary; `team-recap` has a Glossary and diagrams; `product-doc` has Features and Known gaps); and the read-key-before-publishing protocol is intact in `recap-core.md`.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `3ee6806` | 2026-08-18 | fix(plan-agent): close three build-feature gaps found in its first run (9.4.6) (#580) |

<!-- generated:end -->

## References

- Plan: [extract-recap-command-core.md](plans/extract-recap-command-core.md)

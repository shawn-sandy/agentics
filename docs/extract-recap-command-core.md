# Say the recap workflow once, not three times

> Extracts the shared gather/scrub/build/publish workflow from three artifact-tools recap commands into a single `references/recap-core.md`, reducing each command to its framing differences: audience, sections, and republish key.

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [extract-recap-command-core.md](plans/extract-recap-command-core.md)
**Type:** refactor

## What shipped

- Created `kit/plugins/artifact-tools/references/recap-core.md` containing the shared workflow: PR and session gathering including the 20-file diff cap and `--name-only` fallback, the blocking `security-scrub` gate, page build, publish, local-HTML fallback, and the republish-record protocol parameterised by key name.
- Rewrote `commands/eng-recap.md`, `commands/team-recap.md`, and `commands/product-doc.md` to state each command's audience, section list, plain-language posture, favicon, inbox stem, and republish key, then delegate to `references/recap-core.md`. Each command file is under 500 words.
- Preserved the four distinct per-command republish keys (`eng-artifact-url:`, `team-artifact-url:`, `product-artifact-url:`, and `artifact-url:` which belongs exclusively to `session-artifact`) — no key was collapsed.
- Added `tests/plugins/test-recap-command-dedupe.sh` asserting: pairwise identical lines across commands are under 50, each command is under 500 words, `recap-core.md` exists, and each command file writes its own key per-file without assigning `artifact-url:` to itself.
- Bumped `artifact-tools` to the next minor version in `.claude-plugin/marketplace.json` and added a CHANGELOG entry.
- Retargeted three assertions in `tests/plugins/test-artifact-tools.sh` (gh preflight, PR gather block, 20-file diff cap) from `commands/*.md` to `references/recap-core.md` where those contracts now live, and widened `tests/plugins/test-remaining-skill-splits.sh` to glob commands as linkers alongside skills so `recap-core.md` is not reported as orphaned.
- `product-doc` gained the page-build requirements, SVG-inlining destination, and favicon (📋) it had been missing, now inherited from the shared workflow.
- Added one line to `kit/plugins/artifact-tools/README.md` for the `recap-core.md` structure tree entry.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/artifact-tools/references/recap-core.md` | Shared gather/scrub/build/publish workflow | Created |
| `kit/plugins/artifact-tools/commands/eng-recap.md` | Reduced to engineer framing + `eng-artifact-url:` | Modified |
| `kit/plugins/artifact-tools/commands/team-recap.md` | Reduced to whole-team framing + `team-artifact-url:` | Modified |
| `kit/plugins/artifact-tools/commands/product-doc.md` | Reduced to product framing + `product-artifact-url:` | Modified |
| `.claude-plugin/marketplace.json` | artifact-tools minor version bump | Modified |
| `kit/plugins/artifact-tools/CHANGELOG.md` | Extraction entry | Modified |
| `tests/plugins/test-recap-command-dedupe.sh` | Objective test for deduplication and key isolation | Created |
| `tests/plugins/test-artifact-tools.sh` | Three assertions retargeted to recap-core.md | Modified |
| `tests/plugins/test-remaining-skill-splits.sh` | Widened linker glob to include commands | Modified |
| `kit/plugins/artifact-tools/README.md` | recap-core.md structure tree entry | Modified |

## How it works

The three recap commands shared 168 identical lines between `eng-recap` and `team-recap` alone, and 68 identical lines across all three. They are three framings of one workflow — gather the session or PR, scrub it, build the page, publish, record the republish URL — with only the audience, section list, plain-language rule, and republish frontmatter key genuinely differing.

The plan required care on one sharp edge: four distinct keys live on the same shared session record, one per command plus `artifact-url:` owned exclusively by `session-artifact`. Two commands writing the same key would silently overwrite each other's published artifact. The extraction therefore preserves each command's own key explicitly and each command still carries the "Never write `artifact-url:`" prohibition pointing to `session-artifact`.

The shared extraction followed a two-pass approach: first a pairwise diff classified every shared line as either genuinely shared workflow or a coincidental match (shared section headings whose content differs by audience). Only the genuine workflow lines moved to `recap-core.md`. The test's per-file grep check (rather than a `sort -u` across all files) is specifically what enforces this: it verifies that each command assigns its own key and only its own key.

`product-doc` had been the thinnest of the three commands and was missing several things `eng-recap` and `team-recap` had. Inheriting from the shared workflow gave it the page-build requirements and SVG-inlining destination it lacked, plus a favicon it needed to publish under.

The Completion Report documents one integration test that was deliberately not executed: running all three commands against a live PR to confirm three separate artifacts publish. The behavioral contracts (distinct favicons, inbox stems, republish keys, and audience-appropriate sections) were verified structurally instead.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `bcaf6fa` | 2026-08-17 | feat: worked examples and remaining verification checks (audit Tier 4) (#570) |

<!-- generated:end -->

## References

- Plan: [extract-recap-command-core.md](plans/extract-recap-command-core.md)

# Say the recap workflow once, not three times

> Three artifact-tools recap commands say the same thing three times — eng-recap and team-recap alone share 1,568 identical words. Pulling the shared workflow into one reference file leaves each command as a short framing brief, and we will know it worked when the three commands share fewer than 50 identical lines while each still publishes to its own artifact URL key.

<!-- generated:start -->

**Status:** Shipped 2026-08-01  **Plan:** [extract-recap-command-core.md](plans/extract-recap-command-core.md)
**Type:** refactor

## What shipped

- Created `kit/plugins/artifact-tools/references/recap-core.md` containing the shared gather/scrub/build/publish workflow: PR and session gathering including the 20-file diff cap and `--name-only` fallback, the blocking `security-scrub` gate, page build, publish, local-HTML fallback, and the republish-record protocol parameterised by key name.
- Reduced `commands/eng-recap.md`, `commands/team-recap.md`, and `commands/product-doc.md` to each contain only its audience framing, section list, plain-language posture, and its own republish key — each under 500 words.
- Preserved each command's distinct republish key (`eng-artifact-url:`, `team-artifact-url:`, `product-artifact-url:`) and the `artifact-url:` prohibition in all three files.
- Created `tests/plugins/test-recap-command-dedupe.sh` asserting pairwise identical lines are under 50, each command is under 500 words, `recap-core.md` exists, and per-file key assignments are correct.
- Wired the new test into `.github/workflows/check-plugin-versions.yml`.
- Bumped `artifact-tools` to the next minor version in `.claude-plugin/marketplace.json`.
- Retargeted three checks in `test-artifact-tools.sh` from `commands/*.md` to `references/recap-core.md` where the contracts now live; widened `test-remaining-skill-splits.sh` to glob commands as linkers so `recap-core.md` is not flagged as orphaned.
- `product-doc` gained the page-build requirements and SVG-inlining destination it had been missing (they were only in the two siblings; inheriting them from the shared workflow is the extraction working as intended), plus a favicon.

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `kit/plugins/artifact-tools/references/recap-core.md` | Shared gather/scrub/build/publish workflow | Created |
| `kit/plugins/artifact-tools/commands/eng-recap.md` | Reduced to engineer framing + eng-artifact-url: | Modified |
| `kit/plugins/artifact-tools/commands/team-recap.md` | Reduced to team framing + team-artifact-url: | Modified |
| `kit/plugins/artifact-tools/commands/product-doc.md` | Reduced to product framing + product-artifact-url: | Modified |
| `.claude-plugin/marketplace.json` | artifact-tools minor version bump | Modified |
| `kit/plugins/artifact-tools/CHANGELOG.md` | Refactor entry | Modified |
| `tests/plugins/test-recap-command-dedupe.sh` | Deduplication objective test | Created |
| `.github/workflows/check-plugin-versions.yml` | New test wired in | Modified |
| `tests/plugins/test-artifact-tools.sh` | Retargeted three checks to recap-core.md | Modified |

## How it works

The refactor followed the context-engineering principle of saying a thing once, in the place that owns it. Before extraction, `eng-recap` and `team-recap` shared 168 identical lines (1,568 words), and all three commands shared 68 lines (417 words). A keyword scan to classify each shared line determined whether the line was "genuinely shared workflow" or a "coincidental match" (shared section headings whose content differs per audience). Only the genuinely shared lines moved to `recap-core.md`.

The sharper edge of this refactor was the four distinct republish keys. `session-artifact` owns `artifact-url:`; the three recap commands each own their own key (`eng-artifact-url:`, `team-artifact-url:`, `product-artifact-url:`). All three command files also *name* `artifact-url:` in a prohibition ("Never write `artifact-url:`"), because that key belongs to `session-artifact`. A naive collapse that merged the commands would have collided the keys. Step 4 of the plan verified assignments *per file* rather than counting key names across files — the prohibition text mentions keys a command must *not* write, so a cross-file grep returns 9 lines (3 own-key assignments + 6 prohibition mentions), not 3.

`recap-core.md` owns the gather step, the 20-file diff cap, the blocking scrub gate, the page-build step, the publish, the local-HTML fallback, and the republish-record protocol. Each command file's only content is the audience framing (what tone and vocabulary to use), the section list (which sections appear, in what order), and the explicit own-key assignment.

The `test-recap-command-dedupe.sh` test guards against regression by asserting pairwise identical line counts. Pasting 60 lines of `recap-core.md` back into two commands makes the test exit 1, proving the check detects duplication rather than passing unconditionally.

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| 0fd7b67 | 2026-08-19 | fix(plan-agent): plan-authoring skills state the plan-only gate (9.4.8) (#584) |

<!-- generated:end -->

## References

- Plan: [extract-recap-command-core.md](plans/extract-recap-command-core.md)

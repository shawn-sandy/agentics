# Say the recap workflow once, not three times

> Three artifact-tools recap commands say the same thing three times — eng-recap and team-recap alone share 1,568 identical words. Pulling the shared workflow...

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [extract-recap-command-core.md](plans/extract-recap-command-core.md)
**Type:** refactor

## What shipped

- Diff the three command files pairwise and write the shared-line inventory to a scratch file, separating lines that ar...
- Write `kit/plugins/artifact-tools/references/recap-core.md` containing only the Step 1 "shared workflow" lines — PR a...
- Rewrite each of the three commands to state its audience, its section list, its plain-language posture, and its repub...
- Confirm each command still writes its own republish key and still carries the `artifact-url:` prohibition, checking a...
- Bump `artifact-tools` to the next minor version in `.claude-plugin/marketplace.json` and add a `kit/plugins/artifact-...
- Write `tests/plugins/test-recap-command-dedupe.sh` asserting the three commands share fewer than 50 identical lines,...
- Add the new test to `.github/workflows/check-plugin-versions.yml`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/artifact-tools/references/recap-core.md` | the shared gather/scrub/build/publish workflow | Created |
| `kit/plugins/artifact-tools/commands/eng-recap.md` | reduce to engineer framing + `eng-artifact-url:` | Modified |
| `kit/plugins/artifact-tools/commands/team-recap.md` | reduce to whole-team framing + its key | Modified |
| `kit/plugins/artifact-tools/commands/product-doc.md` | reduce to product framing + `product-artifact-url:` | Modified |
| `.claude-plugin/marketplace.json` | bump artifact-tools minor version | Modified |
| `kit/plugins/artifact-tools/CHANGELOG.md` | record the refactor | Modified |
| `tests/plugins/test-recap-command-dedupe.sh` | objective test | Created |
| `.github/workflows/check-plugin-versions.yml` | wire the new test | Modified |

## How it works

Extract the shared recap workflow from `eng-recap`, `team-recap`, and `product-doc` into a single `references/recap-core.md`, reducing each command to the framing that actually differs: audience, sections, and republish key.

The Claude 5 context-engineering guidance names redundancy across context layers as an anti-pattern: say a thing once, in the place that owns it. The three `artifact-tools` recap commands violate this at scale. Measured across the three files:

The implementation proceeded through these steps: Diff the three command files pairwise and write the shared-line inventory to a scratch file, separating lines that ar...; Write `kit/plugins/artifact-tools/references/recap-core.md` containing only the Step 1 "shared workflow" lines — PR a...; Rewrite each of the three commands to state its audience, its section list, its plain-language posture, and its repub...; Confirm each command still writes its own republish key and still carries the `artifact-url:` prohibition, checking a...; Bump `artifact-tools` to the next minor version in `.claude-plugin/marketplace.json` and add a `kit/plugins/artifact-....

- Integration test — the behavioral run named in Verification (run all three commands against one merged PR and confirm three artifacts publish) was not performed — it publishes three pages to an external service, which is not something to trigger unprompted. Verified structurally instead: each comm

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f6b0bdd` | 2026-08-17 | docs(plans): mark settings-sync guard next-step done in add-verification-gates ( |

<!-- generated:end -->

## References

- Plan: [extract-recap-command-core.md](plans/extract-recap-command-core.md)

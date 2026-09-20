# Say the recap workflow once, not three times

> Three artifact-tools recap commands say the same thing three times — eng-recap and team-recap alone share 1,568 identical words. Pulling the shared workflow...

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [extract-recap-command-core.md](plans/extract-recap-command-core.md)
**Type:** refactor

## What shipped

- Diff the three command files pairwise and write the shared-line inventory to a scratch file, separating lines that are genuinely shared workflow from lines that only look identical (shared section *headings* whose content differs per audience).
- Write `kit/plugins/artifact-tools/references/recap-core.md` containing only the Step 1 "shared workflow" lines — PR and session gathering including the 20-file diff cap and `--name-only` fallback, the blocking `security-scrub` gate, page build, publish, local-HTML fallback, and the republish-record protocol parameterised by key name.
- Rewrite each of the three commands to state its audience, its section list, its plain-language posture, and its republish key explicitly, then delegate the workflow to `references/recap-core.md`.
- Confirm each command still writes its own republish key and still carries the `artifact-url:` prohibition, checking assignments per file rather than counting key names across files.
- Bump `artifact-tools` to the next minor version in `.claude-plugin/marketplace.json` and add a `kit/plugins/artifact-tools/CHANGELOG.md` entry describing the extraction.
- Write `tests/plugins/test-recap-command-dedupe.sh` asserting the three commands share fewer than 50 identical lines, each is under 500 words, `references/recap-core.md` exists, and — per file, not across files — that `eng-recap.md` writes `eng-artifact-url:`, `team-recap.md` writes `team-artifact-url:`, `product-doc.md` writes `product-artifact-url:`, and none of the three assigns `artifact-url:` to itself.
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

The Claude 5 context-engineering guidance names redundancy across context layers as an anti-pattern: say a thing once, in the place that owns it. The three `artifact-tools` recap commands violate this at scale. Measured across the three files: - `eng-recap` and `team-recap` share 168 identical lines / 1,568 words

The implementation proceeded through the following steps: Diff the three command files pairwise and write the shared-line inventory to a scratch file, separating lines that are genuinely shared workflow from lines that only look identical (shared section *headings* whose content differs per audience). Why: collapsing a line that reads the same but means something different per audience is how a refactor silently changes behavior. Verify: the scratch file classifies every one of the 68 all-three shared lines as either "shared workflow" or "coincidental match".; Write `kit/plugins/artifact-tools/references/recap-core.md` containing only the Step 1 "shared workflow" lines — PR and session gathering including the 20-file diff cap and `--name-only` fallback, the blocking `security-scrub` gate, page build, publish, local-HTML fallback, and the republish-record protocol parameterised by key name. Why: one file that owns the workflow means a fix to the scrub gate lands in all three commands at once instead of one-third of the time. Verify: `recap-core.md` exists and contains no audience-specific words (`engineer`, `stakeholder`, `glossary`).; Rewrite each of the three commands to state its audience, its section list, its plain-language posture, and its republish key explicitly, then delegate the workflow to `references/recap-core.md`. Why: the differences are the whole reason three commands exist, so they are what the command file should contain. Verify: each command file is under 500 words, names its own republish key, and links `references/recap-core.md`.; Confirm each command still writes its own republish key and still carries the `artifact-url:` prohibition, checking assignments per file rather than counting key names across files. Why: a shared key silently overwrites another command's published artifact, and a command reassigned to `artifact-url:` would clobber the session recap. Verify: run the three per-file greps below — each prints its own key and nothing else — then confirm all three files still match `Never write .artifact-url:`; note that a bare `grep -o ... commands/*.md | sort -u` cannot prove this, because grep prefixes each match with its filename and the prohibition text names keys the command must *not* write (that form returns 9 lines today, not 3).; Bump `artifact-tools` to the next minor version in `.claude-plugin/marketplace.json` and add a `kit/plugins/artifact-tools/CHANGELOG.md` entry describing the extraction. Why: any edit under `kit/plugins/<name>/` requires a version bump higher than main, per repo convention. Verify: `BASE_REF=main node scripts/check-plugin-versions.mjs` exits 0.; Write `tests/plugins/test-recap-command-dedupe.sh` asserting the three commands share fewer than 50 identical lines, each is under 500 words, `references/recap-core.md` exists, and — per file, not across files — that `eng-recap.md` writes `eng-artifact-url:`, `team-recap.md` writes `team-artifact-url:`, `product-doc.md` writes `product-artifact-url:`, and none of the three assigns `artifact-url:` to itself. Why: without a check, the next feature added to all three commands re-introduces the duplication. Verify: `bash tests/plugins/test-recap-command-dedupe.sh` exits 0; pasting 60 lines of recap-core back into two commands makes it exit 1..

- Integration test — the behavioral run named in Verification (run all three commands against one merged PR and confirm three artifacts publish) was not performed — it publishes three pages to an external service, which is not something to trigger unprompted. Verified structurally instead: each command names a distinct favicon (🔧 / 🧭 / 📋), a distinct inbox stem, and a distinct republish key; the audience-appropriate sections the Verification section names all survive (eng-recap has Architecture and code paths and no Glossary; team-recap has Glossary and the diagram section; product-doc has Features and Known gaps); and the read-key-before-publishing protocol is intact in `recap-core.md`. Every acceptance criterion was verified directly. This one Verification item was not. - `tests/plugins/test-artifact-tools.sh` (modified, not in the plan's Files list) — checks 8, 8b, and 9 asserted the gh preflight, the PR gather block, and the 20-file diff cap lived inside `commands/*.md`, and check 8 required `found >= 3`. Extracting the workflow made all three fail. They now assert the same contracts against `references/recap-core.md` — the file that owns them after this change — and additionally assert that each command loads the core, that none keeps a second gather block, and that exactly one command (`eng-recap`) opts in to the diff budget. Retargeted, not weakened. - `tests/plugins/test-remaining-skill-splits.sh` (modified, not in the plan's Files list) — its orphaned-reference check globbed only `skills/*/SKILL.md` as linkers, so `recap-core.md` — the first reference read by commands rather than skills — was reported as orphaned. The check now globs commands too. Confirmed the widened logic still flags a genuinely unlinked reference. - `product-doc` gained the page-build requirements and the SVG-inlining destination — it had neither before, because they lived only in the two siblings. Inheriting them from the shared workflow is the extraction working as intended, and it needed a favicon (📋) to publish under, which it also lacked.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f6b0bdd` | 2026-08-17 | docs(plans): mark settings-sync guard next-step done in add-verification-gates (#573) |

<!-- generated:end -->

## References

- Plan: [extract-recap-command-core.md](plans/extract-recap-command-core.md)

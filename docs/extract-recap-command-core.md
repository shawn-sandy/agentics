# Say the recap workflow once, not three times

> Extracts the shared gather/scrub/build/publish workflow from three artifact-tools recap commands into a single reference file, leaving each command as a short audience-specific framing brief under 500 words.

<!-- generated:start -->

**Status:** Shipped 2026-08-01 **Plan:** [extract-recap-command-core.md](plans/extract-recap-command-core.md)
**Type:** refactor

## What shipped

- Extracted the shared recap workflow (PR/session gathering, security scrub, page build, publish, republish-record protocol) from `eng-recap`, `team-recap`, and `product-doc` into a single `references/recap-core.md` (reduces 6,190-word combined source that shared 168 identical lines between two commands and 68 lines across all three).
- Rewrote each of the three commands to contain only audience, section list, plain-language posture, and its own republish key, delegating the workflow to `recap-core.md` (each command now under 500 words and fewer than 50 identical pairwise lines).
- Confirmed each command still writes its own distinct republish key — `eng-artifact-url:`, `team-artifact-url:`, `product-artifact-url:` — and none reassigns `artifact-url:`, which belongs to `session-artifact` (preserves the four-key isolation on the shared session record).
- Added `tests/plugins/test-recap-command-dedupe.sh` asserting the pairwise line count, per-file key assignments, word budgets, and `recap-core.md` existence (so future duplication regresses a test rather than shipping silently).
- Wired the new test into `.github/workflows/check-plugin-versions.yml` and bumped `artifact-tools` to the next minor version.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/artifact-tools/references/recap-core.md` | Shared gather/scrub/build/publish workflow | Created |
| `kit/plugins/artifact-tools/commands/eng-recap.md` | Engineering audience framing + `eng-artifact-url:` | Modified |
| `kit/plugins/artifact-tools/commands/team-recap.md` | Whole-team audience framing + `team-artifact-url:` | Modified |
| `kit/plugins/artifact-tools/commands/product-doc.md` | Product/stakeholder framing + `product-artifact-url:` | Modified |
| `.claude-plugin/marketplace.json` | artifact-tools minor version bump | Modified |
| `kit/plugins/artifact-tools/CHANGELOG.md` | Refactor entry | Modified |
| `tests/plugins/test-recap-command-dedupe.sh` | Objective deduplication test | Created |
| `.github/workflows/check-plugin-versions.yml` | Wires new test into CI | Modified |

## How it works

The three recap commands — `eng-recap`, `team-recap`, and `product-doc` — previously duplicated the same gather-scrub-build-publish workflow in full. A pairwise diff measured 168 identical lines between `eng-recap` and `team-recap` alone (1,568 words) and 68 lines common to all three. The Claude 5 context-engineering guidance identifies cross-layer redundancy as an anti-pattern: a fix to the scrub gate needed to land in one file to reach all three commands simultaneously, but the duplication guaranteed it landed at most once in three.

The core extraction (`recap-core.md`) pulls out every line that belongs to the shared workflow: the 20-file diff cap and `--name-only` fallback for PR gathering, the blocking `security-scrub` gate, the page-build and publish steps, the local-HTML fallback, and the republish-record protocol. The protocol is parameterised by key name so each command's own key name remains explicit in the command file rather than collapsed into a generic token.

The sharp constraint throughout was key isolation. Four distinct republish keys live on the same shared session record. `artifact-url:` belongs to `session-artifact`; the three recap commands each own one of `eng-artifact-url:`, `team-artifact-url:`, and `product-artifact-url:`. Collapsing the commands could not collapse the keys: two commands writing the same key silently overwrite each other's published artifact, and any command reassigned to `artifact-url:` would clobber the reviewer-first session recap. The extraction preserves the three per-command keys in the command files and retains the `artifact-url:` prohibition in all three.

The verification test (`test-recap-command-dedupe.sh`) checks four properties per file — not once across files — to distinguish the prohibition text (which names keys a command must not write) from the assignment (which is the single key a command does write). A naive `grep -o ... | sort -u` would return 9 lines rather than 3 and cannot prove per-file isolation.

Two test files outside the plan's listed scope required fixes: `test-artifact-tools.sh` had checks that asserted the PR gather block and diff cap lived in `commands/*.md`, and `test-remaining-skill-splits.sh` reported `recap-core.md` as orphaned because its orphan check only globbed skill files as linkers. Both were retargeted rather than weakened.

## How to use it

No direct user-facing invocation change — the three commands are still called as `/artifact-tools:eng-recap`, `/artifact-tools:team-recap`, and `/artifact-tools:product-doc`. The extracted core is a reference file loaded by those commands, not a command itself.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `024ddd0` | 2026-08-01 | refactor(artifact-tools): say the recap workflow once, not three times (#504) |
| `eb283c3` | 2026-07-27 | fix(artifact-tools): backport eng-recap's PR-gather fixes to team-recap and product-doc (#475) |
| `04d2b41` | 2026-07-27 | feat(artifact-tools): add /eng-recap command for the engineering team (#473) |

<!-- generated:end -->

## References

- Plan: [extract-recap-command-core.md](plans/extract-recap-command-core.md)

# Say the recap workflow once, not three times

> Extracts the shared recap workflow from the three artifact-tools recap commands into a single `references/recap-core.md`, reducing duplication from 1,568 shared words down to framing-only command files.

<!-- generated:start -->

**Status:** Shipped 2026-08-26  **Plan:** [extract-recap-command-core.md](plans/extract-recap-command-core.md)
**Type:** refactor

## What shipped

- Created `kit/plugins/artifact-tools/references/recap-core.md` holding the single shared gather/scrub/build/publish workflow — PR and session gathering including the 20-file diff cap, the blocking security-scrub gate, page build, publish, local-HTML fallback, and the republish-record protocol.
- Reduced `eng-recap.md`, `team-recap.md`, and `product-doc.md` to framing-only files: each now states its audience, its section list, its plain-language posture, and its republish key, then delegates to `recap-core.md`.
- Preserved the four distinct republish keys: `eng-artifact-url:`, `team-artifact-url:`, `product-artifact-url:`, and the prohibition on each command assigning `artifact-url:` (which belongs to `session-artifact`).
- Shipped `tests/plugins/test-recap-command-dedupe.sh` to assert pairwise identical lines across the three commands stays below 50, each is under 500 words, and each file writes its own key.
- Bumped artifact-tools to the next minor version in `.claude-plugin/marketplace.json`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/artifact-tools/references/recap-core.md` | Shared recap workflow | Created |
| `kit/plugins/artifact-tools/commands/eng-recap.md` | Engineer-audience framing | Modified |
| `kit/plugins/artifact-tools/commands/team-recap.md` | Whole-team framing | Modified |
| `kit/plugins/artifact-tools/commands/product-doc.md` | Product-audience framing | Modified |
| `.claude-plugin/marketplace.json` | Version bump | Modified |
| `kit/plugins/artifact-tools/CHANGELOG.md` | Refactor entry | Modified |
| `tests/plugins/test-recap-command-dedupe.sh` | Objective test | Created |

## How it works

The extraction followed the Claude 5 context-engineering guidance of saying a thing once, in the place that owns it. The three commands shared 168 identical lines between eng-recap and team-recap alone, and all three shared 68 more. The first step inventoried every shared line to distinguish genuine shared workflow from coincidentally identical section headings whose content differs per audience — collapsing those would silently change behavior.

`recap-core.md` holds only the workflow lines: gathering the session or PR diff (with its 20-file cap and `--name-only` fallback), the blocking `security-scrub` gate, page construction, the Artifact-tool publish, the local-HTML fallback, and the republish-record protocol parameterized by key name. It contains no audience-specific words.

The republish keys were the sharpest edge. A shared key would silently overwrite another command's published artifact. The test verifies assignments per file rather than counting key names across files, because the prohibition text names keys the command must _not_ write — a naive cross-file grep would return 9 lines instead of 3 and prove nothing about which file owns which key.

`product-doc` also gained the page-build requirements and SVG-inlining destination it previously lacked, because those lived only in the two siblings and now flow from the shared workflow.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `6d6bfeb3` | 2026-08-26 | fix(plan-agent): carry completion state to artifact-published plans (9.9.0) (#604) |

<!-- generated:end -->

## References

- Plan: [extract-recap-command-core.md](plans/extract-recap-command-core.md)
- Related: [create-artifact-tools-plugin.md](create-artifact-tools-plugin.md)

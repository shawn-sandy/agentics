# Say the recap workflow once, not three times

> Extracts the shared gather/scrub/build/publish workflow from the three `artifact-tools` recap commands into a single `references/recap-core.md`, reducing each command to the framing that actually differs: audience, sections, and republish key.

<!-- generated:start -->

**Status:** Shipped 2026-08-01  **Plan:** [extract-recap-command-core.md](plans/extract-recap-command-core.md)
**Type:** refactor

## What shipped

- Added `kit/plugins/artifact-tools/references/recap-core.md` — the shared PR-and-session gathering workflow (20-file diff cap, `--name-only` fallback), the blocking `security-scrub` gate, page build, publish, local-HTML fallback, and the republish-record protocol parameterised by key name.
- Reduced `eng-recap.md`, `team-recap.md`, and `product-doc.md` to each command's framing brief (audience, section list, plain-language posture, and its own republish key), delegating the workflow to `recap-core.md`. Each command is now under 500 words.
- Added `tests/plugins/test-recap-command-dedupe.sh` — asserts pairwise identical lines across the three commands number fewer than 50, each is under 500 words, `references/recap-core.md` exists, and per-file each command writes only its own republish key.
- Updated `tests/plugins/test-artifact-tools.sh` checks 8/8b/9 to assert the contracts against `recap-core.md` (where they now live) and to assert each command loads the core.
- Updated `tests/plugins/test-remaining-skill-splits.sh` orphaned-reference check to glob commands alongside skills.
- Updated `kit/plugins/artifact-tools/README.md` structure tree.
- Bumped `artifact-tools` minor version in `.claude-plugin/marketplace.json`.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/artifact-tools/references/recap-core.md` | Shared workflow reference | Created |
| `kit/plugins/artifact-tools/commands/eng-recap.md` | Engineer recap command | Modified |
| `kit/plugins/artifact-tools/commands/team-recap.md` | Team recap command | Modified |
| `kit/plugins/artifact-tools/commands/product-doc.md` | Product doc command | Modified |
| `tests/plugins/test-recap-command-dedupe.sh` | Dedupe smoke test | Created |
| `tests/plugins/test-artifact-tools.sh` | Smoke test | Modified |
| `tests/plugins/test-remaining-skill-splits.sh` | Orphan check | Modified |
| `kit/plugins/artifact-tools/README.md` | Plugin documentation | Modified |
| `kit/plugins/artifact-tools/CHANGELOG.md` | Release notes | Modified |
| `.claude-plugin/marketplace.json` | Marketplace version | Modified |

## How it works

The three commands (`eng-recap`, `team-recap`, `product-doc`) were 6,190 words total with 168 identical lines shared between just the first two. The extraction preserves the four distinct republish keys: `session-artifact` owns `artifact-url:`, `eng-recap` writes `eng-artifact-url:`, `team-recap` writes `team-artifact-url:`, and `product-doc` writes `product-artifact-url:`. Each command still names all four keys — its own in the assignment and the others in the prohibition — but the shared workflow that uses them lives in one place.

A fix to the scrub gate or the diff-cap logic now lands in all three commands at once, instead of requiring three separate edits that could drift.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `67ab9a1` | 2026-08-19 | docs: sync README plugin table with memory-tools 4.3.0 (#588) |

<!-- generated:end -->

## References

- Plan: [extract-recap-command-core.md](plans/extract-recap-command-core.md)

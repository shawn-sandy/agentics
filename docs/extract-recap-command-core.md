# Say the recap workflow once, not three times

> Extracts the shared recap workflow from `eng-recap`, `team-recap`, and `product-doc` into a single `references/recap-core.md`, reducing each command to the framing that actually differs: audience, sections, and republish key.

<!-- generated:start -->

**Status:** Shipped 2026-08-20  **Plan:** [extract-recap-command-core](plans/extract-recap-command-core.md)
**Type:** refactor

## What shipped

- Created `kit/plugins/artifact-tools/commands/references/recap-core.md` — the shared workflow: PR preflight, session-artifact delegation, scrub gate, save-artifact destination, republish-key discipline
- Rewrote `eng-recap.md`, `team-recap.md`, and `product-doc.md` as thin framing overrides that link to `recap-core.md` for all mechanics
- Each command now contains only: audience definition, section list, and republish key declaration
- Updated `tests/plugins/test-artifact-tools.sh` to assert that each command references the shared core

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/artifact-tools/commands/references/recap-core.md` | Reference — shared recap workflow | Created |
| `kit/plugins/artifact-tools/commands/eng-recap.md` | Command — framing only, links to core | Modified |
| `kit/plugins/artifact-tools/commands/team-recap.md` | Command — framing only, links to core | Modified |
| `kit/plugins/artifact-tools/commands/product-doc.md` | Command — framing only, links to core | Modified |
| `tests/plugins/test-artifact-tools.sh` | Smoke test — core reference assertion | Modified |

## How it works

Three recap commands shared the same mechanics: the `gh auth status` + GitHub-remote PR preflight, delegation to `session-artifact` for extraction, the scrub gate, the `save-artifact` destination flow with its collision-safe local fallback, and the republish-key discipline. Each command file contained a full copy.

Three copies of the same prose diverge silently. When the scrub gate was updated (fixing the `sk-` pattern), the fix had to be applied to all three. When a new command is added, the author must copy-and-adapt the whole block or miss coverage.

`recap-core.md` holds the mechanics once. Each command file reads the core at the start of a run and applies its framing-specific overrides on top. The overrides are genuinely short: `eng-recap` is about 80 lines; `product-doc` is under 60. A command file that defers to a reference is harder to follow in one read (the tradeoff noted in the plan), but the maintenance benefit outweighs it at three copies.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `d1dfefb` | 2026-08-20 | docs: sync README and how-to guides with latest plugin changes (#589) |

<!-- generated:end -->

## References

- Plan: [extract-recap-command-core](plans/extract-recap-command-core.md)

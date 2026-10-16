# Extract shared recap command core

> Extracts the shared workflow from team-recap, eng-recap, and product-recap into `references/recap-core.md`, reducing each command to its audience-specific framing while sharing the underlying generation logic.

<!-- generated:start -->

**Status:** Shipped 2026-08-01 **Plan:** [extract-recap-command-core.md](plans/extract-recap-command-core.md)
**Type:** refactor

## What shipped

- Created `kit/plugins/artifact-tools/skills/references/recap-core.md` with the shared recap workflow.
- Reduced each recap command to framing only: audience, section ordering, republish key, favicon.
- `eng-recap` now uses `eng-artifact-url:`, team uses `team-artifact-url:`, product uses `product-artifact-url:`.
- Removed duplicated generation logic from all three command files.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/artifact-tools/skills/references/recap-core.md` | Shared core | Created |
| `kit/plugins/artifact-tools/skills/eng-recap/SKILL.md` | Eng recap skill | Modified |
| `kit/plugins/artifact-tools/skills/team-recap/SKILL.md` | Team recap skill | Modified |
| `kit/plugins/artifact-tools/skills/product-recap/SKILL.md` | Product recap skill | Modified |

## How it works

Three recap commands shared identical generation logic — fetching the diff, scrubbing secrets, building the artifact HTML, publishing, recording the URL — but differed in three ways: who the audience is (engineers, the whole team, product stakeholders), what order the sections appear in (technical-first for engineers, outcomes-first for the team and product), and which frontmatter key records the artifact URL.

The extraction moves all shared logic into `recap-core.md`, which each command includes by reference. Each command's `SKILL.md` becomes a thin framing layer: "this is the audience, this is the section order, use this URL key." When the core logic changes — say, to add a new security-scrub check — it changes in one place.

The distinct URL keys (`eng-artifact-url:`, `team-artifact-url:`, `product-artifact-url:`) prevent one recap command from clobbering another's published artifact when multiple recaps are run for the same plan.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `a881edb` | 2026-08-19 | feat(memory-tools): add implementing-insights skill (4.2.0) (#586) |

<!-- generated:end -->

## References

- Plan: [extract-recap-command-core.md](plans/extract-recap-command-core.md)

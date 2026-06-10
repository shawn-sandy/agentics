---
description: Run plan file hygiene before committing changes
paths:
  - "**/plans/**"
---

# Pre-Commit Plan Hygiene

Before creating any git commit, check if there are plan files with random
non-descriptive names (e.g., `precious-knitting-tulip.md`) in the planning
directories.

If random-named plan files exist, run `/plan-hygiene` first and complete the
rename workflow before proceeding with the commit.

## Plans Index Merge Driver

`docs/plans/index.html` is a generated file — rebuilt from the plan HTML files
by `docs/plans/build-index.sh` (auto-run on every plan write by the
`plan-agent` rebuild hook). Because every plan-adding branch regenerates it,
concurrent plan PRs always conflict on this file.

The `scripts/merge-plans-index.mjs` merge driver (registered as `plans-index`
via `.gitattributes`, activated by `scripts/setup-merge-driver.sh`, which the
SessionStart hook runs automatically) resolves these conflicts by unioning the
gallery cards from both sides: ours' cards keep their order, new cards from
theirs are appended, and a card deleted on either side (relative to the merge
base) stays deleted. The driver intentionally does **not** re-run
`build-index.sh` — at merge-driver time git has not yet written the incoming
branch's plan files to the working tree, so regenerating from disk would
silently drop every incoming plan. Ordering/timestamp drift after a driver
merge is cosmetic and self-heals on the next plan write.

Never hand-edit conflict markers in `index.html`. If a merge still conflicts
on it (driver not registered), run `bash scripts/setup-merge-driver.sh`, then
re-merge — or finish the merge and re-run `bash docs/plans/build-index.sh`
once the working tree contains both sides' plan files.

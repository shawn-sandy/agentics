# Delete the six de-registered plugin directories and fix survivor frontmatter

> Six de-registered plugins still loaded through `--plugin-dir` and collided with live plugins by name; this deleted them, corrected documentation, and ran skill-reviewer over the survivors to fix description budget overruns.

<!-- generated:start -->

**Status:** Shipped 2026-08-27  **Plan:** [remove-dead-plugins-and-fix-frontmatter.md](plans/remove-dead-plugins-and-fix-frontmatter.md)
**Type:** chore

## What shipped

- Migrated `code-review:fix-branch` off the deleted `agent-reviewer` skill, pointing agent-file reviews at `skill-reviewer` instead (the stated replacement in v4.0.0's own removal note).
- Deleted the six de-registered plugin directories (`agent-creator`, `agent-reviewer`, `agentic-plugin-dev`, `code-simplifier`, `marketplace-builder`, `react-perf-analyzer`) — 5,454 lines across 40 files.
- Corrected `README.md`: replaced the false "retained in the repository" claim with a git-history pointer, removed six entries from the tree diagram, and updated the migration table.
- Updated `.claude/rules/marketplace.md` to remove the retained-for-reference promise while keeping the do-not-re-add table.
- Replaced the `ls | xargs` loader one-liner in `CLAUDE.local.md` with a form that reads the manifest, closing the class of problem rather than just the instance.
- Ran `/skill-reviewer:optimizing-skill-frontmatter` over all eight over-budget SKILL.md files and fixed their descriptions to the three-part 200/80 format.
- Added `tests/plugins/test-no-orphan-plugin-dirs.sh` and `tests/plugins/test-description-budget.sh` as new objective tests, and bumped five plugins in `marketplace.json`.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/code-review/commands/fix-branch.md` | Command — agent review delegation migrated from `agent-reviewer` to `skill-reviewer` | Modified |
| `kit/plugins/code-review/README.md` | Plugin README — updated delegation sentence at line 89 | Modified |
| `kit/plugins/agent-creator/` | Dead plugin directory (5 files, 613 lines) | Deleted |
| `kit/plugins/agent-reviewer/` | Dead plugin directory (6 files, 1,208 lines) | Deleted |
| `kit/plugins/agentic-plugin-dev/` | Dead plugin directory (10 files, 1,026 lines) | Deleted |
| `kit/plugins/code-simplifier/` | Dead plugin directory (7 files, 798 lines) | Deleted |
| `kit/plugins/marketplace-builder/` | Dead plugin directory (7 files, 860 lines) | Deleted |
| `kit/plugins/react-perf-analyzer/` | Dead plugin directory (5 files, 949 lines) | Deleted |
| `README.md` | Repo README — breaking-change note, tree diagram, migration-table links | Modified |
| `.claude/rules/marketplace.md` | Authoring rules — retained-for-reference promise removed | Modified |
| `kit/plugins/skill-reviewer/commands/check-description.md` | Command — reconciled 160-char legacy target against real 200-char budget | Modified |
| `.claude-plugin/marketplace.json` | Marketplace — PATCH bumps for five touched plugins | Modified |
| `tests/plugins/test-no-orphan-plugin-dirs.sh` | Objective test — asserts kit/plugins/ directories equal manifest entries | Created |
| `tests/plugins/test-description-budget.sh` | Unit test — asserts 200/80 description budget across all SKILL.md files | Created |

## How it works

De-registering a plugin from `.claude-plugin/marketplace.json` stops distribution but not loading. The documented local-testing command read directories rather than the manifest, so all 19 plugin directories loaded — including the six de-registered ones. This produced duplicate skill names in every session (`0.1.0:agent-creator` competing with `plugin-dev:agent-creator`) and consumed description budget in every invocation.

The first step was migrating `code-review` off `agent-reviewer` before deleting anything, since `kit/plugins/code-review/commands/fix-branch.md:119` delegated agent-file reviews to it. The reference was repointed to `skill-reviewer`, the stated replacement in the v4.0.0 removal note. This was verified by confirming `grep -rn 'agent-reviewer' kit/plugins/code-review/` returns nothing.

With the live dependency cleared, `git rm -r` removed all six directories. The resulting `kit/plugins/` contains exactly 13 plugin directories plus `README.md`, and every remaining directory appears in `.claude-plugin/marketplace.json` — the invariant `test-no-orphan-plugin-dirs.sh` now enforces in CI.

Documentation corrections followed: `README.md`'s breaking-change note was rewritten (line 9 would otherwise assert the directories "are retained"), the tree diagram was updated, and dead relative links were removed from the migration table (names kept, links removed). `.claude/rules/marketplace.md` had its retained-for-reference promise deleted while keeping the do-not-re-add table intact.

For the description budget, the real rule is 200 chars total with the first sentence under 80. Eight files failed against this rule (all in surviving plugins). `/skill-reviewer:optimizing-skill-frontmatter` was run over each, letting the skill decide the rewrite and the `disable-model-invocation` value rather than hand-editing. Version bumps for the five touched plugins (`team-defaults`, `plan-agent`, `social-media-tools`, `git-agent`, `skill-reviewer`) and matching CHANGELOG entries ensured CI passed.

## How to use it

The changes are operational — no new user-facing commands or skills. The key behavioral change is that loading plugins locally now reads the manifest rather than directory names:

```bash
# Corrected loader (reads marketplace.json, not kit/plugins/ directory listing)
claude $(python3 -c "import json;print(' '.join('--plugin-dir kit/plugins/'+p['name'] for p in json.load(open('.claude-plugin/marketplace.json'))['plugins']))")
```

The new tests run as part of the CI suite:

```bash
bash tests/plugins/test-no-orphan-plugin-dirs.sh
bash tests/plugins/test-description-budget.sh
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `5764be8` | 2026-11-05 | fix(plan-agent): drop gallery tabs whose page does not exist (9.22.1) (#670) |
| `43d18ee` | 2026-10-31 | fix(plan-agent,social-media-tools): remove model pins from skills (9.22.0, 2.25.0) (#668) |
| `8a8a392` | 2026-10-31 | fix(git-agent): remove model pins from skills (4.25.0) (#667) |
| `58f14cd` | 2026-10-30 | feat(design-system-tools): add customize-design and align-design-md skills (0.3.0) (#666) |
| `cc28a20` | 2026-10-28 | fix(settings-sync): restore switches back to this machine's branch (1.3.1) (#665) |
| `2f8b101` | 2026-10-28 | fix(settings-sync): back up each machine to its own branch (1.3.0) (#662) |
| `174d0ef` | 2026-10-27 | fix(marketplace): resolve claude.ai plugin validation issues (#660) |
| `02136c1` | 2026-10-26 | fix(marketplace): drop bin/ wrappers so claude.ai installs all plugins (#658) |
| `86412c3` | 2026-10-26 | fix(git-agent): finish post-merge-cleanup inside an app session's worktree (4.23.1) (#657) |
| `82227d6` | 2026-10-20 | feat(mcp-tools): add plugin with fix-playwright-mcp skill (0.1.0) (#655) |
| `1c31569` | 2026-10-14 | fix: stop goal loops on blocked checks (plan-agent 9.19.2) (#652) |
| `c16fe83` | 2026-10-13 | feat(plan-agent): live UI previews inside plan pages (9.20.0) (#651) |
| `d9fdb0b` | 2026-10-10 | feat(git-agent-launcher): add the kit's first mod (0.1.0) (#648) |
| `052d88c` | 2026-10-08 | refactor(git-agent): commit-agent pushes without asking (4.23.0) (#646) |
| `daeaf31` | 2026-09-29 | docs: sync quick docs and changelog with eleven releases (#644) |
| `6a6cf33` | 2026-09-28 | feat(design-system-tools): add plugin with from-design-md skill (0.1.0) (#643) |
| `3056b57` | 2026-09-28 | fix: retire dated prompt patterns in plan-agent and git-agent (#641) |
| `417a957` | 2026-09-26 | feat(plan-agent): offer prototype and design canvas together in Step 8 (9.19.0) (#640) |
| `5e1b3c2` | 2026-09-26 | feat(git-agent): sync with the base branch before pushing (4.22.0) (#639) |
| `7a4214f` | 2026-09-26 | feat(memory-tools): implementing-insights publishes a live record per item (4.4.0) (#638) |

<!-- generated:end -->

## References

- Plan: [remove-dead-plugins-and-fix-frontmatter.md](plans/remove-dead-plugins-and-fix-frontmatter.md)

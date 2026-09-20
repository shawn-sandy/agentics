# Delete the six de-registered plugin directories and fix survivor frontmatter

> Six plugins were dropped from the marketplace in v4.0.0 but their directories stayed on disk, and because the local loader reads directories instead of the m...

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [remove-dead-plugins-and-fix-frontmatter.md](plans/remove-dead-plugins-and-fix-frontmatter.md)
**Type:** chore

## What shipped

- Migrate `code-review` off `agent-reviewer` before deleting anything: change `kit/plugins/code-review/commands/fix-bra...
- Delete the six directories with `git rm -r kit/plugins/{agent-creator,agent-reviewer,agentic-plugin-dev,code-simplifi...
- Correct `README.md` by rewriting line 9's breaking-change note to say the source was removed and is recoverable from...
- Update the Removed Plugins section of `.claude/rules/marketplace.md` so the notes for `agentic-plugin-dev` and `code-...
- Replace the `ls | xargs` loader one-liner in `CLAUDE.local.md` with a form that reads the manifest, such as `claude $...
- Run `/skill-reviewer:optimizing-skill-frontmatter` over all eight failing files — `team-defaults/sync-rules`, `plan-a...
- Reconcile the two budget numbers by either raising `check-description.md`'s threshold to 200 or rewording its message...
- Bump `version` in `.claude-plugin/marketplace.json` for every plugin whose SKILL.md step 5 touched (`team-defaults`,...

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/code-review/commands/fix-branch.md` | line 119 delegates agent review to skill-reviewer, not th... | Modified |
| `kit/plugins/code-review/README.md` | line 89 advertises the same delegation | Modified |
| `README.md` | breaking-change note, tree diagram, migration-table links | Modified |
| `.claude/rules/marketplace.md` | drop the retained-for-reference promise, keep the do-not-... | Modified |
| `CLAUDE.local.md` | gitignored; loader reads marketplace.json instead of ls | Modified |
| `kit/plugins/skill-reviewer/commands/check-description.md` | reconcile 160 against the real 200 budget | Modified |
| `.claude-plugin/marketplace.json` | PATCH bumps for every plugin whose SKILL.md changes | Modified |
| `tests/plugins/test-no-orphan-plugin-dirs.sh` | the objective-verification test | Created |
| `tests/plugins/test-description-budget.sh` | unit test for the 200/80 rule | Created |

## How it works

Remove the six plugin directories that v4.0.0 de-registered from the marketplace but left on disk, correct the three documentation sites that assert those directories are retained, and bring the surviving 13 plugins' SKILL.md frontmatter back inside the 200-char description budget by running the repo's own `skill-reviewer` tooling over itself.

`.claude-plugin/marketplace.json` lists 13 plugins. `kit/plugins/` contains 19 directories. The six extras — `agent-creator`, `agent-reviewer`, `agentic-plugin-dev`, `code-simplifier`, `marketplace-builder`, `react-perf-analyzer` — were removed from the marketplace on 2026-05-29 (see the removed-plugins table in `.claude/rules/marketplace.md`) and their source was retained "for reference". Retention has a cost that was not visible when the decision was made. De-registering a plugin stops *distri...

The implementation proceeded through these steps: Migrate `code-review` off `agent-reviewer` before deleting anything: change `kit/plugins/code-review/commands/fix-bra...; Delete the six directories with `git rm -r kit/plugins/{agent-creator,agent-reviewer,agentic-plugin-dev,code-simplifi...; Correct `README.md` by rewriting line 9's breaking-change note to say the source was removed and is recoverable from ...; Update the Removed Plugins section of `.claude/rules/marketplace.md` so the notes for `agentic-plugin-dev` and `code-...; Replace the `ls | xargs` loader one-liner in `CLAUDE.local.md` with a form that reads the manifest, such as `claude $....

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f6b0bdd` | 2026-08-17 | docs(plans): mark settings-sync guard next-step done in add-verification-gates ( |

<!-- generated:end -->

## References

- Plan: [remove-dead-plugins-and-fix-frontmatter.md](plans/remove-dead-plugins-and-fix-frontmatter.md)

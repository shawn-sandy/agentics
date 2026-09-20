# Give engineers a recap written for them

> The two existing recap commands both spend their space translating for non-engineers, which leaves no room for the code paths, tradeoffs, and test coverage a...

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [add-eng-recap-command.md](plans/add-eng-recap-command.md)
**Type:** feature

## What shipped

- Write `kit/plugins/artifact-tools/commands/eng-recap.md` with frontmatter (`description`, `allowed-tools: Skill, Bash...
- In the same file, add the **diff-read budget** under Source: read full hunks via `gh pr diff` for at most **20 files*...
- Extend `tests/plugins/test-artifact-tools.sh`: add `"commands/eng-recap.md": "eng-artifact-url"` to check 7's `owners...
- Confirm the new checks actually fail on a broken command file: temporarily change `eng-artifact-url` to `team-artifac...
- Bump `artifact-tools` to `1.7.0` in `.claude-plugin/marketplace.json`, extend its `description` to mention the engine...
- Update `kit/plugins/artifact-tools/README.md` in all four places it lists commands — the Commands table row, the Usag...

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/artifact-tools/commands/eng-recap.md` | the command file; framing overrides only, no new pipeline | Created |
| `tests/plugins/test-artifact-tools.sh` | extend checks 7 and 8, add a diff-cap check | Modified |
| `.claude-plugin/marketplace.json` | `artifact-tools` 1.6.0 → 1.7.0 and its description | Modified |
| `kit/plugins/artifact-tools/CHANGELOG.md` | `[1.7.0]` entry | Modified |
| `kit/plugins/artifact-tools/README.md` | Commands table, Usage block, Plugin Structure tree, `### ... | Modified |
| `CLAUDE.md` | the `artifact-tools` row in the reference-implementations... | Modified |

## How it works

Add `/artifact-tools:eng-recap` — the third recap command over the `session-artifact` pipeline (its fourth framing, counting the skill's own), written for the engineer who has to touch the code next — and register it across the marketplace, tests, and docs.

`artifact-tools` ships two recap commands over one pipeline: `product-doc` (stakeholders) and `team-recap` (whole team, mixed audience). Neither serves an engineering reader, because both are bound by a translate-for-non-engineers rule. `team-recap` states it outright: *"Lead every section with the

The implementation proceeded through these steps: Write `kit/plugins/artifact-tools/commands/eng-recap.md` with frontmatter (`description`, `allowed-tools: Skill, Bash...; In the same file, add the **diff-read budget** under Source: read full hunks via `gh pr diff` for at most **20 files*...; Extend `tests/plugins/test-artifact-tools.sh`: add `"commands/eng-recap.md": "eng-artifact-url"` to check 7's `owners...; Confirm the new checks actually fail on a broken command file: temporarily change `eng-artifact-url` to `team-artifac...; Bump `artifact-tools` to `1.7.0` in `.claude-plugin/marketplace.json`, extend its `description` to mention the engine....

- Verification step 4 (`claude --plugin-dir ./kit/plugins/artifact-tools`, confirm the command is listed) — verified by proxy, not directly. Launching an interactive Claude Code session was not available in this run, so the check was made structurally instead: all three command files under `commands

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f6b0bdd` | 2026-08-17 | docs(plans): mark settings-sync guard next-step done in add-verification-gates ( |

<!-- generated:end -->

## References

- Plan: [add-eng-recap-command.md](plans/add-eng-recap-command.md)

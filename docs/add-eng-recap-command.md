# Give engineers a recap written for them

> The two existing recap commands both spend their space translating for non-engineers, which leaves no room for the code paths, tradeoffs, and test coverage a...

<!-- generated:start -->

**Status:** Shipped 2026-08-17  **Plan:** [add-eng-recap-command.md](plans/add-eng-recap-command.md)
**Type:** feature

## What shipped

- Write `kit/plugins/artifact-tools/commands/eng-recap.md` with frontmatter (`description`, `allowed-tools: Skill, Bash`) and a body that overrides only framing: **Source** (session default; PR via `#n`/URL/`--pr n`, behind the same `gh auth status` + `git remote get-url origin | grep -qi 'github\.com'` preflight emitting `PR_MODE_OK`/`PR_MODE_UNAVAILABLE` before any `gh pr view`), **Audience** (assume the vocabulary; lead with the technical fact — the inverse of `team-recap`'s rule, stated as such), **Sections** (At a glance — a stat strip of changes shipped, files touched, decisions, and open items, plus two or three sentences on where the work landed; Architecture and code paths; Decisions with rationale; Tradeoffs and rejected options; Learnings; Tests and verification; Review follow-ups and tech debt; Files touched), **Visual requirements** and **Destination** (copied from `team-recap`: mermaid in `<pre class="mermaid">`, the SVG-inlining procedure, `save-artifact` handoff, stem `eng-recap` / `pr-<number>-eng`), and **Republish key** (`eng-artifact-url:` plus a "Never write" line naming `artifact-url:`, `product-artifact-url:`, and `team-artifact-url:`).
- In the same file, add the **diff-read budget** under Source: read full hunks via `gh pr diff` for at most **20 files**, fall back to `--name-only` for the remainder, and report how many files were summarized rather than read — commit bodies still lead for the *why*, hunks only supply the *what*.
- Extend `tests/plugins/test-artifact-tools.sh`: add `"commands/eng-recap.md": "eng-artifact-url"` to check 7's `owners` map, raise check 8's `assert found >= 2` to `>= 3` with a message naming all three PR-mode commands, and add a new check asserting `eng-recap.md` documents both a numeric diff cap and the `--name-only` fallback.
- Confirm the new checks actually fail on a broken command file: temporarily change `eng-artifact-url` to `team-artifact-url` in `eng-recap.md`, run the suite, confirm it FAILs on the key collision, then revert.
- Bump `artifact-tools` to `1.7.0` in `.claude-plugin/marketplace.json`, extend its `description` to mention the engineering recap, and add a `[1.7.0]` Added entry to `kit/plugins/artifact-tools/CHANGELOG.md` in Keep a Changelog form, naming the command, its sections, the `eng-artifact-url:` key, and the diff budget.
- Update `kit/plugins/artifact-tools/README.md` in all four places it lists commands — the Commands table row, the Usage block, the Plugin Structure tree comment, and a new `### eng-recap (command)` subsection after `### team-recap (command)` — then update the `artifact-tools` row in the root `CLAUDE.md` reference-implementations table.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/artifact-tools/commands/eng-recap.md` | the command file; framing overrides only, no new pipeline | Created |
| `tests/plugins/test-artifact-tools.sh` | extend checks 7 and 8, add a diff-cap check | Modified |
| `.claude-plugin/marketplace.json` | `artifact-tools` 1.6.0 → 1.7.0 and its description | Modified |
| `kit/plugins/artifact-tools/CHANGELOG.md` | `[1.7.0]` entry | Modified |
| `kit/plugins/artifact-tools/README.md` | Commands table, Usage block, Plugin Structure tree, `### eng-recap (command)` section | Modified |
| `CLAUDE.md` | the `artifact-tools` row in the reference-implementations table | Modified |

## How it works

Add `/artifact-tools:eng-recap` — the third recap command over the `session-artifact` pipeline (its fourth framing, counting the skill's own), written for the engineer who has to touch the code next — and register it across the marketplace, tests, and docs.

`artifact-tools` ships two recap commands over one pipeline: `product-doc` (stakeholders) and `team-recap` (whole team, mixed audience). Neither serves an engineering reader, because both are bound by a translate-for-non-engineers rule. `team-recap` states it outright: *"Lead every section with the plain-language statement, then the technical detail. Never the reverse."* That

The implementation proceeded through the following steps: Write `kit/plugins/artifact-tools/commands/eng-recap.md` with frontmatter (`description`, `allowed-tools: Skill, Bash`) and a body that overrides only framing: **Source** (session default; PR via `#n`/URL/`--pr n`, behind the same `gh auth status` + `git remote get-url origin | grep -qi 'github\.com'` preflight emitting `PR_MODE_OK`/`PR_MODE_UNAVAILABLE` before any `gh pr view`), **Audience** (assume the vocabulary; lead with the technical fact — the inverse of `team-recap`'s rule, stated as such), **Sections** (At a glance — a stat strip of changes shipped, files touched, decisions, and open items, plus two or three sentences on where the work landed; Architecture and code paths; Decisions with rationale; Tradeoffs and rejected options; Learnings; Tests and verification; Review follow-ups and tech debt; Files touched), **Visual requirements** and **Destination** (copied from `team-recap`: mermaid in `<pre class="mermaid">`, the SVG-inlining procedure, `save-artifact` handoff, stem `eng-recap` / `pr-<number>-eng`), and **Republish key** (`eng-artifact-url:` plus a "Never write" line naming `artifact-url:`, `product-artifact-url:`, and `team-artifact-url:`). Why: the value is entirely in the framing — re-implementing extraction, scrubbing, or publishing would fork a pipeline that already works. Verify: `head -6` shows a valid frontmatter block, and `grep -c 'eng-artifact-url' kit/plugins/artifact-tools/commands/eng-recap.md` returns at least 2.; In the same file, add the **diff-read budget** under Source: read full hunks via `gh pr diff` for at most **20 files**, fall back to `--name-only` for the remainder, and report how many files were summarized rather than read — commit bodies still lead for the *why*, hunks only supply the *what*. Why: this is the one place `eng-recap` departs from both siblings, and an uncapped diff read reintroduces exactly the context blowout `session-artifact` avoids by refusing to read the JSONL directly. Verify: the file states a numeric file cap and the `--name-only` fallback in the same section.; Extend `tests/plugins/test-artifact-tools.sh`: add `"commands/eng-recap.md": "eng-artifact-url"` to check 7's `owners` map, raise check 8's `assert found >= 2` to `>= 3` with a message naming all three PR-mode commands, and add a new check asserting `eng-recap.md` documents both a numeric diff cap and the `--name-only` fallback. Why: check 7 is the only thing standing between a copied-from-a-sibling command and a silent republish over a live page, and it is blind to any command absent from that map. Verify: `bash tests/plugins/test-artifact-tools.sh` prints PASS with a higher check count than before.; Confirm the new checks actually fail on a broken command file: temporarily change `eng-artifact-url` to `team-artifact-url` in `eng-recap.md`, run the suite, confirm it FAILs on the key collision, then revert. Why: a check that passes against a deliberately broken input is a tautology and proves nothing — this is the only step that establishes the test has teeth. Verify: the suite exits non-zero while broken and PASSes after the revert, with `git diff --stat kit/plugins/artifact-tools/commands/eng-recap.md` empty relative to step 2's state.; Bump `artifact-tools` to `1.7.0` in `.claude-plugin/marketplace.json`, extend its `description` to mention the engineering recap, and add a `[1.7.0]` Added entry to `kit/plugins/artifact-tools/CHANGELOG.md` in Keep a Changelog form, naming the command, its sections, the `eng-artifact-url:` key, and the diff budget. Why: a new command is a MINOR bump, and the smoke test cross-checks the marketplace version against the CHANGELOG's newest heading — they fail together if either is missed. Verify: `python3 -c "import json;print([p['version'] for p in json.load(open('.claude-plugin/marketplace.json'))['plugins'] if p['name']=='artifact-tools'])"` prints `['1.7.0']`, and `BASE_REF=main node scripts/check-plugin-versions.mjs` passes.; Update `kit/plugins/artifact-tools/README.md` in all four places it lists commands — the Commands table row, the Usage block, the Plugin Structure tree comment, and a new `### eng-recap (command)` subsection after `### team-recap (command)` — then update the `artifact-tools` row in the root `CLAUDE.md` reference-implementations table. Why: the README documents each command twice by design, and a command present in one place but not the other reads as an oversight to the next maintainer. Verify: `grep -c 'eng-recap' kit/plugins/artifact-tools/README.md` returns at least 4, and `grep -c 'eng-recap' CLAUDE.md` returns at least 1..

- Verification step 4 (`claude --plugin-dir ./kit/plugins/artifact-tools`, confirm the command is listed) — verified by proxy, not directly. Launching an interactive Claude Code session was not available in this run, so the check was made structurally instead: all three command files under `commands/` parse to valid frontmatter with a `description`, which is what plugin loading reads. Every acceptance criterion was verified directly; this one verification step was not.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `f6b0bdd` | 2026-08-17 | docs(plans): mark settings-sync guard next-step done in add-verification-gates (#573) |

<!-- generated:end -->

## References

- Plan: [add-eng-recap-command.md](plans/add-eng-recap-command.md)

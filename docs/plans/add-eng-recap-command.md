---
status: completed
type: feature
created: 2026-07-27
workflow: false
glance: The two existing recap commands both spend their space translating for non-engineers, which leaves no room for the code paths, tradeoffs, and test coverage a maintainer needs. This adds a third recap command that inverts that rule. We will know it worked when the artifact-tools smoke test passes with eng-recap in its republish-key map.
---

# Plan: Give engineers a recap written for them

## Objective

Add `/artifact-tools:eng-recap` — the third recap command over the
`session-artifact` pipeline (its fourth framing, counting the skill's own),
written for the engineer who has to touch the code next — and register it across
the marketplace, tests, and docs.

## Context

`artifact-tools` ships two recap commands over one pipeline: `product-doc`
(stakeholders) and `team-recap` (whole team, mixed audience). Neither serves an
engineering reader, because both are bound by a translate-for-non-engineers
rule. `team-recap` states it outright: *"Lead every section with the
plain-language statement, then the technical detail. Never the reverse."* That
rule is correct for its audience and is exactly what crowds out code paths,
invariants, and rejected tradeoffs.

Decision-complete proposal: `docs/proposals/add-eng-recap-command.md`. Its five
locked decisions are inputs to this plan, not open questions.

**Risk — republish-key collision.** All recap writers share one per-session
record under `{plansDirectory}/sessions/`, distinguished only by a frontmatter
key. A fourth writer that reuses a sibling's key silently republishes over that
sibling's live page. *Mitigation:* `eng-artifact-url:` is unique, the command
carries an explicit never-write warning naming the other three keys, and
Step 2 extends the existing test that enforces this.

**Risk — context blowout from the diff read.** Decision 4 has `eng-recap` read
diff hunks, which no sibling does. An uncapped `gh pr diff` on a large PR
consumes the context the recap itself needs. *Mitigation:* a documented
cap-and-summarize policy modelled on `diff-artifact`'s, asserted by a test.

## Files

- `kit/plugins/artifact-tools/commands/eng-recap.md` (new) — the command file; framing overrides only, no new pipeline
- `tests/plugins/test-artifact-tools.sh` (modified) — extend checks 7 and 8, add a diff-cap check
- `.claude-plugin/marketplace.json` (modified) — `artifact-tools` 1.6.0 → 1.7.0 and its description
- `kit/plugins/artifact-tools/CHANGELOG.md` (modified) — `[1.7.0]` entry
- `kit/plugins/artifact-tools/README.md` (modified) — Commands table, Usage block, Plugin Structure tree, `### eng-recap (command)` section
- `CLAUDE.md` (modified) — the `artifact-tools` row in the reference-implementations table

## Steps

1. [x] Write `kit/plugins/artifact-tools/commands/eng-recap.md` with frontmatter (`description`, `allowed-tools: Skill, Bash`) and a body that overrides only framing: **Source** (session default; PR via `#n`/URL/`--pr n`, behind the same `gh auth status` + `git remote get-url origin | grep -qi 'github\.com'` preflight emitting `PR_MODE_OK`/`PR_MODE_UNAVAILABLE` before any `gh pr view`), **Audience** (assume the vocabulary; lead with the technical fact — the inverse of `team-recap`'s rule, stated as such), **Sections** (At a glance — a stat strip of changes shipped, files touched, decisions, and open items, plus two or three sentences on where the work landed; Architecture and code paths; Decisions with rationale; Tradeoffs and rejected options; Learnings; Tests and verification; Review follow-ups and tech debt; Files touched), **Visual requirements** and **Destination** (copied from `team-recap`: mermaid in `<pre class="mermaid">`, the SVG-inlining procedure, `save-artifact` handoff, stem `eng-recap` / `pr-<number>-eng`), and **Republish key** (`eng-artifact-url:` plus a "Never write" line naming `artifact-url:`, `product-artifact-url:`, and `team-artifact-url:`). Why: the value is entirely in the framing — re-implementing extraction, scrubbing, or publishing would fork a pipeline that already works. Verify: `head -6` shows a valid frontmatter block, and `grep -c 'eng-artifact-url' kit/plugins/artifact-tools/commands/eng-recap.md` returns at least 2.
2. [x] In the same file, add the **diff-read budget** under Source: read full hunks via `gh pr diff` for at most **20 files**, fall back to `--name-only` for the remainder, and report how many files were summarized rather than read — commit bodies still lead for the *why*, hunks only supply the *what*. Why: this is the one place `eng-recap` departs from both siblings, and an uncapped diff read reintroduces exactly the context blowout `session-artifact` avoids by refusing to read the JSONL directly. Verify: the file states a numeric file cap and the `--name-only` fallback in the same section.
3. [x] Extend `tests/plugins/test-artifact-tools.sh`: add `"commands/eng-recap.md": "eng-artifact-url"` to check 7's `owners` map, raise check 8's `assert found >= 2` to `>= 3` with a message naming all three PR-mode commands, and add a new check asserting `eng-recap.md` documents both a numeric diff cap and the `--name-only` fallback. Why: check 7 is the only thing standing between a copied-from-a-sibling command and a silent republish over a live page, and it is blind to any command absent from that map. Verify: `bash tests/plugins/test-artifact-tools.sh` prints PASS with a higher check count than before.
4. [x] Confirm the new checks actually fail on a broken command file: temporarily change `eng-artifact-url` to `team-artifact-url` in `eng-recap.md`, run the suite, confirm it FAILs on the key collision, then revert. Why: a check that passes against a deliberately broken input is a tautology and proves nothing — this is the only step that establishes the test has teeth. Verify: the suite exits non-zero while broken and PASSes after the revert, with `git diff --stat kit/plugins/artifact-tools/commands/eng-recap.md` empty relative to step 2's state.
5. [x] Bump `artifact-tools` to `1.7.0` in `.claude-plugin/marketplace.json`, extend its `description` to mention the engineering recap, and add a `[1.7.0]` Added entry to `kit/plugins/artifact-tools/CHANGELOG.md` in Keep a Changelog form, naming the command, its sections, the `eng-artifact-url:` key, and the diff budget. Why: a new command is a MINOR bump, and the smoke test cross-checks the marketplace version against the CHANGELOG's newest heading — they fail together if either is missed. Verify: `python3 -c "import json;print([p['version'] for p in json.load(open('.claude-plugin/marketplace.json'))['plugins'] if p['name']=='artifact-tools'])"` prints `['1.7.0']`, and `BASE_REF=main node scripts/check-plugin-versions.mjs` passes.
6. [x] Update `kit/plugins/artifact-tools/README.md` in all four places it lists commands — the Commands table row, the Usage block, the Plugin Structure tree comment, and a new `### eng-recap (command)` subsection after `### team-recap (command)` — then update the `artifact-tools` row in the root `CLAUDE.md` reference-implementations table. Why: the README documents each command twice by design, and a command present in one place but not the other reads as an oversight to the next maintainer. Verify: `grep -c 'eng-recap' kit/plugins/artifact-tools/README.md` returns at least 4, and `grep -c 'eng-recap' CLAUDE.md` returns at least 1.

## Tests

Tier 1 — This plan changes application code (the plugin's command surface and its test suite).

- Objective: `/artifact-tools:eng-recap` exists as a complete, registered, collision-free command — the plan's stated objective. File: `tests/plugins/test-artifact-tools.sh`; Type: smoke; Asserts: `commands/eng-recap.md` exists with valid frontmatter, carries all eight agreed section headings, owns `eng-artifact-url` and warns against writing all three sibling keys, guards its `gh` calls behind the preflight, and documents the 20-file diff cap with its `--name-only` fallback; and that `artifact-tools` is registered at a version matching the CHANGELOG. Run: `bash tests/plugins/test-artifact-tools.sh`
- Integration: the republish-key map covers every command that writes to the shared session record, so no writer can collide with another. File: `tests/plugins/test-artifact-tools.sh`; Targets: check 7's `owners` map across `session-artifact/SKILL.md`, `product-doc.md`, `team-recap.md`, `eng-recap.md`; Key cases: each writer declares its own key; each sibling key it mentions sits under a never-write warning; a command whose key is swapped for a sibling's fails the check.
- Unit: the version guard agrees with the bump. File: `tests/publish/test-check-plugin-versions.mjs`; Targets: `scripts/check-plugin-versions.mjs`; Key cases: `artifact-tools` at 1.7.0 is accepted against a 1.6.0 base; an unbumped 1.6.0 is rejected.

## Acceptance Criteria

- [x] `kit/plugins/artifact-tools/commands/eng-recap.md` exists with valid YAML frontmatter carrying a `description` and `allowed-tools`
- [x] The command's audience section explicitly inverts `team-recap`'s plain-language-first rule rather than restating it
- [x] All eight agreed sections are present: At a glance, Architecture and code paths, Decisions, Tradeoffs and rejected options, Learnings, Tests and verification, Review follow-ups and tech debt, Files touched
- [x] Tradeoffs and Learnings are distinguished in the command's own wording — decisions weighed versus dead ends walked — so an author cannot collapse one into the other
- [x] The command declares `eng-artifact-url:` and carries a never-write warning naming `artifact-url:`, `product-artifact-url:`, and `team-artifact-url:`
- [x] PR mode is guarded by the `gh auth status` + github.com-remote preflight, which appears before the first `gh pr view`
- [x] The diff read states a numeric file cap and a `--name-only` fallback, and requires reporting how many files were summarized
- [x] `bash tests/plugins/test-artifact-tools.sh` passes, and fails when `eng-recap.md`'s key is swapped for a sibling's
- [x] `artifact-tools` is at `1.7.0` in `marketplace.json` with a matching `[1.7.0]` CHANGELOG entry
- [x] `eng-recap` appears in the README's Commands table, Usage block, Structure tree, and its own Components subsection, and in the root `CLAUDE.md` plugin table

## Completion Report

- Verification step 4 (`claude --plugin-dir ./kit/plugins/artifact-tools`, confirm the command is listed) — verified by proxy, not directly. Launching an interactive Claude Code session was not available in this run, so the check was made structurally instead: all three command files under `commands/` parse to valid frontmatter with a `description`, which is what plugin loading reads. Every acceptance criterion was verified directly; this one verification step was not.

## Verification

End-to-end, in order:

1. `bash tests/plugins/test-artifact-tools.sh` — PASSes, with a check count higher than the pre-change run.
2. `BASE_REF=main node scripts/check-plugin-versions.mjs` — passes, confirming the bump is visible to the guard that gates merges.
3. Break it deliberately: swap `eng-artifact-url` for `team-artifact-url` in `eng-recap.md` and re-run the suite. It must FAIL on the key collision. Revert. This is the step that proves the new coverage is real rather than decorative.
4. Load the plugin (`claude --plugin-dir ./kit/plugins/artifact-tools`) and confirm `/artifact-tools:eng-recap` is listed alongside `/artifact-tools:product-doc` and `/artifact-tools:team-recap`.
5. Read `eng-recap.md` end-to-end against `team-recap.md` and confirm it overrides framing only — no duplicated transcript extraction, scrub gate, or publish logic.

## Next Steps

- Wire the artifact-tools smoke test into CI — it currently runs nowhere
  `tests/plugins/test-artifact-tools.sh` is not referenced by any workflow in
  `.github/workflows/`, so its checks only run when invoked by hand. Found while
  planning this change; out of scope here because it alters CI for the whole repo.
  ```text
  tests/plugins/test-artifact-tools.sh is not referenced by any workflow in .github/workflows/, so it never runs in CI. Other plugin smoke tests (test-artifact-titles.mjs, test-save-artifact.sh, test-build-skill.sh) are wired into publish-dist.yml or check-plugin-versions.yml. Audit tests/plugins/ and tests/publish/ for every test file that is not referenced by any workflow, then add the missing ones to the appropriate workflow, matching the existing step style. Report which tests were unwired before your change.
  ```

- Factor the shared recap contract out of the three command files
  `product-doc`, `team-recap`, and `eng-recap` will each restate the same PR
  preflight, `save-artifact` destination flow, and republish-key discipline.
  Worth extracting once there are three copies, not before.
  ```text
  In kit/plugins/artifact-tools/, the commands product-doc.md, team-recap.md, and eng-recap.md each restate the same three contracts: the gh/GitHub-remote PR preflight, the save-artifact destination flow with its collision-safe local fallback, and the shared-session-record republish-key discipline. Evaluate extracting these into a references/ file that each command links to, in the style of references/titles.md which the skills already share. Weigh the cost: a command file that defers to a reference is harder to follow in one read, and progressive disclosure means the model may not load the reference. Recommend whether to extract or leave duplicated, with reasoning. Do not implement without approval.
  ```

## Resources

- `docs/proposals/add-eng-recap-command.md` — the decision-complete proposal this plan executes; its Locked Decisions table is the authority for the five choices made here
- `kit/plugins/artifact-tools/commands/team-recap.md` — the structural template; its Visual requirements and Destination sections are copied nearly verbatim
- `kit/plugins/artifact-tools/commands/product-doc.md` — the lighter sibling; source of the PR preflight pattern
- `tests/plugins/test-artifact-tools.sh` — checks 7 and 8 are the extension points; check 7's non-tautological structure is the pattern to preserve
- `kit/plugins/artifact-tools/skills/diff-artifact/SKILL.md` (lines 107–151) — the cap-and-summarize policy the diff budget is modelled on

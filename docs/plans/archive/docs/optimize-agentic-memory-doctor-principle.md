---
status: completed
type: docs
created: 2026-05-20
---

# Plan: Teach `agentic-memory-doctor` what "optimize" means

## Context

The `agentic-memory-doctor` skill audits and rewrites `CLAUDE.md` files
against six scored dimensions, then offers an optimized version (Steps 5–6).
Today the skill is precise about *what* the audit measures but silent on the
underlying *principle* of what makes a rule worth keeping during the
optimization rewrite. The transformation list in Step 5 only tells the
model to: redact secrets, extract 80%-rule violations, condense padding,
and add missing section stubs.

The user wants the skill to explicitly encode a single guiding principle:

> **Optimizing means keeping only rules that would change Claude's behavior
> versus its built-in defaults, and tightening language so the load-bearing
> rules read crisply.**

Without this, the skill tends to preserve rules that merely restate Claude's
defaults ("write clear code", "add tests for new features", "be concise"),
which inflates the instruction count without changing model behavior — the
exact failure mode Dimensions 1 and 5 are trying to prevent.

## Objective

Land the "behavior-changing rules only + crisp load-bearing language"
principle in three places: a one-line definition near the top of `SKILL.md`,
a new hygiene item in Dimension 5, and two new transformation bullets in
Step 5. Bump the plugin to **3.1.0** (MINOR — new behavior added to an
existing skill, no breaking changes).

## Files to Modify

- [`kit/plugins/memory-tools/skills/agentic-memory-doctor/SKILL.md`](../../kit/plugins/memory-tools/skills/agentic-memory-doctor/SKILL.md)
  — add principle + transformation bullets
- [`kit/plugins/memory-tools/skills/agentic-memory-doctor/references/audit-steps.md`](../../kit/plugins/memory-tools/skills/agentic-memory-doctor/references/audit-steps.md)
  — add hygiene item to Dimension 5
- [`.claude-plugin/marketplace.json`](../../.claude-plugin/marketplace.json)
  — bump `memory-tools` version `3.0.0` → `3.1.0`
- [`kit/plugins/memory-tools/CHANGELOG.md`](../../kit/plugins/memory-tools/CHANGELOG.md)
  — add 3.1.0 entry
- Plan file rename: `kit-plugins-memory-tools-skills-agentic-enchanted-cray.md`
  → `optimize-agentic-memory-doctor-principle.md`

## Steps

1. **Add an "Optimization principle" block under the title in `SKILL.md`** —
   directly after the one-line description on line 7, insert a blockquote that
   states the principle verbatim plus a one-sentence gloss explaining that
   it governs both the audit *and* the rewrite phases.
   - *Why:* Sets the lens for every later step. The principle is short
     enough to read inline and load-bearing enough that it should not be
     buried in `references/`.
   - *Verify:* Re-read `SKILL.md`; the principle appears between the
     description (line 7) and the existing operational-rules blockquote
     (line 9+), and it names both "behavior change vs. built-in defaults"
     and "crisp load-bearing language."

2. **Add a 4th item to Dimension 5 (Safety and Hygiene) in
   `references/audit-steps.md`** — labeled "Default-restating rules":
   instructions that merely restate Claude's built-in behavior (write tests,
   use clear names, prefer composition, avoid magic numbers, etc.). Keep
   the existing "0 / 1 / 2+ issues = 2 / 1 / 0" scale unchanged — a fourth
   category is added but the tiering is not rebalanced (decided by the
   user; the harsher scoring is intentional because default-restating
   rules are the most common bloat source).
   - *Why:* This is the audit-side teeth behind the principle. Without it,
     the optimizer can flag default-restating rules in the rewrite but the
     scored report never penalises them — so the user has no signal that
     the file is bloated by no-op rules.
   - *Verify:* Re-read Dimension 5 in `audit-steps.md`; it now lists four
     hygiene items (Secrets, Linter-replaceable, Inferable, Default-
     restating) with concrete examples for the new item, and the scoring
     table is still consistent.

3. **Add two transformation bullets to Step 5 of `SKILL.md`** —
   directly under the existing four transformation bullets:
   - "Cut rules that only restate Claude's built-in behavior — keep only
     rules that would change what Claude does by default."
   - "Tighten kept rules to crisp imperatives — one rule per bullet, verb-
     first, no hedging or padding. Preserve the user's intent and any
     constraint they specifically called out."
   - *Why:* This is the optimization-side teeth. The transformation list is
     what the model actually applies when it rewrites the file in-chat in
     Step 5; the principle must appear here or it will not influence the
     output.
   - *Verify:* Re-read Step 5; the transformation list has six bullets
     instead of four, the two new bullets are phrased as imperatives, and
     they appear before the "Do not invent new content" guardrail.

4. **Cross-link the principle from Step 4's "Per-dimension findings"
   guidance** — when Dimension 5 scores below 2 because of default-
   restating rules, the findings bullet should call them out by name.
   Add a one-line note under the existing
   "Progressive Disclosure" callout in Step 4 of `SKILL.md`.
   - *Why:* Closes the loop so the user sees the same vocabulary
     ("default-restating") in the audit report and the optimized rewrite.
     Without this, a low Dimension 5 score and the Step 5 transformation
     list use different words for the same problem.
   - *Verify:* Re-read Step 4; after the Progressive Disclosure callout
     there is a parallel callout instructing the model to name "default-
     restating rules" explicitly when they drove the Dimension 5 deduction.

5. **Bump `memory-tools` version `3.0.0` → `3.1.0` in
   `.claude-plugin/marketplace.json` and add a `[3.1.0]` entry to
   `kit/plugins/memory-tools/CHANGELOG.md`** —
   conventional `feat(kit/plugins/memory-tools): bump version to 3.1.0`
   per `.claude/rules/marketplace.md`.
   - *Why:* New behavior added to an existing skill (extra audit item,
     extra transformation bullets) is a MINOR bump per project convention.
     No skill/command renames, so no MAJOR bump needed; no `plugin.json`
     `version` edit required (versions live only in `marketplace.json`
     for relative-path plugins).
   - *Verify:* `grep '"version": "3.1.0"' .claude-plugin/marketplace.json`
     returns the memory-tools entry; `CHANGELOG.md` has a `## [3.1.0]`
     block dated 2026-05-20 summarising the principle, new hygiene item,
     and new transformation bullets.

6. **Rename the plan file** —
   `docs/plans/kit-plugins-memory-tools-skills-agentic-enchanted-cray.md`
   → `docs/plans/optimize-agentic-memory-doctor-principle.md`, then commit
   all five files (plan + four skill/manifest files) together per
   `CLAUDE.md` ("Always include the plan file in commits for plugin
   changes").
   - *Why:* Plan filename must match content per
     [`plan-mode.md`](../../../../.claude/rules/plan-mode.md), and
     project convention bundles plan + plugin change in one commit.
   - *Verify:* `git status` shows the rename plus four modified files
     staged together; commit message follows
     `feat(kit/plugins/memory-tools): …`.

## Acceptance Criteria

- [ ] `SKILL.md` states the optimization principle (behavior-changing rules
      only + crisp language) in a single readable block near the top.
- [ ] Dimension 5 in `audit-steps.md` lists "Default-restating rules" as a
      named hygiene item with at least two concrete examples.
- [ ] Step 5 of `SKILL.md` includes the two new transformation bullets,
      phrased as verb-first imperatives.
- [ ] Step 4 of `SKILL.md` instructs the model to name "default-restating
      rules" by phrase when reporting a Dimension 5 deduction.
- [ ] `memory-tools` version is `3.1.0` in `marketplace.json`, with a
      matching `CHANGELOG.md` entry dated 2026-05-20.
- [ ] All five files commit together with a conventional `feat(...)`
      message; plan file is renamed before the commit.
- [ ] Existing behavior is unchanged for files that have no default-
      restating rules (no regressions to the scoring of clean files).

## Verification

1. **Read-through** — open the modified `SKILL.md` end to end and
   confirm the principle is referenced in Steps 4 and 5 with consistent
   vocabulary ("default-restating rules", "crisp load-bearing language").
2. **Self-audit** — run the skill against a synthetic `CLAUDE.md`
   containing one obvious default-restating rule (e.g., "Always write
   tests for new functionality" with no project-specific qualifier).
   Expect: Dimension 5 scores ≤ 1, the per-dimension finding names the
   rule, and the optimized rewrite in Step 5 either drops the rule or
   replaces it with a project-specific version.
3. **Regression check** — run the skill against a clean `CLAUDE.md` (a
   recent commit of this repo's own `CLAUDE.md` is a fine sample). Expect:
   the score is unchanged from a pre-change baseline (Dimension 5 still
   scores 2 if there were no default-restating rules), and the Step 5
   rewrite preserves all behavior-changing rules verbatim.
4. **Marketplace sanity** — `claude --plugin-dir
   ~/devbox/agentics/kit/plugins/memory-tools` loads cleanly; the auto-
   validator on `.claude/settings.json` does not flag a JSON error in
   `marketplace.json` after the version bump.

## Next Steps *(optional)*

- **Backfill the principle into `path-rules-advisor`**:
  ```text
  Look at kit/plugins/memory-tools/skills/path-rules-advisor/SKILL.md.
  Decide whether the "behavior-changing rules only + crisp language"
  principle (now in agentic-memory-doctor's SKILL.md) also belongs in
  path-rules-advisor — rules extracted into .claude/rules/*.md are
  subject to the same bloat failure mode. If yes, propose a minimal
  insertion location and wording that mirrors the agentic-memory-doctor
  treatment. Do not edit yet — return a recommendation.
  ```

- **Add an eval fixture for default-restating rules**:
  ```text
  Add a fixture file under tests/fixtures/ representing a CLAUDE.md
  whose only problems are default-restating rules (no secrets, no 80%
  violations, no missing sections). Use it to validate that
  agentic-memory-doctor's Dimension 5 now scores it ≤ 1 and that the
  per-dimension finding names the rules by phrase. Keep the fixture
  small (≤ 30 lines).
  ```


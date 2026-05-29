---
status: completed
modified: 2026-05-28
type: refactor
created: 2026-05-28
repo-name: agentics
---

# Plan: Lower optimizing-skill-frontmatter default target to ≤200 chars

## Context

The `optimizing-skill-frontmatter` skill rewrites SKILL.md `description:` fields
to a three-part format and currently targets **≤256 chars total**. That target
was introduced yesterday (skill-reviewer v2.2.0, 2026-05-27) and was sized for
**≤31 installed skills** (8,000-char default listing budget ÷ 256 ≈ 31).

The agentics marketplace now has **45 canonical skills**. At 45 skills the safe
average is **~177 chars** (8,000 ÷ 45), but the skill keeps producing
descriptions up to 256 — and nearly every current description sits at 180–246
chars. Summed, they overflow the ~8,000-char budget, so Claude Code is likely
truncating or dropping descriptions. In short: the descriptions aren't too long
in the abstract, they're too long *for this install footprint*, because Rule 1
hardcodes a ceiling sized for a much smaller marketplace.

The user chose a **fixed ≤200 default** (down from 256) — a pragmatic middle
ground that keeps the three-part format viable while pulling totals back toward
budget. (Strictly, 45 × 200 = 9,000 is still marginally over 8,000; the existing
Budget advisory already tells users to raise `skillListingBudgetFraction` to
0.02 if `/doctor` reports overflow, so that escape hatch stays in place.)

Two existing problems get fixed in the same pass:
1. The skill is **internally inconsistent** — Step 2's skip rule uses ≤256 while
   Step 6's status logic uses ≤160. Retargeting to 200 lets both agree.
2. The project convention rule (`plugin-patterns.md`) and the skill-reviewer
   `marketplace.json` description still say 256 — they must move to 200 too, or
   the repo contradicts itself.

**Scope:** the skill's rules + its supporting docs only. The 45 existing skill
descriptions are intentionally **not** re-optimized now — they get shortened the
next time the skill runs (the user's "update skill rules only" choice). The
short-description sub-limit (**≤80 chars**, the truncation-survival guarantee)
stays unchanged.

## Objective

Change the default total-length target in `optimizing-skill-frontmatter` from
≤256 to ≤200 chars everywhere it appears, unify the Step 2 / Step 6 thresholds
on 200, refresh the budget math/advisory, and sync the two downstream
references (`plugin-patterns.md`, `marketplace.json`) plus a version bump and
CHANGELOG entry.

## Files to modify

- `kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/SKILL.md` — the skill (primary).
- `.claude/rules/plugin-patterns.md` — convention rule, line ~92.
- `.claude-plugin/marketplace.json` — skill-reviewer version + description.
- `kit/plugins/skill-reviewer/CHANGELOG.md` — new release entry.

## Steps

1. **Retarget the skill's hard limits 256 → 200, and unify Step 6 with Step 2.**
   In `optimizing-skill-frontmatter/SKILL.md`, change every *active target* from
   256 to 200: Overview (line 10), Rule 1 heading + body (104, 106), Rule 2b
   overflow clause (134), Step 2 skip rule (88 — `≤256`→`≤200` and `>256`→`>200`),
   Step 5 verify (327). In Step 6, change the status thresholds from 160 to 200:
   `REWRITE — >160`→`>200`, `SKIP — ≤160`→`≤200`, `Optimize all over 160`→`over 200`
   (349, 350, 353). Leave the `≤80` short-description sub-limit untouched everywhere.
   - *Why:* This is the behavioural core — it lowers the ceiling and resolves the
     pre-existing Step 2 (256) vs Step 6 (160) contradiction by landing both on 200.
   - *Verify:* `grep -n "256" SKILL.md` returns only historical/advisory mentions
     (none as an active REWRITE/SKIP/verify target); `grep -n "160" SKILL.md`
     shows 160 only in the advisory table's "~50 skills" row and the legacy note,
     never in Step 2/5/6 thresholds.

2. **Recompute the budget-math prose and advisory table.**
   Update the derivation text: Overview bullet (17) `8,000 ÷ 256 ≈ 31`→`8,000 ÷ 200 = 40`;
   the "practical target" line (20) `256 is a practical target`→`200 is a practical target`;
   Rule 1 explanation (108) `256-char total target fits ... ~31 skills`→`200-char total target fits ... ~40 skills`;
   advisory table top row (374) `| ≤31 | ~256 chars |`→`| ≤40 | ~200 chars |`;
   skip-advisory condition (390) `count is ≤31 and ... ≤256`→`count is ≤40 and ... ≤200`.
   Keep the `~50 → ~160` and `~100 → ~80` advisory rows and the `≤160` legacy note
   (18) as-is — they remain valid tiers.
   - *Why:* The math must stay honest and self-consistent after the retarget;
     ~40 is the integer fit for a 200-char budget against 8,000 chars.
   - *Verify:* Read the Overview and advisory table — every figure ties out
     (200 → 40 skills); no `÷ 256` arithmetic remains.

3. **Fix the skill's own frontmatter + Worked Example B parentheticals.**
   Line 3 frontmatter description and its echo at line 210: `three-part format (≤256 chars)`→`(≤200 chars)`.
   Rule 2 capability *example* (115) `(≤256 chars)`→`(≤200 chars)`.
   Worked Example B "After" block (210) and its check line (217): `≤256`→`≤200`,
   and `188 ≤256 ✓`→`188 ≤200 ✓` (188 still passes ≤200, so the example stays valid).
   - *Why:* The skill should model its own rule; a 256 in its own description or
     examples would directly contradict the new target.
   - *Verify:* `grep -m1 "^description:" SKILL.md` shows `(≤200 chars)`; the
     skill's own description is still ≤200 (currently 187) and ≤80 short; Example
     B's stated char count is ≤200.

4. **Sync the project convention rule.**
   In `.claude/rules/plugin-patterns.md` (~line 92), change `Total budget: ≤256 chars.`
   → `Total budget: ≤200 chars.`
   - *Why:* This bullet is the authoritative convention other skills/authors read;
     leaving it at 256 would contradict the retargeted skill.
   - *Verify:* `grep -n "Total budget" .claude/rules/plugin-patterns.md` shows ≤200.

5. **Bump version, sync marketplace description, add CHANGELOG entry.**
   In `.claude-plugin/marketplace.json`: bump skill-reviewer `2.2.0`→`2.2.1`, and
   update its `description` string so any `256` reference reads `200`. In
   `kit/plugins/skill-reviewer/CHANGELOG.md`: add a `## [2.2.1] - 2026-05-28`
   section under `### Changed` noting the default target dropped 256→200 and the
   Step 2/Step 6 threshold unification. PATCH bump (refines an existing rule's
   value — no new/removed component, no activation-behaviour change).
   - *Why:* Repo convention requires marketplace version + CHANGELOG to move
     together with behaviour changes; the marketplace description must not
     advertise a stale 256 target.
   - *Verify:* `python3 -c "import json; ..."` confirms skill-reviewer version is
     `2.2.1` and JSON parses; CHANGELOG top entry is `[2.2.1] - 2026-05-28`; the
     `.claude/settings.json` post-write marketplace.json validation passes.

## Acceptance Criteria

- [ ] No active REWRITE/SKIP/verify threshold in `optimizing-skill-frontmatter/SKILL.md` references 256; the default total target is ≤200.
- [ ] Step 2 (skip rule) and Step 6 (status logic) both use the same ≤200 threshold — the prior 256/160 split is gone.
- [ ] The ≤80 short-description sub-limit is unchanged in every location.
- [ ] Budget math reads consistently: 200 → ~40 skills (8,000 ÷ 200 = 40); advisory table top row is `≤40 | ~200 chars`.
- [ ] The skill's own frontmatter description still parses, is ≤200 total and ≤80 short, and references `(≤200 chars)`.
- [ ] `plugin-patterns.md` "Total budget" reads ≤200; `marketplace.json` skill-reviewer entry is v2.2.1 with no stale 256; CHANGELOG has a `[2.2.1] - 2026-05-28` entry.
- [ ] The 45 existing skill descriptions are NOT modified by this plan.

## Verification

1. Static grep audit on the skill:
   ```bash
   cd ~/devbox/agentics
   f=kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/SKILL.md
   grep -n "256" "$f"   # expect: none as active targets
   grep -n "200" "$f"   # expect: Overview, Rule 1, Step 2, Step 5, Step 6, advisory
   grep -n "≤80\|80 chars" "$f"  # expect: short-desc limit intact
   ```
2. Cross-file consistency:
   ```bash
   grep -n "Total budget" .claude/rules/plugin-patterns.md   # ≤200
   python3 -c "import json; m=json.load(open('.claude-plugin/marketplace.json')); \
     p=[x for x in m['plugins'] if x['name']=='skill-reviewer'][0]; \
     print(p['version']); assert '256' not in p['description']"
   head -12 kit/plugins/skill-reviewer/CHANGELOG.md   # [2.2.1] - 2026-05-28
   ```
3. End-to-end dry run (manual, optional): invoke
   `/skill-reviewer:optimizing-skill-frontmatter` on a single skill and confirm
   it now reports the REWRITE/SKIP boundary at 200, not 256, and that a 230-char
   description is flagged REWRITE where it previously would have been SKIP.

## Next Steps *(optional)*

- Re-optimize the 45 existing descriptions to the new ≤200 target (the deferred half of this work):
  ```text
  Run /skill-reviewer:optimizing-skill-frontmatter on all SKILL.md files in the
  agentics marketplace (kit/plugins/*/skills/*/SKILL.md plus .claude/skills/*).
  The default total target is now ≤200 chars (short description ≤80). Rewrite
  every description currently over 200 chars down to ≤200 while keeping all three
  parts (short description, capability sentence, "Use when…" trigger). Report a
  before/after char-count table and the new summed total against the ~8,000-char
  listing budget.
  ```

- Fix the dangling reference discovered during planning:
  ```text
  optimizing-skill-frontmatter/SKILL.md line 12 cites
  references/best-practices.md (Pattern 1), but that skill's references/ directory
  is empty. Either create references/best-practices.md documenting the three-part
  format and Pattern 1, or remove the citation from the Overview. Recommend one
  and apply it.
  ```

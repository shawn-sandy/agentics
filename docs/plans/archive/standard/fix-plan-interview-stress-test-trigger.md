---
status: in-progress
created: 2026-04-20
---

# Plan: Fix `plan-interview` skill "stress test" trigger

## Context

The `plan-interview` skill (v1.14.1) description uses only the hyphenated
form `stress-test`. When users type the natural phrasing "stress test plan"
(with a space), the skill sometimes fails to activate because the description
doesn't surface the unhyphenated form. The README's own example phrase is
"Stress-test this plan", but in practice users drop the hyphen.

The sibling skill `deep-grill` already mentions "stress-test individual
decisions" and `plan-status` explicitly excludes stress-testing, so the
canonical trigger needs to be strengthened on `plan-interview` itself.

## Steps

1. Update `kit/plugins/plan-interview/skills/plan-interview/SKILL.md`
   description to include the space form ("stress test") and "interview"
   alongside the existing keywords.
2. Bump `plan-interview` version from `1.14.1` to `1.14.2` in
   `.claude-plugin/marketplace.json`.
3. Add a `[1.14.2]` entry to
   `kit/plugins/plan-interview/CHANGELOG.md`.
4. Commit with `fix(kit/plugins/plan-interview): …` and push to
   `claude/fix-stress-test-trigger-ojaCM`.

## Critical Files

- `kit/plugins/plan-interview/skills/plan-interview/SKILL.md`
- `.claude-plugin/marketplace.json`
- `kit/plugins/plan-interview/CHANGELOG.md`

## Verification

- `grep -n "stress test" kit/plugins/plan-interview/skills/plan-interview/SKILL.md`
  returns the new description line.
- `marketplace.json` parses as valid JSON (enforced by hook).
- CHANGELOG entry matches the bumped version.

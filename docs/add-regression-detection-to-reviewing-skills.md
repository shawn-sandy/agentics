# Add Regression & Breaking-Change Detection to `reviewing-skills`

> Adds an optional Step 2c to the `skill-reviewer` skill that compares the current SKILL.md against its last git-committed version and reports breaking changes and regressions separately from the quality score.

<!-- generated:start -->

**Status:** Shipped 2026-03-03   **Plan:** [add-regression-detection-to-reviewing-skills.md](plans/add-regression-detection-to-reviewing-skills.md)   **Type:** feature

## What shipped

- **Step 2c: Regression Risk Check** added to `kit/plugins/skill-reviewer/skills/reviewing-skills/SKILL.md` — optional git-based comparison with graceful skip conditions.
- Comparison matrix with 6 classified fields: `name:` change (BREAKING), trigger phrase removal (BREAKING), activation intent shift (WARNING), reference file removal (WARNING), >30% line reduction (WARNING), new anti-patterns introduced (INFO).
- Regression Risk section appended to audit report after the Scores table and before the Grade line — does not affect the 1–10 quality score.
- Quick Reference Checklist updated with a Regression Risk block (6 items).
- `references/audit-steps.md` updated with the full comparison matrix and three report template variants (Skipped / Clean / Findings).
- BREAKING findings trigger a warning note before the Step 5 optimized-version offer without suppressing it.
- `skill-reviewer` plugin bumped from `1.2.0` → `1.3.0`.

> See [CHANGELOG §1.3.0](../kit/plugins/skill-reviewer/CHANGELOG.md#130---2026-03-03) for the authoritative feature list.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/skill-reviewer/skills/reviewing-skills/SKILL.md` | Skill instructions — reviewing-skills | Modified |
| `kit/plugins/skill-reviewer/skills/reviewing-skills/references/audit-steps.md` | Audit workflow detail + report templates | Modified |
| `kit/plugins/skill-reviewer/skills/reviewing-skills/references/best-practices.md` | Best practices reference | Modified |
| `kit/plugins/skill-reviewer/README.md` | Plugin documentation | Modified |
| `kit/plugins/skill-reviewer/CHANGELOG.md` | Plugin changelog | Modified |
| `.claude-plugin/marketplace.json` | Marketplace registry — version bump 1.2.0 → 1.3.0 | Modified |

## How it works

Step 2c runs only when all skip conditions are clear: the directory is a git repo (`git rev-parse --git-dir` returns zero), the SKILL.md has at least one commit (`git log --oneline -1 -- <path>` returns output), and the user hasn't opted out. When any condition applies, the Regression Risk line in the report reads "Skipped — [reason]" and the section is otherwise absent.

When not skipped, the step resolves the git-relative path via `git ls-files --full-name` and retrieves the previous version via `git show HEAD:<path>`. If this fails (renamed file, shallow clone), the step notes "No previous version found — file may have been renamed" and stops without attempting `git log --follow`.

The six comparison points were calibrated against real-world SKILL.md regressions. `name:` and trigger phrase changes are BREAKING because they directly break invocation and activation. Activation intent is a WARNING (not BREAKING) because description rewrites that preserve intent are legitimate refactors. Reference file removal is a WARNING because missing reference files break progressive disclosure. The 30% line-reduction threshold catches accidental content loss without flagging targeted edits. Anti-pattern introduction is INFO only — useful signal but no immediate user impact.

Multi-line YAML `description:` values (folded YAML) are handled by collecting continuation lines until the next top-level key. Reference file detection uses the pattern `` `?references/[^\s`]+\.md`? `` to match both bare and backtick-quoted paths.

## How to use it

Step 2c fires automatically on every `reviewing-skills` invocation when conditions are met. To skip explicitly:

```
/skill-reviewer:reviewing-skills kit/plugins/my-plugin/skills/my-skill/SKILL.md --skip-regression
```

Or say "skip regression check" in your message. The audit report will include:

```markdown
## Regression Risk

| Risk | Field / Metric | Previous | Current | Impact |
|------|----------------|----------|---------|--------|
| BREAKING | `name:` | `old-name` | `new-name` | Invocation references break |

**Summary:** BREAKING: 1 | Warnings: 0 | Info: 0
> Regression Risk findings are informational and do not affect the 1–10 quality score.
```

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `9c70a52` | 2026-03-30 | chore(docs/plans): add YAML frontmatter status to 83 plan files |
| `e15fba2` | 2026-04-04 | refactor: rename agentics/ marketplace subtree to kit/ |
| `9924d3f` | 2026-04-09 | refactor(kit/plugins): trim allowed-tools to only tools each skill actually uses |

<!-- generated:end -->

## References

- Plan: [add-regression-detection-to-reviewing-skills.md](plans/add-regression-detection-to-reviewing-skills.md)
- Changelog: [CHANGELOG §1.3.0](../kit/plugins/skill-reviewer/CHANGELOG.md#130---2026-03-03)

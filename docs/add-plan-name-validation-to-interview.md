# Add Plan Name Validation to plan-interview Plugin

> Extends the plan-interview skill and command to validate that plan filenames and H1 headings are descriptive and aligned with the plan's content, surfacing suggestions for random or generic names.

<!-- generated:start -->

**Status:** Shipped 2026-02-26   **Plan:** [add-plan-name-validation-to-interview.md](plans/add-plan-name-validation-to-interview.md)   **Type:** feature

## What shipped

- Plan name validation added as a sub-step inside **Step 2** of both `kit/plugins/plan-interview/skills/plan-interview/SKILL.md` and `commands/plan-interview.md`.
- Validation checks both the filename (without path/extension) and the H1 heading, flags random patterns (adjective-noun chains unrelated to content) and generic placeholders (`plan.md`, `draft.md`), and suggests a descriptive kebab-case replacement.
- Results appear immediately in Step 2 when issues are found; a `### Plan Naming` section is added to the Step 5 summary.
- Silent pass: no output when both filename and heading are descriptive — the validation does not interrupt normal reviews.
- Step 0 todo label updated: "Step 2: Read and analyze the plan" → "Step 2: Read, validate plan name, and analyze the plan".
- `plan-interview` plugin bumped from `1.1.0` → `1.2.0`.

> See [CHANGELOG v1.2.0](../kit/plugins/plan-interview/CHANGELOG.md#120---2026-02-26) for the authoritative feature list.

## Files changed

| Path | Role | Status |
|------|------|--------|
| `kit/plugins/plan-interview/skills/plan-interview/SKILL.md` | Skill instructions — plan-interview | Modified |
| `kit/plugins/plan-interview/commands/plan-interview.md` | Command wrapper for plan-interview | Modified |
| `kit/plugins/plan-interview/CHANGELOG.md` | Plugin changelog | Modified |
| `kit/plugins/plan-interview/README.md` | Plugin documentation | Modified |
| `.claude-plugin/marketplace.json` | Marketplace registry — version bump 1.1.0 → 1.2.0 | Modified |

## How it works

The validation sub-step runs at the start of Step 2, before any content is extracted for interview generation. It extracts two identifiers — the filename (without path or `.md`) and the first `# ...` line — then reads enough of the plan body to summarize the plan's purpose in one sentence.

The filename is evaluated on three axes: **descriptive** (words relate to the plan's goal), **not random** (does not follow a random adjective-noun or adjective-verb-noun pattern with no connection to content), and **not too generic** (not a placeholder like `plan.md` or `untitled.md`). The heading is evaluated for existence, descriptiveness, and alignment with the filename.

The validation uses heuristic judgement rather than regex rules — Claude reads the name against the plan summary and decides. The key distinction is intent: `add-dark-mode-toggle` passes even though it contains adjectives, because the words relate to the content; `fuzzy-swimming-pearl` fails because the words have no connection to the plan's subject.

When issues are found, a `### Plan Name Review` table is output immediately:

```markdown
| Element | Current | Issue | Suggested |
|---------|---------|-------|-----------|
| Filename | `fuzzy-swimming-pearl.md` | Random — unrelated | `create-skill-reviewer-plugin.md` |
| H1 Heading | _(missing)_ | No H1 heading found | `# Plan: Create 'skill-reviewer' Plugin` |
```

The same table is included in the Step 5 summary under `### Plan Naming`. The plugin surfaces the finding and may offer to rename the file — but does not rename automatically.

## How to use it

Validation runs automatically as part of every `plan-interview` invocation. To review a plan with a known random name:

```
/plan-interview:plan-interview docs/plans/fuzzy-swimming-pearl.md
```

The Plan Name Review table will appear at the start of Step 2. No additional flags are needed.

## Commit history

| SHA | Date | Subject |
|-----|------|---------|
| `6b9fab3` | 2026-03-26 | Merge pull request #51 from shawn-sandy/docs/plan-interview-upgrade |
| `9c70a52` | 2026-03-30 | chore(docs/plans): add YAML frontmatter status to 83 plan files |

<!-- generated:end -->

## References

- Plan: [add-plan-name-validation-to-interview.md](plans/add-plan-name-validation-to-interview.md)
- Changelog: [CHANGELOG v1.2.0](../kit/plugins/plan-interview/CHANGELOG.md#120---2026-02-26)

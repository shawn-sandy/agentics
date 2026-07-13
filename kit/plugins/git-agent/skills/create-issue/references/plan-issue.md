# Plan Issue Template

Use this body skeleton for the `plan` source — when the issue is created from a plan file (markdown spec or rendered HTML plan).

```markdown
## Objective

{{The plan's Objective section, verbatim or lightly condensed.}}

## Plan

{{Repo-relative path to the plan spec, e.g. `docs/plans/add-dark-mode-toggle.md` (link it when the host renders repo paths).}}

## Steps

- [ ] {{Step 1 action}}
- [ ] {{Step 2 action}}
- [ ] {{…one checklist item per plan step — action text only, no Why/Verify detail}}

## Acceptance Criteria

- [ ] {{Criterion 1}}
- [ ] {{Criterion 2}}

## Additional Context

{{Anything from the plan's Context section worth carrying over; open questions; related files.}}
```

## Title

Use the plan's title (`# Plan: <title>` heading) as the issue title — no `[BUG]`/`[FEATURE]` prefix.

## Suggested labels

Map from the plan's frontmatter `type:` — `fix` → `bug`, `feature` → `enhancement`, `docs` → `documentation`, `refactor`/`chore` → `chore`.

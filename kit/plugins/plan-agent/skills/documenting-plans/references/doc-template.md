# Document template and report

Loaded once evidence collection is complete. Covers Steps 8 and 9 — the full
document template to write, and the closing report table.

### Step 8 — Synthesize and write the doc

Compose the document using the template below and write it via `Write` (new
file) or `Edit` (refresh mode — replace only between the markers).

**Dynamic plan link**: compute the plan link as a relative path from
`docs/<slug>.md` to the resolved plan file. Do not hardcode `./plans/`. For
example, if the plan is at `docs/plans/my-plan.md` and the output is at
`docs/my-plan.md`, the relative link is `plans/my-plan.md`. If the plan is at
`~/.claude/plans/my-plan.md`, use an absolute path or note it in the References
section.

**CHANGELOG citation**: if the plan references a plugin with a `CHANGELOG.md`,
locate the entry that corresponds to the shipped feature (by version or date)
and link to it from the "What shipped" section. Do not reproduce CHANGELOG text
verbatim — cite and link instead.

---

**Document template:**

```markdown
# <H1 title with "Plan:" prefix removed>

> <One-line summary — first sentence of Context / Summary / Objective, trimmed
> to ~160 characters.>

<!-- generated:start -->

**Status:** Shipped <YYYY-MM-DD> **Plan:** [<plan-filename>](relative-plan-link)
**Type:** <type or "feature">

## What shipped

<Bulleted list distilled from the plan's Objective and ## Steps, rewritten in
past tense. One bullet per major capability. Where a Step includes a _Why:_
rationale, fold it into the bullet as a brief parenthetical.>

<If a CHANGELOG entry exists for this feature, add a citation footer:>

> See [CHANGELOG v<version>](<relative-path-to-CHANGELOG.md>#<anchor>) for the
> authoritative feature list.

## Files changed

| Path              | Role            | Status  |
| ----------------- | --------------- | ------- |
| `path/to/file.md` | <inferred role> | Created |

<Populate from the Step 5 file index. Role is inferred from file kind and
exported surface (e.g., "Skill instructions", "Command wrapper", "Marketplace
entry"). Status: Created / Modified / Relocated / Missing.>

## How it works

<3–8 short paragraphs, one per plan Step, rewritten as a walk-through that
references the actual code paths from Step 5. Where plan Steps mention a "Why:"
rationale, fold it into the prose. Where actual code diverged from the plan,
note the divergence briefly. Use inline backticks for every file path and
identifier.>

## How to use it

<Include this section ONLY when user-facing surface exists — commands, skills,
public APIs, or components. Omit entirely for internal refactors, chores, and
infrastructure changes with no user-visible interface.>

<For skills: show the activation trigger (description field text), plus the
companion command if one exists.>

<For commands: show the invocation syntax, argument-hint, and 2–3 example
calls.>

<For library code: show the import path, primary exported symbol, and a minimal
usage example (if one exists in plan or code).>

## Commit history

| SHA       | Date       | Subject                                              |
| --------- | ---------- | ---------------------------------------------------- |
| `abc1234` | 2026-03-29 | feat(plan-agent): add update-plan-status command |

<Populate from Step 6 git log output. Up to 20 rows. If result was capped at 20,
append: "_Showing 20 of N commits — run `git log` for the full history._">

<!-- generated:end -->

## References

- Plan: [<plan-filename>](relative-plan-link)
- Related docs: <links to other docs/\*.md files discovered via Grep on
  keywords/slug, if any>
- Changelog: <link to plugin CHANGELOG entry if applicable>
```

---

After writing, confirm: `"Written to docs/<slug>.md"`

### Step 9 — Report

Output a summary table:

```text
| Field          | Value                                    |
|----------------|------------------------------------------|
| Output         | docs/<slug>.md                           |
| Plan           | docs/plans/<plan-file>.md                |
| Shipped date   | 2026-03-29                               |
| Files indexed  | 5 (4 found, 1 missing)                   |
| Commits        | 12 in window (2026-01-15 – 2026-03-29)   |
```

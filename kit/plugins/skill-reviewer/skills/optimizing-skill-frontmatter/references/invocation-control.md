# Invocation control (Step 4b)

Loaded by Step 4b. Applies to every SKILL.md **resolved in Step 1** — not just
files that were rewritten, since files SKIP'd in Step 2 may still need invocation
control tuned.

## Why the flag matters

`disable-model-invocation` controls how a skill activates. `true` forces explicit
invocation only (via `/plugin:skill-name`); omitting it lets the model auto-fire
the skill when user intent matches. Workflow skills that write files, commit
code, or run pipelines should require explicit invocation — auto-firing a deploy
on a loose intent match causes unintended side effects. Advisory/read-only skills
benefit from auto-activation.

## Classification

Classify each file as **workflow** or **advisory** using two static signals:

| Signal | Strong workflow → `true` | Strong advisory → omit |
|---|---|---|
| `allowed-tools:` | Contains `Edit`, `Write`, or `Bash` with side-effect verbs | Only `Read`, `Glob`, `Grep`, `WebFetch`, `WebSearch`, `AskUserQuestion` |
| `description:` verbs | commit, push, PR, ship, branch, deploy, migrate, generate, scaffold, iterate, TDD-loop, "writes to" | review, audit, check, analyze, score, advise, report, recommend |
| Body signals | mentions `ExitPlanMode` Step 0; mentions writing/editing files | "report under N words"; no Edit/Write calls in any step |

**Confidence rules:**
- Both signals agree → **confident** recommendation; still confirm per policy below.
- Signals disagree or are mixed → **ambiguous**; surface both in the prompt.

**Never write `disable-model-invocation: false`.** The convention in this repo is: write `true` for workflow skills; omit the field entirely for advisory skills.

## Classification output

Print a compact table — one row per touched SKILL.md:

```
| Path | Current value | Recommendation | Confidence | Reason |
|------|---------------|----------------|------------|--------|
| kit/plugins/foo/skills/bar/SKILL.md | missing | omit (no change) | confident | read-only tools, advisory verbs |
| kit/plugins/foo/skills/baz/SKILL.md | missing | true | confident | Edit+Bash in allowed-tools, "generates" in description |
```

Show `true` / `missing` in the **Current value** column. Show `omit (no change)` when the current value already matches the recommendation.

## Confirmation

Call `AskUserQuestion` with three options:

- **Apply recommendations** — apply all non-trivial changes (skip `omit (no change)` rows)
- **Pick per file** — loop back through each changed row individually, ask per file
- **Skip invocation changes** — leave all files untouched; proceed to Step 5

## Apply rules (on confirmation)

**To set `true`:** first check for any existing `disable-model-invocation:` line (any value — including `false`). If one exists, delete it. Then insert `disable-model-invocation: true` on a new line immediately after the `allowed-tools:` line.

Step 1 — delete any existing `disable-model-invocation` line:
1. Extract the YAML frontmatter block first: read lines between the opening `---` (line 1) and the closing `---` (the next `---` after line 1). Run `Grep` for `^disable-model-invocation:` **only within that extracted range** — stop after the first frontmatter block so instruction examples in the body code blocks are not matched.
2. If found, use `Edit` with that exact matched line as `old_string` and `""` as `new_string`.

```
# Example — if grep returned: disable-model-invocation: false
old_string: "disable-model-invocation: false\n"
new_string: ""
```

Step 2 — insert after the `allowed-tools:` line:
1. Extract the YAML frontmatter block (lines between `---` delimiters as above). Run `Grep` for `^allowed-tools:` within that range to get the exact frontmatter line content.
2. Use `Edit` with that exact line as `old_string`, appending `disable-model-invocation: true` on the next line.

```
# Example — if grep returned: allowed-tools: AskUserQuestion, Read, Edit, Bash
old_string: "allowed-tools: AskUserQuestion, Read, Edit, Bash\n"
new_string: "allowed-tools: AskUserQuestion, Read, Edit, Bash\ndisable-model-invocation: true\n"
```

Never use placeholder values like `<value>` — always grep the file for the exact current content and use that as `old_string`.

**To remove an existing `true`:** delete the `disable-model-invocation: true` line entirely (do not replace with `false`). If an existing `false` is present, delete it too — never leave `false` in the file.

**Never write `disable-model-invocation: false`** — the omit-the-field convention must be preserved.

## Negative-scope clauses

Negative-scope clauses (“Does NOT cover X”) are relocated to a `## When not to use` body section rather than dropped. See `references/description-rules.md`, Rule 4.

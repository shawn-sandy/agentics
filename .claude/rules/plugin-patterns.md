---
paths:
  - "kit/plugins/**"
---

# Plugin Component Patterns

Commands (`commands/<name>.md`, invoked `/plugin:command`, input via
`$ARGUMENTS`) and skills (`skills/<name>/SKILL.md`, auto-activated by
`description`) follow the standard Claude Code formats. What follows is only
what this repo does differently.

## `allowed-tools`

List every tool the skill actually calls, so nothing prompts mid-run. Prefer
the restricted form when a skill shells out to one CLI family:

```yaml
allowed-tools: Bash(git *)
```

`kit/plugins/skill-reviewer` ships `auditing-allowed-tools`, which patches a
SKILL.md's list automatically or cross-references it against a real session
transcript.

## Deferred tools

Some harness tools (`ExitPlanMode` among them) load their schemas on demand. A
skill that calls one lists both `ToolSearch` **and** the deferred tool in
`allowed-tools`; omitting `ToolSearch` triggers a permission prompt mid-skill.

Do **not** explain the `ToolSearch` mechanic in the skill body. The harness
already tells the model how deferred loading works, so a per-skill copy costs
context in every session and buys nothing.

## The plan-mode guard

Any skill, command, or agent that mutates the filesystem, git state, or a
remote carries exactly this line — verbatim, once, as its first step:

```markdown
**If in plan mode**, call `ExitPlanMode` first — this workflow mutates state.
```

Standalone on its own line, nothing appended. `tests/plugins/test-exitplanmode-guard.sh`
greps for the exact string. A step needing a further instruction (`build`'s
"produce no plan document") puts it in the next paragraph, so the guard reads
identically in every file carrying it.

Do not expand it. An earlier four-line variant explained plan mode, why writes
are mutations, and how to `ToolSearch` — 43 copies of something the model
already knows.

Read-only skills, and dispatchers whose downstream skill carries its own guard,
omit the line and drop `ToolSearch`/`ExitPlanMode` from `allowed-tools`.

## Skill descriptions

Three parts, ≤200 chars total:

```text
[Short description, ≤80 chars.] [Capability statement.] Use when the user asks to [trigger].
```

The ≤80-char first sentence is the part that survives truncation at ~100
installed skills (8,000 char budget ÷ 100). Source both sentences from the
skill body's `## Overview`.

## Plugin README

Overview, Features (with invocation syntax), Installation, Usage, Structure,
Components. Write it before implementing anything complex.

## Pitfalls

- `version` set in both `plugin.json` and `marketplace.json` — for
  relative-path plugins it belongs only in `marketplace.json`.
- Version strings that are not `X.Y.Z` (`v1.0` and `1.0` both fail).
- A skill missing `name` or a command missing `description` in frontmatter.

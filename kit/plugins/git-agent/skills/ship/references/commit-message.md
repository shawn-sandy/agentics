# Commit message format

Referenced by Step 3 of `ship`. Format rules only — the instruction to run
`git diff --staged` and write a message stays in the SKILL.md core.

## Shape

```
<type>(<scope>): <description>
```

## Rules

- Total length: ≤ 72 characters
- Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `perf`, `style`,
  `ci`, `build`
- Scope: the most-changed top-level directory; omit it entirely if changes span
  more than 2 top-level directories
- Description: imperative mood, lowercase, no trailing period

## Examples

- `feat(plugins/git-agent): add commit-agent and pr-agent skills`
- `fix(plugins/code-review): correct activation trigger wording`
- `chore: update marketplace.json with new plugin entry`

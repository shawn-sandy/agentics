# branch-agent: always append date suffix to created branches

## Context

The `branch-agent` skill (`kit/plugins/git-agent/skills/branch-agent/SKILL.md`) creates branches from three name sources: verbatim `$ARGUMENTS`, slugified descriptive phrases, or auto-generated `<type>/<scope>-<description>` names. None of these currently carry a date, which makes branches harder to sort, group, and clean up chronologically.

The fix: append a `-YYYY-MM-DD` suffix to every branch the skill creates, regardless of source.

## Objective

Update `kit/plugins/git-agent/skills/branch-agent/SKILL.md` so the final branch name always ends with `-YYYY-MM-DD` (today's date in ISO format).

## Files to modify

- [kit/plugins/git-agent/skills/branch-agent/SKILL.md](kit/plugins/git-agent/skills/branch-agent/SKILL.md)
- [kit/plugins/git-agent/CHANGELOG.md](kit/plugins/git-agent/CHANGELOG.md)
- [kit/plugins/git-agent/README.md](kit/plugins/git-agent/README.md)
- [.claude-plugin/marketplace.json](.claude-plugin/marketplace.json)

## Steps

1. **Add `Bash(date *)` to `allowed-tools`** — the skill's current `Bash(git *)` allowlist would trigger a permission prompt on the new `date +%Y-%m-%d` call. *Why:* preserves the "no mid-run prompts" flow the skill is designed around.

2. **Update the opening paragraph** to state that a `-YYYY-MM-DD` suffix is always appended. *Why:* documents the new invariant at the top so future readers see it before diving into steps.

3. **Route Step 2 Cases A/B/C to a new Step 2b** (instead of Step 3) after the name is resolved. *Why:* a single shared step avoids duplicating the date-appending logic across three cases.

4. **Insert new Step 2b: Append Date Suffix** between Step 2a and Step 3. Runs `date +%Y-%m-%d`, appends the output with a `-` separator, and truncates the description at a word boundary if the total exceeds 60 chars. *Why:* centralizes the behavior and keeps the existing 60-char final-branch-name cap stable.

5. **Tighten Step 2a's auto-gen length cap from 60 → 49 chars** to reserve 11 chars for the suffix. *Why:* without this, an auto-generated name at the old 60-char cap + 11-char suffix would breach the 60-char final-name invariant.

6. **Bump git-agent version 3.3.2 → 3.4.0** in `.claude-plugin/marketplace.json` and add a CHANGELOG entry. *Why:* MINOR bump per `.claude/rules/marketplace.md` — new behavior added to an existing skill without removing or renaming any command.

7. **Update the git-agent README** branch-agent section: mention the suffix in the feature blurb and renumber the flow (5 steps → 6 steps) to reflect the inserted Step 2b. *Why:* keeps user-facing docs in sync with the SKILL.md flow.

## Verification

1. Start a fresh session in the worktree.
2. Invoke the skill: "create a branch called feat/date-suffix-test".
3. Confirm the created branch is `feat/date-suffix-test-YYYY-MM-DD` with today's date.
4. Invoke again with uncommitted changes and no argument; confirm the auto-generated name also carries the suffix.
5. Clean up test branches.

## Out of scope (Next Steps)

- Applying the same date-suffix pattern to `commit-agent` or `ship` — they operate on the current branch and don't create new ones.
- Configurable date formats (compact `YYYYMMDD`, time-of-day, etc.) — single ISO format keeps the skill predictable.
- Detecting existing date suffixes in user-provided names to avoid double-dating — adds ambiguity; current approach is "always append" for predictability.

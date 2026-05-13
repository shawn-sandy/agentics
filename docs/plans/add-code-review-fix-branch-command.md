---
status: todo
type: standard
created: 2026-05-13
---

# Plan: Add `/code-review:fix-branch` slash command

## Context

This session was started with `/goal review all changes and fix blocking, major and minor issues until these issues are resolved`. The `/goal` directive set a `Stop` hook condition; I then performed the workflow manually — diffed `git log main..HEAD`, read every changed file, ran the plan's verification commands, found one bug (a missing deferred-tool bootstrap note in `code-simplifier`'s Step 1), fixed it, committed, and stopped.

The user wants that exact workflow packaged as a reusable, repeatable plugin slash command so it can be triggered with one keystroke instead of being re-described as a session goal. The Explore agent confirmed:

- No existing skill or command in the marketplace covers "review branch diff, then iteratively fix blocking/major/minor findings until clean."
- `code-review-agent` reports findings but does not apply fixes.
- `code-simplifier` refactors but is not branch-diff-scoped.
- `tdd-loop` has the iterate-until-clean rhythm but is test-suite-scoped.
- The `code-review` plugin currently ships zero commands, so there is no naming collision.

User decisions (captured via `AskUserQuestion` across two rounds):

- **Plugin home:** `code-review`.
- **Diff scope:** branch vs the default remote branch (auto-detected; falls back to main → master).
- **Fix mode:** autonomous fixes for blocking + major + minor findings; no per-fix prompt; no auto-commit (user reviews `git diff` and commits themselves).
- **Severity rubric:** defined concretely inline in the command body — no model-judgment punt.
- **Review criteria (all four):** repo `.claude/rules/*.md`, project `CLAUDE.md` + `CLAUDE.local.md`, frontmatter validation, and the changed plan's own verification section.
- **Dirty working tree:** refuse to run with a clear error message.
- **Base branch detection:** `git symbolic-ref refs/remotes/origin/HEAD` first, fallback chain afterward.
- **Loop cap:** 2 iterations (one pass + one retry) — the manual session resolved in a single pass, so 5 was over-engineered.
- **Delegate sibling reviews:** when a changed file is a `SKILL.md` or under `agents/`, delegate the *review phase* to the `skill-reviewer:reviewing-skills` or `agent-reviewer:reviewing-agents` skills via the `Skill` tool; merge findings into the master list and apply fixes from `fix-branch`.

## Objective

Add a new slash command `/code-review:fix-branch` in `kit/plugins/code-review/commands/fix-branch.md` that, when invoked, (1) refuses on a dirty working tree, (2) resolves the branch's changes vs the auto-detected default branch, (3) reviews each changed file against `.claude/rules/`, `CLAUDE.md`/`CLAUDE.local.md`, frontmatter constraints, and any modified plan's verification section — delegating SKILL.md / agent reviews to sibling skills, (4) classifies findings via a concrete severity rubric (**blocking / major / minor / unfixable**), (5) applies fixes autonomously via `Edit`/`Write` for the first three severities and lists `unfixable` findings for human review, (6) re-verifies and retries once (cap = 2), and (7) leaves all fixes uncommitted with a one-line summary pointing the user to `git diff` and `/git-agent:commit-agent`.

## Files to modify

- `kit/plugins/code-review/commands/fix-branch.md` — **NEW**. Command file with frontmatter (`description`, `argument-hint`, `allowed-tools`) and a numbered Step 0 → Step 6 body following the existing convention used in `kit/plugins/skill-reviewer/commands/check-description.md` and `kit/plugins/plan-interview/commands/plan-interview.md`.
- `kit/plugins/code-review/README.md` — add a **Commands** section listing `fix-branch` with invocation, scope, and a usage example. Insert above the existing **Agent (Internal)** section.
- `kit/plugins/code-review/CHANGELOG.md` — prepend a `## [3.3.0] - 2026-05-13` entry describing the new command (Added).
- `.claude-plugin/marketplace.json` — bump `code-review` `version` from `3.2.1` → `3.3.0` (MINOR — new command added per `.claude/rules/marketplace.md`).

## Steps

<ol>
<li>
<strong>Create <code>kit/plugins/code-review/commands/fix-branch.md</code></strong> with the frontmatter and step body described below.
<br><em>Why:</em> the command file is the entire user-facing surface — without it, the slash command does not exist.
<br><em>Verify:</em> <code>cat kit/plugins/code-review/commands/fix-branch.md | head -10</code> shows valid YAML frontmatter (<code>description</code>, <code>argument-hint</code>, <code>allowed-tools</code>) and the body has seven numbered steps (0–6) including a severity rubric table.

<br>

<strong>Frontmatter:</strong>

```yaml
---
description: Review all branch changes vs the default branch, then autonomously fix blocking, major, and minor issues until the branch is clean. Refuses on a dirty working tree. Leaves fixes uncommitted.
argument-hint: "[base-branch] (optional) — defaults to the remote default branch; falls back to main, then master"
allowed-tools: Bash(git *), Read, Edit, Write, Glob, Grep, Skill
---
```

<strong>Body (seven steps):</strong>

- <strong>Step 0 — Pre-flight.</strong>
  - Refuse on dirty tree: <code>git diff --quiet HEAD || { echo "ERROR: working tree has uncommitted changes. Commit or stash first so review fixes are isolated."; exit 1; }</code>.
  - Resolve base branch: if <code>$ARGUMENTS</code> is non-empty, use it. Else run <code>git symbolic-ref refs/remotes/origin/HEAD 2&gt;/dev/null | sed 's,^refs/remotes/origin/,,'</code>. If that fails, try <code>main</code>, then <code>master</code>. If all fail, stop with an error.
  - Compute merge base: <code>MERGE_BASE=$(git merge-base "$BASE" HEAD)</code>.

- <strong>Step 1 — Enumerate changes.</strong> Run <code>git log $MERGE_BASE..HEAD --oneline</code> and <code>git diff $MERGE_BASE..HEAD --name-only</code>. If empty, output "Branch is clean — nothing to review." and stop.

- <strong>Step 2 — Review each changed file against four criteria.</strong> For every changed file, build findings using these sources (apply all four):
  1. <strong>Repo rules:</strong> <code>.claude/rules/*.md</code> (especially <code>plugin-patterns.md</code>, <code>skill-authoring.md</code>, <code>marketplace.md</code>, <code>plan-hygiene.md</code>).
  2. <strong>Project conventions:</strong> <code>CLAUDE.md</code> and <code>CLAUDE.local.md</code> (e.g. no-emoji rule, version-only-in-marketplace.json rule).
  3. <strong>Frontmatter validation:</strong> for <code>SKILL.md</code>, validate <code>name</code> (kebab-case, ≤64 chars), <code>description</code> (third person, ≤1024 chars), and the repo's 160-char budget target. For <code>plugin.json</code>, validate required fields. For <code>marketplace.json</code>, ensure JSON syntax and required keys.
  4. <strong>Plan verification:</strong> for every <code>docs/plans/**.md</code> in the change set, locate the verification section using a <strong>flexible parser</strong> — match any heading whose text contains "verif" (case-insensitive), and additionally extract <code>&lt;em&gt;Verify:&lt;/em&gt;</code> snippets from any <code>&lt;li&gt;</code> blocks. Execute discovered shell commands and treat non-zero exits as findings.

  <strong>Delegation:</strong> when a changed file matches <code>**/SKILL.md</code>, invoke the <code>skill-reviewer:reviewing-skills</code> skill via the <code>Skill</code> tool and merge its findings. When a changed file matches <code>**/agents/*.md</code>, invoke <code>agent-reviewer:reviewing-agents</code>. Do not duplicate those skills' logic inline.

- <strong>Step 3 — Classify findings with the severity rubric.</strong> Tag each finding using this table:

  | Tag | Definition | Examples |
  |---|---|---|
  | <strong>blocking</strong> | Breaks the file, contradicts the plan's verification, fails frontmatter validation | Invalid JSON, missing required field (<code>name</code>), failing <code>jq</code> verification, broken cross-reference in a CHANGELOG |
  | <strong>major</strong> | Significant gap likely to cause user confusion or runtime issues | Behavior change without doc update, missing <code>ToolSearch</code> for a deferred tool, README references a renamed skill |
  | <strong>minor</strong> | Polish, consistency, or style issues | Typo, inconsistent capitalization, table cell alignment, description over 160 chars but under 1024 |
  | <strong>unfixable</strong> | Needs human judgment — do not auto-edit | Ambiguous renaming, missing description text that requires domain knowledge, logic bugs requiring design input |

- <strong>Step 4 — Apply fixes autonomously.</strong> For every finding tagged <code>blocking</code>, <code>major</code>, or <code>minor</code>, apply the fix using <code>Edit</code> or <code>Write</code> without prompting. Do not edit <code>unfixable</code> findings — accumulate them for the final report. After all edits in a round, re-run only the verification commands that previously failed.

- <strong>Step 5 — Retry once (cap = 2).</strong> If new findings (blocking / major / minor) surfaced after Step 4 fixes, repeat Steps 2–4 exactly once more. After two iterations total, stop and report whatever remains.

- <strong>Step 6 — Report.</strong> Output a markdown summary:
  - Bullet list of <code>iteration | findings_found | findings_fixed | remaining</code>.
  - Bullet list of <strong>Unfixable findings</strong> with file path, line range, and a one-line "needs human review" note.
  - One summary line: "Fixed N issues across M files. K unfixable findings need human review. Run <code>git diff</code> to review, then <code>/git-agent:commit-agent</code> to commit."

</li>

<li>
<strong>Update <code>kit/plugins/code-review/README.md</code></strong> to document the new command. Add a <code>## Commands</code> section between the existing <code>## Skills</code> and <code>## Review Checklist Overview</code> sections.
<br><em>Why:</em> the README is the published surface for plugin contents; if it does not list the command, users discover it only by invocation guesswork.
<br><em>Verify:</em> <code>grep -n '^## Commands' kit/plugins/code-review/README.md</code> returns one line; that section names <code>/code-review:fix-branch</code>, its argument hint, and a one-line example.
</li>

<li>
<strong>Prepend a <code>## [3.3.0] - 2026-05-13</code> entry to <code>kit/plugins/code-review/CHANGELOG.md</code></strong> with an <code>### Added</code> sub-heading describing the new command (one bullet, one line). Do not modify existing entries.
<br><em>Why:</em> the CHANGELOG is the canonical record per <code>.claude/rules/marketplace.md</code>; an unlogged version bump will fail the next CHANGELOG audit.
<br><em>Verify:</em> <code>head -10 kit/plugins/code-review/CHANGELOG.md</code> shows the new entry above <code>## [3.2.1]</code> and contains the string <code>fix-branch</code>.
</li>

<li>
<strong>Bump the marketplace version</strong> for <code>code-review</code> from <code>3.2.1</code> to <code>3.3.0</code> in <code>.claude-plugin/marketplace.json</code>.
<br><em>Why:</em> users on the marketplace will not see the new command until the version increments; the per-Write hook also re-validates JSON syntax on save.
<br><em>Verify:</em> <code>jq '.plugins[] | select(.name=="code-review") | .version' .claude-plugin/marketplace.json</code> prints <code>"3.3.0"</code>.
</li>

<li>
<strong>End-to-end dry-runs.</strong>
- <em>Clean-branch case</em>: invoke <code>/code-review:fix-branch</code> on a freshly-cleaned branch (the current branch after the recent commits is a candidate). Expected: "Branch is clean — nothing to review." and immediate exit at Step 1.
- <em>Dirty-tree case</em>: introduce a deliberate uncommitted edit, invoke the command. Expected: refusal with the dirty-tree error from Step 0.
- <em>Broken-branch case</em>: introduce a deliberate over-budget description (e.g. paste a 300-char description into a SKILL.md), commit it, invoke the command. Expected: the command detects the issue, applies the trim via <code>Edit</code>, and reports "Fixed 1 issues across 1 files."
<br><em>Why:</em> the three cases exercise the three primary code paths (empty diff, pre-flight refusal, fix loop). Without this, frontmatter typos or merge-base bugs ship undetected.
<br><em>Verify:</em> all three cases produce the expected outputs above; <code>git status</code> after the clean-branch case shows no changes; the broken-branch case shows exactly one modified file.
</li>
</ol>

## Verification

End-to-end correctness checks once all steps are complete:

- <code>ls kit/plugins/code-review/commands/</code> shows <code>fix-branch.md</code>.
- <code>head -5 kit/plugins/code-review/commands/fix-branch.md</code> shows valid YAML frontmatter with <code>description</code>, <code>argument-hint</code>, and <code>allowed-tools</code> keys, and <code>allowed-tools</code> does <strong>not</strong> include <code>AskUserQuestion</code> but does include <code>Skill</code>.
- <code>jq '.plugins[] | select(.name=="code-review") | .version' .claude-plugin/marketplace.json</code> returns <code>"3.3.0"</code>.
- <code>head -10 kit/plugins/code-review/CHANGELOG.md</code> shows the <code>3.3.0</code> entry above <code>3.2.1</code>, mentioning <code>fix-branch</code>.
- <code>grep -c '## Commands' kit/plugins/code-review/README.md</code> returns <code>1</code>; that section documents <code>/code-review:fix-branch</code>.
- The body of the new command file contains the four-row severity rubric table and the verification-parser instruction to match any heading containing "verif" case-insensitive.
- All three dry-run cases (clean / dirty / broken) produce the expected outputs described in Step 5.

## Next steps (out of scope)

- Optional: add a <code>--report-only</code> argument variant that surfaces findings without applying fixes (would require a second branch in Step 4).
- Optional: integrate <code>fix-branch</code> with <code>/git-agent:commit-bg</code> so a chain like <code>/code-review:fix-branch && /git-agent:commit-bg</code> becomes a one-line "review, fix, and commit" pipeline.
- Optional: expose the severity rubric as a separate reference file (e.g. <code>kit/plugins/code-review/references/severity-rubric.md</code>) so the <code>code-review-agent</code> skill can reuse it for consistent classification.

## Interview Summary

The plan was stress-tested via `/plan-interview:plan-interview` on 2026-05-13. One technical round was run (the plan is short/focused with no UI involvement). Four concerns and one simplification opportunity were surfaced, and the user accepted all proposed amendments. The amendments have already been folded into the **Steps** section above; this section preserves the interview record.

### Key decisions confirmed

- Severity rubric defined concretely inline (four tiers including a new `unfixable` bucket).
- Review criteria expanded to four sources: repo rules, project CLAUDE.md(/local), frontmatter validation, and the plan's verification section.
- Pre-flight refuses on a dirty working tree.
- Base branch resolved via `git symbolic-ref refs/remotes/origin/HEAD` with main/master fallback.
- Sibling reviews (SKILL.md, agents/) delegated to the dedicated skills via the `Skill` tool — no duplication.
- Loop cap downgraded from 5 → 2 (one pass + one retry).
- `AskUserQuestion` removed from `allowed-tools`; `Skill` added.

### Plan name change

| Element | Before | After |
|---|---|---|
| Filename | `adaptive-marinating-pascal.md` | `add-code-review-fix-branch-command.md` |
| H1 | _(was already descriptive)_ | _(unchanged)_ |

### Open risks accepted

- **Verification-parser flexibility**: heuristic match on "verif" headings + `<em>Verify:</em>` snippets covers the existing plan styles in the repo. May still miss exotic formats; acceptable for v1.
- **Loop cap = 2**: matches the actual session evidence. Re-running the command is cheap if more iterations turn out to be needed in practice.
- **Sibling-skill delegation timing**: the `Skill` tool invokes a sub-skill synchronously; if `reviewing-skills` or `reviewing-agents` ask their own clarifying questions, the autonomous flow may stall. Acceptable for v1; revisit if it becomes a problem.

### Recommended next steps post-implementation

If the command sees real use, consider extracting the severity rubric into a shared reference file (see Next Steps) so both `code-review-agent` and `fix-branch` classify findings consistently.

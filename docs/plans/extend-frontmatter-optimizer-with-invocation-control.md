---
status: todo
type: standard
---

# Plan: Extend description-optimizer skill to also tune `disable-model-invocation`

> Filename note: this file was auto-named (`i-wnat-this-skill-purring-wand.md`). After approval, rename to `extend-frontmatter-optimizer-with-invocation-control.md` per plan-mode.md rule #2.

## Context

The `optimizing-skill-descriptions` skill (in `kit/plugins/skill-reviewer/`) currently has one job: trim each SKILL.md `description:` field to ≤160 chars while preserving activation accuracy. Anthropic's docs on [controlling who invokes a skill](https://code.claude.com/docs/en/skills#control-who-invokes-a-skill) show that the `disable-model-invocation` frontmatter flag is the other lever that decides *how* a skill activates — `true` forces explicit invocation only; omitted leaves the default (model can auto-fire on intent match).

This repo already applies that pattern consistently: 10 workflow SKILL.md files set `disable-model-invocation: true` (git-agent ops, TDD loops, ship pipelines, the description-optimizer itself); 20 advisory/read-only SKILL.md files omit the field. The convention is established but unenforced — new skills can drift, and the skill-reviewer toolkit currently has no way to surface the mismatch.

The user wants the description-optimizer to also assess and (on confirmation) apply the right `disable-model-invocation` value during the same pass. Scope broadens from "description-only" to "frontmatter-level optimization," so the skill is being renamed accordingly.

## Objective

Rename `optimizing-skill-descriptions` to `optimizing-skill-frontmatter` and add a new step that classifies each SKILL.md as workflow vs. advisory, recommends `disable-model-invocation: true` (or omit) based on static signals in the file itself, and applies the change only after the user confirms via `AskUserQuestion`. Default value policy: write `true` when workflow; never write explicit `false` — match the repo's omit-the-field convention for advisory skills.

## Heuristic (lives in the skill body, not just this plan)

Classify each touched SKILL.md from two static signals:

| Signal source | Strong workflow (`true`) | Strong advisory (omit) |
|---|---|---|
| `allowed-tools:` | Contains `Edit`, `Write`, or `Bash` with side-effect verbs | Only `Read`, `Glob`, `Grep`, `WebFetch`, `WebSearch`, `AskUserQuestion` |
| `description:` verbs | commit, push, PR, ship, branch, deploy, migrate, generate, scaffold, iterate, TDD-loop, "writes to" | review, audit, check, analyze, score, advise, report, recommend |
| Body signals | mentions `ExitPlanMode` Step 0; mentions writing/editing files | "report under N words"; no Edit/Write calls in any step |

- Both signals agree → **confident** recommendation; still confirm per user's policy.
- Signals disagree or are mixed → **ambiguous**; surface both in the prompt so the user decides.
- Per the user's "always confirm" policy: every flip goes through `AskUserQuestion`, even confident ones. Batched per-table prompt is acceptable (one prompt for all touched files).

## Files to modify

- `/Users/shawnsandy/devbox/agentics/kit/plugins/skill-reviewer/skills/optimizing-skill-descriptions/SKILL.md` — directory renamed to `.../optimizing-skill-frontmatter/`; `name:`, `description:`, body updated; new "Step 4b: Tune invocation control" inserted between current Steps 4 and 5; Table of Contents updated.
- `/Users/shawnsandy/devbox/agentics/kit/plugins/skill-reviewer/scripts/measure-description.sh` — 4 WARNING strings reference the old skill name; replace with `/skill-reviewer:optimizing-skill-frontmatter`.
- `/Users/shawnsandy/devbox/agentics/kit/plugins/skill-reviewer/README.md` — 4 references to the old name (entry #4 in the skills list, the example WARNING line, the directory tree on line ~188, and the closing usage hint on line ~291).
- `/Users/shawnsandy/devbox/agentics/kit/plugins/skill-reviewer/commands/check-description.md` — 1 reference in the "For any over-budget file" bullet.
- `/Users/shawnsandy/devbox/agentics/kit/plugins/skill-reviewer/CHANGELOG.md` — add a new `## 2.0.0` section at the top describing the rename and the new responsibility. Do **not** edit existing entries.
- `/Users/shawnsandy/devbox/agentics/.claude-plugin/marketplace.json` — bump skill-reviewer `version` from `1.9.0` → `2.0.0`.

## Steps

<ol>
<li>
<strong>Rename the skill directory.</strong>
Move <code>kit/plugins/skill-reviewer/skills/optimizing-skill-descriptions/</code> to <code>.../optimizing-skill-frontmatter/</code> via <code>git mv</code> so history follows the file.
<br><em>Why:</em> directory name is part of the skill's invocation path (<code>/skill-reviewer:optimizing-skill-frontmatter</code>); it must change before any text references are updated.
<br><em>Verify:</em> <code>ls kit/plugins/skill-reviewer/skills/</code> shows <code>optimizing-skill-frontmatter</code> and no <code>optimizing-skill-descriptions</code>; <code>git status</code> shows the rename as a single move (not delete+add).
</li>

<li>
<strong>Update the renamed SKILL.md frontmatter.</strong>
Change <code>name: optimizing-skill-descriptions</code> → <code>name: optimizing-skill-frontmatter</code> and rewrite <code>description:</code> to cover the broader scope (target: ≤160 chars). Suggested text: <code>Use when the user asks to optimize SKILL.md frontmatter: trim descriptions to ≤160 chars and set disable-model-invocation correctly.</code> (137 chars).
<br><em>Why:</em> the <code>name</code> field must match the directory; the <code>description</code> must surface "invocation" so the skill activates when users ask about that, not just descriptions.
<br><em>Verify:</em> run <code>bash kit/plugins/skill-reviewer/scripts/measure-description.sh kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/SKILL.md</code> — it must report a length ≤160 with no WARNING.
</li>

<li>
<strong>Add "Step 4b: Tune invocation control" to the SKILL.md body.</strong>
Insert a new step between current Step 4 (Apply edits) and Step 5 (Verify results). The step must (a) for each SKILL.md touched this pass, read <code>allowed-tools</code> and <code>description</code> and classify per the heuristic table above; (b) print a compact table — path, current value (true/missing), recommendation, confidence (confident/ambiguous), one-line reason; (c) call <code>AskUserQuestion</code> with options <strong>Apply recommendations / Pick per file / Skip invocation changes</strong>; (d) on apply, either insert <code>disable-model-invocation: true</code> on a new line after the <code>allowed-tools:</code> line, or delete an existing <code>disable-model-invocation: true</code> line when the heuristic says omit. Never write <code>disable-model-invocation: false</code>.
<br><em>Why:</em> this is the core behavioral change; placing it after the description edits keeps the Edit-then-confirm rhythm consistent with the existing flow and lets one frontmatter pass cover both fields.
<br><em>Verify:</em> open the SKILL.md and confirm the new Step 4b contains: the heuristic table, the "always confirm" <code>AskUserQuestion</code> call, the exact Edit pattern (insert-after-allowed-tools vs. delete-line), and the explicit "never write <code>false</code>" rule.
</li>

<li>
<strong>Update the Overview, "When not to use," and Table of Contents in the renamed SKILL.md.</strong>
Overview: state that the skill now optimizes both <code>description</code> length and <code>disable-model-invocation</code>. When not to use: keep the pointer to <code>reviewing-skills</code> for overall quality and to <code>auditing-allowed-tools</code> for the tools field; do not duplicate scope. Table of Contents: add a <code>Step 4b</code> entry.
<br><em>Why:</em> the activation description has expanded; the body's framing must match so users understand the new responsibility and the skill stays out of <code>auditing-allowed-tools</code>'s lane.
<br><em>Verify:</em> the SKILL.md mentions <code>disable-model-invocation</code> in the Overview; the ToC lists Step 4b; the "When not to use" still names the two sibling skills without claiming their scope.
</li>

<li>
<strong>Update cross-references to the old skill name.</strong>
In one editing pass, replace <code>optimizing-skill-descriptions</code> with <code>optimizing-skill-frontmatter</code> in: <code>kit/plugins/skill-reviewer/scripts/measure-description.sh</code> (4 hits), <code>kit/plugins/skill-reviewer/README.md</code> (4 hits — skills list entry, sample WARNING, directory tree, closing usage hint), and <code>kit/plugins/skill-reviewer/commands/check-description.md</code> (1 hit). Also update the README's prose entry #4 to describe the broader scope (frontmatter, not just descriptions).
<br><em>Why:</em> the WARNING strings emitted by <code>measure-description.sh</code> are the main way users discover this skill; they must point at the new slash command. README and command docs are the published surface.
<br><em>Verify:</em> <code>grep -rn 'optimizing-skill-descriptions' kit/plugins/skill-reviewer/</code> returns zero results (CHANGELOG history aside — historic entries are intentionally untouched).
</li>

<li>
<strong>Add the CHANGELOG entry and bump the marketplace version.</strong>
Prepend a <code>## 2.0.0</code> section to <code>kit/plugins/skill-reviewer/CHANGELOG.md</code> noting (a) BREAKING: skill renamed <code>optimizing-skill-descriptions</code> → <code>optimizing-skill-frontmatter</code>, (b) ADDED: Step 4b for tuning <code>disable-model-invocation</code>, (c) the file list updated to reference the new slash command. In <code>.claude-plugin/marketplace.json</code>, change the skill-reviewer <code>version</code> from <code>1.9.0</code> to <code>2.0.0</code>.
<br><em>Why:</em> per <code>.claude/rules/marketplace.md</code>, renaming a skill is a MAJOR bump; CHANGELOG is the canonical record. The repo's commit-message convention also requires a <code>feat!:</code> with a <code>BREAKING CHANGE:</code> footer when committing this work (handled at commit time, not here).
<br><em>Verify:</em> <code>jq '.plugins[] | select(.name=="skill-reviewer") | .version' .claude-plugin/marketplace.json</code> prints <code>"2.0.0"</code>; the new CHANGELOG entry sits above <code>## 1.9.0</code> and explicitly says <code>BREAKING</code>.
</li>

<li>
<strong>End-to-end dry-run inside the renamed skill.</strong>
With the new skill loaded (no plan mode), invoke <code>/skill-reviewer:optimizing-skill-frontmatter</code> against a sample target — e.g. <code>kit/plugins/code-review/skills/code-review-agent/SKILL.md</code> (advisory; should recommend omit) and <code>kit/plugins/git-agent/skills/commit-agent/SKILL.md</code> (workflow; should already be <code>true</code> — recommend no change). Confirm the table prints, the <code>AskUserQuestion</code> fires, and choosing "Skip invocation changes" leaves files untouched.
<br><em>Why:</em> proves the new step actually classifies correctly and that the confirm-before-flip policy is wired up; catches any wrong-direction Edit before the change ships.
<br><em>Verify:</em> the skill outputs a 2-row classification table with the expected recommendations; <code>git diff</code> on the two sample SKILL.md files is empty after choosing "Skip"; no Edit was performed on the <code>disable-model-invocation</code> line.
</li>
</ol>

## Verification

End-to-end correctness checks once all steps are complete:

- `find kit/plugins/skill-reviewer -type d -name 'optimizing-skill-*'` shows only `optimizing-skill-frontmatter`.
- `grep -rn 'optimizing-skill-descriptions' kit/plugins/skill-reviewer/` returns 0 lines (CHANGELOG historic entries excepted — they describe what the *old* name was at the time and should remain).
- `bash kit/plugins/skill-reviewer/scripts/measure-description.sh kit/plugins/skill-reviewer/skills/optimizing-skill-frontmatter/SKILL.md` reports ≤160 chars with no WARNING.
- The SKILL.md body shows Step 4b with the heuristic table, the `AskUserQuestion` confirmation step, and the explicit "never write `false`" rule.
- `jq '.plugins[] | select(.name=="skill-reviewer") | .version' .claude-plugin/marketplace.json` → `"2.0.0"`.
- Sample run on a known-advisory skill recommends "omit"; sample run on a known-workflow skill recommends "true"; choosing **Skip invocation changes** in the prompt leaves files untouched (verified with `git diff`).

## Next steps (out of scope)

- Rename this plan file from `i-wnat-this-skill-purring-wand.md` to `extend-frontmatter-optimizer-with-invocation-control.md` after approval (cannot rename in plan mode).
- Backfill the broader scope into `reviewing-skills` so its scored audit also flags `disable-model-invocation` mismatches as a finding (advisory-only, no edits).
- Consider adding a CI-side `marketplace.json` lint that warns when a SKILL.md has Edit/Write tools but omits `disable-model-invocation: true`.

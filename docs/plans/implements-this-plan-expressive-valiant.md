# Plan: Finalize add-html-output-to-rename-workflow

> Filename note: This file is the plan-mode placeholder. Before commit, it must
> be renamed to a descriptive name (or removed in favor of the existing
> [add-html-output-to-rename-workflow.md](./add-html-output-to-rename-workflow.md)
> which already documents the broader scope). See Step 0.

## Context

The existing plan at
[docs/plans/add-html-output-to-rename-workflow.md](./add-html-output-to-rename-workflow.md)
describes a 7-step change: extend `plan-to-html` with batch flags, wire the
`review-rename-plans` and `plan-hygiene` commands to call that skill after a
rename, bump the plugin version, and add a CHANGELOG entry.

Inspection of the working tree shows steps 1–3 are **already applied** to:

- `kit/plugins/plan-interview/skills/plan-to-html/SKILL.md` (flag parsing in
  Step 1; conditional in Step 3 and Step 6)
- `kit/plugins/plan-interview/commands/review-rename-plans.md` (new "Step 5 —
  Generate HTML for renamed files"; `Skill` in `allowed-tools`)
- `kit/plugins/plan-interview/commands/plan-hygiene.md` (new "HTML Generation"
  section with Steps A–E; `Skill` in `allowed-tools`)

What remains:

- No CHANGELOG entry yet describes the **rename commands** producing HTML. The
  current top entry `[1.17.0]` is about the `plan-to-html` skill's own visual
  upgrades, not about the commands invoking it.
- `marketplace.json` still pins `plan-interview` at `1.17.0`. Adding new behavior
  to two commands is a MINOR bump per `.claude/rules/marketplace.md` → `1.18.0`.
- The placeholder filename of this plan file must be cleaned up before commit
  per `.claude/rules/plan-hygiene.md` and the global plan-mode rules.

`plugin.json` correctly has no `version` field — leave it untouched.

## Objective

Finish the last three line-items of
[add-html-output-to-rename-workflow.md](./add-html-output-to-rename-workflow.md):
add a CHANGELOG entry for the cross-command HTML behavior, bump the plugin
version in `marketplace.json`, verify end-to-end, and clean up the plan-mode
placeholder filename so the branch is commit-ready.

## Critical files

- `kit/plugins/plan-interview/CHANGELOG.md` — add `[1.18.0]` entry
- `.claude-plugin/marketplace.json` — bump `plan-interview` `version` →
  `1.18.0`
- `docs/plans/implements-this-plan-expressive-valiant.md` (this file) — rename
  to a descriptive slug or delete if redundant with the existing plan

Reuse — do not modify:

- The three already-edited files (`plan-to-html/SKILL.md`,
  `review-rename-plans.md`, `plan-hygiene.md`) — they already implement
  steps 1–3 of the parent plan exactly as specified there.

## Steps

<ol>

<li>
<strong>Clean up this placeholder plan file.</strong>
<br><em>Why:</em> Both
<code>.claude/rules/plan-hygiene.md</code> and the global
<code>plan-mode.md</code> rule forbid committing random-named plan files. The
existing
<a href="./add-html-output-to-rename-workflow.md">add-html-output-to-rename-workflow.md</a>
already documents the full scope, so this placeholder is redundant.
<br><em>Verify:</em> Run <code>ls docs/plans/implements-this-plan-expressive-valiant.md</code>
and confirm it returns "No such file" (after <code>git rm</code> or local
deletion). Confirm
<code>docs/plans/add-html-output-to-rename-workflow.md</code> still exists and
will travel with the implementation commit.
</li>

<li>
<strong>Add a <code>[1.18.0]</code> CHANGELOG entry to
<code>kit/plugins/plan-interview/CHANGELOG.md</code>.</strong>
<br><em>Why:</em> The current top entry covers
<code>plan-to-html</code>'s own visual upgrades; no entry yet names the new
cross-command behavior (rename commands invoking the skill). Per
<code>.claude/rules/marketplace.md</code>, new command behavior requires a
CHANGELOG entry alongside the version bump.
<br><em>Verify:</em> Re-read the CHANGELOG and confirm a new
<code>## [1.18.0] - 2026-05-13</code> section exists above
<code>[1.17.0]</code>, names both
<code>commands/review-rename-plans.md</code> and
<code>commands/plan-hygiene.md</code>, and describes the post-rename HTML
generation (single up-front theme prompt, <code>--no-open</code> per file,
stale <code>.html</code> migration via <code>git mv</code>, separate commit for
regenerated HTML in <code>plan-hygiene</code>). Mention the two new
<code>plan-to-html</code> flags (<code>--theme</code>, <code>--no-open</code>).
</li>

<li>
<strong>Bump <code>plan-interview</code> version in
<code>.claude-plugin/marketplace.json</code> from <code>1.17.0</code> →
<code>1.18.0</code>.</strong>
<br><em>Why:</em> Adding new behavior to two existing commands is a MINOR bump
per <code>.claude/rules/marketplace.md</code>.
<br><em>Verify:</em> Open <code>.claude-plugin/marketplace.json</code>, find
the <code>plan-interview</code> entry, and confirm
<code>"version": "1.18.0"</code>. Confirm
<code>kit/plugins/plan-interview/.claude-plugin/plugin.json</code> still does
NOT contain a <code>version</code> field (project rule: version lives in
marketplace only for relative-path plugins). The settings auto-validator runs
on save — confirm no JSON syntax errors are flagged.
</li>

<li>
<strong>End-to-end sanity test of the batch invocation.</strong>
<br><em>Why:</em> Confirms the wiring between the rename commands and the
extended skill works on disk, not just on paper.
<br><em>Verify:</em> Pick any existing plan under <code>docs/plans/</code> and
invoke
<code>/plan-interview:plan-to-html docs/plans/&lt;file&gt;.md --theme=developer --no-open</code>.
Confirm: (a) zero <code>AskUserQuestion</code> prompts fire; (b) the
<code>.html</code> file is written next to the <code>.md</code>; (c) the report
line includes <code>(theme: developer)</code>. If a throwaway plan is desired
for a fuller test, create one with a misaligned filename and run
<code>/plan-interview:review-rename-plans</code> on it — confirm the rename
applies, the theme is asked exactly once, and the resulting <code>.html</code>
lands.
</li>

</ol>

## Verification

End-to-end confirmation that the branch is ready to ship:

1. **Working tree is coherent**: `git status` shows the three already-modified
   files (`plan-to-html/SKILL.md`, `review-rename-plans.md`,
   `plan-hygiene.md`), plus the new CHANGELOG entry and the marketplace
   version bump. The placeholder plan file
   (`implements-this-plan-expressive-valiant.md`) is no longer present.
2. **Skill flags work standalone**: invoking
   `/plan-interview:plan-to-html docs/plans/<any>.md --theme=developer --no-open`
   produces the `.html` with zero `AskUserQuestion` prompts.
3. **CHANGELOG + marketplace align**: `marketplace.json` shows `1.18.0` for
   `plan-interview`; the top CHANGELOG entry is `[1.18.0]` and names both
   rename commands. `plugin.json` for `plan-interview` does not contain a
   `version` field.
4. **No regressions**: the existing single-file
   `/plan-interview:plan-to-html <path>` invocation (without flags) still
   prompts for theme and browser-open as before.
5. **Pre-commit hygiene**: no random-named plan files remain under
   `docs/plans/`; the existing
   `add-html-output-to-rename-workflow.md` will be included in the same commit
   as the implementation changes per project convention.

## Next steps (out of scope)

- Commit and push the branch (`feat/plan-interview-html`) — defer until the
  user confirms; the project rule is to bundle plan and implementation in one
  commit.
- Items already listed as out-of-scope in the parent plan
  ([add-html-output-to-rename-workflow.md](./add-html-output-to-rename-workflow.md))
  remain so: extending `documenting-plans` / `plan-status` to regenerate HTML,
  a `--theme` settings default, and backfilling HTML for legacy plans.

## Unresolved questions

None — the parent plan resolved scope, default behavior, batch theme UX, and
stale-HTML handling. Only the three finalize steps above remain.

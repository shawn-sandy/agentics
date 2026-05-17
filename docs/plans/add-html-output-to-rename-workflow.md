---
status: completed
type: artifact
created: 2026-05-13
---

# Plan: Generate HTML after plan rename via plan-to-html skill

> Filename note: this plan has been finalized as `add-html-output-to-rename-workflow.md`.

## Context

The `plan-interview` plugin has two rename workflows that end at "renames applied" without producing any downstream artifact:

- `kit/plugins/plan-interview/commands/review-rename-plans.md` — per-file/directory reviewer that offers to rename plans whose filenames don't match their content. Ends at a "Renames Applied" summary table.
- `kit/plugins/plan-interview/commands/plan-hygiene.md` — batch scanner for randomly-named plan files. Ends after `git mv` + `chore:` commit.

Separately, `kit/plugins/plan-interview/skills/plan-to-html/SKILL.md` already exists and converts a single plan to a themed `.html` file alongside it. Today the only way to invoke it is interactively (single-file).

After a rename, the natural next step is to refresh the HTML view of that plan so the on-disk artifact matches the new filename and content. The user wants the rename workflows to always run `plan-to-html` on renamed files when they finish, reusing the existing skill rather than reimplementing its logic.

## Objective

Extend both rename commands so that immediately after a successful rename, they invoke the `plan-interview:plan-to-html` skill for every renamed file using a single theme captured once up-front, and migrate any stale `.html` matching the old basename via `git mv` before regenerating. Generate HTML for every renamed file by default — no opt-in prompt.

## Critical files

- `kit/plugins/plan-interview/commands/review-rename-plans.md` — add post-rename HTML step
- `kit/plugins/plan-interview/commands/plan-hygiene.md` — add post-rename HTML step (after the existing commit)
- `kit/plugins/plan-interview/skills/plan-to-html/SKILL.md` — extend argument parsing to support non-interactive batch invocation (theme passed in, browser-open suppressed)
- `kit/plugins/plan-interview/CHANGELOG.md` — document the change
- `.claude-plugin/marketplace.json` — bump `plan-interview` version (MINOR)

Reuse — do not reimplement:

- Existing skill at `skills/plan-to-html/SKILL.md` (Step 1 path resolution, Step 4 path derivation, Step 5 write, Step 7 report) — the rename commands will invoke this skill, not duplicate its logic.
- The cross-skill invocation pattern already used by `skills/documenting-plans/SKILL.md` (declares `Skill` in `allowed-tools`, invokes by qualified name `plan-interview:<skill>`, passes path as args).

## Approach summary

1. **Extend `plan-to-html` SKILL.md** to accept two optional flags in `$ARGUMENTS` after the path: `--theme=<default|developer|document|minimal>` and `--no-open`. When `--theme` is provided, skip Step 3's theme `AskUserQuestion` and use the supplied theme. When `--no-open` is provided, skip Step 6's browser-open `AskUserQuestion`. This makes the skill safe to invoke in batch from another command without N prompts per file.

2. **In `review-rename-plans.md`**, after Step 4 ("Renames Applied" table is shown), add a new Step 5 that:
   - For each renamed file, check whether `<old-basename>.html` exists in the same directory; if so, `git mv` it to `<new-basename>.html` (with `mv` + `git add` fallback) so the stale artifact follows the rename and history is preserved.
   - Ask theme once via `AskUserQuestion` (Default / Developer / Document / Minimal).
   - For each renamed file, invoke the `Skill` tool with `skill: "plan-interview:plan-to-html"` and `args: "<new-path> --theme=<chosen> --no-open"`.
   - Append an "HTML Generated" column to the summary, or print a separate table listing `<file>.html (theme: <chosen>)`.
   - Add `Skill` to the command's `allowed-tools`.

3. **In `plan-hygiene.md`**, after the existing `chore: rename plan files to descriptive conventions` commit, add an analogous post-commit Step that:
   - Same stale-html `git mv` migration per renamed file (staged into a follow-up commit, not the rename commit).
   - Same single up-front theme prompt.
   - Same per-file `Skill` invocation.
   - Stage the regenerated `.html` files and commit them with `chore: regenerate plan HTML after rename`.
   - Add `Skill` to the command's `allowed-tools`.

4. **Version + changelog**: bump `plan-interview` MINOR in `marketplace.json`; add a CHANGELOG entry describing the new post-rename HTML generation.

## Steps

<ol>
<li>
<strong>Extend <code>plan-to-html</code> SKILL.md to accept <code>--theme=&lt;name&gt;</code> and <code>--no-open</code> flags.</strong>
<br><em>Why:</em> Batch invocation from rename commands must not trigger 2 <code>AskUserQuestion</code> prompts per file. Flags let the caller capture the theme once up-front and suppress the browser prompt.
<br><em>Verify:</em> Re-read <code>skills/plan-to-html/SKILL.md</code> and confirm Step 1 parses optional flags from <code>$ARGUMENTS</code> after the path; Step 3 uses the supplied theme and skips the question when <code>--theme</code> is present; Step 6 skips browser-open when <code>--no-open</code> is present. Manually invoke the skill with <code>args: "docs/plans/sample.md --theme=developer --no-open"</code> and confirm no prompts fire.
</li>

<li>
<strong>Add a "Generate HTML" step to <code>commands/review-rename-plans.md</code>.</strong>
<br><em>Why:</em> The single-file/per-directory rename flow should always refresh the HTML view of every file it just renamed.
<br><em>Verify:</em> Re-read the command file and confirm: (a) <code>Skill</code> is listed in <code>allowed-tools</code>; (b) a new step appears after the "Renames Applied" summary that migrates stale <code>.html</code> via <code>git mv</code>, asks theme once, then calls <code>plan-interview:plan-to-html</code> per renamed file with <code>--theme=&lt;chosen&gt; --no-open</code>; (c) the final summary lists generated HTML paths. Dry-run by invoking the command on a throwaway plan and confirm the <code>.html</code> file is produced.
</li>

<li>
<strong>Add a "Generate HTML" step to <code>commands/plan-hygiene.md</code> after the existing <code>chore:</code> rename commit.</strong>
<br><em>Why:</em> Batch random-name renames should also refresh the HTML; placing the HTML step after the rename commit keeps each concern in its own commit.
<br><em>Verify:</em> Re-read the command file and confirm: (a) <code>Skill</code> is listed in <code>allowed-tools</code>; (b) after the existing rename commit, a new step migrates stale <code>.html</code> via <code>git mv</code>, asks theme once, calls <code>plan-interview:plan-to-html</code> per file with the chosen theme and <code>--no-open</code>, and commits the regenerated files with <code>chore: regenerate plan HTML after rename</code>. Dry-run on a fixture directory with one random-named plan and confirm two commits land (rename, then HTML regen).
</li>

<li>
<strong>Add a CHANGELOG entry to <code>kit/plugins/plan-interview/CHANGELOG.md</code>.</strong>
<br><em>Why:</em> Per project conventions, plugin behavior changes require a CHANGELOG entry alongside the version bump.
<br><em>Verify:</em> Open the CHANGELOG and confirm a new entry exists under the bumped version that names both commands and the new post-rename HTML behavior.
</li>

<li>
<strong>Bump <code>plan-interview</code> version in <code>.claude-plugin/marketplace.json</code> (MINOR).</strong>
<br><em>Why:</em> Adding new behavior to existing commands is a MINOR bump per <code>.claude/rules/marketplace.md</code>.
<br><em>Verify:</em> Open <code>.claude-plugin/marketplace.json</code>, locate the <code>plan-interview</code> entry, and confirm the <code>version</code> field is incremented in the MINOR position. Confirm no <code>version</code> field is set in <code>kit/plugins/plan-interview/.claude-plugin/plugin.json</code> (project rule — version lives in marketplace only for relative-path plugins).
</li>

<li>
<strong>End-to-end sanity test on a real plan.</strong>
<br><em>Why:</em> Confirms the wiring between the rename commands and the extended skill works on disk, not just in spec.
<br><em>Verify:</em> Create a throwaway plan file with a clearly mismatched filename in <code>docs/plans/</code>. Run <code>/plan-interview:review-rename-plans docs/plans/&lt;file&gt;.md</code>. Confirm: (a) the rename is offered and applied; (b) the theme question fires exactly once; (c) the new <code>.html</code> file lands next to the renamed <code>.md</code>; (d) no stale <code>.html</code> with the old basename remains in the directory. Repeat with a random-named fixture under <code>plan-hygiene</code> and confirm both commits land.
</li>

<li>
<strong>Rename this plan file to a descriptive name and commit.</strong>
<br><em>Why:</em> The current filename (<code>i-want-to-add-sparkling-bonbon.md</code>) is a random placeholder; per <code>.claude/rules/plan-hygiene.md</code> plans should have descriptive kebab-case names, and per global plan-mode rules the plan must be committed alongside the related changes.
<br><em>Verify:</em> <code>git mv docs/plans/i-want-to-add-sparkling-bonbon.md docs/plans/add-html-output-to-rename-workflow.md</code>, confirm the new path exists, and include it in the same commit as the implementation changes.
</li>
</ol>

## Verification

End-to-end confirmation that the plan was executed correctly:

1. **Skill flags work standalone:** invoking `/plan-interview:plan-to-html docs/plans/<any>.md --theme=developer --no-open` produces the `.html` with the developer theme and fires zero `AskUserQuestion` prompts.
2. **`review-rename-plans` end-to-end:** on a directory containing one plan with a misaligned filename, the command renames it, asks the theme once, generates the `.html`, and the resulting summary lists both the renamed `.md` and the new `.html`.
3. **`plan-hygiene` end-to-end:** on a directory containing one random-named plan (and optionally a stale `<old-basename>.html`), the command produces two commits — `chore: rename plan files to descriptive conventions` and `chore: regenerate plan HTML after rename` — and the stale `.html` has been `git mv`'d, not left orphaned.
4. **No regressions:** running either command with `--help`/no arguments still surfaces the original behavior; the existing single-file `/plan-interview:plan-to-html <path>` invocation (without flags) still prompts for theme and browser-open as before.
5. **Marketplace + changelog:** `marketplace.json` shows the new MINOR version for `plan-interview`; CHANGELOG describes the post-rename HTML behavior; `plugin.json` for `plan-interview` does not contain a `version` field.

## Next steps (out of scope)

- Extend other plan workflows (e.g. `documenting-plans`, `plan-status` post-completion) to also offer HTML regeneration.
- Add a `--theme` default to `.claude/settings.json` so the rename workflows don't need to ask at all when a user preference is set.
- Backfill `.html` files for existing plans under `docs/plans/` that don't have one yet.

## Unresolved questions

None — clarified scope (both commands), default behavior (always generate), batch theme UX (ask once up-front), and stale-HTML handling (`git mv`) up-front.

---
status: completed
type: standard
created: 2026-05-13
modified: 2026-05-13
---

# Plan: Add HTML output to the plan-interview skill (rename + save findings)

> Filename note: this file uses the plan-mode placeholder slug. Step 6 renames
> it to `add-html-output-to-plan-interview-skill.md` before commit.

## Context

The previous round of work wired the `plan-to-html` skill into the two
*command* surfaces that rename plans
([commands/review-rename-plans.md](../../kit/plugins/plan-interview/commands/review-rename-plans.md),
[commands/plan-hygiene.md](../../kit/plugins/plan-interview/commands/plan-hygiene.md)).
That shipped in commit `6493c1e` as `plan-interview` v1.18.0.

The `plan-interview` **skill** itself has two natural moments where the plan
file changes and an HTML refresh is useful:

- **Step 2 — rename**
  ([skills/plan-interview/SKILL.md:138–161](../../kit/plugins/plan-interview/skills/plan-interview/SKILL.md))
  renames the file via `Bash mv` and updates the H1 via `Edit`.
- **Step 6 — save findings**
  ([skills/plan-interview/SKILL.md:456–476](../../kit/plugins/plan-interview/skills/plan-interview/SKILL.md))
  appends a `## Interview Summary` to the plan via `Edit` when the user
  confirms.

Today neither moment generates HTML. The user wants both to offer HTML
generation — so the artifact alongside the plan reflects the latest renamed
filename **and** the latest interview summary. Without the Step 6 hook, the
HTML generated at Step 2 would be stale by the end of the interview.

The `plan-to-html` skill already accepts a file-path argument and supports
`--theme=<value>` and `--no-open` flags (added in v1.18.0 work). It also has
its own overwrite prompt for existing `.html` files (its Step 4), so a
"regenerate" call from Step 6 is well-supported. Invoking it via the `Skill`
tool is the established pattern in `review-rename-plans.md` and
`plan-hygiene.md`.

The user has confirmed (this session) that the invocation should pass
`--no-open` to avoid disrupting the in-progress interview with a browser tab
launch. The theme prompt inside `plan-to-html` is acceptable as a single extra
question.

## Objective

Extend `skills/plan-interview/SKILL.md` so that:

- After a user-confirmed **rename in Step 2**, the skill offers to generate
  HTML for the renamed plan via `plan-to-html`.
- After a user-confirmed **summary append in Step 6**, the skill offers to
  generate (or regenerate) the HTML so it reflects the appended summary.

Both invocations pass `--no-open`. Ship as a MINOR version bump
(1.18.0 → 1.19.0) with a CHANGELOG entry, and clean up the placeholder plan
filename.

## Critical files

- [kit/plugins/plan-interview/skills/plan-interview/SKILL.md](../../kit/plugins/plan-interview/skills/plan-interview/SKILL.md)
  — add `Skill` to `allowed-tools` (line 4); insert HTML-offer paragraphs at
  the end of the Step 2 "If the user confirms" block (after line 159) and at
  the end of the Step 6 "If they confirm" block (after the `Edit` write
  around line 466).
- [kit/plugins/plan-interview/CHANGELOG.md](../../kit/plugins/plan-interview/CHANGELOG.md)
  — add `## [1.19.0] - 2026-05-13` entry above `[1.18.0]`.
- [.claude-plugin/marketplace.json](../../.claude-plugin/marketplace.json) —
  bump `plan-interview` `version` from `"1.18.0"` to `"1.19.0"`.
- [docs/plans/implements-this-plan-expressive-valiant.md](./implements-this-plan-expressive-valiant.md)
  (this file) — rename to `add-html-output-to-plan-interview-skill.md` before
  commit.

Reuse — do not modify:

- [skills/plan-to-html/SKILL.md](../../kit/plugins/plan-interview/skills/plan-to-html/SKILL.md)
  — already accepts a path argument and the `--no-open` flag, and already
  handles the overwrite prompt for existing `.html` (its Step 4). No changes
  needed.
- The two command files (`review-rename-plans.md`, `plan-hygiene.md`) — they
  handle the *command* surface; this plan only touches the *skill* surface.
- `kit/plugins/plan-interview/.claude-plugin/plugin.json` — has no `version`
  field by project convention; leave alone.

## Steps

<ol>

<li>
<strong>Add <code>Skill</code> to <code>allowed-tools</code> on the
<code>plan-interview</code> skill.</strong>
<br><em>Why:</em> The skill will invoke <code>plan-to-html</code> via the
<code>Skill</code> tool in both Step 2 and Step 6. Without declaring it, the
user gets a mid-skill permission prompt that breaks the interview flow.
<br><em>Verify:</em> Re-read line 4 of
<code>skills/plan-interview/SKILL.md</code> and confirm the line ends with
<code>…, TodoWrite, Skill</code>.
</li>

<li>
<strong>Insert an HTML-generation offer at the end of the Step 2 "If the user
confirms" block</strong> (immediately after the bullet ending
"<code>…Step 6's save operation) reference the new path.</code>" at line 159
— and before the line "If the user declines, proceed without changes." at
line 161).
<br><em>Why:</em> This is the moment the rename has just been applied and the
resolved path now points to the new filename — exactly the state needed for
HTML generation. The user explicitly asked for the offer to fire on rename.
<br><em>Verify:</em> Re-read Step 2 and confirm the new paragraph (a) sits
inside the "If the user confirms" block, (b) uses <code>AskUserQuestion</code>
with options like <code>Yes, generate HTML</code> / <code>Skip</code>,
(c) on confirmation invokes the <code>Skill</code> tool to call
<code>plan-to-html</code> with the <strong>new</strong> file path and
<code>--no-open</code>, (d) explicitly notes that <code>plan-to-html</code>
will prompt for a theme, and (e) on decline simply continues to the rest of
Step 2. The fall-through "If the user declines, proceed without changes." line
still belongs to the rename offer — confirm it remains the next paragraph.
</li>

<li>
<strong>Insert a parallel HTML-(re)generation offer at the end of the Step 6
"If they confirm" block</strong> (immediately after the existing instruction
to append the summary via <code>Edit</code> — around line 466 — and before the
<code>skill-review</code> mode branch).
<br><em>Why:</em> After Step 6 appends the interview summary to the plan, any
HTML produced earlier in Step 2 is stale. Offering regeneration here keeps the
artifact aligned with the final plan content. If no HTML was generated in
Step 2, this offer is also the right time to produce one from the updated
plan.
<br><em>Verify:</em> Re-read Step 6 and confirm the new paragraph (a) only
fires when the user confirms the summary append (i.e., inside the "If they
confirm" branch — not on decline), (b) uses <code>AskUserQuestion</code> with
options like <code>Yes, generate HTML</code> / <code>Skip</code> and explicitly
notes "regenerate" when an existing <code>.html</code> is present so the user
understands the overwrite prompt that may follow from <code>plan-to-html</code>
Step 4, (c) invokes <code>Skill</code> to call <code>plan-to-html</code> with
the current resolved plan path (which is the renamed path when Step 2 renamed
the file) and <code>--no-open</code>, (d) on decline falls through to the
existing <code>skill-review</code> mode branch unchanged.
</li>

<li>
<strong>Bump <code>plan-interview</code> from <code>1.18.0</code> to
<code>1.19.0</code> in <code>.claude-plugin/marketplace.json</code>.</strong>
<br><em>Why:</em> New behavior added to an existing skill is a MINOR bump per
<code>.claude/rules/marketplace.md</code>.
<br><em>Verify:</em> Open
<code>.claude-plugin/marketplace.json</code>, find the
<code>plan-interview</code> entry, and confirm
<code>"version": "1.19.0"</code>. Confirm
<code>kit/plugins/plan-interview/.claude-plugin/plugin.json</code> still does
NOT contain a <code>version</code> field. The settings auto-validator runs on
save — confirm no JSON syntax errors.
</li>

<li>
<strong>Add a <code>## [1.19.0] - 2026-05-13</code> CHANGELOG entry above the
existing <code>[1.18.0]</code> section</strong> in
<code>kit/plugins/plan-interview/CHANGELOG.md</code>.
<br><em>Why:</em> Per <code>.claude/rules/marketplace.md</code>, every version
bump needs a CHANGELOG entry. This one names the new skill-level behavior,
separating it from the v1.18.0 command-level wiring.
<br><em>Verify:</em> Re-read the CHANGELOG and confirm the new
<code>## [1.19.0] - 2026-05-13</code> section sits above <code>[1.18.0]</code>
and names: (a) <code>skills/plan-interview/SKILL.md</code> Step 2 HTML offer
on rename, (b) Step 6 HTML (re)generation offer after the summary append,
(c) both invocations use <code>Skill</code> with <code>--no-open</code>,
(d) <code>Skill</code> added to <code>allowed-tools</code>.
</li>

<li>
<strong>Rename the placeholder plan file</strong> from
<code>docs/plans/implements-this-plan-expressive-valiant.md</code> to
<code>docs/plans/add-html-output-to-plan-interview-skill.md</code> using
<code>git mv</code>.
<br><em>Why:</em> The placeholder slug violates
<code>.claude/rules/plan-hygiene.md</code> and the global plan-mode rule
against random-named plan files. The new name describes the actual change.
The placeholder was committed in <code>6493c1e</code>, so a <code>git mv</code>
(not a plain <code>rm</code>) is needed to preserve history.
<br><em>Verify:</em> Run <code>ls docs/plans/</code> and confirm:
(a) <code>implements-this-plan-expressive-valiant.md</code> is gone;
(b) <code>add-html-output-to-plan-interview-skill.md</code> exists; (c) the
relative links inside the renamed file
(<code>../../kit/plugins/…</code> and <code>./add-html-output-to-rename-workflow.md</code>)
are independent of the file's own name and still resolve.
</li>

<li>
<strong>End-to-end sanity test of both new offer points.</strong>
<br><em>Why:</em> Confirms the wiring between the skill's two HTML-offering
moments and <code>plan-to-html</code> works on disk.
<br><em>Verify:</em> Create a throwaway plan under <code>docs/plans/</code>
with a deliberately random filename (e.g.
<code>fuzzy-swimming-pearl.md</code>) containing a minimal valid plan body.
Invoke <code>/plan-interview:plan-interview docs/plans/fuzzy-swimming-pearl.md</code>.
Confirm:
<br>(a) Step 2 detects the random name and offers a rename;
<br>(b) accepting the rename triggers a new <code>AskUserQuestion</code> for
HTML — accept, confirm <code>plan-to-html</code> prompts for theme but NOT
browser-open, and the <code>.html</code> lands next to the renamed
<code>.md</code>;
<br>(c) the interview proceeds through Step 5 and into Step 6;
<br>(d) at Step 6, accept the summary append, then a second
<code>AskUserQuestion</code> fires offering HTML regeneration —
<code>plan-to-html</code> Step 4 prompts to overwrite the existing
<code>.html</code>, then writes the refreshed file;
<br>(e) opening the regenerated <code>.html</code> shows the
<code>## Interview Summary</code> section as a new <code>&lt;section&gt;</code>
in the sidebar and main content.
<br>Delete the throwaway files before committing.
</li>

</ol>

## Verification

End-to-end confirmation that the branch is ready to ship:

1. **Skill change is minimal and scoped**: `git diff` on
   `skills/plan-interview/SKILL.md` shows only (a) `Skill` added to
   `allowed-tools`, (b) one new paragraph inside Step 2's "If the user
   confirms" block, and (c) one new paragraph inside Step 6's "If they
   confirm" block. No other steps, no removals.
2. **Plan-to-html is untouched**: `git diff` shows no changes to
   `skills/plan-to-html/SKILL.md`.
3. **Decline paths still work**: declining the rename in Step 2 skips both
   the rename and its HTML offer; declining the summary append in Step 6
   skips both the append and its HTML offer.
4. **Version + CHANGELOG align**: `marketplace.json` shows
   `"version": "1.19.0"` for `plan-interview`; the top CHANGELOG entry is
   `[1.19.0] - 2026-05-13` and names the skill (not the commands), covering
   both Step 2 and Step 6 changes.
5. **Plan filename is clean**:
   `docs/plans/add-html-output-to-plan-interview-skill.md` exists;
   `docs/plans/implements-this-plan-expressive-valiant.md` is gone.
6. **No regressions in unrelated flows**:
   `/plan-interview:plan-to-html <path>` (standalone) still prompts for
   theme and browser-open as before; the two rename commands
   (`review-rename-plans`, `plan-hygiene`) still pass `--theme` and
   `--no-open` and produce HTML.

## Next steps (out of scope)

- Apply the same HTML-on-write pattern to other skills that modify plans
  (`plan-status`, `documenting-plans`).
- A `--theme` settings default so the skill could pass `--theme` automatically
  and skip the in-flow theme prompt entirely.
- Track the previously selected theme within a single interview session and
  reuse it for the Step 6 regeneration so the user is not prompted twice.

## Unresolved questions

None — the HTML invocation UX (`--no-open` only, theme prompt allowed) was
confirmed this session, and Step 6 regeneration was added per the user's
follow-up.

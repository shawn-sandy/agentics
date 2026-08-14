# The three completion gates

Loaded once implementation is done. Covers Steps 3, 4, and 5 and the
spec-is-source-of-truth rules they enforce.

## Step 3 — Acceptance criteria gate (mandatory)

1. Read each criterion from the spec's `## Acceptance Criteria` bullets.
2. Verify each one — run the relevant command or inspect the changed files.
3. Flip a bullet to `- [x]` only after confirming it; flip back to `- [ ]` to
   undo.
4. If any criterion cannot be verified, list the unverified items via
   `AskUserQuestion` ("Mark them as done anyway?" — `Yes, check them off` /
   `No, leave unchecked`). Criteria checked off this way are **not verified**:
   record each one as a `## Completion Report` bullet naming the criterion and
   that it was accepted unverified.
5. Every criterion checked → continue to Step 4. Any left unchecked → set
   `status: in-progress`, record each unchecked criterion as a
   `## Completion Report` bullet, and re-render (which stamps the status into
   all three HTML representations). Then **continue to Step 4 anyway** — the
   objective still has to be verified, and its result belongs in the same
   report. An unchecked criterion blocks `completed`, not the rest of the run.

**Do not set `status: completed` here** — that happens in Step 5, after
end-to-end verification. Writing it now would advertise a completed plan on
the gallery for the whole duration of Step 4's fix loop.

## Step 4 — End-to-end verification gate (mandatory)

Confirms the *objective* works, not just that criteria are met.

1. Read the plan's Verification and Tests sections.
2. Run the objective-verification test via its authored **Run** command; run
   the other test entries via the project's test runner against their **File**
   paths (those cards carry no per-card run command by design — a missing one
   is not a defect). No detectable runner → run only the objective test and say
   so. The objective test's **Run** command always exists and always runs —
   Tier 2 included, where it is a plain shell command (`grep -q`, `test -f`).
   If the spec somehow has no **Run**, author one now against the objective,
   re-render, then run it; never fall back to inspection alone.
3. Confirm the objective test passes and every verification step holds.
4. **On failure — fix and re-verify (bounded loop):** diagnose, fix the source
   files, re-run from sub-step 2, up to 3 times. Still failing → STOP and ask
   via `AskUserQuestion` ("End-to-end verification is still failing after 3
   fix attempts: <summary>. How do you want to proceed?") with `Keep trying` /
   `Mark in-progress and stop` / `Mark completed anyway`. Set status per the
   chosen option; for either "Mark" option add a Completion Report bullet
   naming the failing check and reason.
5. Proceed only once verification holds — or the user explicitly chose to
   proceed anyway. Report the outcome briefly.

## Step 5 — Completion checklist gate (mandatory)

1. Decide the final status:
   - Steps 3 and 4 both held (every criterion `- [x]`, end-to-end verification
     passing) → `completed`.
   - The user answered `Mark completed anyway` at Step 4.4 → `completed`. Their
     explicit override stands; do not walk it back here.
   - Anything else → `in-progress`. This is a legitimate terminal state, not a
     failure to repair.
2. Write a `## Completion Report` section (after `## Acceptance Criteria`)
   listing every gap: one `- <exact step/criterion> — <reason>` bullet each,
   never a generic "some steps incomplete". It carries the Step 3.4 bullets
   (criteria accepted unverified), the Step 3.5 bullets (criteria left
   unchecked), and the Step 4.4 bullet (failing check) — **an unverified or
   overridden item is a permanent record, not a gap to clear.** Delete the
   section only when a later run genuinely verifies every item in it; the
   default "No items to report" sentence then returns on the next re-render.
3. Re-render, then run the check:

   ```bash
   plan-agent-render "<stem>.md" -o "<stem>.html" --check
   ```

   It prints one row per property — `html`, `steps`, `criteria` — and exits
   non-zero if any fails. `html` compares the file on disk against a fresh
   in-memory render and names the first differing line; `steps` and `criteria`
   read the spec's `[x]` and `- [x]` markers and are **skipped unless the spec
   says `status: completed`**, because partial progress below that status is
   the correct state, not a defect. A non-zero exit names the property that
   broke, so read the row rather than searching the HTML: the check evaluates
   the render, and nothing here is answerable by grepping markup.

   Because `html` compares the whole file byte for byte, it already subsumes
   everything the old hand-inspection list named — the three status
   representations, the criteria inputs, the completed step cards, and the
   completion checklist — so none of them has to be located or confirmed
   individually. That is why this gate names no selectors: a passing `html` row
   is a stronger statement than any of them.
4. If the check fails, fix the **spec**, never the HTML — and never by
   promoting `status:` to satisfy the check. The status is an output of
   sub-step 1, not a knob for making sub-step 3 pass. A failing `html` row
   means the re-render was skipped or the HTML was hand-edited: re-render it.
5. **Update the linked tracking ticket.** Skip when the spec carries no
   `issue:` key. Check the URL before anything else: it is frontmatter, it
   reaches this step unvalidated, and it is about to become a shell argument.
   Proceed only when it starts `https://` **and** its host is `github.com` or
   a GitLab host; report one line and skip the rest otherwise. A Jira or
   Linear URL is a valid thing for a plan to link and still renders on the
   page — there is simply no CLI here to drive it, and guessing GitLab for
   every non-GitHub host would fire `glab` at a host it cannot serve. Always
   quote the URL in the command (`"<url>"`).

   Then write a one-paragraph summary — plan filename, final status, `N/M`
   criteria checked, every `## Completion Report` bullet verbatim — to a
   temporary file, and pass that **file** to every command below. Never
   interpolate the summary into a shell string: a Completion Report bullet
   routinely contains backticks naming a file or function, and `` `x` ``,
   `$(x)`, and `$VAR` all expand before the CLI ever sees them — corrupting
   the comment in the ordinary case and executing plan text in the worst one.
   Then:
   - Status `completed`: ask via `AskUserQuestion` ("The plan links tracking
     issue `<url>`. Close it?" / `Yes, close it` / `No, leave it open`), and on
     yes run, for a `github.com` URL,
     `gh issue comment "<url>" --body-file <file> && gh issue close "<url>"`
     — or, for GitLab,
     `glab issue note "<url>" -m "$(cat <file>)" && glab issue close "<url>"`.
     Closing is visible to everyone watching the ticket, so it is never
     automatic.
   - Status `in-progress`: never close and never ask — post the summary as a
     comment (`gh issue comment "<url>" --body-file <file>` / `glab issue note
     "<url>" -m "$(cat <file>)"`) so the ticket shows where the work stopped.
     A comment does not change the ticket's state.

   A missing CLI, a failed auth, or a failed command is a one-line report with
   the ticket URL, then continue — an open ticket never blocks completion.

`/plan-agent:finalize-plan` applies the same completion rules to a plan
implemented outside this skill, including an auto-check-verified-only mode and
its HTML-drift reconciliation. Keep the two consistent when either changes.

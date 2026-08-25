# Writing the completions, the ticket, and delivery

Loaded at Step 5. Covers Step 5 (spec and legacy modes), Step 5f, and Step 6.

## Step 5 — Write the completions

### Spec mode (the normal path)

Edit `<stem>.md` only — never the HTML. The renderer derives everything the old HTML surgery wrote by hand: the three status representations (`<html data-status>`, the `plan-status` meta tag, the visible badge), criteria `checked` attributes, `.step-card completed` classes and `done` chips, the completion checklist (cc1–cc3 plus `all-complete`), and the Completion Report markup.

**5a0 — Phase gate (phased specs only).** If `## Steps` carries `### Phase: <name>` headings, list every phase holding at least one step with no `[x]` marker. **If that list is non-empty, this plan is not completable:** set `status: in-progress` in 5a, skip 5c entirely (never mass-mark the steps of a phase that was never implemented), and record one bullet per unfinished phase in 5d. A spec with no phase headings skips this and behaves exactly as before.

The failure mode this closes: `build` stops at its first phase boundary by design, so a plan that ran correctly and stopped early looks — to a criteria-and-evidence check alone — a lot like a plan that is done. Naming the phase is what tells the user which one to resume.

**5a — Status frontmatter.** Set `status: completed` in the YAML frontmatter (add the key, or the whole frontmatter block, if absent).

**5b — Acceptance criteria.** Flip bullets under `## Acceptance Criteria` to `- [x] <text>`:
- User chose **check all**: flip every bullet.
- User chose **only auto-check verified**: flip only criteria marked `verified` in Step 3b (plus any flagged by Step 2's drift reconciliation). Leave the rest as `- [ ] <text>` (normalize plain `- ` bullets to `- [ ]` so the remaining work is visible). **Downgrade rule:** if any criterion remains unchecked, set `status: in-progress` in 5a instead of `completed`.

**5c — Steps.** Mark every step done by inserting the marker after the number: `1. <action>…` → `1. [x] <action>…` (skip steps that already carry `[x]`). **Skipped entirely when 5a0's phase gate fired** — the unmarked steps are the record of where the work stopped.

**5d — Completion report.** If every criterion was verified and checked and the objective test did not fail, remove any existing `## Completion Report` section and add nothing. Otherwise write (or replace) the section — one `- <item> — <reason>` bullet per finding, the em dash separating item from reason:

```markdown
## Completion Report

- <unverified criterion text> — No matching file found in codebase
- Implementation evidence gap — 3/5 tokens found; missing: AuthProvider, useAuth
- Objective-verification test failed — npm test -- objective exited with code 1
- Unfinished phase "Render" — steps 4-6 carry no [x]; resume with /plan-agent:build <stem>.md
```

Each item names the specific criterion, token gap, or test — never a generic summary. Place the section after `## Acceptance Criteria`.

**5e — Re-render, then check.** Regenerate the HTML from the spec and confirm it succeeded.

Where it goes depends on how the plan was delivered, and `<stem>.html`'s
existence is the signal. **Sibling exists** — the plan is a file; overwrite it:

```bash
plan-agent-render "<stem>.md" -o "<stem>.html"
```

**No sibling** — the plan lives at a claude.ai artifact. Render to the
scratchpad and republish to the spec's `artifact-url:`, passing that URL to
`Artifact` so the shared page updates in place rather than becoming a second
copy. Completion is exactly when the shared page most needs to be current — it
is the state everyone else reads:

```bash
plan-agent-render "<stem>.md" -o "$SCRATCHPAD/<stem>.html"
```

Never write `<stem>.html` in that case: it resurrects a file the author chose
not to publish and flips the plan's gallery card off its artifact.

`plan-agent-render` ships with this plugin in `bin/`, which Claude Code puts on
the Bash tool's `PATH` — invoke it by bare name, never by path.

Exit 1 means the spec edit broke the format — fix the reported problem in the markdown and re-run. Never hand-edit the HTML to compensate. (The plugin's `render-plan-html.py` hook also re-renders on every spec write, but run the script explicitly so a failure surfaces here, not silently.)

Then verify the result with the same gate `build` Step 5.3 runs — the two are
deliberately kept consistent:

```bash
plan-agent-render "<stem>.md" -o "<stem>.html" --check
```

For an artifact-delivered plan point `--check` at the scratchpad render
instead; it compares a file on disk against a fresh in-memory render, so it
needs whichever file was just written.

It prints one row per property — `html`, `steps`, `criteria` — and exits
non-zero if any fails. `html` compares the file on disk against a fresh
in-memory render and names the first differing line; `steps` and `criteria`
read the spec's `[x]` and `- [x]` markers and are **skipped unless the spec
says `status: completed`**, so a spec the downgrade rule sent to
`in-progress` is expected to pass with those rows skipped. A non-zero exit
names the property that broke: fix the **spec** and re-render, never the HTML,
and never by promoting `status:` to satisfy the check. Read the reported row
rather than searching the markup — nothing here is answerable by grepping the
rendered HTML.

### Legacy mode (no spec — HTML attribute surgery)

Use `Edit` on the plan HTML file. Read the file once before any edit.

**5a — Status representations (all three must update together):** the `<html>` attribute (`data-status="todo|in-progress"` → `data-status="completed"`), the `<meta name="plan-status">` tag (same value change), and the visible badge (typically `.status-badge`, `.plan-status-badge`, or `data-plan-status` — replace its text with `completed` and any `status-todo`/`status-in-progress` class with `status-completed`).

**5b — Acceptance-criteria checkboxes:** add the `checked` attribute to `#criteria-list` inputs per the user's Step 4 choice — every unchecked input for "check all", or only `verified` criteria for "auto-check verified" (leave the others' state unchanged). If any criteria remain unchecked, apply the downgrade rule: set all three status representations to `in-progress`.

**5c — Step cards:** add the `completed` class to every `.step-card` that lacks it, and flip each such card's chip text: `<span class="step-chip">todo</span>` → `<span class="step-chip">done</span>`.

**5d — Completion checklist:** if `#completion-list` exists, add `checked` to `cc1` (steps are always completed by 5c); to `cc2` only if **all** criteria are checked after 5b; to `cc3` only if the **final** status after the downgrade rule is `completed`. When all three are checked, add the `all-complete` class to the `completion-checklist` div.

**5e — Completion report:** if `#completion-report` exists and anything fell short (unverified criteria left unchecked, evidence below 80%, objective test failed), replace the `<p class="report-empty">…</p>` element with a `<dl class="report-list">` of `<dt>` (specific criterion/token/test) + `<dd>` (reason) entries; otherwise leave the report untouched.

Do not remove or alter any surrounding markup.

---

## Step 5f — Update the linked tracking ticket

Applies to both modes. Skip entirely when the plan carries no ticket: the
spec's `issue:` frontmatter key, or in legacy mode the `plan-issue` meta tag in
the HTML.

**1. Check the URL before anything else.** The ticket URL is frontmatter — it
reaches this step unvalidated, and it is about to become a shell argument.
Proceed only when it starts `https://` **and** its host is `github.com` or a
GitLab host; report one line and skip the rest of this step otherwise. A Jira
or Linear URL is a valid thing for a plan to link and still renders as a link
on the page — there is simply no CLI here to drive it, and guessing GitLab for
every non-GitHub host would fire `glab` at a host it cannot serve. Always quote
the URL in the command (`"<url>"`).

**2. Write the summary to a file.** One paragraph — plan filename, final
status, `N/M` criteria checked, and every `## Completion Report` bullet
verbatim — and pass that **file** to every command below. Never interpolate the
summary into a shell string: a Completion Report bullet routinely contains
backticks naming a file or function, and `` `x` ``, `$(x)`, and `$VAR` all
expand before the CLI ever sees them — corrupting the comment in the ordinary
case and executing plan text in the worst one.

**3. Branch on the final status** — the status decides whether a question is
even asked, so determine it first:

- **Final status `completed`**: closing is visible to everyone watching the
  ticket, so ask via `AskUserQuestion` — "The plan links tracking issue
  `<url>`. Close it?" with `Yes, close it` / `No, leave it open`. In sweep
  mode ask once, listing every plan/ticket pair the sweep would close. On yes,
  for a `github.com` URL,
  `gh issue comment "<url>" --body-file <file> && gh issue close "<url>"`;
  for GitLab,
  `glab issue note "<url>" -m "$(cat <file>)" && glab issue close "<url>"`.
  On no, fall through to the comment below.
- **Final status `in-progress`** (the downgrade rule fired): never close, and
  **never ask** — there is no closure to confirm, so the question would be
  noise. Post the summary as a comment instead — `gh issue comment "<url>"
  --body-file <file>` / `glab issue note "<url>" -m "$(cat <file>)"` — so the
  ticket shows where the work stopped. A comment does not change the ticket's
  state.

If the CLI is missing, unauthenticated, or the command fails, report it in one
line with the ticket URL and continue to Step 6 — an open ticket
never blocks a plan from being marked completed.

---

## Step 6 — Deliver

Send the updated plan file(s) to the user via `SendUserFile` — in spec mode both the `.md` spec and the re-rendered `.html`.

Report one of:
- If all criteria were verified and checked: `"Plan marked completed: <filename> — all N acceptance criteria verified and checked, status updated to completed."`
- If the user chose "check all" but some criteria were unverified: `"Plan marked completed: <filename> — all criteria checked (N verified, K unverified), status updated to completed."` List the unverified criteria so the user is aware.
- If unverified criteria were left unchecked: `"Plan updated: <filename> — N/M acceptance criteria verified and checked, K criteria left unchecked, status set to in-progress."` List the unchecked criteria so the user knows what remains.

**STOP.** Do not commit, push, or start any implementation work.

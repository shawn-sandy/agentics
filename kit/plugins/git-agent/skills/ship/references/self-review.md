# Adversarial Self-Review: Dispatch, Checklist, and Amend Procedure

Procedure detail for **Step 4.5: Self-Review Before Push**. The
policy that governs this step — it runs by default, `--no-review` opts out, it
never blocks the ship (one exception below), and `<base>` comes from Step 7
rather than being detected twice — lives in `SKILL.md`. This file is the
subagent dispatch, the checklist, and the fix procedure.

## The review runs in a fresh context

The author of a diff is the worst-placed reviewer of it: knowing what an edit
was *meant* to do makes a no-op edit read like a fix. Spawn a subagent with the
`Agent` tool — `subagent_type: code-review:agent-code-reviewer` when available,
otherwise `general-purpose` — substituting `<base>` literally, because the
subagent starts with no context:

> Review the output of `git diff <base>...HEAD` as a hostile reviewer with no
> memory of the implementation. Report only defects you can prove with
> file:line evidence. Check specifically for: (a) no-op edits — changes that do
> not actually alter behavior (CSS losing to specificity, config that silently
> no-ops when a dependency is missing); (b) vacuous test assertions — any test
> that would still pass with the change reverted; (c) regressions introduced by
> the change itself; (d) unsafe auth/role/key lookups; (e) secrets or tokens in
> the diff; (f) accessibility regressions in CSS/UI changes; (g) pagination or
> sort tie-breakers — a sort with no unique final key, so equal rows reorder
> between pages and records repeat or vanish; (h) `parseInt`/`Number()` on user
> or query input with no validation — NaN, negative, or out-of-range reaching a
> query or an index; (i) derived state left stale after a client-side update —
> result counts, pagination links, labels, or cached totals still rendering
> pre-update data; (j) timezone-dependent date anchors — "today", midnight, or
> day boundaries computed in local time against UTC data; (k) scripts that
> continue after a failed step — a missing `set -e`, an unchecked exit code, or
> a default env var that silently no-ops.

If the `Agent` tool is unavailable, run the same checklist inline against
`git diff <base>...HEAD` and say so in the report: "Self-review ran inline — no
subagent available."

## Confirm, then fix — single pass

A fresh-context reviewer proves defects but does not know intent, so confirm
every finding against the actual source before touching anything.

**Confirmed findings:** fix them, then fold the fixes into the commit from
Step 4:

```
git add -A && git commit --amend --no-edit
```

The Step 4 commit is not yet pushed, so amending is safe.
**Single pass — never dispatch a second review of the amended diff.**
Re-read your own fixes, then continue to Step 5.

**Unconfirmed findings:** never block the ship on them. Carry each into the PR
body (Step 8) as a `## Review Notes` section, one line per finding: the claim
and why it could not be confirmed. Omit the section when there are none.

**Exception — check (e):** a confirmed secret or token is the one blocking
finding. Amend it out, tell the user verbatim what leaked and where — never
name it in a PR body — and **STOP**: a secret that reached a commit needs
rotation, and that is the user's call.

**If no findings:** output "Self-review: no findings." and continue.

# CI Autofix Classification

Detail for **Step 6b** of `ship-autonomous`: how to fetch a failing log,
classify it, and apply the three allow-listed fixes. The attempt cap and the
type-loosening prohibition are stated in SKILL.md and still apply here: track
each check's attempt count in TodoWrite, and on the 4th recurrence of the same
check stop fixing it and escalate via AskUserQuestion. **`external-blocker` is
the one exception** — it is never autofixed, so it never advances the cap.

## Fetch the failing log

```
gh run list --commit "$(gh pr view --json headRefOid --jq .headRefOid)" \
  --json databaseId,conclusion,workflowName \
  --jq '.[] | select(.conclusion=="failure") | "\(.databaseId) \(.workflowName)"'
gh run view <run-id> --log-failed
```

**`--commit` is not optional.** An unfiltered `gh run list` returns failing runs
from the whole repository, so `head -1` can hand back a concurrent PR's red run
— and every classification and autofix below would then be applied to someone
else's failure. Bind to this PR's head SHA, then pick the row whose
`workflowName` matches the check you are fixing.

## Classify on log content

**Check `external-blocker` first.** A failing GitHub Actions check is not a code
defect until proven one, and the other three classes all assume it is.

| Class | Signature in log | Allowed action |
|---|---|---|
| `external-blocker` | `billing`, `quota`, `spending limit`, `Bad credentials`, `refusing to allow`, token-expiry text, `action_required` — or an **empty `jobs` array** (see below) | **Report verbatim. No autofix, and the attempt cap does not advance** |
| `lint` | `eslint`, `lint error`, rule violation names | Run the project's lint-fix command |
| `typecheck` | `TS`, `TypeScript`, `error TS`, `tsc` | Apply minimal TS fixes |
| `peer-deps` | `peer dep`, `ERESOLVE`, `incompatible peer` | Reinstall lockfile |
| anything else | any other content | **Ask the user — do not guess** |

## `external-blocker`

An expired `CLAUDE_CODE_OAUTH_TOKEN`, a billing or quota block, a revoked
permission, or a workflow awaiting approval fails exactly the way a broken test
does — red checks — while the code is correct. Autofixing one changes correct
code, re-fires CI for another round, and burns the attempt budget against a
defect that does not exist.

**Empty-log detection.** A billing or quota block produces no log text at all,
so there is no signature string to match and a signature-only table would send
the most common instance to "anything else" as an unknown. Read the jobs
directly:

```
gh run view <run-id> --json jobs
```

Classify as `external-blocker` only when the **jobs array is empty**. That is
the only state that proves no job ran. Every entry in a non-empty jobs array
carries a `startedAt` and populated `steps`, so the run dispatched — whatever
its logs return.

A zero-byte `--log-failed` on a run whose jobs *started* is a different
condition: logs unavailable (expired retention, a fetch landing on a different
attempt, a transient API error). Do not classify it as `external-blocker` —
that would suppress a real failure. Report it as a failing check of unknown
cause, naming the failed jobs and steps from the jobs JSON
(`.steps[] | select(.conclusion == "failure") | .name`), and let the signature
table classify it from the check name if it can.

**Measured on this repo, 2026-08-14** (`shawn-sandy/agentics`, last 300 runs):
the four blocked runs — `31703518612`, `31638004638`, `31624323167`,
`31307691925`, all conclusion `action_required` — returned **0 bytes** from
`--log-failed`, an **empty `jobs` array**, and `createdAt == updatedAt`
(**0 s** elapsed). The eight genuine failures in the same window each ran
**6–22 s** and returned **2,218–40,948 bytes**.

So **duration alone does not discriminate** — real code failures here also
finish well under a minute. Nor does log size: every blocked run measured here
had an empty jobs array, so nothing in this window measured a started-jobs run
with empty logs, and the zero-byte reading was never independent of the empty
jobs array. The load-bearing clause is the **empty jobs array**. Treat a
sub-minute duration and a zero-byte log as corroboration, never as the test.

**Action:** report the failure verbatim as an external blocker, name the likely
cause and its remediation (re-auth, billing, workflow approval), and stop
autofixing that check.
**An `external-blocker` classification does not advance the three-attempt cap**
— the cap bounds guessing at code fixes, and nothing was attempted here. Never
edit source in response, and never re-run the workflow hoping it passes.

## `lint`

Detect the lint-fix command:

```
jq -r '.scripts | to_entries[] | select(.key | test("lint")) | "\(.key): \(.value)"' package.json 2>/dev/null
```

Run the script that includes `--fix` (or add `--fix` if the lint script calls
`eslint` directly). If no lint script exists, ask the user.

## `typecheck`

Read the reported errors from the log and apply minimal fixes (add missing
imports, use correct existing types). Never introduce `any`, `as unknown`,
`// @ts-ignore`, or `// @ts-expect-error`, and never loosen an existing type. If
the fix requires type loosening, ask the user.

## `peer-deps`

Detect the package manager and reinstall:

```
test -f pnpm-lock.yaml && echo pnpm || test -f yarn.lock && echo yarn || echo npm
```

Run `pnpm install` / `yarn install` / `npm install`, then confirm the diff is
lockfile-only (`git diff --name-only`). If anything else changed, ask the user.

## Outside the allowlist (or attempt cap reached)

Use **AskUserQuestion**. Summarize the failing check and the first ~20 lines of
its log, and offer options such as "attempt a fix", "skip this check", or "stop
watching the PR". Do not guess a fix for an unrecognized failure.

# CI Autofix Classification

Detail for **Step 6b** of `ship-autonomous`: how to fetch a failing log,
classify it, and apply the three allow-listed fixes. The attempt cap and the
type-loosening prohibition are stated in SKILL.md and still apply here: track
each check's attempt count in TodoWrite, and on the 4th recurrence of the same
check stop fixing it and escalate via AskUserQuestion.

## Fetch the failing log

```
gh run list --json databaseId,conclusion,workflowName --jq '.[] | select(.conclusion=="failure") | .databaseId' | head -1
gh run view <run-id> --log-failed
```

## Classify on log content

| Class | Signature in log | Allowed action |
|---|---|---|
| `lint` | `eslint`, `lint error`, rule violation names | Run the project's lint-fix command |
| `typecheck` | `TS`, `TypeScript`, `error TS`, `tsc` | Apply minimal TS fixes |
| `peer-deps` | `peer dep`, `ERESOLVE`, `incompatible peer` | Reinstall lockfile |
| anything else | any other content | **Ask the user — do not guess** |

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

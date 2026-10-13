# Mutation check

A test written against code that already works can pass for the wrong reason.
The only way to know it can fail is to make it fail. Break the implementation
on purpose, watch the new test go red, put the file back.

## The catalogue

Pick the mutation that targets the specific behaviour the new test claims to
cover. A mutation somewhere else proves the test can fail, not that it guards
the thing it says it guards.

| Change type | Mutation | What a green test proves |
|---|---|---|
| Conditional / guard clause | Invert the condition, or delete the early return | The test never reaches the branch |
| Boundary (`<` vs `<=`, first/last) | Shift the comparison by one | The test only uses mid-range inputs |
| Return value / computed field | Return a constant of the right type | The test asserts the shape, not the value |
| Error path | Swallow the throw and return a default | Nothing asserts the failure case |
| Exit status in a shell script | `return 0` where a failure propagates | The test reads output text and ignores the exit code |
| Ordering / sequence | Swap two adjacent steps | The test checks presence, not order |
| Filter / query predicate | Negate it, or drop it entirely | The test's fixture has no rows the filter excludes |
| Sort with ties | Remove the tie-breaker | The test data has no ties |
| String or template output | Change one interpolated value | The assertion is locked to the surrounding literal |
| CSS or layout token | Change the value, not the property | Nothing measures the computed style |

If the test stays green, it is not a test. Rewrite the assertion so it fails,
then mutate again.

## The safe protocol

The risk here is real: a mutation is a deliberate break in the working tree,
and a crash mid-loop leaves it there. Never use `git stash` and never use
`git checkout --` — both destroy uncommitted work that has nothing to do with
this change.

Work from a scratchpad copy, under a trap.

```bash
SCRATCH=$(mktemp -d)
cp path/to/impl.ts "$SCRATCH/impl.ts"
trap 'cp "$SCRATCH/impl.ts" path/to/impl.ts' EXIT INT TERM
```

The trap fires on `EXIT`, `INT` and `TERM`, which covers a normal exit, Ctrl-C,
and an ordinary kill. It cannot fire on `SIGKILL` (`kill -9`), and no shell can
— that signal is not trappable. So the scratchpad copy is the recovery path,
not just a source for the restore: keep it until `cmp` has confirmed the file
is back, and restore from it by hand if the shell was killed outright.

Then mutate in place, run only the scoped test — not the whole gate, which is
slow and answers a different question — and read the result:

```text
1. Edit path/to/impl.ts, applying one mutation from the catalogue.
2. Run the single new test.
3. It must FAIL. Record the failure output verbatim; it goes in VERIFICATION.
```

Restore, and prove the restore:

```bash
cp "$SCRATCH/impl.ts" path/to/impl.ts
cmp -s "$SCRATCH/impl.ts" path/to/impl.ts && echo "restored" || echo "NOT RESTORED"
```

## Why `cmp`, not `git diff --quiet`

`git diff --quiet <path>` ignores untracked files entirely. A file the current
change created has never been committed, so `git diff` reports the tree clean
over a file that is still mutated — a proof that is vacuous exactly where it is
needed most. `cmp -s` compares bytes on disk and is true whether the file is
tracked, untracked, or ignored.

## STOP path

If `cmp` reports a difference, **stop immediately**. Do not re-run the test, do
not continue to the next step, do not try a second restore silently. Tell the
user:

- which file is still mutated
- the absolute path of the good copy in the scratchpad
- the one command that restores it

A broken tree the user does not know about is the worst outcome of this whole
loop, and it is silent.

## Cleanup

Delete the scratchpad copy only after `cmp` has passed:

```bash
rm -rf "$SCRATCH"
```

Working-tree source sitting in a scratchpad is outside both the repo and its
`.gitignore`. Leaving it there after a proven restore is how source code ends
up somewhere nobody is looking.

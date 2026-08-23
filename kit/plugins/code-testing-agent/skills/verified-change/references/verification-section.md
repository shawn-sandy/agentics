# VERIFICATION section — worked example

Copy the shape below into the PR body. This is the real record from the change
that introduced the gate itself, not a schema: every command shown was run, and
every result shown is what it printed.

The rule this example exists to set: a VERIFICATION section listing a command
nobody executed is worse than no section at all, because it reads as proof.

---

## VERIFICATION

**Gate:** `bash scripts/verify.sh` — exit 0

Absolute paths below are shortened to `…/agentics`; everything else is verbatim,
including the gate's own 60-character truncation of the RUN lines.

```text
typecheck  SKIP (not configured)
lint       SKIP (not configured)
unit       RUN  (bash …/agentics/tests/run-all.sh)

run-all: 77 passed, 0 failed, 4 skipped
unit       PASS
e2e        SKIP (not configured)

marketplace RUN  (validate_marketplace)
marketplace.json parses, 12 plugins, every source path resolves
marketplace PASS
versions   RUN  (node …/agentics/scripts/check-plugin-versions.mjs)
OK: every changed plugin has a higher version than origin/main
versions   PASS
readme     RUN  (node …/agentics/scripts/build-readme-table.mjs --check)
README.md Plugin Reference Table is up to date.
readme     PASS

verify: PASS — every stage above either passed or reported why it was skipped.
```

Three stages skipped, and they are recorded as skips, not folded into "all
green": this repo has no `tsconfig.json`, no ESLint config and no
`.shellcheckrc`, and no Playwright config.

**Suite:** `bash tests/run-all.sh` — 77 passed, 0 failed, 4 skipped. The four
skips are the documented entries in the runner's own skip list, unchanged by
this work.

**Test written first:** `tests/test-verify-gate.sh`, before `scripts/verify.sh`
existed. Its first run was red for the right reason:

```text
=== verify.sh merge gate (objective test) ===
FATAL: /Users/…/agentics/scripts/verify.sh does not exist — every check below would cascade.
```

**Mutation applied:** in `scripts/verify.sh`, the `stage()` failure branch was
changed from `exit 1` to `return 0`, so a failing stage no longer propagates.

Observed failure, which is the point — the test detected the break:

```text
-- Check 3: a broken stage fails the gate and stops it --
  FAIL: the gate exited 0 in a project whose unit stage exits 1 — it is not a gate
  FAIL: the e2e stage ran after unit failed — the gate does not stop at the first failure
=== FAILED (2 check(s)) ===
```

**Restore proven:** `cmp -s "$SCRATCH/verify.sh" scripts/verify.sh` — exit 0,
and `bash tests/test-verify-gate.sh` green again. `cmp`, not
`git diff --quiet`: the gate was untracked at that moment, and `git diff`
ignores untracked files, so it would have reported clean over the mutation.

**Version guard:** `code-testing-agent 3.5.2 -> 3.6.0`, no violations against
`origin/main`.

**Browser verification:** not applicable — this change has no rendered surface.
The repo ships Markdown and shell; there is no page for axe to run against.

---

## When the change does render

Replace the "not applicable" line above with measured evidence at both widths
and both themes. Numbers from a tool run, never estimated:

```text
390px  light — .cta computed background #1B4D3E on #FFFFFF, ratio 8.59:1, axe: 0 violations
390px  dark  — .cta computed background #7FD1B9 on #101418, ratio 9.12:1, axe: 0 violations
1280px light — .cta box 184×48 at (596, 312), no overflow, axe: 0 violations
1280px dark  — .cta box 184×48 at (596, 312), no overflow, axe: 0 violations
screenshots: docs/evidence/cta-390-light.png, -390-dark.png, -1280-light.png, -1280-dark.png
```

Run axe against the real rendered page, never a Storybook iframe — it stalls.
Both themes are listed because a contrast regression usually lands in only one.

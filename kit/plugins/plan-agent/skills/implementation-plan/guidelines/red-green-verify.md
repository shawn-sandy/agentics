# Red-Green-Verify

A four-phase shape for `## Steps` that forces a test to fail before any
implementation exists. Nothing here is new machinery: the phases are
`### Phase:` headings, the discipline lives in each step's `Verify:` marker,
and `build` stops at every boundary. Authoring the plan this way is what
makes the discipline survive into implementation.

## When it applies

**Apply it** when the steps create, modify, or delete application source
*and* Step 0b found a test runner (a `test` script, a `vitest`/`jest`/
`pytest`/`go test` config, an existing `__tests__` tree). That is the same
Tier 1 signal Step 5c classifies on, plus a way to actually run red.

**Skip it** for Tier 2 work — docs, plans, non-runtime metadata. There is
nothing to fail for the right reason, and a RED phase over a `grep -q` check
is theatre.

**Ask once** via `AskUserQuestion` when the call is genuinely close:

- Tier 1, but Step 0b found no runner — the plan would have to stand one up
  first, which is scope the user did not ask for.
- Config, fixtures, or asset-only edits where the failing test would assert
  the edit rather than the behaviour.
- A spike, where the steps are questions and the evidence is findings.

Offer "structure as red-green-verify" against "single-pass steps with the
normal Tests section", and say which you'd pick. `--tdd` and `--no-tdd`
settle it without asking.

## The four phases

Flat, global numbering across all four — phases group, they never restart.

### `### Phase: RED`

Author the executable tests, run them, and capture the failure. Steps here
write test files only; no implementation source.

- The `Verify:` line demands the failure output, not a claim: *"`npx vitest
  run __tests__/theme.test.tsx` exits non-zero with `expected toggle to
  persist, received undefined` — paste the output"*.
- Failing **for the right reason** is the assertion. A test that errors on a
  missing import has not gone red; it has not run. Say which failure the
  step expects.
- Every RED step's file also appears as a `## Tests` bullet — same files,
  two views. The Tests section is the catalogue; RED is when they get
  written.
- **UI work adds a browser-verification step** here: a script driving the
  browser MCP tools that asserts on real DOM state —
  `mcp__Claude_Browser__read_page` refs,
  `mcp__Claude_Browser__javascript_tool` computed styles,
  `mcp__Claude_Browser__read_console_messages`. Either connected surface
  works: `mcp__claude-in-chrome__*` exposes the same calls, and this
  plugin's `prototype` skill and Step 7 use that one. Write whichever the
  target repo has. Never a screenshot as the assertion — a screenshot is
  evidence for a human; it fails silently for an agent, and has come back
  blank.

### `### Phase: GREEN`

The minimum implementation that turns the RED tests green.

- One step per source change, each `Verify:` naming the re-run command and
  the diff. Re-run after **every** edit — not once at the end.
- Cap the loop at **8 iterations**. Write the cap into the phase's last
  step: *"if tests still fail after 8 iterations, stop and report the exact
  blocker — the failing assertion, the last diff tried, and what was ruled
  out. Do not report success."* Without the cap in the spec, the loop has
  nothing to stop it.
- Minimum means minimum. Anything the RED tests do not demand belongs in
  `## Next Steps`.

### `### Phase: VERIFY`

- Full suite plus lint, as one step each, with the exact commands.
- A live browser pass over affected pages: layout holds, interactive
  targets ≥ 44×44px, **zero hydration warnings in the console**. Assert
  computed values via `mcp__Claude_Browser__javascript_tool` (or the
  `claude-in-chrome` equivalent); report the numbers.
- This is also what `## Verification` describes in prose. Keep them
  consistent — the section is the end-to-end statement, the phase is the
  steps that produce it.

### `### Phase: SHIP`

Entered only when all three prior phases are green.

- Commit, then open the PR.
- The PR body carries the **evidence**: the RED failure output, the GREEN
  passing run, and the browser assertions with their measured values. A PR
  body that says "tests pass" is not evidence.
- A failing GitHub Actions check is not a code defect until proven one.
  Check for a billing or quota block first — `gh run view <id> --log-failed`
  on a quota-blocked run reports no test failure at all. Write that check
  into the step.

## Environment constraint — no backgrounded servers

`&` and `nohup` are blocked by permissions. A step that says "start the dev
server in the background, then curl it" cannot run.

Write a short Node driver instead: boot the server as a child process, poll
the endpoint until it answers, assert, exit non-zero on failure, and kill
the child in a `finally`. It runs in the foreground, so it needs no
backgrounding, and its exit code is the `Verify:` line.

```js
// scripts/verify-<feature>.mjs — foreground; exit code is the assertion
import { spawn } from 'node:child_process'
const srv = spawn('npm', ['run', 'dev'], { stdio: 'inherit' })
try {
  let res
  for (let i = 0; i < 60; i++) {
    try { res = await fetch('http://localhost:3000/health'); break }
    catch { await new Promise(r => setTimeout(r, 500)) }
  }
  // Two distinct failures — never collapse them into one message.
  if (!res) throw new Error('server never answered within 30s')
  if (!res.ok) throw new Error(`server up but unhealthy: ${res.status}`)
  // …assert the objective here…
} finally { srv.kill() }
```

Name the driver in `## Files` and give its `node scripts/verify-<feature>.mjs`
invocation as the step's `Verify:`.

## Effect on the rest of the spec

- `## Tests` — unchanged in format; Tier 1, objective test first. RED is
  when those files get authored.
- `## Decisions` — record that the plan is red-green-verify and why, so a
  resumed session does not restructure it.
- Step count grows by roughly a third. A standard plan lands at Deep's step
  budget; that is expected, not a signal to split.

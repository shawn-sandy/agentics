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
normal Tests section", and say which you'd pick.

**When Step 0b did not run** (`--quick` skips exploration entirely, so
"found a runner" was never established): do not infer the shape from
nothing. Check for a runner with a single cheap read — a `test` script in
`package.json`, a `pytest.ini`/`pyproject.toml`, a `*_test.go` — and treat a
hit as the Step 0b signal. No hit under `--quick` means no RGV: the caller
asked for speed, and standing up a test runner is not a silent addition to
their scope.

**`--tdd` with no runner** is the one case that overrides all of the above,
because the caller asked for the shape explicitly. Author the phases, and
make **step 1 of RED stand up the runner** — naming it in `## Files` and in
`## Tests` — so the scope addition is visible in the plan rather than
discovered during implementation. `--no-tdd` suppresses the shape
unconditionally and needs no runner check.

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
- **UI work adds a browser-verification step** here, asserting on real DOM
  state. Two ways to write it, and they are not interchangeable:
  - **An agent-driven pass** — the step names the MCP calls the implementing
    agent makes: `mcp__Claude_Browser__read_page` for refs,
    `mcp__Claude_Browser__javascript_tool` for computed styles,
    `mcp__Claude_Browser__read_console_messages` for warnings.
    (`mcp__claude-in-chrome__*` exposes the same calls — this plugin's
    `prototype` skill and Step 7 use that one. Name whichever the target
    repo has.) These are model-side tool calls: **no `.mjs` file can invoke
    them.** The `Verify:` line is the assertion the agent reports, with its
    measured value.
  - **A committed script** — when the check must run in CI or without an
    agent, it is a Playwright/Puppeteer test, not an MCP call. Then it is a
    normal RED test file with a `Run:` command, and it belongs in `## Tests`
    like any other.

  Never a screenshot as the assertion — that is evidence for a human; it
  fails silently for an agent, and has come back blank.

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

- Full suite plus lint, as one step each, with the exact commands. Add a
  typecheck step when the project has one (`tsc --noEmit`, `mypy`, `go vet`)
  — a green suite over code that does not typecheck is not verified.
- **Only when the plan touches UI:** a live browser pass over affected
  pages — layout holds, interactive targets ≥ 44×44px, **zero hydration
  warnings in the console**. Assert computed values via
  `mcp__Claude_Browser__javascript_tool` (or the `claude-in-chrome`
  equivalent) and report the numbers. A backend, CLI, or library plan has no
  affected pages; omit this step rather than inventing one, exactly as RED
  scopes its browser step.
- This is also what `## Verification` describes in prose. Keep them
  consistent — the section is the end-to-end statement, the phase is the
  steps that produce it.

### `### Phase: SHIP`

Entered only when all three prior phases are green — **and only when the
user asked to ship.** `build` Step 6 stops after implementing and commits
only on request; a SHIP phase that commits unconditionally would override
that from inside the plan, turning "implement this" into "implement, commit,
and open a PR". Author the phase when the objective is to land the change;
omit it otherwise and let VERIFY be the last phase. When in doubt, omit —
a missing SHIP phase costs one follow-up prompt, an unwanted one costs a
commit the user did not ask for.

- Commit, then open the PR.
- The PR body carries the **evidence**: the RED failure output, the GREEN
  passing run, and — for UI plans — the browser assertions with their
  measured values. A PR body that says "tests pass" is not evidence.
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
const url = 'http://localhost:3000/health'
const srv = spawn('npm', ['run', 'dev'], { stdio: 'inherit' })
try {
  let res
  for (let i = 0; i < 60; i++) {
    // A booting server answers 503 before it answers 200, and fetch does not
    // throw on either — so poll until res.ok, not until the first response.
    try { res = await fetch(url, { signal: AbortSignal.timeout(1000) }) } catch {}
    if (res?.ok) break
    await new Promise(r => setTimeout(r, 500))   // also bounds a hung request
  }
  if (!res?.ok) throw new Error(`never healthy in 30s (last: ${res?.status ?? 'no response'})`)
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

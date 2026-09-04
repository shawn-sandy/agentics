# Changelog — git-agent

## v4.20.2 — 2026-09-03 — a stalled reviewer no longer stalls the ship

### Fixed

- **pr-agent Step 4.7 and ship Step 4.5 fall back to an inline review when the
  adversarial reviewer returns no report.** Both steps block on the reviewer's
  findings, yet dispatched `code-review:agent-code-reviewer` — a background
  agent capped at ten turns — with no rule for what to do when the report never
  came. In three sessions on 2026-09-03 the agent ran out of turns or stalled
  before reporting, and the ship hung until the user re-sent the command. Both
  steps now define "no report" — a partial, empty, or `### Summary`-less result
  — and run the same checklist inline, saying so under `## Review Notes` in the
  PR body (pr-agent) or in the step report (ship) instead of re-dispatching.
  The review prompt itself is unchanged. Pairs with `code-review` 3.3.6, which
  raises the agent's cap to 30 so the partial return is the exception.

## v4.20.1 — 2026-08-27 — an empty log is not an empty CI run

### Fixed

- **A zero-byte `--log-failed` no longer reports as "CI never dispatched".**
  The 4.19.4 rule in `merge` treated three states as a non-dispatch: an empty
  run list, an empty `jobs` array, or every job failed *and* `--log-failed`
  returning zero bytes. The third clause was an extrapolation the cited
  measurement never covered — all four blocked runs in the 2026-08-14 window
  had an **empty `jobs` array**, so the zero-byte log was never observed
  independently of it. A dispatched run *can* return no log bytes: expired log
  retention, a fetch landing on a different attempt than the failing one, or a
  transient API error. Reporting that as "CI never dispatched — billing block"
  tells the user to ignore a real failure — the one wrong direction that
  matters.
- **The jobs array, not the log size, now makes the call.** Verified against
  live runs on this repo: blocked run `31703518612` returns `jobs: []` with no
  `startedAt` anywhere, while genuine failures `32881670224` and `32641116349`
  return jobs carrying `startedAt`, `completedAt`, and populated `steps` with
  named failed steps. A non-empty `jobs` array is therefore proof of dispatch
  on its own. `merge` and `ship-autonomous/references/ci-autofix.md` now treat
  an empty run list or empty `jobs` array as the whole non-dispatch test, and
  report a started-jobs run with an unreadable log as **"CI failed — logs
  unavailable"** — a red check of unknown cause, named down to the failing job
  and step from the jobs JSON, never an external blocker.
- **`ci-autofix.md`'s measurement paragraph states its own limit.** It now says
  the window contained no started-jobs run with empty logs, so a later reader
  cannot mistake the zero-byte reading for an independently verified signal.
- **The run being classified is now bound to the PR's head commit.** Both files
  listed runs without pinning them: `merge` used `gh run list --branch`, which
  returns every recent run across *every* commit and *every* workflow on the
  branch — PR #607's own branch carried four runs from two workflows on a single
  SHA — and `ci-autofix.md` used a bare `gh run list ... | head -1`, unfiltered
  across the **whole repository**, so a concurrent PR's red run could be fetched
  and autofixed against. Both now list by `--commit <headRefOid>` (the SHA
  already verified in `merge` Step 1) and say to pick the row whose
  `workflowName` matches the failing check. An unbound `<run-id>` reached the
  same wrong verdict by a second route, so the classification fix above is only
  sound with this in place. Raised by CodeRabbit on #607.

`tests/review-gates.test.mjs` gains nine assertions: the two classification
sentences, three negatives that fail if the removed clause returns, and the
run-binding checks. They assert the rule sentences rather than bare tokens — a
token like `startedAt` would still be found if it survived only in a code
comment while the rule reverted — over whitespace-collapsed text so rewrapping a
paragraph does not fail the run. Every one was mutation-checked.
`tests/plugins/test-ship-preflight.sh` no longer pins the removed clause.
`docs/guides/how-to/git-agent.md` needs no change — its `merge` section
documents the readiness gate and never described the dispatch heuristic.

## v4.20.0 — 2026-08-27 — a context guard before ship-autonomous spends the session

### Added

- **`ship-autonomous` Step 0: Context Guard.** The pipeline derives every input from `git` and `gh` — no step reads the conversation. But Step 5 ends the turn and waits, so each PR event that wakes the session re-sends the whole transcript as input. A pipeline that needs none of that context pays for all of it, once per CI event. Step 0 now checks whether the session is already long and offers three routes: `clear` (**STOP** — the user runs `/clear` and re-invokes, because a skill cannot clear its own context and a silent no-op would run the pipeline in the very session the user asked to escape), `background` (dispatch `ship-bg` then `ship-ci-bg`, each subagent getting its own context window; merge still returns to the foreground because a subagent has no user to ask for approval), or `continue`. Skipped on a short session, so it catches an expensive default rather than adding a prompt to every run. The former Step 0 (`ExitPlanMode`) is now Step 0.5 — the file already used Step 2.5, and renumbering would have touched every later cross-reference.

### Why no `ship-autonomous-bg`

Chaining the two existing background commands already gives fresh contexts, and a dedicated agent would duplicate them while losing the Step 8 merge gate — background agents have no user to prompt.

### Tests

`tests/plugins/test-ship-autonomous-context-guard.sh` — step ordering, the no-session-context claim the guard rests on, all three routes, the STOP guarantee, the skip condition, and README sync. Verified by mutation: deleting the STOP clause fails the check that covers it.

## v4.19.4 — 2026-08-21 — the adversarial review hunts the defects that escape it

### Changed

- **The adversarial pre-PR checklist gains five checks, (g)–(k).** Usage
  analysis over 652 sessions found that the defects reaching PR review bots
  were not the six classes 4.19.3 added, but a different, narrower set that
  ordinary review keeps missing: (g) pagination or sort tie-breakers — a sort
  with no unique final key, so equal rows reorder between pages; (h)
  `parseInt`/`Number()` on user or query input with no validation; (i) derived
  state left stale after a client-side update — counts, links, labels, cached
  totals; (j) timezone-dependent date anchors computed in local time against
  UTC data; (k) scripts that continue after a failed step. Both copies of the
  checklist — `pr-agent` Step 4.7 and `ship/references/self-review.md` — carry
  the identical eleven-point prompt, and `tests/review-gates.test.mjs` fails if
  they drift apart.
- **`merge` distinguishes "CI never dispatched" from "CI passed"** (Step 2, new
  subsection). A billing block, an expired token, or a workflow awaiting
  approval stops jobs from starting, so `gh pr checks` reports nothing to fail
  — indistinguishable from a repo with no CI unless you look. The skill now
  reads `gh run list` and the jobs array, and treats an empty run list, an
  empty `jobs` array, or all-failed-with-zero-log-bytes as a non-dispatch. This
  is a **reporting** rule, not a gate: it never blocks a merge, but it forbids
  calling a PR "CI green" when no job produced output. Detection previously
  existed only in `ship-autonomous/references/ci-autofix.md`, which `merge`
  does not read; the measurements behind the empty-log signal still live
  there.

## v4.19.3 — 2026-08-19 — adversarial pre-PR review in every PR-opening flow

### Changed

- **Every flow that opens a PR now runs an adversarial review of
  `git diff <base>...HEAD` before `gh pr create`.** Usage analysis found the
  #1 friction is first implementations shipping with real defects — no-op
  edits, vacuous test assertions, self-introduced regressions, unsafe auth
  lookups — that only PR review bots catch, at 2–6 review rounds per PR. The
  review is single-pass and shares one six-point checklist: (a) no-op edits,
  (b) vacuous test assertions that survive reverting the change, (c)
  regressions the change itself introduces, (d) unsafe auth/role/key lookups,
  (e) secrets or tokens in the diff, (f) accessibility regressions in CSS/UI
  changes.
- **The interactive skills review in a fresh context.** `pr-agent` (new
  Step 4.7) and `ship` (Step 4.5, rewritten `references/self-review.md`) spawn
  a subagent via the `Agent` tool — `code-review:agent-code-reviewer` when
  available, `general-purpose` otherwise — because the author of a diff is the
  worst-placed reviewer of it. Confirmed findings are fixed and folded in per
  each skill's commit conventions (`ship` amends pre-push; `pr-agent` adds a
  `fix:` commit post-push); unconfirmed findings land in the PR body's
  `## Review Notes` instead of blocking. `ship-autonomous` opens its PR by
  invoking `pr-agent`, so it inherits Step 4.7 — its Step 4 now says so
  rather than duplicating the review (its core sits at the split test's
  600-word ceiling, and one review per PR is the point).
- **The background agents review inline.** `agent-pr` (new Step 4.7) and
  `agent-ship` (Step 4.5 upgraded from the old four-check list) cannot spawn
  subagents or edit source, so they re-read the full diff cold, report every
  finding with file:line in the PR body and final report, and never fix. One
  blocking exception everywhere: a confirmed secret in the diff stops the flow
  and is never named in a PR body.

## v4.19.2 — 2026-08-17 — worked examples, and a fallback that keeps the draft

### Changed

- **One canonical worked PR body** now lives in `ship/references/pr-body.md`
  (Step 8): real title, real Summary bullets, a Test Plan with one checked box
  naming its result and one honest unchecked box, a real `Closes` URL.
  `pr-agent` points at it; the self-contained background agents (`agent-pr`,
  `agent-ship`) embed a compact copy matching their own template shape. Every
  PR body spec was previously bracket-placeholders only, in contrast to
  commit messages (three examples) and branch naming (good/bad table).
- **`create-issue` ships a filled bug-issue example** in
  `references/bug-report.md` — the exact file Phase 5 reads at drafting time.

### Fixed

- **`create-issue`'s failure fallback no longer discards the approved
  draft.** The bare `gh issue create --web` became
  `gh issue create --web --title "<title>" --body "<body>"` (glab
  equivalent included); labels move to the report on that path since a bad
  label is a likely cause of the original failure. Phase 8 gains the honest
  fourth outcome: "CLI creation failed (<error>). Opened a prefilled browser
  form — no issue exists until you submit it." No issue number is ever
  printed on that path.

## v4.19.1 — 2026-08-17 — ship no longer declares success against a dead PR

### Fixed

- **`ship` and `agent-ship` check PR/MR state before stopping at an "existing"
  PR.** Step 6 ran `gh pr view --json url`, which also resolves merged and
  closed PRs — so a re-ship on a branch whose PR had merged reported "Pushed
  to existing PR" and never opened a new one. Both now query `state` and STOP
  only on `"OPEN"` (GitHub) / `"opened"` (GitLab); merged, closed, or
  no-PR-found proceeds to create a fresh one. This ports the fix `pr-agent`
  received in v3.3.2 and which ship never picked up; ship/SKILL.md's summary
  line no longer paraphrases the buggy semantic.

## v4.19.0 — 2026-08-15 — post-merge cleanup that looks before it deletes

### Added

- **`skills/post-merge-cleanup/`, a skill for clearing merged branches and their
  worktrees.** It inspects each worktree for uncommitted work *before* removing
  anything, and stops with the file list when `git status --porcelain` is
  non-empty for any reason — untracked, staged, or unstaged. The ordering is the
  point: an unforced `git worktree remove` already refuses a dirty tree, so
  checking first lets the skill delegate its central safety property to git
  instead of reimplementing it. Four absolutes back that up: never
  `worktree remove --force`, never remove a dirty worktree, never `branch -D`
  without a confirmed merged PR, never `rm` outside the worktrees root.
- **Dual-signal selection, because commit ancestry is not enough.** This project
  squash-merges, and a squash merge replays a branch's changes as one commit
  with a new SHA — so the branch's own commits never become ancestors of the
  default branch and `git branch --merged` cannot see it by construction.
  Measured on this repo: 84 branches are ancestry-merged, while 318 have a
  merged pull request, 296 of them invisible to the ancestry test. The union is
  380 cleanable branches, so ancestry alone would have found 84 of 380 and
  missed 78% of the backlog. A branch qualifies when either signal fires, and
  the qualifying signal decides the flag — `-d` for ancestry, `-D` only where a
  merged PR supplies positive evidence, since `-d` applies the same ancestry
  test and would refuse those 296.
- **Repo-wide sweep behind `--all`, with the report before the question.** One
  approval spanning hundreds of branches is a gate that gets clicked through, so
  the inventory table prints first — branch, qualifying signal, worktree, dirty
  count, action — and batch approval is a separate deliberate answer that names
  its count, never the default option. Blocked worktrees are listed with their
  file lists rather than silently skipped.
- **Unregistered-directory detection, covering a gap `git worktree prune` cannot
  reach.** Prune scans the admin directories under `.git/worktrees/`; a
  directory whose admin entry is already gone is invisible to it. Three
  directories on this repo (~7.3M) sit in exactly that state. Because their
  dangling `.git` files mean `git status` cannot vouch for the contents, the
  skill prints size, file count, and recently modified files, then requires a
  per-directory confirmation and a `pwd -P` containment check before any
  removal — and prints the command rather than acting when `rm` is denied by
  policy.
- **An explicit `<branch>` or `<worktree-path>` target, alongside `--all` and
  `--dirs`.** Without it the self-deletion refusal was a dead end: the flow
  defaulted to the current branch, refused because the cwd sat inside the target
  worktree, and told the user to `cd` out — after which the current branch was no
  longer the target and a bare re-invocation would resolve to something else. The
  refusal now prints a resumable command naming the target, and a target that
  resolves to neither a branch nor a worktree is an error rather than a silent
  fallback to the current branch.
- **`tests/plugins/test-post-merge-cleanup.sh`, wired into CI.** Builds a real
  throwaway repo and asserts the objective directly: a dirty worktree survives
  with its file byte-identical, while a clean one is still removed, so the gate
  is proven to block dirty trees specifically rather than blocking everything.
  The forbidden-flag checks scan fenced code blocks only — the safety contract
  has to name `--force` in order to forbid it, so a naive whole-file grep would
  fail on a correctly written skill. Prose is a mention; a code block is an
  invocation.

## v4.18.0 — 2026-08-14 — a scope guard for repo-wide formatters and bare stash pops

### Added

- **`hooks/scope-guard.py`, a second `PreToolUse` hook on `Bash`.** It refuses
  two commands whose blast radius exceeds their intent, each with a recorded
  incident behind it: a formatter or linter run with `--write`/`--fix` and
  either no path operand or `.` (one such run reformatted ~190 untouched files
  and needed a guarded revert), and `git stash pop`/`git stash apply` with no
  stash reference (one bare pop restored an unrelated stash and created
  conflicts needing recovery). Blocks exit 2 with the rule and its safe
  alternative on stderr. Escape hatch: `.claude/no-scope-guard` at the repo
  root, mirroring `.claude/no-lint-gate`.
- **Package scripts are resolved before matching.** `npm run fix:all` carries
  none of the dangerous text itself — its expansion lives in `package.json` —
  so a runner invocation is resolved against the nearest manifest, walking up
  from the command's directory to the git root, and the script's body is what
  the rule sees. An optional `run` token is stripped rather than required, so
  all eight spellings (`npm`/`pnpm`/`yarn`/`bun`, each with and without `run`)
  behave identically; a script delegating to another script resolves through up
  to three hops. A missing manifest, malformed JSON, or absent script resolves
  to nothing and never blocks.
- **A mention is not an invocation.** The guard parses the command and checks
  the program actually being run, so a blocked pattern quoted inside a
  `git commit -m` message, an `echo`, or a `grep` argument is not blocked, and
  `git` is admitted only for `git stash`. Nothing touches the filesystem until
  a command is a genuine candidate — this hook runs on every `Bash` call in
  every repo that installs git-agent. `rm`, `curl`, `git reset --hard`, and
  `git checkout -- .` are deliberately out of scope: a guard that fires on safe
  commands gets switched off, which costs more than the two it was catching.
- **`tests/plugins/test-scope-guard.sh`** — 79 assertions covering both blocked
  patterns, each pattern's passing counterpart, all eight runner spellings in
  both directions, the manifest walk (nearest wins, git root is the ceiling,
  malformed never blocks), the opt-out, and the fast bail. Disabling either
  rule turns exactly its own checks red and leaves the other rule green.

### Changed

- **The lint gate's `.claude/lint-gate.json` is documented as a test gate.** It
  already accepted arbitrary commands and already compares every one against
  `HEAD`, so `{"commands": ["npm run lint", "npm test"]}` is safe on a suite
  that is already red — only a failure your change introduces blocks. The
  capability existed and was documented only as a lint mechanism; this adds the
  example. No behaviour change.
- README documents both scope-guard rules, the `.claude/no-scope-guard` opt-out,
  and the caveat that plugin `hooks.json` files are **not** registered in Claude
  Code desktop sessions — this guard is CLI-only enforcement, so a desktop
  session is not a test surface and the equivalent `CLAUDE.md` rules stay as the
  desktop fallback.

### Note on the version number

Released as **4.18.0**, skipping 4.17.0. `harden-ship-preflight` was shipping
concurrently from a sibling branch and took 4.17.0, which landed as PR #555
while this work was in progress — `origin/main` read 4.16.1 when the number was
chosen. Both branches taking 4.17.0 would have left whichever merged second
failing `scripts/check-plugin-versions.mjs`, which requires the touched
plugin's version to *exceed* the base branch. 4.18.0 exceeds it in either merge
order.

## v4.17.0 — 2026-08-14 — pre-flight reports every blocker at once

### Added

- **Pre-flight runs every guard, then reports once.** `ship` Step 1 and
  `ship-autonomous`'s `preflight-and-verify.md` both stopped at the first
  failing guard, so a session with an unauthenticated `gh`, a dirty tree, and a
  worktree missing its `.env` cost three separate spin-ups — fix one, re-invoke,
  discover the next. Both now run every guard against the unmutated tree and
  print one PASS/BLOCKED table with a verbatim remediation command per BLOCKED
  row. **The halt is unchanged**: any BLOCKED row still stops the skill before
  any mutation. It just stops knowing all of them.
- **A worktree env-parity guard.** Gitignored `.env*` files do not travel with
  `git worktree add`, so every linked worktree starts without them and the
  failure presents as a code defect in whatever was edited last — the cause
  behind two recorded phantom bugs (a Clerk sign-in regression blamed on a CSS
  change, and an earlier "missing nav button"). The guard is skipped entirely
  unless `git rev-parse --git-dir` differs from `--git-common-dir`, then reports
  each missing file with its exact `cp` command. **It never copies the file** —
  these hold secrets, so detection is the deliverable and copying stays the
  user's action.
- **A browser-availability probe, and an honest marker when it fails.**
  Step 2.5's browser block had no probe, so an absent MCP silently skipped
  verification while the PR body still read as verified. It now states
  `UNVERIFIED — no browser` in the session output and carries that exact string
  to `pr-agent`, whose Step 5 body template reproduces it verbatim in the Test
  Plan — adopting the convention `wcag-compliance-reviewer` settled in 1.5.2.
  The marker had to reach `pr-agent` to reach a reviewer at all; a commit
  trailer nobody reads would not have.
- **An `external-blocker` class in CI triage**, ordered ahead of `lint` so it is
  classified before the classes that assume a code defect. Covers billing and
  quota blocks, expired credentials, revoked permissions, and workflows awaiting
  approval. It is reported verbatim, never autofixed, and **does not advance the
  three-attempt cap** — the cap bounds guessing at code fixes, and nothing is
  attempted here.
- **Empty-log detection for the billing case**, where no signature string
  exists to match: `gh run view <run-id> --json jobs`, classified as
  `external-blocker` when the jobs array is empty (or every job failed) and
  `--log-failed` returns nothing.

  Measured on `shawn-sandy/agentics`, 2026-08-14, last 300 runs. The four
  blocked runs — `31703518612`, `31638004638`, `31624323167`, `31307691925`,
  all conclusion `action_required` — returned **0 bytes** from `--log-failed`,
  an **empty `jobs` array**, and `createdAt == updatedAt` (**0 s** elapsed). The
  eight genuine failures in the same window ran **6–22 s** and returned
  **2,218–40,948 bytes**. So duration alone does not discriminate on this repo:
  real code failures also finish well under a minute. The load-bearing clause is
  the **empty log**; a sub-minute duration is corroboration only.

- **A named headless default for every pre-flight `AskUserQuestion`.** The
  uncommitted-plan-files gate defaults to `abort` — under `claude -p` the tool
  is unavailable, and staging or stashing the user's plan files unasked is
  precisely what that gate exists to prevent.
- `tests/plugins/test-ship-preflight.sh` — content assertions across both
  pre-flight surfaces, `pr-agent`'s body template, and the CI table.

### Changed

- `ship` Step 1's guard commands moved to a new bundled
  `skills/ship/references/preflight-guards.md`, keeping the core under its
  600-word ceiling. The guard statements themselves stay in SKILL.md. `ship` and
  `ship-autonomous` still carry separate copies of the pre-flight definition —
  a skill can only bundle files under its own directory — and both files say so.

### Explicitly not changed

- **No automatic re-auth, stash, or env-file copy.** Re-auth is an interactive
  browser flow that cannot succeed unattended, and the standing rule is to
  report blockers verbatim rather than guess at a workaround. Only the
  round-trip count changed.
- **`commit-agent` keeps its single-`-m` commit.** It has no commit body to
  write a verification marker into, and giving it one is a behaviour change
  affecting several callers.

## v4.16.1 — 2026-08-14 — two over-reaches in 4.16.0 / 4.15.1

### Fixed

- **A failed reproduction no longer counts as a refutation.** v4.16.0 sent any
  finding that would not reproduce straight to the refuted branch, which
  resolves the thread and lets the merge proceed. But real defects routinely
  will not execute in the shipping environment — a missing dependency or
  credential, production-only configuration, a destructive input, a race that
  does not fire on this machine, or a defect provable from a schema without
  running anything. That turned "I could not run it" into "it is incorrect",
  the exact failure the step was added to prevent. A failed reproduction is now
  **inconclusive** and routes on the source of truth: refuted only if
  inspection shows the finding is wrong, blocking if inspection confirms it,
  otherwise `AskUserQuestion` without resolving the thread.
- **The detached-HEAD guard no longer fires when a PR was named explicitly.**
  v4.15.1 pointed `agent-merge` at Steps 0.5–3 wholesale, importing a hard stop
  that contradicts the agent's own contract that a dispatched PR wins over the
  checkout. With an explicit URL or number nothing reads the current branch, so
  the checkout state is irrelevant — the guard exists only to stop Step 1's
  `gh pr list --head "$(git branch --show-current)"` fallback matching nothing
  on an empty value. Now scoped to the infer-from-branch path in both
  `merge/SKILL.md` and `agent-merge`. `gh auth status` and the dirty-tree check
  are unchanged and still run either way.

## v4.16.0 — 2026-08-14 — review findings get verified in both directions

### Added

- **Step 6c now requires reproducing a blocking finding before fixing it.**
  Previously a finding that was "clear, safe, and in scope" went straight to
  `Edit` → commit → push. But a reviewer asserting a defect is making a claim
  about runtime, and this skill already refuses to accept those on authority
  when *declining* — accepting one on authority when *fixing* is the same error
  pointed the other way, and it costs a commit plus a re-fired review round to
  discover the code was already correct. A finding that cannot be reproduced is
  not blocking: it drops to the refuted branch, with the failed reproduction as
  its evidence.
- **Refuting a finding now requires checking its source of truth first**, and
  putting that evidence in the reply — the schema excerpt, the spec, the file's
  current contents. A bare "this is incorrect" trades an opinion for an
  opinion, and reviewers are right often enough that a reflexive decline
  eventually declines a real bug. Evidence in the thread is also checkable by a
  human reading it later, which an assertion is not.

## v4.15.1 — 2026-08-14 — merge gets the pre-flight guards back

### Fixed

- **`merge` Step 0.5, guards.** `merge` was the only skill in this plugin with
  no pre-flight checks — `branch-agent`, `commit-agent`, `pr-agent`, `ship`,
  and `ship-autonomous` all have them. It now runs three before touching the
  PR:
  - **Detached HEAD.** Step 1's fallback interpolates `git branch
    --show-current` into `gh pr list --head`, so on a detached HEAD it queried
    `--head ""` and matched nothing — reported as "no PR found" rather than as
    the checkout problem it was.
  - **`gh auth status`.** An auth failure surfaced as whatever `gh pr view`
    happened to print, several steps in.
  - **Dirty working tree.** This is the guard v4.15.0 dropped alongside the
    lint gate. It returns with a different purpose: not to align the local tree
    with the PR head for a local lint run, but to name uncommitted files before
    the Step 3 approval, so nobody approves a merge believing work is shipping
    that is not in the PR. It **asks** rather than stopping — the merge is
    server-side, so local edits cannot corrupt it.
- **`agent-merge`** follows Steps 0.5–3 instead of 1–3. The dirty-tree ask
  needs no special case there: the existing "if the skill says ask, report and
  STOP" substitution already covers it.

## v4.15.0 — 2026-08-11 — the merge lint gate is gone

### Removed

- **`merge` Step 3, the lint gate.** The skill no longer probes `package.json`
  for a `lint*` script or runs one before merging. Two gates already cover the
  same ground from better positions: the `PreToolUse` commit lint gate
  (`hooks/lint-before-commit.py`) blocks a failing commit before it ever
  becomes a PR head, and CI runs the project's real checks against the exact
  commit being merged. Step 3 ran a *third* pass in the local working tree,
  which is not necessarily the PR head at all — the case `agent-merge` had to
  guard with a clean-tree + `headRefOid` check, and skip whenever it failed.
  Removing it drops that guard, the package-manager detection, the `--fix`
  script filter, and `Bash(jq|npm|pnpm|yarn *)` from `allowed-tools`.
- Steps renumbered: re-check/ask/merge is now Step 3, report is Step 4.
  `agent-merge`, `/git-agent:merge-bg`, and the README follow.

### Fixed

- **The Step 3 re-check named the wrong queries.** It said "re-run the Step 2
  queries", which are the two `gh pr checks` calls — yet the same paragraph
  claimed the re-check catches a review flipping to `CHANGES_REQUESTED` or
  `mergeStateStatus` flipping to `BLOCKED`. Those fields come only from Step 1's
  `gh pr view`, so the re-check could not see them and the merge decision rode
  on remembered metadata. Step 3 now re-runs **both** queries and evaluates
  every gate against the fresh responses. Predates this release; the wording was
  inherited when the step was renumbered.

Merge readiness is unchanged otherwise — required checks, `mergeable`,
`mergeStateStatus`, `reviewDecision`, the head-pinned squash, and the approval
prompt all behave exactly as before. A repo that wants lint enforced at merge
time should make it a required check.

## v4.14.4 — 2026-08-10 — the last two index-pinning gaps, and a budget that holds

### Fixed

- **Ecosystem manifests were still selected from the working tree.**
  `pyproject.toml`, `go.mod`, and `Cargo.toml` presence came from
  `os.path.exists` while `package.json` and the config had moved to the staged
  tree, so an unstaged `rm go.mod` switched the Go gate off for a commit that
  keeps it. Presence now comes from the same read as everything else, which
  finishes the job 4.14.2 and 4.14.3 started.
- **`TOTAL_BUDGET` was not actually a ceiling.** Each run was clamped to the
  time remaining, but every clamp has a floor, so N configured commands could
  add N seconds apiece past the deadline. The gate now refuses to start a check
  it cannot finish and returns 0 — unrun checks are could-not-run, like a
  timeout or a 127. Being killed by the harness mid-run is the one outcome with
  no exit code at all, which lets the commit through unexamined, so bounding
  the total matters more than squeezing in a last check.

### Changed

- **README corrected on a point where it said the opposite of the code.** It
  listed "an unborn branch" among the silent no-ops; an unborn branch is in
  fact the one case that always blocks, since with no `HEAD` there is nothing
  to compare against and every failure is new by definition. Section 2 of the
  test suite has asserted the blocking behaviour throughout. The no-op list now
  reads: missing dependencies, a linter absent from `PATH`, exit 127, no
  manifest, and an exhausted time budget.
- 96 checks to 100. The new ecosystem test uses a linter that reports what it
  finds rather than failing identically in both trees — a constant-failing fake
  reads as a pre-existing failure and would have passed while proving nothing.

## v4.14.3 — 2026-08-10 — a file staged for deletion stops choosing the checks

### Fixed

- **`read_staged` fell back to disk for a file the commit deletes.** Absent
  from the index means two opposite things: never tracked, where falling back
  to the working tree is right because there is no staged version to prefer;
  or tracked at HEAD and removed from the index, where the file will not exist
  after the commit and must read as absent. Conflating them meant a
  `git rm --cached .claude/lint-gate.json` left the working-tree copy selecting
  the checks for the very commit that removes it — a passing `true` command
  there suppressed the real, newly-failing lint script and the commit landed.
  HEAD is now consulted to tell the two apart. This was the same class as
  4.14.2's fix, one level further down: not the file's contents, but whether
  the file counts as present at all.

### Changed

- Two comments were wrong and are corrected: the `tarfile` fallback branch
  fires on runtimes that *predate* `filter=` (3.11.4/3.12), which the previous
  wording inverted; and `run_check` returning `None` is no longer always a
  no-op, since the degraded-baseline callers block on it.
- `link_deps` builds its target set before iterating rather than shadowing the
  loop variable inside a comprehension. No behaviour change — a comprehension
  has its own scope and is evaluated before the loop starts — but it read as a
  bug and tripped a lint rule.
- 93 checks to 96, covering the deletion case and the untracked case that must
  keep falling back to disk.

## v4.14.2 — 2026-08-10 — index-pin what the gate reads, not just what it judges

### Fixed

- **An unstaged edit could switch the gate off.** `.claude/lint-gate.json` and
  `package.json` were read from the working tree while the verdict was computed
  from the index, so an unstaged edit that emptied the config or dropped
  `scripts.lint` disabled the gate for a commit whose staged version still
  enabled it — contradicting the index-pinning guarantee outright. Which files
  decide the verdict is the same lever as their contents; both are now read
  from the staged tree whenever it differs from disk. `.claude/no-lint-gate`
  stays a working-tree read on purpose: it is a local escape hatch, and needing
  to commit it to use it would defeat the point.
- **Python linters installed only in a project virtualenv were invisible.**
  `shutil.which` probes `PATH`, which a non-activated `.venv` is not on — the
  most common Python layout, where the new Python gate would therefore have
  been a silent no-op. `.venv`/`venv` (`bin` and `Scripts`) are now probed
  ahead of `PATH`, and the resolved binary is invoked by absolute path.
- **A config could outlast the hook timeout.** The 480s budget was arithmetic
  over the two built-in scripts, but a config may name any number of commands,
  each paying for a primary and a baseline run. The harness killing the hook
  mid-run lets the commit through, so all checks now share one `TOTAL_BUDGET`
  deadline and each run is clamped to what remains. Test 13 asserts the
  enforced deadline rather than re-deriving the sum.
- **`mkdtemp` was outside the exception handler,** so an unwritable or full
  temp directory raised a traceback on every commit instead of taking the
  documented could-not-run path.

### Changed

- The absent-toolchain assertions run with a sanitized `PATH` containing only
  `git`, `python3`, and `sh`. Prefixing the caller's `PATH` meant a machine
  with Go, Cargo, or Ruff installed ran the *real* tool, so those cases tested
  nothing there and could fail outright — the suite was green here only because
  this machine has none of them. A check now pins that the sanitized `PATH`
  really does hide every probed toolchain.
- 88 checks to 93.

### Not changed

- **`tarfile.extractall` without a member filter on Python < 3.11.4** was
  raised as a path-traversal and symlink risk. Declined: `git archive` builds
  the tar from a git tree, which cannot contain `..` components, and the gate
  already executes the repo's own lint script by design — so any repo able to
  exploit the extraction can simply run code through `scripts.lint`. Validating
  members would not change the threat model, only its appearance. `filter="data"`
  is still used wherever the runtime supports it.

## v4.14.1 — 2026-08-10 — two degraded-baseline paths that silently passed real failures

### Fixed

- **Hoisted workspace dependencies were never linked into the materialized
  trees.** `link_deps` iterated only the set of check directories, so a check
  in `packages/api` linked `packages/api/node_modules` and nothing else — not
  the repo root, not any intermediate workspace directory. `deps_installed`
  accepts an install anywhere up the tree, so linking less than it accepts left
  the materialized tree without dependencies; the check then failed on a
  missing binary and that 127 read as "could not run". Net effect: in a
  monorepo with hoisted, gitignored `node_modules` — the ordinary layout — a
  brand-new lint failure was **let through**. `link_deps` now links every
  ancestor of every check, root included.
- **A check that flipped from passing to failing could produce nothing the
  record comparison would call new.** Two ways in: a check that fails silently,
  and one whose only difference is a digit the mask erases (`0 problems` vs
  `3 problems` normalize to the same record, so the counts match). Both exited
  0. The gate now decides on exit status first — if HEAD passed and the index
  fails, the commit broke it, whatever the output looks like — which closes
  every normalization blind spot at once rather than one at a time. When the
  failing check produced no output, the block message reports its exit status.
- Both defects shared a root cause worth naming: the original fixtures used
  shell built-ins and committed their `node_modules`, so no test ever exercised
  a check that genuinely needed dependencies or a linter that reports only a
  summary. Section 19 covers both layouts, both flip cases, and asserts the
  pre-existing-failure path still lands — 78 checks to 88.

## v4.14.0 — 2026-08-10 — the commit lint gate is trustworthy outside the repo it grew up in

### Fixed

- **Pre-existing failures no longer block unrelated commits.** The gate ran the
  host repo's whole `scripts.lint` and blocked on any non-zero exit, so walking
  into a repo with 40 errors you did not write meant every commit was refused
  until you fixed them or created `.claude/no-lint-gate`. It now compares the
  staged index against `HEAD` and blocks only on records the commit introduces.
  Four approaches were weighed; baseline comparison is the only one correct
  regardless of which linter the host repo uses — passing staged paths as
  arguments does nothing because `eslint .` ignores them, and parsing output for
  staged filenames needs a format guess per linter.
- **The comparison is linter-agnostic, with no per-tool parser.** Output lines
  are ANSI-stripped, path-stripped, and digit-masked into a multiset; a record
  is new when its count *rises*. Masking absorbs the line-number shift an edit
  causes further down a file, and counting keeps that masking from hiding a
  genuine new occurrence, since adding one always raises its key's count. This
  is what closes the "normalize across eslint/tsc/ruff/go vet/clippy" question —
  `--format json` was rejected because it cannot be injected into a repo whose
  lint script wraps the tool.
- **The verdict is pinned to the index, not the working tree.** Both sides are
  materialized from `git archive` via stdlib `tarfile` — no `git worktree`
  bookkeeping to leak on a crash — so the gate now checks what is being
  committed. Unstaged edits stop being linted, which is a no-op for
  `commit-agent` since its Step 2 runs `git add -A`. Materialization is skipped
  entirely when the working tree already matches the index, so the common path
  pays nothing.
- **Monorepos lint the package they are committing.** `repo_root()` resolved the
  git toplevel and then read only the *root* `package.json`; a commit from
  `sub/pkg/` ran the root script and the nested package's own script never
  executed. Detection now walks up from the commit's directory to the git root —
  a hard ceiling, so it never escapes into a parent project's manifest — and
  stops at the first matching one. `node_modules` is looked up through ancestors
  too, so a hoisted workspace install does not push resolution back to the root.
- **Path comparison uses `realpath` on both sides.** `git rev-parse
  --show-toplevel` resolves symlinks and `os.path.abspath` does not, so on macOS
  any commit under `/tmp` (a link to `/private/tmp`) looked like it sat outside
  its own repository and fell back to root resolution.
- **The hook registers at all.** `hooks.json` sits at the plugin root, which is
  not a discovery path — the documented one is `hooks/hooks.json`. Measured with
  a controlled A/B: identical deliberately-corrupt JSON is reported by
  `claude plugin validate` at `hooks/hooks.json` ("At runtime this breaks the
  entire plugin load") and passes unread at the root. `plugin.json` now declares
  `"hooks": "./hooks.json"` explicitly, the same mechanism by which `ponytail` —
  whose config is at a non-standard filename — does fire. `plan-agent` and
  `skill-reviewer` carry the same one-line fix; `plan-interview` is no longer in
  this marketplace.

### Added

- **Non-Node ecosystems.** Detection was `package.json` only, so Python, Go, and
  Rust projects were silent no-ops regardless of what they had configured. Added
  `pyproject.toml` (`ruff check .`, falling back to `flake8`), `go.mod`
  (`go vet ./...`), and `Cargo.toml` (`cargo clippy --quiet`), reusing the same
  nearest-manifest walk and the same could-not-run guards. `package.json` wins
  where a directory carries more than one. The Rust probe is `cargo-clippy`
  rather than `cargo`, since probing `cargo` would claim a toolchain that cannot
  actually run the check.
- **`.claude/lint-gate.json`** names a repo's own commands
  (`{"commands": ["make lint"]}`). When present it *replaces* built-in detection
  outright rather than adding to it — the only precedence a reader can predict
  without tracing the code. A malformed file disables the gate rather than
  falling back to the detection it was meant to replace.

### Changed

- **Timeout re-budgeted.** Worst case is now every check paying for its baseline
  plus one materialization per side: `2 × (120 + 60) + 2 × 30 = 420s`, inside a
  hook timeout raised from 200s to 480s. The baseline gets a smaller budget than
  the primary run (60s vs 120s) because a baseline timeout degrades to
  whole-project blocking, which is the safe direction. Test 13 asserts the
  arithmetic rather than trusting the numbers to stay in sync.
- **Every could-not-run path was re-audited** against a single rule: exit 0 or
  fall back to whole-project blocking, never silently pass a real failure.
- `tests/plugins/test-lint-before-commit.sh` grew from 38 checks to 78, adding
  nearest-package resolution, each ecosystem in both present and absent-toolchain
  states, the config override, baseline pass/block/line-shift/unstaged/fallback,
  and a behavioural assertion — via monkeypatched `os.path.exists`, `open`, and
  `subprocess.run` — that a non-commit payload touches the filesystem zero times
  before the commit regex bails.

## v4.13.0 — 2026-08-05 — `merge` reads `mergeStateStatus` instead of hand-gating threads

### Changed

- **The unresolved-review-thread gate is gone from `merge` and `agent-merge`.**
  A paginated GraphQL `reviewThreads` query blocked the merge on any unresolved
  node. Nothing in GitHub asked for that: "Require conversation resolution
  before merging" is a per-repo branch-protection toggle, and the skill enforced
  the strictest reading on every repo regardless of what the repo had chosen.
  Six nit-level bot comments were enough to deadlock an approved, fully green
  PR — and since the only way out was to fix them and push, the push re-fired
  the bot.
- **`mergeStateStatus` replaces it**, added to the Step 1 `gh pr view --json`
  field list. GitHub computes it from that repo's own branch protection, so
  conversation-resolution policy is honored where it is configured and ignored
  where it is not. `mergeable` was never a substitute: it reports *conflicts*
  (`MERGEABLE`/`CONFLICTING`), not *permission to merge*.
- **`CLEAN`, `UNSTABLE`, and `HAS_HOOKS` pass.** `UNSTABLE` means only
  non-required checks are failing or pending — a failing *required* check reads
  `BLOCKED` — so blocking on it would have silently overturned the `--required`
  rule, which is the one place this skill decides what counts as enforced.
  `HAS_HOOKS` is `CLEAN` on a repo with pre-receive hooks, and is the *normal*
  state on a GitHub Enterprise repo that uses them; rejecting it would have made
  the skill permanently unable to merge there, with the hook itself already
  serving as the server-side enforcement point. Everything else (`BLOCKED`,
  `BEHIND`, `DIRTY`, `DRAFT`, `UNKNOWN`) stops and asks; `UNKNOWN` means
  re-query, never proceed.
- **Stop conditions say *required* check, not *check*.** The prose lists in
  `merge`, `agent-merge`, and `/git-agent:merge-bg` all said "pending or failing
  checks", which contradicts accepting `UNSTABLE` and would have rejected a
  merge state the gate above admits. `merge-bg`'s contract also still named
  unresolved review threads, a gate that no longer exists.
- **On a repo with no branch protection, `mergeStateStatus` reads `CLEAN`** for
  the same reason `--required` exits non-zero: nothing is configured to block
  on. Neither signal is a gate there, which the Step 4 summary now says plainly
  — the mandatory `AskUserQuestion` is the gate, as it always was.
- Net effect on safety: unchanged for protected repos (GitHub enforces the same
  policy server-side, and `gh pr merge` fails if violated), and unchanged for
  unprotected ones (the human approval prompt was always the only gate). What
  changed is that the skill no longer invents policy the repo did not set.
- `BLOCKED` does not report *why*. The Step 4 summary names the status and the
  user opens the PR; restoring the thread query purely as a diagnostic would
  cost more lines than the gate that was deleted.
- GitLab follows the same rule: `glab mr view --unresolved` feeds the summary
  rather than gating, since `glab mr merge` fails server-side when the project
  requires resolved threads.

## v4.12.0 — 2026-08-05 — `ship-autonomous` Step 6c filters findings by severity

### Changed

- **A non-blocking review finding no longer earns a commit.** Step 6c had three
  branches — apply, escalate, refute — and a correct-but-trivial nit matched the
  first one: it is clear, safe, and in scope, so the skill would `Edit`, commit,
  and push. Every push re-fires the review bot, which returns a fresh round of
  nits on a slightly different commit, so the pipeline could spend more output
  on polishing than the change under review cost to write. The existing refute
  branch did not catch this — a nit is not *wrong*, so nothing routed it away
  from the eager path.
- **The filter is a gate ahead of the three branches, not a fourth branch.** A
  fourth would have competed with "clear, safe, and in scope" for the same
  finding and lost. Blocking means correctness, security, data loss, a finding
  carried by a `CHANGES_REQUESTED` review, or a required-check failure;
  everything else — nits, naming, formatting, "consider…", "optional", future
  work, Wish List items, praise, summaries — gets one reply, a resolved thread,
  and a line in the next status update so the user decides.
- **Nits may not be batched into a blocking fix's commit.** "I'm already
  pushing" is the rationalization that erodes the filter one finding at a time,
  so it is refused explicitly rather than left to judgement.
- **Three guardrail bullets collapse into one.** Wrong findings, non-blocking
  findings, and re-fired reviews were the same policy at three generalities —
  reply once, do not commit, do not polish. `ship-autonomous`'s core sat one
  word under the 600-word ceiling that `test-skill-split-git-social.sh`
  enforces, so the new rule paid for itself by merging them rather than by
  raising the ceiling. Nothing was dropped; the full severity table lives in
  `references/pr-events.md`, which is where the ceiling is meant to push it.
- **An "LGTM otherwise" / "approve with minor suggestions" / "ready to merge"
  verdict now routes to Step 7** instead of opening another fix round.
- Thread resolution is scoped: resolve only threads you replied to, never one
  carried by a `CHANGES_REQUESTED` review — resolving that does not clear the
  review decision, and Step 8 still blocks on it.

## v4.11.0 — 2026-08-02 — The plan-issue extractor becomes a `bin/` command

### Fixed

- **The documented invocation could never run — for anybody, at any permission
  level.** Claude Code's Bash tool refuses any command whose text contains
  `${VAR}` or `$VAR`, erroring with `Contains expansion` because it cannot
  statically resolve the expansion. The refusal fires *before* permission rules
  are consulted, so no `allowed-tools` entry, `tools:` grant, or permission rule
  can rescue it — a prefix rule like ``Bash(python3 "${CLAUDE_PLUGIN_ROOT}/...":*)``
  can never match, because the command is rejected before rule matching begins.
  `${CLAUDE_PLUGIN_ROOT}` compounds this: it is a config-file substitution for
  `hooks.json`, MCP/LSP, and monitor commands, and is not exported into the Bash
  tool's environment, so it would expand to empty even if the guard allowed it.
- **The fix is a `bin/` wrapper invoked by bare name.** Claude Code adds a
  plugin's `bin/` directory to the Bash tool's `PATH`, so a bundled script is
  callable as a bare command containing no `$` at all. The wrapper resolves its
  own location via `dirname "$0"` — legal, because the expansion guard inspects
  only the command text passed to the Bash tool, not what the shell then runs.
  A literal absolute path could not ship instead: the install path differs per
  machine.
- **Guarded by `tests/plugins/test-no-shell-expansion.sh`,** a repo-wide check
  that fails on any documented interpreter invocation carrying an expansion, on
  any bundled script invoked via a braced expansion in command position, on a
  wrapper that loses its exec bit or its target, and on `bin` falling off the
  `dist/` KEEP allowlist.

### Changed

- `agent-pr` (Step 4.5) and `agent-ship` (Step 7.5): both now run
  `git-agent-extract-plan-issues <base>`. Until now every PR and ship run
  silently skipped the `## Linked Issues` section, because the extractor call
  errored out and "no output" is indistinguishable from "no linked issues" in
  the documented flow.

## v4.10.1 — 2026-08-02 — clean-tree guard uses `--porcelain`

### Changed

- **`commit-agent` and `agent-commit` Step 1 run `git status --porcelain`.**
  Both guards already stopped on a clean working tree, but judged cleanliness
  from verbose `git status` prose — a call left to the model, and both run on
  `haiku`. `--porcelain` makes it mechanical: empty output means clean, full
  stop.


## v4.10.0 — 2026-07-31 — commit-agent asks whether to push

### Added

- **`commit-agent` Steps 5–6: resolve the push command, then ask.** After a
  successful commit the skill now always asks via `AskUserQuestion` ("Push /
  Don't push") instead of ending at the undo note. Step 5 first runs
  `pr-agent` Step 4's upstream probe —
  `git rev-parse --abbrev-ref --symbolic-full-name @{u}` — to resolve
  `git push -u origin <branch>` (no tracking ref) or `git push` (tracking ref
  exists). The probe is read-only and deliberately precedes the question so the
  prompt can name the exact command it is authorizing, rather than asking about
  an abstract "push" and only then discovering which form it takes. Step 6 asks
  and, on approval, runs the resolved command. A dismissed question counts as
  "Don't push", so closing the dialog leaves the commit local.
- **Push failures stop the skill.** Reported verbatim: no retry, no `--force`,
  and no `pull`/`fetch`/`rebase`/`merge` to make the push land. A rejected push
  means the branch diverged, and reconciling divergence is the user's call —
  not a step the skill takes on its own to satisfy the approval it was given.
- `AskUserQuestion` added to the skill's `allowed-tools`.

- **Delegated invocation stops after Step 4.** The push question is for a user
  who invoked `commit-agent` directly. When another skill or agent invokes it as
  a sub-step it skips the probe and the prompt entirely, because the caller owns
  the push: `ship-autonomous` Step 3 commits and then delegates the push to
  `pr-agent` in Step 4, and its Step 6d commits and pushes directly. Without
  this carve-out an unattended ship run would block on an interactive question,
  and answering "Don't push" would not have stopped the caller from pushing a
  moment later — a prompt that cannot honor its own answer. Both `ship-autonomous`
  call sites and `references/pr-events.md` state the delegated contract.

### Changed

- The skill's stop marker moves from step 4 to step 6, and the "When not to
  use" note narrows from "Does not push or create PRs" to "Does not create PRs
   — use pr-agent for that. Never pushes without the Step 6 approval."

### Unchanged

- **`agent-commit` still never pushes.** A background subagent has no user to
  ask, and the dispatch authorizes a commit, not a remote write — the same
  reasoning that kept `agent-merge` from inheriting `merge`'s approval prompt.
  Background flows that should reach the remote use `agent-pr` or `agent-ship`.


## v4.9.0 — 2026-07-30 — Prune ordering reminders, keep every irreversibility guard

### Changed

- **`ship-autonomous` drops "Steps 0–5 run in strict order."** The operative
  half of that paragraph — Step 5 subscribing to PR events and ending the turn,
  and Steps 6–8 being standing policy rather than a loop — is unchanged.
- **`branch-agent` drops its opening ordering sentence** —
  `Follow these steps in strict order. **STOP immediately after step 6.**` —
  because the `## Step 6: Confirm and STOP` block already states the same
  stopping rule, and it survives verbatim.
- Untouched, by classification: "Never merge on anything but green", the
  branch-deletion approval guard, "Never dismiss a review on your own
  initiative", "Do not retry. Do not force.", and the stale-ref and
  no-further-action stops.

### Testing

- **Baselines recorded and reproduced before the prune** (`ed6b854`).
  `branch-agent` was run headless against a fixed dirty tree that conflicts with
  a checkout: it branches, and the stash/pop cycle returns every file with its
  contents intact (`tracked.txt` still modified, the untracked scratch file
  still present, `git stash list` empty) while adding no commit and never
  reaching `gh`. `ship-autonomous` on a clean tree leaves `HEAD`, the branch,
  and the working tree unchanged. Both reproduced their manifests after the
  prune.
- Guarded by `tests/plugins/test-imperative-pruning.sh`, now wired into
  `check-plugin-versions.yml`.

## v4.8.0 — 2026-07-30 — Split the three heaviest skills into cores plus references

### Changed

- **`ship-autonomous` 2,406 → 597 words**, **`branch-agent` 1,476 → 582**, and
  **`ship` 1,191 → 571** — 5,073 words down to 1,750. A SKILL.md body has no
  partial load: the moment a skill triggers, its whole body is paid. These three
  now ship a small always-loaded core plus skill-local `references/*.md` files
  the model opens only at the step that needs them, matching the layout
  `create-issue` already used.
- New reference files: `ship-autonomous/references/{preflight-and-verify,pr-events,ci-autofix,merge-gate}.md`,
  `branch-agent/references/{branch-naming,stash-and-recovery}.md`, and
  `ship/references/{platform-clis,self-review,pr-body,commit-message}.md`.
- No frontmatter changed. All three `description:` lines are byte-identical to
  v4.7.1 — the description is the only trigger surface, so a reworded one would
  silently change when the skill fires.
- **Guard restored:** `ship` Step 1 states its fourth hard stop in the core again
  — "**CLI not available or not authenticated:** … and **STOP**", as v4.7.1 had
  it. The first cut of this split left only "verify the CLI" in the body and moved
  the stop itself into `references/platform-clis.md`, which is the one thing this
  refactor is not allowed to do. The commands, install URLs, and message text stay
  in the reference. `tests/plugins/test-skill-split-git-social.sh` now asserts the
  phrase so it cannot slip again — 12 git guard assertions, up from 11. That
  count is now tallied by the test rather than written into its log line: both
  hard-coded numbers the message previously carried were off by one.
- Step 3's commit-message format rules moved to `ship/references/commit-message.md`.
  That is procedure, and moving it paid for the guard above: `ship` went 599 → 571,
  turning 1 word of headroom under the 600-word ceiling into 29.
- `ship-autonomous` Steps 2/3/4 say "invoke the `git-agent:branch-agent` skill"
  rather than bare ``git-agent:branch-agent``. Shortening the step text had
  dropped the noun v4.7.1 carried ("the existing … skill"), leaving the
  identifier ambiguous enough to read as a `/plugin:name` command — which these
  are not.

### Why the guards stayed in the core

These three skills rewrite refs, push to remotes, and end in an irreversible
squash merge; `ship-autonomous` alone carries 22 negative imperatives. A guard
relocated into a reference file the model never opens is a guard that no longer
exists, and its absence is invisible until the day it should have fired. So only
commands and tables moved out — the CI classification table, the
`gh api graphql` review-thread query, the branch-name type-inference table, the
stash-pop recovery script. Every hard stop stayed in the always-loaded body,
including `do not commit a red tree`, `Do not use --no-verify`,
`Cap autofix at 3 attempts per failing check`, `Never merge on anything but
green`, `--match-head-commit`, and `Branch deletion requires its own explicit
approval`. `ship-autonomous` now leads with a `## Guardrails` block because
inline guard prose alone would not fit under the ceiling.

`tests/plugins/test-skill-split-git-social.sh` (new, wired into
`.github/workflows/check-plugin-versions.yml`) fails if any core creeps back
over 600 words, loses a guard phrase, drifts a description, or leaves a
reference link dangling in either direction.

Eight further tests were wired into that workflow at the same time. They already
existed and already passed on `main`, but none was named in any workflow — and in
a repo with no test runner, a test nobody runs is decoration. All nine were run
green locally before being gated on.

- **`tests/plugins/test-ship-self-review.sh` retargeted** — Step 4.5's four
  regression checks, the amend procedure, and the loop bound now live in
  `ship/references/self-review.md`, so checks 5-7 read that file while the
  policy checks (default-on, `--no-review`, never blocks the ship, Step 7 base
  reuse) still read the core. A new check asserts SKILL.md actually links the
  reference — a reference nothing links to never loads.

## v4.7.1 — 2026-07-28 — Collapse the plan-mode guard to one line

### Changed

- **Ten files lose the `ExitPlanMode` tutorial** — `branch-agent`, `commit-agent`,
  `create-issue`, `merge`, `pr-agent`, `ship`, `ship-autonomous`, and the
  `agent-merge` / `agent-ship` / `agent-ship-ci` agents each carried their own
  wording of the same four-line block: what plan mode is, why staging or pushing
  is a mutation, how to `ToolSearch` for the deferred tool, and how to treat the
  "You are not in plan mode" error as success. All ten now carry one line.
- The guard is preserved everywhere it was — these skills all mutate git state or
  a remote, and `tests/plugins/test-exitplanmode-guard.sh` fails if any of them
  loses it.

## v4.7.0 — 2026-07-21 — lint gate before commit

### Added

- **`hooks/lint-before-commit.py`** — a `PreToolUse` hook on `Bash` that runs the host repo's lint script before any `git commit` lands. Exit 2 blocks the commit and feeds the lint output back to Claude, which fixes and retries without a user round-trip.

### Why a hook and not a skill step

`commit-agent` ends with an explicit "do not run tests, analyze coverage, check for issues" instruction, and the background `agent-commit` repeats it — a lint step added there would contradict that contract and could still be skipped, since a skill instruction is advisory. A hook is executed by the harness, so it covers `commit-agent`, `agent-commit`, `ship`, and hand-written `git commit` calls alike, and cannot be reasoned around.

### Detection and scope

package.json only: `scripts.lint`, then `scripts.typecheck` if present. The package manager comes from the lockfile (`pnpm-lock.yaml`, `yarn.lock`, `bun.lock`, `bun.lockb`, else `npm`) — both Bun formats are recognized, since `bun.lock` became the default in Bun 1.2 and `bun.lockb` is legacy. A repo with no package.json, no matching script, or a missing runner is a silent no-op — the gate never strands a commit in a repo it does not understand.

Each check gets 90s, so both together stay inside the 200s hook timeout declared in `hooks.json`. A test asserts that relationship rather than trusting the two numbers to stay in sync.

### Only a check that ran may block

A check that *could not run* is never treated as a failure. Two guards enforce this: the hook skips entirely when dependencies are not installed (no `node_modules` and no `.pnp.cjs` — the fresh-clone-before-`npm install` case), and it skips any script exiting `127`, the shell's command-not-found code that npm, pnpm, and yarn all pass straight through. A real lint failure exits `1`. Without these, a fresh clone would refuse to commit and blame the code.

`.pnp.cjs` is checked because Yarn PnP resolves binaries without ever creating `node_modules`; reading that as an unbuilt repo would silently drop the gate.

### Escape hatch

Create `.claude/no-lint-gate` at the repo root to disable it. The block message names this path, so nobody has to find it in the docs.

### Matching

Only real commits trigger it: `git commit`, `git commit --amend`, `git -C path commit`, and `git add -A && git commit` all match, while `git log --grep commit` and `git commit-tree` do not.

`-C <path>` retargets the lint root, because that flag moves the commit to another repo — linting the payload's `cwd` there would check the wrong package, letting a real failure through while blocking on an unrelated one. Absolute and relative paths both resolve. `-c` is left alone; it sets config, not a directory.

Covered by `tests/plugins/test-lint-before-commit.sh` (38 checks).

## v4.6.0 — 2026-07-21 — background merge

### Added

- **`agents/agent-merge.md`** — a background subagent that runs the `merge` skill's readiness gate (PR lookup, `gh pr checks --required`, `mergeable`, `reviewDecision`, unresolved review threads, lint) and squash-merges only when everything is unambiguously green.
- **`commands/merge-bg.md`** — `/git-agent:merge-bg [pr]` dispatches it and returns control immediately.

### What the dispatch authorizes

The `merge` skill ends in an `AskUserQuestion` approval prompt, and a background subagent has no user to ask. Running `/git-agent:merge-bg` is therefore the approval — for **one squash merge of a fully green PR**, and nothing else. Every branch the skill routes to "ask" becomes a stop-and-report instead: pending or failing checks, `CONFLICTING`/`UNKNOWN` mergeable state, `CHANGES_REQUESTED`, unresolved review threads, a truncated thread list, a failing lint gate, or a head commit that moved between verification and merge (`--match-head-commit` still pins it). If squash merges are disallowed the agent reports the allowed methods rather than silently switching method — the approval was for a squash.

It never passes `--delete-branch` (or GitLab's `-d`), never marks a draft ready, never replies to or resolves reviews, and upholds the background-agent deny list (`Write`/`Edit`/`NotebookEdit`) asserted by `tests/plugins/test-ship-self-review.sh`.

### Two background-specific divergences from the skill

The `merge` skill assumes the foreground invariants that the working tree *is* the PR head and that the checked-out branch *is* the PR. Neither holds for a background agent, so:

- **The PR argument wins over the branch.** `/git-agent:merge-bg 123` acts on PR 123 even when another branch is checked out. Only an argument-less dispatch resolves the PR from the current branch. The argument is a PR target, not a summary hint like `commit-bg`'s.
- **The lint gate is guarded.** It runs only when the working tree is clean *and* `HEAD` equals the PR's `headRefOid`; otherwise it is skipped and reported as skipped. The parent session keeps editing after dispatch, so lint passing in a drifted tree says nothing about the commit `--match-head-commit` will merge — reporting that as a passed gate would be a false green.

## v4.5.0 — 2026-07-20 — background CI watcher

### Added

- **`agents/agent-ship-ci.md`** — a background subagent that watches an already-open PR's checks, applies at most one deterministic autofix per failing check, and reports. It is the unattended, truncated half of the `ship-autonomous` skill, not a background wrapper around it.
- **`commands/ship-ci-bg.md`** — `/git-agent:ship-ci-bg [pr]` dispatches it and returns control immediately.
- `tests/plugins/test-ship-ci-agent.sh` — 20 checks covering the deny-list invariant, the never-merge / never-review / never-ready guarantees, the existing-PR precondition, the one-attempt autofix cap, the lockfile-only revert, and the bounded `--watch`.

### Why it is not `ship-autonomous` in a subagent

`ship-autonomous` is built around `mcp__github__subscribe_pr_activity`: Step 5 ends the turn and the session is woken by PR webhooks. A subagent runs once to completion and can never be re-woken, so wrapping the skill would silently downgrade it to the polling fallback. Its escalation points — unrecognized CI failure, ambiguous review comment, `CHANGES_REQUESTED`, and the merge gate — are all `AskUserQuestion`, and a subagent has no user to ask. `agent-ship-ci` therefore drops every step that needs a human instead of guessing at it: it never merges, never marks a draft ready, never deletes a branch, and never replies to, resolves, or dismisses a review. It reports and stops; the merge decision stays with the parent session.

### Autofix scope and the deny-list invariant

Background git agents have denied `Write`/`Edit`/`NotebookEdit` since v3.5.0, and `tests/plugins/test-ship-self-review.sh` asserts that across every `agents/agent-*.md`. `agent-ship-ci` upholds it. That splits the `ship-autonomous` autofix allowlist in two:

- **Applied** — `lint` (only via a `--fix` script the project already defines) and `peer-deps` (lockfile reinstall, with the diff verified lockfile-only and reverted if it is not). These are the project's own tooling rewriting its own output via `Bash`, not model-authored edits.
- **Reported only** — `typecheck`, test failures, and everything unrecognized. Their fixes are source edits, which an unattended agent must not author.

One attempt per check, not three: these fixers are deterministic, so a second identical run cannot succeed where the first failed. `gh pr checks --watch` is bounded by the **Bash tool's own `timeout` parameter** (540s) and looped at most 5 times (~45 min) so a long CI run cannot exceed a single command timeout. It deliberately does not shell out to `timeout` — that is GNU coreutils and absent on stock macOS, where `timeout 540 gh ...` fails with `command not found` and the watch never runs. This was caught live on macOS while shipping the agent's own PR.

Throttled external review bots (CodeRabbit and similar report a red check when merely rate-limited, with an empty `workflow` and `link`) are classified `bot-infra` and are report-only. There is no defect to fix, and pushing a commit to clear one just burns another CI round. Also caught live on the agent's own PR.

### Fixed before merge

Three P2 findings from review on the agent's own PR, all of them inherited or blast-radius bugs rather than typos:

- **Failing logs are scoped to this PR.** Step 3 originally used `gh run list | head -1`, copied from `ship-autonomous`, which lists runs repo-wide — an unrelated branch's failure could be classified and "fixed" on this PR while the real failing check went unread. The run id now comes from the failing check's own `link`. A link-less failing check (external status bots report no run) is classified `bot-infra`.
- **The peer-deps blast-radius check sees untracked files.** `git diff --name-only` covers only tracked files, but Step 5 stages with `git add -A`, so an untracked install artifact (`.pnp.cjs`, install state, an unignored `node_modules`) would ride along into the commit despite passing the check. Now `git status --porcelain`, with a path-scoped `git clean` on discard — never a bare one.
- **The report queries review threads, not just `reviewDecision`.** `reviewDecision` carries only the summary verdict and reads empty on a PR with unresolved threads waiting, so reporting it alone would tell the parent session a PR is clear when it is not. The report now also runs the GraphQL `reviewThreads { isResolved }` query. This reproduced on the agent's own PR: `reviewDecision` was empty while three threads sat unresolved.

---

## v4.4.0 — 2026-07-20 — `merge?` shorthand as a skill + prompt hook

### Added

- **`skills/merge/SKILL.md`** — merge-readiness skill, explicitly invocable as `/git-agent:merge`. Finds the branch's PR, gates on `MERGEABLE` + green required checks + no `CHANGES_REQUESTED` + no unresolved review threads, runs the project's first non-`--fix`, non-`watch` `lint*` script (the `ship-autonomous` Step 2.5 precedent), then **re-runs the readiness queries** and asks for explicit approval via `AskUserQuestion` before `gh pr merge --squash --match-head-commit <headRefOid>`. Never auto-applies `--fix` (it would change the PR head), never passes `--delete-branch`, and never silently retries a rejected `--squash` as `--merge`/`--rebase`. Anything pending, failing, or ambiguous → status summary and a question.
  - The blocking gate uses `gh pr checks --required` — what branch protection actually enforces — while the full list still feeds the approval summary, so a pending optional check is surfaced without deadlocking a mergeable PR.
  - Checks are read via `gh pr checks --json name,state`, not `statusCheckRollup`: rollup nodes are heterogeneous (`CheckRun` carries `status`+`conclusion`, `StatusContext` carries `state`), so a single "is it SUCCESS" test reads an in-progress run as green. Same reasoning `ship-autonomous` Step 8 already documents.
  - Review threads are fetched with `totalCount`/`pageInfo`; a truncated page is reported as unknown rather than counted as zero.
- **`hooks/merge-shorthand.py` + `hooks.json`** — `UserPromptSubmit` hook that routes the literal prompt `merge?` (anchored, case-insensitive, whitespace-tolerant) to the merge skill. Silent on every other prompt, so ordinary sentences containing "merge" are untouched. First hook wiring in `git-agent`; mirrors `plan-agent/hooks.json`.
- `tests/plugins/test-merge-shorthand.sh` — pins the hook's trigger boundary (3 firing cases, 5 near-miss silences), the hooks.json wiring, and the skill's safety contract (MERGEABLE gate, lint gate with no auto-fix, explicit approval, `--match-head-commit`, no `--delete-branch`).

Replaces a private per-machine memory note with a shipped, reviewable, tested behavior.


---

## v4.3.0 — 2026-07-20 — ship self-reviews the diff before pushing

### Added

- **Step 4.5 (Self-Review Before Push)** in `skills/ship/SKILL.md` and `agents/agent-ship.md` — diffs the whole branch against its base and critiques it as a hostile reviewer before Step 5 pushes. Checks four regression classes that CI review bots repeatedly caught after the fact: dropped accessibility attributes, double-escaping in generated output, string parsing/truncation edge cases, and responsive/desktop layout regressions. Findings are fixed and folded into the Step 4 commit via `git commit --amend --no-edit`; the check re-runs once, never loops, and never blocks the ship.
  - `ship` (foreground): on by default — pass `--no-review` to skip.
  - `agent-ship` (background): always runs, and is **report-only** — it never edits files. Background git agents have denied `Write`/`Edit`/`NotebookEdit` since v3.5.0 so an unattended agent cannot rewrite source, and Step 4.5 upholds that rather than weakening it. Every finding is surfaced in the report returned to the parent session, so nothing ships silently; acting on a finding is the parent session's call. The step also explicitly forbids routing around the deny list via `Bash` (`sed -i`, heredoc rewrites, `git apply`).
- `tests/plugins/test-ship-self-review.sh` — 22 checks covering step ordering, the four regression classes, the non-blocking guarantee, the fix-vs-report asymmetry between skill and agent, and the deny-list invariant across all three `git-agent` background agents.

### Changed

- `skills/ship/SKILL.md`: `allowed-tools` gains `Edit` so self-review findings can be fixed in place. This is safe in the foreground, where the user sees the edits before the push.
- `agents/agent-ship.md`: the Step 8 close-out now reports self-review findings alongside the PR/MR URL. `tools` is deliberately unchanged — adding `Edit` there would have been inert (`disallowedTools` overrides it) and misleading.

---

## v4.2.0 — 2026-07-20 — Test Plan in PR bodies, lint gate, refuted-finding replies

### Added

- **`## Test Plan` section in PR bodies** (`pr-agent`, `ship`) — a checklist of the commands a reviewer runs to verify the change. Boxes may only be checked for work actually verified in-session; an unchecked box is honest, a false checkmark is not.
- **Lint gate in `ship-autonomous` Step 2.5** — runs the project's first non-`fix`, non-`watch` `lint*` script alongside the test suite and stops on failure, catching lint locally instead of a full CI round-trip later in Step 6b. No auto-`--fix` at this stage: the user has not seen the diff yet.
- **Refuted-finding path in `ship-autonomous` §6c** — a review comment that misreads the code, describes stale state, or repeats a declined finding is answered with one short reply on the thread and resolved, not silenced with a no-op commit. A repeat of the same refuted finding is skipped silently. When the finding arrived as a formal `CHANGES_REQUESTED` review, replying and resolving does **not** clear the review decision that Step 8 blocks on, so that case escalates via `AskUserQuestion` (dismiss the review, or request a re-review) instead of being marked handled — never merged around.

---

## v4.1.1 — 2026-07-16 — Trim ship-autonomous description to budget

### Fixed

- `skills/ship-autonomous/SKILL.md`: description reduced from 214 chars to within the 200-char budget, so it no longer trips `/skill-reviewer:check-description`.

---

## v4.1.0 — 2026-07-16 — ship-autonomous verifies before committing and gates the merge

### Added

- **Step 2.5 (Verify)** — runs the project's `test*` script before committing and stops on failure rather than shipping a red tree. When the change is observable in a browser, previews it via `.claude/launch.json`, checks console and server logs, and screenshots both light and dark themes.
- **Step 8 (Merge)** — re-confirms every check is green immediately before merging, re-fetches the live review decision and unresolved-thread count (an approval or change request may have landed since the last event), then gates the merge itself behind `AskUserQuestion`. The merge pins `--match-head-commit <headRefOid>` so commits arriving after verification cause the merge to fail rather than silently land unreviewed. Branch deletion requires a **separate** explicit approval: a merge approval never authorizes `--delete-branch`.
- Closing policy note: a re-fired bot review on an already-approved PR is not new information — after one substantive fix pass, only merge-blocking findings are actioned.

### Changed

- `allowed-tools` gained the `mcp__Claude_Browser__*` preview tools used by Step 2.5.

### Fixed

- **Step 5 fallback polling was broken (pre-existing, since v3.x).** `gh pr checks --json name,state,conclusion,workflowName` errors out with `Unknown JSON field` — `gh pr checks` exposes `state`/`workflow`, not `conclusion`/`workflowName` (those belong to `gh run list`). Local runs without the GitHub MCP server could never read CI status. Now queries `name,state,workflow,link` and reads `state`. Prose in Steps 5 and 7 updated from "conclusions" to "states".
- Step 8's green re-check used the same invalid `conclusion` field; corrected to `name,state,link`.
- Step 8 suggested `gh pr branch-delete`, which is not a `gh` subcommand — cleanup would have failed after an otherwise successful merge. Replaced with `git push origin --delete <branch>` and an optional local `git branch -d`.
- Step 2.5's test-script selector matched `^test`, so a `test:watch` or `test:dev` script could be selected and hang the pipeline forever. Now prefers the exact `test` script and excludes persistent variants (`watch`, `dev`, `ui`, `serve`) when falling back.
- Step 2.5's browser preview checked console and server logs but only treated theme breakage as blocking; console/server errors now block and must be fixed and re-checked before the pipeline continues.
- README described the local fallback as stopping once CI is green, contradicting Step 8, which routes fallback mode through merge approval. Corrected.

## v4.0.1 — 2026-07-13 — Per-skill model pinning

### Changed

- Model frontmatter tuned to match each component's job: `branch-agent` fixed from `Haiku` to the documented lowercase `haiku` alias; `commit-agent` and the `agent-commit` background agent pinned to `haiku` (rigid conventional-commit format, high frequency); `pr-agent` and `create-issue` pinned to `sonnet` (outward-facing prose, matching `agent-pr`). `ship` and `ship-autonomous` deliberately inherit the session model — ship-autonomous's CI autofix step applies real code edits and should never run on a downgraded model. Overrides are turn-scoped and fall back to the session model if excluded by an org `availableModels` allowlist.

## v4.0.0 — 2026-07-13 — create-issue auto-activates on intent match

### Changed

- **Breaking (activation behavior):** removed `disable-model-invocation: true` from the `create-issue` skill — it now auto-activates when user intent matches (e.g. "file a bug", "open an issue", "create a feature ticket") in addition to explicit `/git-agent:create-issue` invocation. The confirmation gate before issue creation is unchanged.
- `create-issue` Phase 3 documents both activation paths: on ambient model invocation `$ARGUMENTS` is empty, so the source keyword and title are derived from the triggering message and recent conversation before falling back to `AskUserQuestion`.

## v3.12.0 — 2026-07-13 — create-issue accepts plan files as a source

### Added

- `create-issue` skill: new `plan` source — pass a plan file path (`.md` spec or rendered `.html`; a bare `.md`/`.html` token implies the source without the keyword) and the skill maps the plan's title, Objective, Steps (as a `- [ ]` checklist), and Acceptance Criteria into a structured issue body via the new `references/plan-issue.md` template. Labels are suggested from the plan's `type:` frontmatter. The issue body cites the plan path so the ticket links back to its plan.

## v3.11.1 — 2026-07-11 — More descriptive, human-readable generated branch names

### Changed

- `branch-agent` skill: auto-generated branch descriptions are now verb-led
  phrases that read like commit subjects (e.g.
  `feat/add-login-form-validation`) instead of extracted keyword fragments.
  Whole words only — abbreviations to save space are prohibited; long names
  drop trailing words instead of chopping mid-word.
- Length budgets raised to make room for readable names: pre-suffix name
  ≤ 60 chars (was 49), final date-suffixed name ≤ 72 chars (was 60), and
  descriptive-phrase slugs (Case B) ≤ 60 chars (was 30).

## v3.11.0 — 2026-06-16 — Absorb create-issue skill from issue-agent plugin

### Added

- `create-issue` skill: drafts and creates GitHub/GitLab issues from four context sources (`bug`, `feature`, `selection`, `session`) with host auto-detection, a confirmation gate, and automatic browser open (`--no-open` to suppress). Moved from the now-retired `issue-agent` plugin.

### Changed

- **Breaking:** invocation namespace changed from `/issue-agent:create-issue …` to `/git-agent:create-issue …`. Update any scripts, docs, or muscle memory accordingly.

## v3.10.5 — 2026-06-05 — Use portable plugin-dir path in README

### Fixed

- `README.md`: local-development example now uses the repo-relative `./kit/plugins/git-agent` path instead of an author-specific home directory.

---

## v3.10.2 — 2026-06-01 — Add ExitPlanMode error handling

### Fixed

- fix: add ExitPlanMode error handling — treat 'not in plan mode' error as success

## v3.10.1 — 2026-06-01 — Minor wording corrections

### Fixed

- `ship-autonomous` skill: minor description wording corrections.

---

## v3.10.0 — Auto-link plan issue references in PR descriptions

- PR creation now scans plan files changed on the branch for
  `<meta name="plan-issue">` tags and appends a `## Linked Issues` section
  with `Closes <url>` lines to the PR body, enabling GitHub/GitLab to
  auto-close referenced issues on merge.
- Added shared `scripts/extract-plan-issues.sh` for background agents;
  foreground skills use inline `git diff` + `Grep`.
- Applies to all PR creation paths: `pr-agent`, `agent-pr`, `ship`,
  `agent-ship`, and `ship-autonomous` (via delegation to `pr-agent`).

## v3.9.3 — Fix subagent_type namespace qualification in background commands

- `commit-bg`, `pr-bg`, and `ship-bg` now dispatch with fully-qualified
  `subagent_type` values so agents resolve correctly when the plugin is
  installed from the marketplace:
  - `commit-bg`: `agent-commit` → `git-agent:agent-commit`
  - `pr-bg`: `agent-pr` → `git-agent:agent-pr`
  - `ship-bg`: `agent-ship` → `git-agent:agent-ship`

## v3.9.2 — README: sync usage documentation; split provider-specific CLI requirements

- Updated README.md to accurately reflect current plugin capabilities, component inventory, and usage patterns.

## v3.9.1 — branch-agent: auto-stash on checkout conflict

- `branch-agent` now detects tracked files that would conflict with
  `git checkout -b` before attempting the checkout (new Step 4.5). The
  conflict set is computed as the intersection of locally-modified tracked
  files and files that differ between `HEAD` and `origin/<default>`.
- When conflicts are detected, the skill automatically stashes, creates the
  branch, and pops the stash — recovering your uncommitted changes on the new
  branch. Untracked files are never stashed.
- On `git stash pop` failure (rare merge conflict), the skill stops with a
  clear recovery guide (`git stash list` / resolve / `git stash drop`); the
  stash is never auto-dropped.
- No behaviour change for clean or untracked-only working trees.

## v3.9.0 — ship-autonomous watches PRs via event subscription

- `ship-autonomous` now subscribes to the PR's activity events
  (`mcp__github__subscribe_pr_activity`) after opening the PR, replacing the
  synchronous `gh pr checks --watch` polling loop as the primary path. After
  subscribing it posts an initial status update and ends the turn; CI failures
  and review comments arrive as `<github-webhook-activity>` events that wake the
  session.
- Event handling (Step 6) now covers **review comments** in addition to CI
  failures: clear, in-scope review changes are applied, committed, pushed, and
  replied to; ambiguous or architecturally significant comments are escalated.
- Failures outside the safe allowlist (`lint`/`typecheck`/`peer-deps`) and
  ambiguous review comments now **ask the user via `AskUserQuestion`** rather
  than printing an escalation block and stopping. Autofix is capped at 3
  attempts **per check**.
- Posts **regular status updates** and refreshes a live TodoWrite checklist on
  every event so the thread reflects current state.
- Keeps the subscription active after CI goes green to handle later review
  comments; unsubscribes (`mcp__github__unsubscribe_pr_activity`) only when the
  PR merges/closes or the user asks to stop.
- **Fallback:** in environments without the GitHub MCP server (e.g. local
  Claude Code), the skill detects that `subscribe_pr_activity` is unavailable
  and falls back to the previous synchronous `gh pr checks --watch` polling
  with the same ≤3-attempt autofix, stopping once CI is green.
- Added `mcp__github__subscribe_pr_activity` and
  `mcp__github__unsubscribe_pr_activity` to `allowed-tools`; updated the skill
  description and README to describe the watch/autofix lifecycle.

## v3.8.0 — ship-autonomous moved into plugin

- New skill: `ship-autonomous` — supervised full pipeline (branch if on
  default, commit, open PR, poll CI, autofix lint/typecheck/peer-deps ≤3
  iterations, request review when green)
- Moved from project-level `.claude/skills/ship-autonomous/` into
  `kit/plugins/git-agent/skills/ship-autonomous/` so it ships with the plugin
  and is installable by marketplace users
- No behavior changes — content is identical to the project-level version
  (already had Step 0 `ExitPlanMode` and `ToolSearch`/`ExitPlanMode` in
  `allowed-tools` from the prior fix)
- Updated README with `ship-autonomous` in the Skills list, usage section, and
  Plugin Structure tree

## v3.7.1 — ExitPlanMode in agent-ship

- Added `ToolSearch` and `ExitPlanMode` to `agent-ship` tools list
- Added Step 0 to `agent-ship` workflow: calls `ExitPlanMode` unconditionally
  before any mutation, mirroring the pattern already in all four git-agent
  skills

## v3.7.0 — Disable model invocation on workflow skills

- `disable-model-invocation: true` on `commit-agent` — manual invocation only via `/git-agent:commit-agent`; no longer auto-triggers on intent match.
- `disable-model-invocation: true` on `pr-agent` — manual invocation only via `/git-agent:pr-agent`; no longer auto-triggers on intent match.
- `disable-model-invocation: true` on `ship` — manual invocation only via `/git-agent:ship`; no longer auto-triggers on intent match.

## v3.6.2 — Description cleanup and scope boundaries

- Collapsed `branch-agent` and `ship` skill descriptions from multi-line YAML blocks to single-line inline strings starting with "Use when..." for reliable auto-activation
- Added explicit "Does NOT..." scope clauses to `branch-agent` and `ship` descriptions
- Dropped implementation-detail tags (`subagents`, `background`, `slash-commands`) from marketplace entry; these describe internals rather than user search intent

## v3.6.1 — Conditional ExitPlanMode detection

- All four git-mutating skills (`branch-agent`, `commit-agent`, `pr-agent`,
  `ship`) now detect whether plan mode is active before calling
  `ExitPlanMode`, skipping the call when not in plan mode
- No behavioral change (ExitPlanMode was already a no-op outside plan mode)
  but instructions now explicitly model conditional detection and silent exit

## v3.6.0 — Slash commands for explicit background dispatch

- New `commands/` directory with three thin-wrapper slash commands that
  dispatch the v3.5.0 background agents with `run_in_background: true`:
  - `/git-agent:commit-bg [hint]` → dispatches `agent-commit`
  - `/git-agent:pr-bg [hint]` → dispatches `agent-pr`
  - `/git-agent:ship-bg [hint]` → dispatches `agent-ship`
- Each command accepts an optional hint argument that is passed to the agent
  as additional context for the commit message or PR summary
- Commands return control to the user immediately after dispatch — no
  waiting, no polling; the user is notified automatically on completion
- Updated `README.md` with a "Slash commands" section documenting invocation
  syntax and the example `/git-agent:ship-bg fix off-by-one in pagination`

## v3.5.0 — Background subagents for commit, pr, and ship

- New `agents/` directory with three background subagents that mirror the
  existing skills:
  - `agent-commit` — background version of `commit-agent`
  - `agent-pr` — background version of `pr-agent`
  - `agent-ship` — background version of `ship`
- Each agent uses `background: true` so the parent session can dispatch the
  work and keep going while the subagent runs to completion
- Existing skills (`branch-agent`, `commit-agent`, `pr-agent`, `ship`) are
  unchanged and remain the synchronous path
- `branch-agent` is intentionally **not** mirrored as an agent — branch
  creation is a synchronous setup step (you need to be on the new branch
  before continuing) and backgrounding it has no benefit
- Updated `README.md` with a "Background subagents" section, a skill-vs-agent
  decision table, trigger phrases for each agent, and a caveat about the
  working-tree snapshot timing tradeoff

## v3.4.0 — branch-agent always appends date suffix

- `branch-agent` now appends a `-YYYY-MM-DD` suffix (today's date) to every
  branch it creates, regardless of whether the name came from `$ARGUMENTS`,
  was slugified from a phrase, or was auto-generated from working-tree changes
- Added `Bash(date *)` to the skill's `allowed-tools` so the `date +%Y-%m-%d`
  call does not trigger a mid-run permission prompt
- Auto-generated branch names now cap at 49 characters (down from 60) to
  reserve room for the 11-character date suffix; the final branch name still
  stays under 60 chars
- Example: `feat/login-fix` → `feat/login-fix-2026-04-17`

## v3.3.3 — commit-agent, pr-agent, and ship now exit plan mode on entry

- Extends the v3.3.1 `branch-agent` pattern to the remaining three git-mutating
  skills: `commit-agent`, `pr-agent`, and `ship`
- Each skill now calls `ExitPlanMode` as its first step (Step 0) so it
  self-bootstraps out of plan mode before running any git mutations
- Added `ExitPlanMode` to each skill's `allowed-tools` to prevent mid-run
  permission prompts
- Updated `~/.claude/CLAUDE.md` global rule: callers no longer need to
  pre-check plan-mode state before invoking git-agent skills

## v3.3.2 — pr-agent no longer stops on merged PRs

- `pr-agent` Step 3 now checks `state` when inspecting an existing PR;
  only stops for `state: OPEN` — merged and closed PRs no longer block
  new PR creation

## v3.3.1 — branch-agent always exits plan mode on entry

- `branch-agent` now calls `ExitPlanMode` as its first step (Step 0) so it
  can self-bootstrap out of plan mode before running any git mutations
- Added `ExitPlanMode` to the skill's `allowed-tools` list to prevent
  mid-run permission prompts

## v3.3.0 — Auto-detect branch names from working tree changes

- `branch-agent` now auto-generates a branch name when invoked with no
  argument **and** the working tree has uncommitted changes
- Generated names follow the conventional `<type>/<scope>-<description>`
  format, mirroring the type vocabulary used by `commit-agent`
  (`feat`, `fix`, `docs`, `refactor`, `test`, `chore`, `perf`, `style`,
  `ci`, `build`)
- Type is inferred from the changed file paths and diff (markdown-only →
  `docs`, tests-only → `test`, CI-only → `ci`, build manifests → `build`,
  pure renames → `refactor`, etc.); scope is the most-changed top-level
  directory and is omitted when changes span more than two top-level dirs
- Total branch name length capped at 60 characters with word-boundary
  truncation; falls back to `chore/auto-branch` if validation fails
- Empty argument with a clean working tree still errors as before; explicit
  branch names are still used verbatim with no transformation; descriptive
  phrases continue to be auto-slugified per v3.2.0 behavior

## v3.2.0 — Grant read permissions to pr-agent and ship

- `pr-agent`: add `Read, Grep, Glob` to `allowed-tools` (forward-looking
  permission grant — no current behavior change; enables future edits to
  read PR templates, changelogs, and release notes without a permission update)
- `ship`: same as above

## v3.1.0 — Add branch-agent skill

- New skill: `branch-agent` — creates a branch from `origin/<default>` with no upstream tracking ref and switches to it
- Accepts the branch name verbatim from `$ARGUMENTS`; stops cleanly if none provided
- Guards against detached HEAD, missing `origin` remote, and fetch failures
- Default branch detection follows the `pr-agent` pattern (`git symbolic-ref` → `git remote show` → `main`/`master` fallback)
- Uses `--no-track` on `git checkout -b` to prevent automatic upstream tracking

## v3.0.0 — Remove branching-agent skill

- **BREAKING CHANGE:** Removed the `branching-agent` skill. Users who relied
  on automated branch creation should fall back to `git checkout -b` or
  another plugin.
- The remaining skills (`commit-agent`, `pr-agent`, `ship`) are unchanged.

## v2.0.0 — Rename new-branch skill to branching-agent

- Skill renamed: `new-branch` → `branching-agent`
- Directory renamed: `skills/new-branch/` → `skills/branching-agent/`
- No behavior changes — activation, flow, and slug logic are unchanged

## v1.2.1 — Smarter branch slugs in new-branch

- `new-branch` now extracts the core subject from the user's argument and
  produces short, readable slugs (≤20 chars when possible) instead of
  mechanically slugifying the whole sentence
- Example: "start a feature for dark mode" → `dark-mode`
  (was `start-a-feature-for-dark-mode`)

## v1.2.0 — Add new-branch skill

- New skill: `new-branch` — fetches latest from `origin` and creates a branch from `origin/<default>` without switching to the default branch first
- Prompts for name (or extracts from user message) and type prefix, with a recommendation based on observed branch naming patterns in the repo
- Interactive confirmation when working tree is dirty; carries uncommitted changes forward when git allows it

## v1.1.0 — Add ship skill

- New skill: `ship` — chains commit + push + PR into a single flow
- Unified pre-flight checks before any mutations
- Pushes to existing PR if one already exists on the branch

## v1.0.0 — Initial release with commit-agent and pr-agent skills

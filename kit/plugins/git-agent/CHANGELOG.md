# Changelog — git-agent

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

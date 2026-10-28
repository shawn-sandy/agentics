---
status: in-progress
modified: 2026-10-28
type: fix
created: 2026-10-28
repo-name: agentics
artifact-url: https://claude.ai/artifact/FcwU1aKsAzKtnmUqLjCUNM
issue: https://github.com/shawn-sandy/agentics/issues/661
glance: Today the backup repo can only ever hold one Mac's settings - each run mirrors that Mac over the other's, and the second Mac's pushes are rejected and quietly pile up unpushed. When this lands, each Mac backs up to its own branch, both pushes succeed on every run, and restore asks which Mac to restore from, so the second Mac can copy the first without losing its own permission rules - proven by a test that runs two fake machines against one remote with the skill's own commands.
---

# Plan: Give every machine its own branch in the settings backup repo

## Objective

Make `settings-sync` back up each machine to its own `machines/<name>` branch
of one shared repository, so two or more machines never overwrite or block
each other, and let `settings-restore` choose which machine to restore from
while keeping the restoring machine's own permission rules.

## Context

Backing up two Macs into one repo (`github.com/shawn-sandy/claude-settings-backup`)
leaves the repo holding only one of them. Inspecting the real clone at
`~/.claude-settings-backup` (5,018 commits) showed two defects, both by design
rather than by accident:

1. **Each backup overwrites the other machine's.** Step 5 of
   `settings-backup` mirrors `~/.claude/` into the repo root with
   `rsync --delete`, so every run makes the repo an exact copy of one
   machine. The two machines genuinely differ: at the 09-14 handoff commit
   `879c721`, `settings.json` swapped every `/Users/shawnsandy/devbox/...`
   permission for `/Users/shawns-work/repos/...` and dropped the other
   machine's entries.
2. **The second machine stalls for good.** The backup never pulls. A machine
   whose clone is behind commits on a stale base, the push is rejected as
   non-fast-forward, and Step 6 says to stop without resolving. A scheduled
   routine then commits locally on every run and never pushes again. No commit
   from `shawns-MacBook-Pro.local` has reached the remote since 09-14 (assumed
   to be stranded on that machine; not verified, since it is not reachable
   from here).

A third fact rules out keying anything on the live hostname: this Mac's
ComputerName is `Shawn's MacBook Pro (2)` because macOS renamed it over a
name clash with the other Mac.

Keeping the two Macs in step is part of the goal too. The user changes
settings mostly on one Mac and will restore that Mac's branch on the other.
Restore copies `settings.json` whole today, which would replace the
secondary Mac's permission rules with ones naming the primary's home
directory (`/Users/shawnsandy/...` against `/Users/shawns-work/...`). Comparing
the two Macs' last backups, only `permissions` and `autoMode` hold
machine-specific paths; every other key, hooks included, is portable or
simple drift, so restore keeps exactly those two keys from the machine it
restores onto.

Options weighed:

| Option | Stops overwrites | Stops stalled pushes | Why not |
|---|---|---|---|
| `git pull --rebase` before push | No | Partly | The last machine to run still wins, and concurrent `settings.json` edits conflict and stop the routine |
| Shared layer plus per-machine overrides, merged | Yes | Yes | Needs a JSON merge of permission arrays; settings legitimately differ per machine (absolute home paths), so a merge is wrong as often as right |
| One repo per machine | Yes | Yes | The user wants one repository |
| `machines/<name>/` folders on one branch | Yes | Mostly | Still needs pull-and-rebase on every run, and the stranded 1.2 commits (which touch root paths) conflict when rebased onto the new layout |
| **One branch per machine, `machines/<name>`** | **Yes** | **Yes** | Chosen: one writer per branch, so a push never conflicts and no merge logic exists |

Risks and mitigations:

- **Two machines picking the same name** recreates the bug on one branch.
  The name is frozen in `settings-sync.json` after its first derivation, and
  a rejected push on a machine's own branch is reported as exactly this
  collision instead of being merged away.
- **Mixed versions during rollout.** A 1.2 machine keeps writing `master`; a
  1.3.0 machine never touches `master` again. Nothing is lost, but each machine
  must update the plugin before its backups land on a machine branch — the
  CHANGELOG upgrade note says so.
- **A dirty working tree blocks the branch switch** (a run interrupted after
  the copy). The switch failing stops the run with git's message rather than
  discarding files someone may have added by hand.

## Decisions

- One branch per machine, named `machines/<name>` — git's own isolation, so each branch has exactly one writer and the backup needs no pull, rebase, or merge.
- The machine name lives in `~/.claude/settings-sync.json` as `"machine"`, derived once from `hostname -s` and then frozen — the live hostname drifts on macOS name clashes, as this Mac's `(2)` suffix shows.
- The name must match `^[a-z0-9][a-z0-9-]{0,62}$` — it comes from a hand-editable file and lands in a git ref and shell commands, so it is validated before any git command runs.
- The backup never pulls, fast-forwards, or rebases its own branch — on a single-writer branch, a remote that is ahead means a second writer, and merging it would hide the collision and restart the flip-flop.
- The push runs on every run that has a remote, not only after a commit — a machine's first 1.3.0 run is often a no-change run, and its branch (carrying any stranded 1.2 commits) still has to reach `origin`; `git push` is a no-op when nothing is ahead.
- A machine's branch is created from whatever the clone has checked out — on a restored machine that is the source machine's branch, so history starts there instead of from nothing.
- `master` stays as frozen legacy history; nothing deletes or rewrites it. Restore falls back to the checked-out branch when no `machines/*` branch exists, so 1.2 repos restore unchanged.
- When `machines/*` branches exist, restore offers only those, never the frozen `master` — it holds whichever machine last pushed under 1.2, which is the overwritten state this fix exists to escape; plain git still reaches it.
- A derived machine name is saved silently and shown on the report's `Machine:` line, never asked for — routines cannot answer a prompt, and one path for both keeps the behaviour the same; renaming is an edit to `settings-sync.json`.
- A rejected push on a machine's own branch stops the run; it never auto-renames — a silent suffix would leave the other machine's restore pointing at a branch that stopped updating.
- A clone backs up only to a branch it created, recorded in its own `git config settings-sync.branch` (added during implementation) — review showed that adopting an existing `origin/machines/<name>` let a fresh clone, or a restore followed by a backup under the same derived name, fast-forward onto another machine's history without any rejection; a re-cloned repo on the same machine claims its branch once with the command the stop message prints.
- The copy block removes a target folder this machine does not have, as it already did for single files, and `settings.local.json` when this machine has not opted in (added during implementation) — a machine branch starts from another branch's tree and would otherwise keep that branch's `commands/`, `agents/`, or opt-in file.
- The copy block loops over literal word lists (added during implementation) — the Bash tool is zsh on macOS, where `for f in $files` does not split, so the block silently copied nothing; the two-machine test runs the blocks under zsh to hold this.
- A push rejected because the owning machine's branch was edited elsewhere is recovered by the user realigning that clone once, with the command the rejection prints (added during implementation) — the backup itself still never pulls, rebases, or force-pushes.
- Restore never writes `"machine"`, and `settings-sync.json` stays out of the backup — either would hand a new machine the source machine's branch name.
- Two Macs stay in step by restore, not by a two-way sync — the user changes settings mostly on one Mac and restores its branch on the other, so restore's one-way copy is enough and no merge of two machines' edits is needed.
- Restore keeps this machine's `permissions` and `autoMode` and takes every other `settings.json` key from the backup — of the 24 keys in the two Macs' last backups, only these two hold machine-specific home paths (hooks use `$HOME`; every other difference is drift). The cost is deliberate: permission rules, deny rules included, never travel by restore once a machine has its own `settings.json`.
- A key this machine lacks is dropped from the restored file rather than taken from the backup — keeping this machine's own settings includes keeping their absence, so the primary Mac's auto-mode text, which names its own repo paths, never lands on the secondary.
- A machine with no `settings.json` gets the backup's file unchanged — a new machine has nothing of its own to keep, and this keeps the bootstrap restore exactly as before.
- The merge runs through `jq` (shipped at `/usr/bin/jq` on macOS 15 and later, and already used by the user's hooks) — `sed` cannot edit JSON safely, and `python3` on a fresh Mac is a Command Line Tools install prompt. A missing `jq` or invalid JSON stops the `settings.json` entry instead of falling back to a wholesale copy that would silently drop this machine's rules.
- Version 1.3.0, a minor bump, chosen by the user — 1.2 repos still restore unchanged, so it ships as a new capability; mixed 1.2 and 1.3.0 machines lose nothing but write to different branches, which the CHANGELOG upgrade note spells out.
- Red-green-verify inside each lane — the existing settings tests already extract the skill's bash blocks by their bold marker and run them, so the new behaviour gets marked blocks and a runner exists.
- Until the new marked blocks exist, the two-machine test pushes with `git -C <repo> push`, the command Step 6's prose names today — so RED reproduces the real rejection instead of failing on a missing block.

## Files

- kit/plugins/settings-sync/skills/settings-backup/SKILL.md (modified) — resolve the machine name, switch to its branch, push it on every run
- kit/plugins/settings-sync/skills/settings-restore/SKILL.md (modified) — list machine branches, ask which to restore, check it out, keep this machine's permissions and autoMode
- tests/plugins/test-settings-backup-two-machines.sh (new) — two fake machines, one remote, the skill's own blocks
- tests/plugins/test-settings-backup-machine-name.sh (new) — name derivation and validation
- tests/plugins/test-settings-restore-machine-branch.sh (new) — machine listing and checkout, plus the 1.2 fallback
- tests/plugins/test-settings-restore-keep-permissions.sh (new) — the settings.json merge that keeps this machine's permissions and autoMode
- kit/plugins/settings-sync/references/file-manifest.md (modified) — list settings-sync.json as excluded, with the reason
- kit/plugins/settings-sync/README.md (modified) — the machine key, the branch layout, upgrading from 1.2
- docs/guides/how-to/settings-sync.md (modified) — the same, in the how-to's shape
- kit/plugins/settings-sync/CHANGELOG.md (modified) — v1.3.0 entry with the upgrade note
- .claude-plugin/marketplace.json (modified) — settings-sync 1.2.0 to 1.3.0

## Steps

### Lane: backup (owns: kit/plugins/settings-sync/skills/settings-backup/**, tests/plugins/test-settings-backup-two-machines.sh, tests/plugins/test-settings-backup-machine-name.sh)

### Phase: RED

1. [x] Write `tests/plugins/test-settings-backup-two-machines.sh`: a bare `origin` seeded with one `master` commit, two fake homes `alpha` and `beta` (each with its own `settings.json`, a shared `rules/r.md`, and a skill only that machine has), both cloned before either runs, each with `"machine"` set in its `settings-sync.json`; give beta's clone one unpushed 1.2 commit on `master` (the ignore-rules, copy, and commit blocks run without a push) so its first 1.3.0 run has nothing new to commit; then run the skill's marked blocks in skill order for alpha, then beta, then alpha again after a `settings.json` edit, then a third clone that reuses `alpha`. Why: it reproduces the reported failure with the skill's own commands, and the same file later proves the fix. Verify: `bash tests/plugins/test-settings-backup-two-machines.sh` exits non-zero with beta's push rejected as non-fast-forward and no `machines/*` branch on origin — paste the output.
2. [x] Write `tests/plugins/test-settings-backup-machine-name.sh` around the `**Resolve the machine name.**` block: with no `machine` key and a shimmed `hostname` printing `Shawns-MacBook-Pro-2` it prints `shawns-macbook-pro-2`; a stored `"machine": "studio"` wins over the hostname; `../evil`, `-x`, `Has Space`, and an empty value each exit non-zero. Why: the name becomes a git ref and a shell argument, read from a hand-editable file, so its validation is a trust boundary with its own check. Verify: the test exits non-zero reporting no bash block after `**Resolve the machine name.**` — the feature does not exist yet; paste the output.

### Phase: GREEN

3. [x] In Step 1 of `kit/plugins/settings-sync/skills/settings-backup/SKILL.md`, add a `**Resolve the machine name.**` bash block that reads `"machine"` from `~/.claude/settings-sync.json`, otherwise derives it from `hostname -s` (lowercased, each run of characters outside `a-z0-9-` turned into one `-`, leading and trailing `-` trimmed), rejects anything not matching `^[a-z0-9][a-z0-9-]{0,62}$`, and prints the name; persist a derived name beside `repoPath` under the existing preserve-other-keys rule. Why: the hostname is not stable on macOS, so the name is derived once and frozen. Verify: `bash tests/plugins/test-settings-backup-machine-name.sh` prints PASS.
4. [x] In Step 2 of the same file, add a `**Switch to the machine branch.**` bash block after the repo check and before the ignore-rules block: fetch `origin` when one exists (an offline fetch is not an error), do nothing when `HEAD` is already `machines/<machine-name>`, switch to that branch when it exists locally or on `origin`, otherwise create it from the current `HEAD`, and stop with git's message if the switch fails. Why: every later block then writes only to this machine's branch, and creating it from `HEAD` carries any commits a rejected 1.2 push left stranded. Verify: the two-machine test's checks for separate `machines/alpha` and `machines/beta` histories pass.
5. [x] Replace Step 6's prose push with a `**Push the machine branch.**` bash block that runs after both `committed` and `no-change` whenever `origin` exists — `git push -u origin machines/<machine-name>` — and turns a rejection into a STOP saying another clone or machine writes to the same branch and to set a distinct `"machine"` in `~/.claude/settings-sync.json`; add `Machine:` and `Branch:` lines to the Step 7 report. Why: a first 1.3.0 run is often a no-change run whose branch still has to reach `origin`, and a rejected push on a single-writer branch can only mean a name collision. Verify: every check in `bash tests/plugins/test-settings-backup-two-machines.sh` passes, including the third clone being rejected without moving `origin/machines/alpha`.
6. [x] Re-run both new tests plus `test-settings-backup-e2e.sh`, `test-settings-backup-no-change-commit.sh`, and `test-settings-backup-stale-entries.sh` after every edit in steps 3 to 5; if any still fails after 8 iterations, stop and report the failing assertion, the last diff tried, and what was ruled out — do not report success. Why: the existing tests pin the ignore-rule, copy, and no-change-commit behaviour the new blocks must not disturb. Verify: all five exit 0.

### Phase: VERIFY

7. [x] Run every settings-backup test and the manifest-targets test in one loop. Why: the lane has to prove itself on its own branch before anything merges. Verify: `for t in tests/plugins/test-settings-backup-*.sh tests/plugins/test-settings-sync-manifest-targets.sh; do bash "$t" || exit 1; done` exits 0.

### Lane: restore (owns: kit/plugins/settings-sync/skills/settings-restore/**, tests/plugins/test-settings-restore-machine-branch.sh, tests/plugins/test-settings-restore-keep-permissions.sh)

### Phase: RED

8. [x] Write `tests/plugins/test-settings-restore-machine-branch.sh`: build a bare `origin` with plain git holding a legacy `master` plus `machines/alpha` and `machines/beta` with different `settings.json`, clone it, and run the `**List machine branches.**` and `**Check out the chosen machine.**` blocks from the restore skill; assert the list is exactly `beta` then `alpha` (newest first, `master` absent), choosing `beta` leaves `HEAD` on `machines/beta` with beta's `settings.json` in the tree, `../x` exits non-zero with `HEAD` unchanged, and a 1.2 repo with no `machines/*` branch lists nothing. Why: restore is interactive and cannot run whole in a test, so its deterministic parts move into marked blocks this test executes. Verify: the test exits non-zero reporting no bash block after `**List machine branches.**` — paste the output.
9. [x] Write `tests/plugins/test-settings-restore-keep-permissions.sh` around the `**Keep this machine's permissions.**` block, with a fake home and a backup `settings.json`: when the local file has its own `permissions` and `autoMode`, the output takes every other key from the backup (a different `theme`, a different `enabledPlugins`) and this machine's `permissions` and `autoMode` in place of the backup's; a key the local file lacks is absent from the output; with no local `settings.json` the output is the backup file byte for byte; invalid JSON in either file exits non-zero and leaves the local file unchanged; and running the block again over its own result changes nothing. Why: the user restores the secondary Mac from the primary Mac's branch, and today's wholesale copy would replace the secondary's allow rules with ones naming another user's home directory. Verify: the test exits non-zero reporting no bash block after `**Keep this machine's permissions.**` — paste the output.

### Phase: GREEN

10. [x] In Step 2 of `kit/plugins/settings-sync/skills/settings-restore/SKILL.md`, fetch, run a `**List machine branches.**` block (names from `refs/remotes/origin/machines/*` and `refs/heads/machines/*`, newest commit first) and, when it prints any, ask with `AskUserQuestion` which machine to restore — recommending this machine's own `machine` name when `settings-sync.json` has one and it is listed, else the newest, up to four options with Other covering the rest — then run `**Check out the chosen machine.**` (validate the name with the backup's pattern, `git switch` to `machines/<name>`, `git pull --ff-only`); with no machine branches, keep today's pull of the checked-out branch. Why: backups now live one branch per machine, and a 1.2 repo must still restore. Verify: `bash tests/plugins/test-settings-restore-machine-branch.sh` prints PASS.
11. [x] Name the chosen branch in the Step 4 preview header and the Step 9 report, and state in Step 8 that restore never writes `"machine"` to `settings-sync.json`. Why: a new machine that inherited the source machine's name would push to that machine's branch, and the preview must say whose settings are about to land. Verify: Step 8 of the restore SKILL.md carries the never-writes rule, and the Step 4 and Step 9 templates both show a `Machine:` line.
12. [x] In Step 6 of the same file, add a `**Keep this machine's permissions.**` bash block that prints the backup's `settings.json` with `permissions` and `autoMode` taken from this machine's `~/.claude/settings.json` (and dropped where this machine has none) through `jq --slurpfile`, prints the backup file unchanged when this machine has no `settings.json`, and exits non-zero on invalid JSON in either file or a missing `jq`; restore `settings.json` by writing that output to a temp file and moving it into place instead of copying the file; classify `settings.json` in the Step 4 preview against that output, and in Step 7 verify it by re-running the block and comparing the result with the restored file. Re-run both restore tests after every edit in steps 10 to 12; if either still fails after 8 iterations, stop and report the failing assertion, the last diff tried, and what was ruled out — do not report success. Why: everything changed on the primary Mac still arrives, while the rules and auto-mode text that name this machine's home directory stay put; the preview and the verify step must compare against the merged file, or every restore shows `settings.json` as modified and then FAILED. Verify: `bash tests/plugins/test-settings-restore-keep-permissions.sh` prints PASS.

### Phase: VERIFY

13. [x] Run every restore test. Why: the lane has to prove itself on its own branch before anything merges. Verify: `bash tests/plugins/test-settings-restore-machine-branch.sh && bash tests/plugins/test-settings-restore-keep-permissions.sh && bash tests/plugins/test-settings-restore-exec-bits.sh` exits 0.

### Lane: lead (after: backup, restore)

14. [x] Add `~/.claude/settings-sync.json` to the Excluded list in `kit/plugins/settings-sync/references/file-manifest.md` with its reason, and document the `machine` key, the `machines/<name>` layout, restore's machine choice, restore keeping this machine's `permissions` and `autoMode` (and needing `jq`), the one-primary-Mac way to keep two Macs in step, and upgrading from 1.2 in `kit/plugins/settings-sync/README.md` and `docs/guides/how-to/settings-sync.md` — including that a first backup on a new machine now creates its own branch and can no longer overwrite another machine's. Why: if the config file were ever backed up, every machine restored from it would share one branch name and collide again, and the sync workflow only works if users know restore keeps their permissions. Verify: both docs mention `machines/`, the `machine` key, and that restore keeps this machine's `permissions` and `autoMode`, and the manifest's Excluded list names `settings-sync.json`.
15. [x] Set `settings-sync` to `1.3.0` in `.claude-plugin/marketplace.json` and add a `v1.3.0` entry to `kit/plugins/settings-sync/CHANGELOG.md` with an upgrade note: update the plugin on every machine, each machine's first run creates and pushes its own branch, and `master` stays as frozen history. Why: the CI guard fails a plugin change without a version bump, and machines still on 1.2 keep writing `master`, which the upgrade note has to say. Verify: `git fetch origin && BASE_REF=main node scripts/check-plugin-versions.mjs` exits 0.
16. [x] Run the full suite and the repo's merge gate. Why: the two lanes' blocks and docs have to hold together on one branch. Verify: `bash tests/run-all.sh` and `bash scripts/verify.sh` both exit 0.
17. [x] Dry-run the new backup on real history without touching GitHub: `git clone --bare ~/.claude-settings-backup <scratch>/origin.git`, clone that to `<scratch>/clone`, and run the backup's marked blocks with `<repo-path>` set to the scratch clone and `<machine-name>` set to `shawns-macbook-pro-2`. Why: proves the upgrade path against 5,018 real commits, the stray `plans/` and `vscode/` entries, and the unpushed `9818fb8`, not just a fixture. Verify: `git -C <scratch>/origin.git merge-base --is-ancestor 9818fb8 machines/shawns-macbook-pro-2` exits 0 and `git -C ~/.claude-settings-backup status -sb` is unchanged from before the run.

## Tests

Tier 1 — This plan changes application code
- Objective: two machines back up into one repository without overwriting or blocking each other. File: tests/plugins/test-settings-backup-two-machines.sh; Type: smoke; Asserts: alpha's and beta's runs both push, origin holds `machines/alpha` and `machines/beta`, each branch carries only its own machine's `settings.json` and machine-only skill, beta's no-change first run still pushes and its stranded 1.2 commit is an ancestor of `origin/machines/beta`, alpha's second run fast-forwards its branch, and a third clone reusing `alpha` is rejected without moving `origin/machines/alpha`; Run: bash tests/plugins/test-settings-backup-two-machines.sh
- Unit: machine-name resolution and validation. File: tests/plugins/test-settings-backup-machine-name.sh; Targets: the `**Resolve the machine name.**` block; Key cases: hostname slug, stored name wins over hostname, `../evil`, `-x`, `Has Space`, empty value
- Unit: restore keeps this machine's permissions. File: tests/plugins/test-settings-restore-keep-permissions.sh; Targets: the `**Keep this machine's permissions.**` block; Key cases: local `permissions` and `autoMode` replace the backup's while every other key comes from the backup, a key missing locally is dropped, no local file yields the backup unchanged, invalid JSON on either side exits non-zero with the local file untouched, a second run is a no-op
- Integration: restore lists machines and checks out the chosen one. File: tests/plugins/test-settings-restore-machine-branch.sh; Targets: the `**List machine branches.**` and `**Check out the chosen machine.**` blocks; Key cases: newest-first listing, legacy `master` excluded, chosen branch checked out, invalid name rejected with `HEAD` unchanged, 1.2 repo lists nothing

## Acceptance Criteria

- [ ] Two machines backing up in alternation to one remote both push successfully on every run.
- [ ] After both machines back up, each machine's `settings.json` and machine-only skills exist on its own `machines/<name>` branch and on no other branch.
- [ ] A machine whose 1.2 clone holds unpushed commits pushes them on its first 1.3.0 run, even when nothing changed.
- [x] A second clone using an existing machine name is stopped with a message naming the `machine` key, and that branch on origin does not move.
- [x] A `machine` value outside `^[a-z0-9][a-z0-9-]{0,62}$` stops the backup before any git command runs.
- [x] Restore lists the machines that have backed up and checks out the chosen machine's branch; a repo with no `machines/*` branch restores exactly as 1.2 did.
- [x] Restore never adds a `machine` key to `~/.claude/settings-sync.json`.
- [x] Restoring another machine's branch onto a machine with its own `settings.json` keeps that machine's `permissions` and `autoMode` and takes every other key from the backup; a machine with no `settings.json` gets the backup's file unchanged.
- [x] A restore that kept this machine's `permissions` reports `settings.json` as verified, not FAILED, and invalid JSON in either `settings.json` stops that entry without changing the local file.
- [x] `bash tests/run-all.sh` and `bash scripts/verify.sh` exit 0, and `settings-sync` is `1.3.0` in `.claude-plugin/marketplace.json`.

## Verification

Run `bash tests/plugins/test-settings-backup-two-machines.sh` and expect PASS:
two fake machines alternate backups against one bare remote using the skill's
own extracted commands, both push every time, and each machine's branch holds
only its own settings. Run `bash tests/plugins/test-settings-restore-keep-permissions.sh`
and expect PASS: a restore over a machine with its own `settings.json` keeps
that machine's `permissions` and `autoMode` and takes every other key from the
backup. Then run step 17's dry run and expect `9818fb8` to be
an ancestor of `machines/shawns-macbook-pro-2` on the scratch origin, with the
live clone at `~/.claude-settings-backup` untouched. Finish with
`bash scripts/verify.sh` exiting 0.

After release (outside this plan, by the user): update the plugin on both Macs
and run `settings-backup` on each. `git ls-remote
https://github.com/shawn-sandy/claude-settings-backup 'refs/heads/machines/*'`
should list two branches, a second run on either Mac should report
`Pushed: yes` or nothing to push, and `settings-restore` on either Mac should
offer both machines. Restoring the primary Mac's branch on the secondary Mac
should leave the secondary's `permissions` and `autoMode` as they were, with
`jq '.permissions' ~/.claude/settings.json` printing the same rules before and
after.

## Completion Report

- Released: 1.3.0 — PR #662 squash-merged to `main` as `2f8b101b` with the user's approval (all 8 checks SUCCESS or SKIPPED, `CLEAN`), and `publish-dist.yml` run 40787496765 succeeded after its 12 gates passed locally. The `agentics-kit` marketplace lists settings-sync `1.3.0`, and its two SKILL.md files are byte-identical to the source whose blocks ran on this Mac. CodeRabbit's three minor findings were reported, not fixed (merge approved with them open): prune deleted remote refs in the restore listing fetch; have Step 4 check the Keep block's exit status rather than `diff -q <(…)`; validate the backup's JSON before the no-local-file pass-through (declined by design — that path is byte-for-byte and needs no `jq`).
- Blocked on the user: criteria 1–3 on the other Mac — this Mac's half ran on the real remote with the released skill's blocks: they saved `"machine": "shawns-macbook-pro-2"`, switched `~/.claude-settings-backup` to `machines/shawns-macbook-pro-2`, and a no-change first run pushed it to `github.com/shawn-sandy/claude-settings-backup` (`122ae51`, `master` untouched); later runs read the saved name and reported `pushed`. The other Mac (`shawns-MacBook-Pro.local`) cannot be reached from the implementing session by any route: no saved SSH connection exists, the name does not resolve, Bonjour on the LAN finds only this Mac, Tailscale is not installed, and both of that Mac's Claude Remote Control sessions (`shawns-macbook-pro-local-nested-blanket`, `shawns-macbook-pro-local-elegant-widget`) are offline — so it has to be brought online by the user, and updating the plugin there, its first backup (with its stranded 1.2 commits), and the two-branch check are the user's. Check: `git ls-remote https://github.com/shawn-sandy/claude-settings-backup 'refs/heads/machines/*'` lists two branches, and that Mac's unpushed 1.2 commits are ancestors of its branch.
- Verified locally: criteria 6, 7, and 9 — a fresh agent ran `settings-restore` Steps 0–9 exactly as written against scratch homes (HOME overridden, the user's `~/.claude` untouched): restoring `alpha` onto `beta` kept beta's `permissions` and `autoMode`, took the rest from alpha, and reported `settings.json` verified; on a brand-new machine it restored alpha's file byte for byte, reported verified, and wrote `settings-sync.json` with no `machine` key. Each result was re-checked independently. The after-release restore on the real secondary Mac — offering both machines and leaving `jq '.permissions' ~/.claude/settings.json` unchanged — needs the other Mac's branch first and is the user's to run, since restore is interactive and overwrites `~/.claude`.
- Added during implementation — the per-clone branch claim, dropping folders and an un-opted `settings.local.json` a machine lacks, the zsh-safe copy loops, and the realign recovery for a hand-edited branch, each after a review reproduced the failure; see Decisions.

## Next Steps

- Point the backup repo's GitHub default branch at a machine branch
  `master` freezes at its last 1.2 commit, which is what GitHub shows by default.
  ```text
  In the user's settings backup repo (github.com/shawn-sandy/claude-settings-backup), after both machines have pushed their machines/<name> branches with settings-sync 1.3.0, either set the default branch to one machine branch with `gh repo edit shawn-sandy/claude-settings-backup --default-branch machines/<name>`, or commit a short README to master that lists the machines/* branches and says master is frozen 1.2 history. Ask before changing the default branch. Verify with `gh repo view shawn-sandy/claude-settings-backup --json defaultBranchRef`.
  ```
- Remove the stray `plans/` and `vscode/` entries from the backup branches
  Both are reported under "Not a backup target (left in repo)" and come back on every restore.
  ```text
  On each Mac, in that Mac's own clone of the settings backup repo (~/.claude-settings-backup, on its own machines/<name> branch only), confirm with the user that the root entries plans/ and vscode/ are not wanted, then `git rm -r --cached` and delete them, commit, and push that branch. Never edit another machine's branch from this clone — its owner's next push would be rejected until that machine realigns with the command the rejection prints. Verify that a settings-backup run on that machine no longer lists them under "Not a backup target (left in repo)".
  ```
- Wish list: compare two machines' settings
  A read-only helper over `git diff machines/<a> machines/<b> -- settings.json`.
  ```text
  In the agentics repo, add a read-only "compare machines" mode to kit/plugins/settings-sync that runs `git diff machines/<a> machines/<b>` in the backup repo and summarises which settings, rules, and skills differ. Bump the settings-sync minor version in .claude-plugin/marketplace.json and add a CHANGELOG entry. Verify with a test that builds two machine branches and asserts the summary names the differing file.
  ```

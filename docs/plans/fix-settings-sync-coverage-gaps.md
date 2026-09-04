---
status: completed
type: fix
created: 2026-09-04
modified: 2026-09-04
repo-name: agentics
workflow: never
artifact-url: https://claude.ai/code/artifact/ad0ba977-d51c-4d74-bbed-b87cc5bb1db6
issue: https://github.com/shawn-sandy/agentics/issues/622
glance: A restore from today's settings-sync backup hands you a settings.json, a CLAUDE.md, and a hook set that point at four folders the backup never copied, and the backup repo's history is 97 percent timestamp-only commits. When this lands, a fresh machine gets every folder its restored config names, a no-change run commits nothing, and three shell tests in tests/plugins pin both behaviours so they cannot drift back.
---

# Plan: Make settings-sync back up what a restore actually needs, and stop committing when nothing changed

## Objective

Widen the settings-sync manifest to the four folders that captured files already reference (agents, output-styles, scripts, reference), correct the two wrong exclusion notes, and rework the backup skill so the metadata file is written only after a real change is staged and already-ignored files are untracked, with each behaviour pinned by a test that runs the skill's own snippets.

## Context

The settings-sync plugin (1.1.5) backs up Claude Code user settings to a git repo. A coverage audit on 2026-09-04 compared its file manifest against a real `~/.claude/` and the real backup repo and found three classes of problem. First, four user-authored folders that captured files point at are never copied: `~/.claude/agents/` holds custom subagents, `output-styles/` holds the style that settings.json names, `scripts/` holds the script the SessionEnd hook runs, and `reference/` holds files CLAUDE.md links by path. The manifest's exclusion list even labels `agents/` as task state, which it is not. Second, both the skill and the owner's hand-written daily script write `.settings-sync-meta.json` with a fresh timestamp before asking whether anything changed, so every run commits: 4,477 of the real repo's 4,601 commits change only that file, and `git log` cannot show when a setting changed. The no-change branch in the skill also commits, because it appends a timestamped line to a tracked `.sync-log`. Third, four `.pyc` files are tracked in the real repo because an ignore rule added later never untracks files already in git.

The audit page with the full evidence is linked under Resources. The user-facing risk is a new-machine restore that looks complete and is not: the restored `outputStyle` names a style that does not exist, and the restored SessionEnd hook points at a missing script.

Two findings are deliberately not steps here. The cutover of the audited Mac from its hand script to the skill must happen after 1.2.0 is published and pulled into the plugin cache, and it depends on an unresolved question about where scheduled routines run, so it is the first Next Step. The four open decisions the audit raised (MCP servers, auto-memory, the flattened skill symlinks, and `docs/`) are settled in Decisions below; the two that need code are Next Steps with their own prompts.

The restore skill needs no edit: it restores every entry it finds in the repo root, so the four new folders come back on a new machine for free.

## Decisions

- Structured as red-green-verify because the repo's existing settings-sync tests already extract bash blocks from SKILL.md by marker and run them against fixture repos, so a failing test exists before any edit and the behaviours are real, not grep theatre.
- Version goes 1.1.5 to 1.2.0 (minor), not a patch: the backup set grows, so a 1.2.0 backup carries folders a 1.1.x backup never had, and CHANGELOG readers should see that as a feature line.
- `.settings-sync-meta.json` is written only inside the real-change branch, after `git add -A` and `git diff --cached --quiet` say something is staged. The alternative, excluding the file from the change check but still writing it, leaves it perpetually dirty in git.
- `.sync-log` becomes a local, gitignored audit trail. Committing a timestamped no-change line is itself a commit per run, which is the bug. Repos created before this change get the file untracked by the new Step 2 snippet on the next run.
- Untracking uses `git ls-files -ci --exclude-standard`, which lists every tracked file the current ignore rules cover, so one line handles `__pycache__/`, `.sync-log`, and any rule added later. Working files are not deleted; only the index entry goes.
- The restore skill is not edited. It reads the repo root, not a fixed list, so new targets restore without a change there. Its verification step already covers the four folders as directory entries.
- `docs/` stays excluded and is now listed in the manifest with its reason: it is user content, not configuration, and the plans directory is project-scoped by `plansDirectory`, so a global `docs/plans` is an edge case.
- Symlinked skills keep being flattened by `-L`. A flattened copy is still a working skill after restore; the loss is only that the skills CLI can no longer update it. The manifest's Copy behavior section says so, and preserving symlinks is a Next Step.
- Auto-memory under `~/.claude/projects/*/memory/` is not backed up in this plan. The manifest note is corrected to say where it lives and that it is excluded. An opt-in copy of non-empty memory folders, with the absolute-path-slug caveat, is a Next Step.
- MCP servers in `~/.claude.json` are not backed up in this plan. The file is mostly cache plus the OAuth record and cannot be copied whole. An export-only design for the `mcpServers` block is a Next Step.
- The SessionEnd hook on the audited Mac stays in place until a routine-driven backup has produced one real commit. Removing it first would leave a window with no backup at all.

## Files

- kit/plugins/settings-sync/references/file-manifest.md (modified) — four new default targets, corrected exclusion notes, symlink note in Copy behavior
- kit/plugins/settings-sync/skills/settings-backup/SKILL.md (modified) — Step 2 gains the untrack snippet and the `.sync-log` ignore rule, Step 3 and Step 5 name the four folders, Steps 6 and 7 collapse into one commit-only-on-change snippet
- kit/plugins/settings-sync/README.md (modified) — four rows in the What gets backed up table, the no-change wording in Components
- kit/plugins/settings-sync/CHANGELOG.md (modified) — 1.2.0 entry
- .claude-plugin/marketplace.json (modified) — settings-sync version 1.1.5 to 1.2.0
- tests/plugins/test-settings-backup-e2e.sh (new) — the objective test: a fake home backed up twice into a scratch repo
- tests/plugins/test-settings-sync-manifest-targets.sh (new) — pins the four copies of the target list to each other
- tests/plugins/test-settings-backup-no-change-commit.sh (new) — the commit snippet alone, both branches

## Steps

### Phase: RED

1. [x] Write tests/plugins/test-settings-backup-e2e.sh: build a throwaway home under `$TMP/home/.claude` holding settings.json, CLAUDE.md, rules/, commands/, skills/, hooks/, agents/a.md, output-styles/s.md, scripts/x.sh, scripts/__pycache__/x.pyc, and reference/r.md; `git init` a scratch repo with one commit that already tracks a `.pyc` and a `.sync-log`; then, with `HOME` pointed at the fake home, extract from SKILL.md and run in order the bash blocks after the markers `**Ignore rules and already-tracked files.**`, `**Copy the targets.**`, and `**Commit only real changes.**`, substituting `<repo-path>`; assert the repo root now lists agents, output-styles, scripts, and reference, `git ls-files` contains no `.pyc` and no `.sync-log`, and `git rev-list --count HEAD` is 2; run the copy and commit blocks a second time with nothing changed and assert the count is still 2 and `.sync-log` has exactly one line. Why: this is the one test that fails if either half of the objective breaks, and it exercises the skill's real commands rather than a paraphrase of them, following the pattern in test-settings-backup-stale-entries.sh. Verify: `bash tests/plugins/test-settings-backup-e2e.sh` exits 1 and prints `FAIL: no bash block after '**Ignore rules and already-tracked files.**'`, red because the marker does not exist yet, not because the fixture failed to build.
2. [x] Write tests/plugins/test-settings-sync-manifest-targets.sh: assert file-manifest.md's Default targets table has a row for each of `~/.claude/agents/`, `~/.claude/output-styles/`, `~/.claude/scripts/`, and `~/.claude/reference/`; assert its Excluded list has no line naming `agents/` and no line containing `lives with each project`; assert SKILL.md names all four folders in the Step 3 list, in the `**Copy the targets.**` block, and in the `case` list of the stray-entries snippet; print one `FAIL <label>` line per miss. Why: the manifest, the copy block, and the stray detector are three copies of one list, and the audit found the manifest and the daily script had already drifted apart; this keeps the copies inside the plugin pinned together. Verify: the test exits 1 and its first line is `FAIL default target row: agents/`.
3. [x] Write tests/plugins/test-settings-backup-no-change-commit.sh: build a scratch repo with one commit containing settings.json and an old `.settings-sync-meta.json` whose timestamp is `2026-01-01T00:00:00Z`, with `.sync-log` in `.gitignore`; extract the `**Commit only real changes.**` block, run it once, and assert the commit count is unchanged, `.sync-log` gained one line, `git status --porcelain` is empty, and the meta timestamp is still the old one; append a line to settings.json, run again, and assert the count rose by one and the meta timestamp changed. Why: the metadata timestamp written before the change check is the direct cause of 4,477 noise commits, and the meta-only assertion here is what the e2e test cannot isolate. Verify: exits 1 with `FAIL: no bash block after '**Commit only real changes.**'`.

### Phase: GREEN

4. [x] Edit kit/plugins/settings-sync/references/file-manifest.md: add four Default targets rows (`agents/` user-defined subagents, `output-styles/` custom styles named by settings.json `outputStyle`, `scripts/` scripts referenced by settings.json hooks and statusLine, `reference/` files linked from CLAUDE.md and hooks); remove `agents/` from the task-state exclusion line; replace the `projects/` note with `auto-memory lives here, not in the project repo; excluded for now, see Next Steps`; add `docs/`, `GITHUB_COMMANDS.md`, and `.claude/launch.json` to Excluded with one-clause reasons; add a Copy behavior bullet stating that symlinked skill folders are copied as real folders and the skills CLI must re-link them on a new machine. Why: the manifest is what both skills cite, and its wrong notes are how the four folders were excluded for so long without anyone questioning it. Verify: `bash tests/plugins/test-settings-sync-manifest-targets.sh` no longer prints any `FAIL default target row` or `FAIL exclusion note` line; the SKILL.md assertions still fail.
5. [x] Edit kit/plugins/settings-sync/skills/settings-backup/SKILL.md Steps 3 and 5: add the four folders to the Step 3 always-included list; replace Step 5's separate rsync and cp blocks with one bash block under the marker `**Copy the targets.**` that detects rsync, copies the three single files and the eight directories with the existing `-aL` and `--delete` semantics or the cp fallback, quotes every path, and removes single-file targets from the repo when they no longer exist locally; add the four names to the `case` list in the stray-entries snippet. Why: one block under one marker is what makes the copy step testable, and the stray detector must learn the new names or it will report every new target as a stray on the first run. Verify: `bash tests/plugins/test-settings-sync-manifest-targets.sh` exits 0 and `bash tests/plugins/test-settings-backup-stale-entries.sh` still exits 0.
6. [x] Edit SKILL.md Step 2: add `.sync-log` to the ignore-rule list, then add a paragraph headed `**Ignore rules and already-tracked files.**` with one bash block that runs `git -C "<repo-path>" ls-files -ci --exclude-standard -z` and, when the output is non-empty, pipes it to `xargs -0 git -C "<repo-path>" rm --cached --quiet --`, with a sentence explaining that an ignore rule never untracks a file already in git. Why: this is the fix for the four tracked `.pyc` files in the real repo and for every repo created before `.sync-log` was ignored, and it runs once per backup at negligible cost. Verify: `bash tests/plugins/test-settings-backup-e2e.sh` gets past the Step 2 marker and fails on `**Copy the targets.**` if step 5 is not yet merged, or on `**Commit only real changes.**` otherwise.
7. [x] Rewrite SKILL.md Steps 6 and 7 into a single Step 6 headed `**Commit only real changes.**` whose bash block runs `git add -A`, tests `git diff --cached --quiet`, and on no change appends the timestamped no-change line to `.sync-log` and prints `no-change`, or on change writes `.settings-sync-meta.json` with hostname, UTC timestamp, `claude --version`, and the filesIncluded list, stages it, commits with the existing message format, and prints `committed`; keep the push and push-failure text as the following paragraph, run only after a commit; renumber the report step and change its no-change line to `No settings changes since last backup. Logged locally to .sync-log (not committed).`. Why: writing the timestamp after the change check is the whole fix for the noise commits, and keeping `.sync-log` out of git is what stops the no-change branch from being a commit too. Verify: `bash tests/plugins/test-settings-backup-no-change-commit.sh` exits 0 and `bash tests/plugins/test-settings-backup-e2e.sh` exits 0.
8. [x] Update kit/plugins/settings-sync/README.md (four rows in the What gets backed up table; the Components paragraph now says no-change runs are logged locally and never committed), add a 1.2.0 entry to kit/plugins/settings-sync/CHANGELOG.md covering the four targets, the corrected notes, the commit-only-on-change block, and the untrack snippet, and bump settings-sync in .claude-plugin/marketplace.json from 1.1.5 to 1.2.0. Why: the README is what an installer reads, the changelog is where the behaviour change is announced, and the CI version guard fails the PR without the bump. Verify: `git fetch origin && BASE_REF=main node scripts/check-plugin-versions.mjs` exits 0 and `grep -c 'output-styles' kit/plugins/settings-sync/README.md` prints at least 1.
9. [x] Re-run the three RED tests together with `for t in tests/plugins/test-settings-backup-e2e.sh tests/plugins/test-settings-sync-manifest-targets.sh tests/plugins/test-settings-backup-no-change-commit.sh; do bash "$t" || echo "STILL RED: $t"; done`; if any is still red after 8 GREEN iterations, stop and report the failing assertion, the last diff tried, and what was ruled out, and do not report success. Why: the cap is what keeps an implementing agent from looping forever on a snippet that will not extract cleanly. Verify: the loop prints no `STILL RED` line and each test ends with `PASS`.

### Phase: VERIFY

10. [x] Run `bash tests/run-all.sh` from the repo root. Why: the runner auto-discovers `test-*.sh`, so the three new files run alongside test-exitplanmode-guard.sh and test-verification-gate-rule.sh, which grep the restructured SKILL.md for lines that must survive the rewrite. Verify: exits 0 and the summary names all three new test files with no skip.
11. [x] Run `bash scripts/verify.sh` from the repo root. Why: it is the merge gate named in CLAUDE.md, and a merge may not be proposed until it exits 0 on this machine. Verify: exits 0, and the stage table shows the unit stage as a real result rather than `SKIP (not configured)`; paste the table into the completion notes.
12. [x] Dry-run the edited skill against the real `~/.claude/` as the source and a scratch repo as the target, never the real backup repo: `git init "$SCRATCH/repo"`, then extract and run the Step 2, `**Copy the targets.**`, and `**Commit only real changes.**` blocks with `<repo-path>` substituted, twice. Why: the tests use a fake home; this walks the change with the owner's real folders, including the real `scripts/__pycache__`, which is the exact input that produced the tracked `.pyc` files. Verify: `ls "$SCRATCH/repo"` lists agents, output-styles, scripts, and reference; `git -C "$SCRATCH/repo" rev-list --count HEAD` prints 1 after the second run; `git -C "$SCRATCH/repo" ls-files | grep -c '\.pyc$'` prints 0; and `git -C ~/claude-settings-backup status --porcelain` is unchanged from before the dry run.

## Tests

Tier 1 — This plan changes application code
- Objective: a backup from a home holding agents/, output-styles/, scripts/, and reference/ lands all four in the repo, untracks already-ignored files, and a second unchanged run commits nothing. File: tests/plugins/test-settings-backup-e2e.sh; Type: smoke; Asserts: the four folders exist in the scratch repo root, `git ls-files` has no `.pyc` and no `.sync-log`, the commit count is 2 after run one and still 2 after run two, `.sync-log` has one line; Run: bash tests/plugins/test-settings-backup-e2e.sh
- Unit: the four copies of the target list agree. File: tests/plugins/test-settings-sync-manifest-targets.sh; Targets: file-manifest.md Default targets and Excluded, SKILL.md Step 3 list, the Copy the targets block, the stray-entries `case` list; Key cases: each of the four folders present in every copy, `agents/` absent from the task-state line, `lives with each project` absent
- Unit: the commit block writes metadata only on real change. File: tests/plugins/test-settings-backup-no-change-commit.sh; Targets: the `**Commit only real changes.**` bash block; Key cases: no change leaves the commit count and meta timestamp untouched and appends one `.sync-log` line with a clean `git status`, a changed settings.json adds one commit and refreshes the timestamp

## Acceptance Criteria

- [x] `bash tests/plugins/test-settings-backup-e2e.sh` exits 0, proving a backup captures agents/, output-styles/, scripts/, and reference/ and that a second unchanged run adds no commit.
- [x] `bash tests/plugins/test-settings-backup-no-change-commit.sh` exits 0, proving `.settings-sync-meta.json` is rewritten only when something else is staged.
- [x] A `.pyc` and a `.sync-log` already tracked in a fixture repo are untracked by the Step 2 block, and both working files still exist afterward.
- [x] `grep -n 'agents/' kit/plugins/settings-sync/references/file-manifest.md` matches only inside the Default targets table, and `grep -c 'lives with each project'` on the same file prints 0.
- [x] `bash tests/run-all.sh` and `bash scripts/verify.sh` both exit 0 on this machine.
- [x] `.claude-plugin/marketplace.json` lists settings-sync at 1.2.0 and CHANGELOG.md has a 1.2.0 entry dated 2026-09-04.
- [x] `git diff --stat main -- kit/plugins/settings-sync/skills/settings-restore/` is empty; restore was not edited.
- [x] The real backup repo at `~/claude-settings-backup` has no new commits from this plan's work.

## Verification

Run the two gates from the repo root and read their output rather than their exit codes: `bash tests/run-all.sh` must list the three new settings-sync tests as passed alongside the two existing ones, and `bash scripts/verify.sh` must show a real unit-stage result. Then do the Step 12 dry run with the real `~/.claude/` as source and a scratch repo as target, running the three extracted blocks twice. The end state that proves the objective: the scratch repo root contains agents, output-styles, scripts, and reference next to the seven existing targets; `git log --oneline` shows exactly one commit after two runs; `git ls-files` contains no `.pyc` and no `.sync-log`; `.sync-log` on disk has one line; and the real backup repo's `git status` and `git log -1` are byte-for-byte what they were before the run.

## Next Steps

- Cut the audited Mac over from the hand script to the skill
  Sequenced after 1.2.0 is published and pulled into `~/.claude/plugins/cache`. Keeps the SessionEnd hook until the routine has produced one real commit, and depends on the routine-locality question below.
  ```text
  On this Mac, settings-sync 1.2.0 is now installed from the agentics-kit marketplace. Retire the hand-written backup at ~/.claude/scripts/settings-backup.sh in favor of the plugin's settings-backup skill, in this order and without skipping the checks. 1) Confirm that a scheduled routine created with /schedule runs on this machine with access to ~/.claude, not in the cloud; if it runs in the cloud, stop and report, because the SessionEnd hook must then stay and the fix is to regenerate its script from kit/plugins/settings-sync/references/file-manifest.md instead. 2) Run the settings-backup skill once by hand against ~/claude-settings-backup and confirm the commit it makes adds agents/, output-styles/, scripts/, and reference/ and that git ls-files no longer lists any .pyc or .sync-log. 3) Create the daily routine with the prompt "Back up my Claude settings" and wait for its first run to produce a commit. 4) Only then remove the SessionEnd hook entry that runs $HOME/.claude/scripts/settings-backup.sh from ~/.claude/settings.json and move the script to ~/.claude/scripts/archive/. Verify before reporting done: git -C ~/claude-settings-backup log -3 shows one commit from the manual run and one from the routine, both with the four new folders, and grep -c settings-backup.sh ~/.claude/settings.json prints 0.
  ```
- Make the backup repo private
  The audit found the backup repo public with settings.json pushed on every session and, on the daily path, no secret scan. Visibility is an account setting, so it stays a one-line decision for the owner.
  ```text
  Change github.com/shawn-sandy/claude-settings-backup from public to private with the gh CLI: gh repo edit shawn-sandy/claude-settings-backup --visibility private --accept-visibility-change-consequences. Verify with gh repo view shawn-sandy/claude-settings-backup --json isPrivate, which must print true, and report the output.
  ```
- Add an opt-in export of MCP servers from ~/.claude.json
  Export-only by design. The file is mostly cache plus the OAuth account record, so it is never copied whole, and restore never merges into it.
  ```text
  In the agentics repo, extend kit/plugins/settings-sync so that when ~/.claude/settings-sync.json sets "includeMcpServers": true, settings-backup extracts only the top-level mcpServers object from ~/.claude.json into <repo>/mcp-servers.json, runs the Step 4 secret scan over that file, and lists it in filesIncluded; settings-restore must not merge it into ~/.claude.json but instead print one claude mcp add-json <name> '<json>' command per server for the user to run, and must treat mcp-servers.json as a control file that is never copied into ~/.claude/. Update references/file-manifest.md, README.md, and CHANGELOG.md, bump the settings-sync minor version in .claude-plugin/marketplace.json, and add tests/plugins/test-settings-sync-mcp-export.sh that runs the extraction snippet against a fixture ~/.claude.json containing a server whose env holds a fake sk- token and asserts the token is reported by the scan. Verify by running bash tests/run-all.sh and bash scripts/verify.sh, both exiting 0.
  ```
- Add an opt-in backup of non-empty auto-memory folders
  Memory folder names encode absolute project paths, so a restore only helps when checkouts land at the same paths. The manifest must say so.
  ```text
  In the agentics repo, extend kit/plugins/settings-sync so that when ~/.claude/settings-sync.json sets "includeMemory": true, settings-backup copies every ~/.claude/projects/<slug>/memory/ directory that contains at least one file into <repo>/memory/<slug>/, skipping empty ones, and settings-restore copies them back to the same slugs while warning that a slug encodes an absolute path and only matches when the project is checked out at that path. Document the caveat in references/file-manifest.md, add the flag to README.md's Configuration section, add a CHANGELOG entry, bump the settings-sync minor version in .claude-plugin/marketplace.json, and add tests/plugins/test-settings-sync-memory.sh that builds a fake projects tree with two empty and one non-empty memory folder and asserts only the non-empty one is copied. Verify with bash tests/run-all.sh and bash scripts/verify.sh, both exiting 0.
  ```
- Preserve skill symlinks instead of flattening them (wish list)
  Fourteen of the audited machine's skills are symlinks into ~/.agents/skills, managed by the skills CLI with a lockfile. Flattening loses the link. Worth doing only if the CLI's re-link step turns out to be painful in practice.

## Unresolved Questions

- Do scheduled routines run on the local machine with access to `~/.claude`, or in the cloud? The first Next Step depends on the answer, and the hand script exists precisely because a SessionEnd hook is the one thing guaranteed to run locally.
  ```text
  Investigate whether a Claude Code scheduled routine created with /schedule executes on the user's local machine with the user's ~/.claude directory and installed plugins available, or on a cloud runner without them. Check the official Claude Code docs for routines and scheduled tasks, and the description of the scheduled-tasks tool in the desktop app. Report the answer with the source, and recommend one of two paths for the settings-sync plugin: if routines run locally, the daily backup should be a routine that invokes the settings-backup skill and the SessionEnd hook can be retired; if routines run in the cloud, the plugin should ship a non-interactive script generated from references/file-manifest.md that a SessionEnd hook can call, so the manifest stays the single source of truth.
  ```

## Resources

- Settings-Sync Coverage Audit, the artifact this plan resolves, with the coverage ledger and the commit-noise count: https://claude.ai/code/artifact/569c2f98-55b3-41d6-b3e3-ce9f8d930ca6
- tests/plugins/test-settings-backup-stale-entries.sh, the extract-a-marked-snippet-and-run-it pattern every new test here copies
- kit/plugins/settings-sync/skills/settings-backup/SKILL.md at 1.1.5, Steps 2, 5, 6, and 7, the four places the GREEN phase rewrites
- The audited machine's SessionEnd hook script at ~/.claude/scripts/settings-backup.sh, whose file list is the older manifest the repo's stale folders came from

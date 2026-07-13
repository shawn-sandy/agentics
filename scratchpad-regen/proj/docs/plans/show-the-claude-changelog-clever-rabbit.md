---
status: todo
type: feature
created: 2026-05-29
repo-name: agentics
---

> **Rename before commit:** this file was auto-named from an unrelated earlier request.
> Per the plan filename rule, rename it to `port-share-session-onto-main.md` on commit.

# Plan: Port the session-recap feature onto current `main` as `share-session`

## Context

The `feat/share-bg-fix` branch (PR #173) carries two commits and conflicts with `main` on
30+ files. Investigation shows the conflict is almost entirely **redundant/stale work**, not
new value:

- Commit `dba993a` (social-share router + non-interactive contract) **already exists on
  `main`** — `main` is at `social-media-tools` **v1.1.1**, ahead of the branch's v0.10.0, and
  already ships `social-share`, `agent-social-share`, `social-share-bg`, and
  `references/non-interactive-mode.md`.
- The branch uses the **old noun-first** skill naming (`blog-share`, `code-share`, …) while
  `main` adopted **verb-first** naming (`share-blog`, `share-code`, …). Every existing skill
  appears "renamed", which is the bulk of the conflicts.
- The **only genuinely new work** is the session-recap feature (4 files). `main` has no
  session feature at all.

Rather than rebase a branch that mostly re-adds what `main` already has, we rebuild from a
clean `main` base and port **only** the session feature. Decisions confirmed with the user:
skill named **`share-session`** (verb-first, matches main); ship a **dedicated `session-bg`
command + router integration**; **close PR #173** and open a fresh PR from a new branch.

## Objective

Add a `share-session` skill (session token-usage recap card) to the `social-media-tools`
plugin on top of current `main`, wired into the existing background command + router
infrastructure, bumping the plugin to **v1.2.0**.

## Files to port (source: `feat/share-bg-fix`) and adapt

Purely additive, drop onto `main` with namespace/naming edits:

- `kit/plugins/social-media-tools/skills/share-session/SKILL.md` — from branch
  `skills/session-share/SKILL.md`. Adapt: `name: session-share` → `share-session`; fix the
  hardcoded `code-share:security-scrub` → `social-media-tools:security-scrub`; update title.
- `kit/plugins/social-media-tools/scripts/session_usage.py` — copy verbatim (self-contained,
  no namespace deps).
- `kit/plugins/social-media-tools/templates/session-card.html` — copy verbatim.
- `kit/plugins/social-media-tools/commands/session-bg.md` — from branch
  `commands/session-bg.md`. Adapt: usage examples `/code-share:session-bg` →
  `/social-media-tools:session-bg`; `TARGET_SKILL=session-share` → `TARGET_SKILL=share-session`.

Modify existing `main` files:

- `kit/plugins/social-media-tools/skills/social-share/SKILL.md` — add one classification-table
  row routing explicit session/recap/"tokens today" requests to `TARGET_SKILL=share-session`.
- `.claude-plugin/marketplace.json` — bump `social-media-tools` `version` `1.1.1` → `1.2.0`;
  add `session`/`usage`/`tokens` tags.
- `kit/plugins/social-media-tools/CHANGELOG.md` — add a v1.2.0 entry.
- `kit/plugins/social-media-tools/README.md` — add `share-session` + `session-bg` to the
  Features/Components tables and a usage example.

Verified already present on `main` (no action needed): `references/{non-interactive-mode,
variables,platforms,copy-panels,reuse-check,saving-and-delivery,rendering-pipeline}.md`,
`agents/agent-social-share.md`, `skills/security-scrub/`.

## Steps

1. **Create branch from current `main`.** `git fetch origin && git switch -c
   feat/share-session origin/main`.
   - *Why:* A fresh base avoids every rename conflict; `main` already has all dependencies.
   - *Verify:* `git log -1 --oneline` matches `origin/main`; `git ls-tree -d main:.../skills`
     shows verb-first names.

2. **Port the four additive files** with the adaptations listed above (extract from the old
   branch via `git show feat/share-bg-fix:<path> > <new-path>`, then edit).
   - *Why:* These are the only files carrying new value; the session skill is feature-complete
     and only needs namespace/naming fixes.
   - *Verify:* `grep -r "code-share:" kit/plugins/social-media-tools/skills/share-session` and
     `grep "session-share" .../commands/session-bg.md` return nothing; `name: share-session`
     present in the SKILL.md frontmatter.

3. **Wire into the router.** Add a classification row to `social-share/SKILL.md` mapping
   explicit session-recap intent to `share-session`.
   - *Why:* User chose command + router; the router is the single dispatch point for
     `social-share-bg`.
   - *Verify:* `grep share-session .../skills/social-share/SKILL.md` shows the new row.

4. **Bump metadata.** Update `marketplace.json` (1.2.0 + tags), `CHANGELOG.md`, `README.md`.
   - *Why:* Adding a skill + command is a MINOR bump; conventions require changelog + readme +
     marketplace kept in sync (the settings hook validates `marketplace.json` syntax on save).
   - *Verify:* `grep -A2 social-media-tools .claude-plugin/marketplace.json` shows `1.2.0`;
     CHANGELOG has a v1.2.0 heading; README lists `share-session`/`session-bg`.

5. **Carry the plan file.** Rename this file to `port-share-session-onto-main.md`, set
   `status: in-progress`, and stage it with the change.
   - *Why:* Repo convention — plan files commit alongside plugin changes; the filename rule
     requires a meaningful `verb-target` name.
   - *Verify:* `ls docs/plans/port-share-session-onto-main.md` exists; the
     `validate-plan-filename` hook does not flag it.

6. **Close #173 and open a fresh PR.** `gh pr close 173 --comment "Superseded by clean
   port onto main (#NEW)"`; commit, push `feat/share-session`, open PR to `main`.
   - *Why:* #173 conflicts and mostly re-adds existing work; the new PR is conflict-free.
   - *Verify:* `gh pr view <new> --json mergeStateStatus` is not `DIRTY`/`CONFLICTING`; CI
     green.

## Acceptance Criteria

- [ ] `skills/share-session/SKILL.md` exists on the new branch with `name: share-session` and
      no `code-share:` namespace references.
- [ ] `commands/session-bg.md` dispatches `TARGET_SKILL=share-session` and uses the
      `social-media-tools:` namespace in examples.
- [ ] `social-share` router has a row routing session-recap intent to `share-session`.
- [ ] `marketplace.json` shows `social-media-tools` at `1.2.0`; CHANGELOG + README updated.
- [ ] New PR against `main` reports a non-conflicting merge state with CI passing.
- [ ] PR #173 is closed as superseded.

## Verification

End-to-end:
1. Load the branch: `claude --plugin-dir ./kit/plugins/social-media-tools`.
2. Run `/social-media-tools:session-bg --platform=linkedin` in a session with recent commits;
   confirm it dispatches in the background and emits
   `SOCIAL-SHARE: DONE skill=share-session …` with a PNG saved under `docs/media/social/`.
3. Run `python3 kit/plugins/social-media-tools/scripts/session_usage.py` standalone; confirm
   it prints JSON with token counts (no traceback).
4. Run `/social-media-tools:social-share-bg share my session recap`; confirm the router
   classifies it to `share-session`.
5. `gh pr checks <new-pr>` all green; `mergeStateStatus` not `DIRTY`.

## Next Steps *(optional)*

- Delete the stale branch:
  ```text
  After the share-session PR merges to main, delete the obsolete feat/share-bg-fix and
  feat/kit/add-social-share-router-2026-05-28 branches both locally and on origin, since their
  router work is already on main and the session work was ported separately. Confirm each is
  fully contained in main before deleting.
  ```

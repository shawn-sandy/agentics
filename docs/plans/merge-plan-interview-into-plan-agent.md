---
status: completed
type: refactor
created: 2026-07-17
modified: 2026-07-17
issue: https://github.com/shawn-sandy/agentics/issues/423
effort: high
workflow: true
repo: agentics
glance: Fold plan-interview into plan-agent v4.0.0 (plan-agent wins every overlap), then de-register and delete plan-interview.
---

# Plan: Merge plan-interview into plan-agent

## Objective

Fold the `plan-interview` plugin into `plan-agent` (bumped to v4.0.0), carrying
over only the capabilities plan-agent lacks and dropping every redundant
overlap, then de-register and delete `plan-interview` and update all repo
touchpoints.

## Context

The marketplace ships two planning plugins that already operate as one system
split by file format. The decision-complete proposal at
[docs/proposals/merge-plan-interview-into-plan-agent.md](../proposals/merge-plan-interview-into-plan-agent.md)
locks three decisions: **(1)** full merge into `plan-agent` v4.0.0, **(2)**
de-register + delete `plan-interview` (recoverable from git history, matching
the six prior removals in `.claude/rules/marketplace.md`), and **(3)**
plan-agent wins every overlap seam — drop the redundant version, port only
capabilities plan-agent lacks entirely.

Carry over: `documenting-plans` (skill + command + `plan-documenter` agent),
`plan-maintenance` (command), `markdown-to-html` (skill + command + assets),
`plan-status` (skill + command, as legacy `.md` support), `deep-grill` (skill +
command — kept for its node-by-node decision walk, a distinct mode from the
review-plan team), and the ExitPlanMode nudge hook. Drop: `plan-interview`,
`plan-to-html`, `plan-hygiene`, `review-rename-plans`.

## Files

- kit/plugins/plan-agent/ (modified) — destination for carried-over components
- kit/plugins/plan-interview/ (deleted) — removed after its unique parts are ported
- .claude-plugin/marketplace.json (modified) — de-register plan-interview, bump plan-agent to 4.0.0
- .claude/rules/marketplace.md (modified) — Removed Plugins row
- .claude/settings.json (modified) — drop plan-interview from enabledPlugins
- CLAUDE.md (modified) — plugin table 13 to 12 rows
- kit/plugins/plan-agent/README.md (modified) — replace plan-interview pairing section
- kit/plugins/plan-agent/CHANGELOG.md (modified) — 4.0.0 entry with migration map
- tests/publish/smoke-clean-dist.sh (modified) — drop plan-interview from roster
- tests/publish/test-dist-transforms.mjs (modified) — remove plan-interview README block
- tests/plugins/test-save-pdf.sh (modified) — update plan-interview origin comment

## Steps

1. Copy the carry-over components from plan-interview into plan-agent preserving directory shape: skills documenting-plans, markdown-to-html (with its assets, reference, scripts), plan-status, and deep-grill; commands documenting-plans.md, plan-maintenance.md, markdown-to-html.md, plan-status.md, update-plan-status.md, deep-grill.md; and agents/plan-documenter.md. Why: these have no plan-agent counterpart and decision 3 ports only unique capability — deep-grill is kept for its node-by-node decision walk, a mode the review-plan team does not cover. Verify: `ls kit/plugins/plan-agent/skills/` shows documenting-plans, markdown-to-html, plan-status, and deep-grill, and the agent plus commands exist under plan-agent.

2. Rewrite every `plan-interview:` namespace reference and intra-plugin path in the copied files to `plan-agent:` — skill bodies, command bodies, the plan-documenter agent, and cross-links between the moved skills. Why: invocations and internal links must resolve under the new plugin namespace. Verify: `grep -rn "plan-interview:" kit/plugins/plan-agent/` returns nothing except the intentional CHANGELOG migration note.

3. Fold update-plan-status's bulk mode into the moved plan-status skill as a directory/all flag, then delete the standalone update-plan-status command just copied. Why: one status skill with a bulk flag beats two commands doing the same job. Verify: plan-status SKILL.md documents the bulk flag and `kit/plugins/plan-agent/commands/update-plan-status.md` does not exist.

4. Merge the ExitPlanMode nudge hook from plan-interview/hooks.json into plan-agent/hooks.json as a new PostToolUse matcher, rewording its message to point at plan-agent's built-in Step 5b interview. Why: the post-plan-mode nudge is unique and must survive the deletion. Verify: plan-agent/hooks.json contains an ExitPlanMode matcher referencing the built-in interview and `python3 -c "import json; json.load(open('kit/plugins/plan-agent/hooks.json'))"` exits 0.

5. Repoint plan-agent's internal handoffs to the now-local skills: finalize-plan/SKILL.md (plan-interview:plan-status becomes plan-agent:plan-status) and review-plan/SKILL.md (conversational stress-test note points at the local skill or built-in interview). Why: the old cross-plugin handoffs now resolve in-plugin. Verify: `grep -rn "plan-interview" kit/plugins/plan-agent/skills/` returns nothing.

6. De-register plan-interview from marketplace.json by removing its plugin object, bump plan-agent version to 4.0.0, and extend plan-agent's description and tags to cover the absorbed documenting, maintenance, markdown-to-html, and status capabilities. Why: MAJOR bump since a plugin is absorbed and the plan-interview namespace is removed. Verify: `python3 -c "import json; m=json.load(open('.claude-plugin/marketplace.json')); assert 'plan-interview' not in [p['name'] for p in m['plugins']]; assert next(p for p in m['plugins'] if p['name']=='plan-agent')['version']=='4.0.0'"` exits 0 and the jq hook reports marketplace.json valid.

7. Delete the kit/plugins/plan-interview/ directory in full. Why: decision 2 is de-register plus delete, with source recoverable from git history. Verify: `test ! -d kit/plugins/plan-interview && echo gone` prints gone.

8. Add a Removed Plugins row to .claude/rules/marketplace.md recording plan-interview, 2026-07-17, merged into plan-agent 4.0.0, source recoverable from git history. Why: the removal table is the canonical record and the guard against re-adding. Verify: `grep -n "plan-interview" .claude/rules/marketplace.md` shows the new row in the Removed Plugins table.

9. Update CLAUDE.md by deleting the plan-interview plugin-table row, folding its surviving capabilities into the plan-agent row, and changing the 13-plugins count to 12. Why: the plugin table and count must match the shipped marketplace. Verify: `grep -c "plan-interview" CLAUDE.md` is 0 and the table lists 12 plugins.

10. Remove plan-interview@agentics-kit from enabledPlugins in .claude/settings.json. Why: the deleted plugin can no longer be enabled. Verify: `python3 -c "import json; assert 'plan-interview@agentics-kit' not in json.load(open('.claude/settings.json'))['enabledPlugins']"` exits 0.

11. Repoint the three test references: drop plan-interview from the PLUGINS array in smoke-clean-dist.sh and change its 13-dir comment to 12; remove the plan-interview README transform block in test-dist-transforms.mjs or repoint it to a surviving plugin; update the line-7 origin comment in test-save-pdf.sh. Why: tests hardcode the plugin roster and must not assert on a deleted plugin. Verify: `grep -rn "plan-interview" tests/plugins tests/publish` returns only tests/fixtures data and `bash tests/publish/smoke-clean-dist.sh` passes against a fresh dist.

12. Add a 4.0.0 entry to kit/plugins/plan-agent/CHANGELOG.md documenting the merge with a plan-interview-to-plan-agent migration mapping table, and update plan-agent/README.md to replace the Optional plan-interview pairing section with the merged skills. Why: users need the rename map and the README must describe the current surface. Verify: CHANGELOG has a 4.0.0 heading with the mapping table and `grep -n "Optional" kit/plugins/plan-agent/README.md` no longer shows a plan-interview pairing section.

## Tests

> Tier: 1 (code-touching — moves and deletes plugin source, edits manifests and tests)

### Objective-Verification Test

- **File:** `tests/publish/smoke-clean-dist.sh` (extend) or a new
  `tests/plugins/test-plan-merge.sh`
- **Type:** smoke test
- **Asserts:** after a clean dist build, the marketplace lists 12 plugins with
  no `plan-interview`, `plan-agent` is at `4.0.0`, and
  `dist/kit/plugins/plan-agent/skills/` contains `documenting-plans`,
  `markdown-to-html`, and `plan-status` — i.e. the merge is complete and the
  deletion took.
- **Run:** `bash tests/publish/smoke-clean-dist.sh`

### Integration Tests

- **File:** `tests/publish/test-dist-transforms.mjs`
- **Targets:** the dist publish pipeline against the new 12-plugin roster
- **Key cases:** no plan-interview README transform is asserted; plan-agent
  README carries the merged skills; the run exits 0.

## Acceptance Criteria

- [x] `plan-agent` is version `4.0.0` in `marketplace.json`; `plan-interview` is absent. _(verified: marketplace lists 12 plugins, plan-agent 4.0.0, no plan-interview.)_
- [x] `kit/plugins/plan-agent/` contains the `documenting-plans`, `markdown-to-html`, and `plan-status` skills (plus `deep-grill`), the `plan-documenter` agent, the `plan-maintenance`/`documenting-plans`/`markdown-to-html`/`plan-status`/`deep-grill` commands, and the ExitPlanMode nudge hook. _(verified: `ls` + `hooks.json` ExitPlanMode matcher present.)_
- [x] No `plan-interview:` namespace or path reference remains anywhere under `kit/plugins/plan-agent/` except migration notes. _(verified: skills/commands/agents/hooks are clean; the only remaining mentions are the CHANGELOG 4.0.0 migration note and the README migration map — both are old→new documentation, not live handoffs.)_
- [x] `kit/plugins/plan-interview/` no longer exists. _(verified: directory removed.)_
- [x] `.claude/rules/marketplace.md` Removed Plugins table has the plan-interview row. _(verified.)_
- [x] `CLAUDE.md` shows 12 plugins with no plan-interview row. _(verified: 12 table rows; only a folded "absorbed from the former plan-interview" note remains.)_
- [x] `.claude/settings.json` `enabledPlugins` no longer lists plan-interview. _(verified.)_
- [x] `bash tests/publish/smoke-clean-dist.sh` and `node tests/publish/test-dist-transforms.mjs` pass. _(verified: 14/14 transforms pass against a fresh 12-plugin dist; full plugin + publish suites green.)_
- [x] The dropped components (`plan-interview`, `plan-to-html`, `plan-hygiene`, `review-rename-plans`) were not carried into plan-agent. _(verified.)_

## Finalization notes (2026-07-17)

Executed and verified end-to-end. Two deviations from the reference plan, both optimizing for the outcome:

1. **Scope beyond the plan's listed files.** The plan's step 11 named three test files, but `tests/plugins/test-command-delegation.sh` also hard-referenced the moved command paths (would have failed "missing") and live cross-references to the moved skills existed in `kit/plugins/README.md`, `product-plans/` (README + `plan-review-agents` SKILL), and `social-media-tools/` (`write-guide`). All were repointed to `plan-agent`; historical CHANGELOG entries were left intact as accurate history.
2. **Test assertion repointed, not deleted.** `test-dist-transforms.mjs` asserted a `marketplace add` line unique to plan-interview's README; plan-agent (like other surviving plugins) installs via `/plugin install <name>@agentics-kit`, so the assertion was repointed to that line rather than dropped.

## Verification

1. Build a clean dist (`node scripts/build-dist.mjs`) and run `bash
   tests/publish/smoke-clean-dist.sh` — it passes with the 12-plugin roster.
2. `grep -rn "plan-interview" kit/ CLAUDE.md .claude/settings.json .claude/rules/marketplace.md tests/plugins tests/publish`
   returns only the intentional Removed Plugins row, the CHANGELOG migration
   note, and `tests/fixtures/` sample data.
3. Load the merged plugin locally (`claude --plugin-dir
   kit/plugins/plan-agent`) and confirm `/plan-agent:documenting-plans`,
   `/plan-agent:markdown-to-html`, `/plan-agent:plan-status`, and
   `/plan-agent:plan-maintenance` resolve; the ExitPlanMode nudge fires after
   exiting plan mode.
4. Confirm the marketplace JSON validates via the PostToolUse `jq` hook and
   `check-version-bump.sh` accepts the 4.0.0 bump.

## Next Steps

- Announce the rename to installed users:
  ```text
  Draft a short migration note for anyone who had plan-interview@agentics-kit installed: it merged into plan-agent 4.0.0. List the /plan-interview:* → /plan-agent:* command mapping, note that plan-interview, plan-to-html, plan-hygiene, and review-rename-plans were dropped (plan-agent's built-in interview, review-plan team, and validate-plan-filename hook cover them), and tell users to uninstall plan-interview and ensure plan-agent >= 4.0.0.
  ```


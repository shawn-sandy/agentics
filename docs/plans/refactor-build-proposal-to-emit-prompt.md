---
status: todo
type: refactor
created: 2026-07-27
effort: high
workflow: true
glance: build-proposal currently ends by hand-writing a one-line handoff string, and the skill that exists to author prompts properly cannot be called at all. This wires the two together so a proposal converges on a real saved prompt, and we will know it worked when a single pipeline test confirms the command wrapper, the fifth prompt type, the dual-write, and the gallery chip all line up.
---

# Plan: Make build-proposal converge on a saved prompt authored by write-prompt

## Objective

Refactor build-proposal so its decision-complete output is a saved, copy-pasteable prompt under docs/prompts/, authored by delegating to write-prompt, while dual-writing the legacy docs/proposals/ document for one deprecation release. Ship the whole change as plan-agent 6.0.0.

## Context

`build-proposal` already ends by emitting a prompt — a hand-built one-line invocation string for `implementation-plan`. The skill spends an entire paragraph (`build-proposal/SKILL.md:207-214`), duplicated in `references/operating-principles.md:49` and `build/SKILL.md:185-188`, warning that getting that string's grammar wrong drops `implementation-plan` into conversion mode and yields a plan whose steps restate proposal headings. That is prompt authoring being done by hand, in prose, in triplicate — and `write-prompt` is the skill that exists to do it properly.

The blocker found during proposal research is mechanical, not conceptual. `disable-model-invocation: true` blocks programmatic `Skill` invocation, not just ambient auto-activation. Four plan-agent skills carry the flag; the two with thin `commands/*.md` wrappers (`deep-grill`, `documenting-plans`) are invocable and appear in the session skill registry, and the two without (`write-prompt`, `finalize-plan`) are not. The wrapper is the fix, and it is 15 lines.

Four decisions were locked in the 2026-07-27 proposal review and are not reopened here: keep `disable-model-invocation` and add the wrapper; make the saved prompt file the living document; add a fifth `proposal` prompt type rather than compressing into `task`; dual-write both artifacts for 6.0.0 with the prompt authoritative. Four follow-on decisions were settled while drafting this plan: `status:` uses the proposal-native vocabulary `gathering`/`converged`; `--dir` follows the authoritative artifact and now names the prompts directory; appendices map to a single catch-all `{{APPENDICES}}` slot; and this plan covers the full 6.0.0 release rather than the de-risking spike alone. Four more came out of the plan interview: Tier 0 keeps writing nothing while Tier 1 emits a short-subset prompt; the prompt path is derived from slug and date rather than read back; an in-place rewrite diffs for hand edits before overwriting; and long proposal bodies rely on the gallery's existing `<details>` collapse rather than type-specific CSS.

Known risk carried into implementation: `Skill()` has no documented return value. The interview resolved this by deriving the prompt path deterministically from the slug and date instead of parsing anything out of the transcript, which removes the dependency rather than working around it. What remains unverified is whether `Skill()` can reach `write-prompt` at all once the wrapper lands, whether three-level nesting works, and whether the `claude-fable-5` to `opus` pin boundary changes behavior. Step 2 exists to prove those empirically before anything is built on them, and is a hard stop if they fail.

See `docs/proposals/replace-proposal-doc-with-prompt.md` for the full decision record, risk register, and the section-to-slot mapping table.

## Files

- kit/plugins/plan-agent/commands/write-prompt.md (new) — thin Skill wrapper that unblocks programmatic invocation
- kit/plugins/plan-agent/skills/write-prompt/references/proposal-prompt-template.md (new) — fifth template with proposal-shaped slots
- kit/plugins/plan-agent/skills/write-prompt/SKILL.md (modified) — fifth type across Phases 1, 2, 3, 4, 7
- kit/plugins/plan-agent/skills/build-proposal/SKILL.md (modified) — dual-write in Step 6, prompt handoff in Step 8, --dir retarget
- kit/plugins/plan-agent/skills/build-proposal/references/artifact-shape.md (modified) — slot mapping and the bare-.md handoff fix at line 102
- kit/plugins/plan-agent/skills/build/SKILL.md (modified) — Step 1b prompt path, dirty-tree exclusion, abandonment contract
- kit/plugins/artifact-tools/skills/prompt-artifact/SKILL.md (modified) — fifth filter chip and tolerance for status/modified frontmatter
- tests/plugins/test-proposal-prompt-pipeline.sh (new) — objective-verification test for the whole wiring
- tests/plugins/test-write-prompt-proposal-type.sh (new) — unit coverage for the fifth type
- tests/plugins/test-build-proposal.sh (modified) — checks 10, 11, 14, 15 rewritten to the dual-write contract
- tests/plugins/test-build-skill.sh (modified) — Step 1b assertions updated; runs in CI
- kit/plugins/plan-agent/README.md (modified) — build-proposal and write-prompt sections, Plugin Structure tree
- kit/plugins/artifact-tools/README.md (modified) — prompt-artifact type list
- kit/plugins/plan-agent/CHANGELOG.md (modified) — 6.0.0 entry
- kit/plugins/artifact-tools/CHANGELOG.md (modified) — fifth-chip entry
- .claude-plugin/marketplace.json (modified) — plan-agent 5.0.0 to 6.0.0, artifact-tools patch bump
- CLAUDE.md (modified) — plan-agent and artifact-tools table rows
- README.md (modified) — build-proposal artifact path

## Steps

1. Create `kit/plugins/plan-agent/commands/write-prompt.md` mirroring `commands/deep-grill.md` exactly — frontmatter with `description`, `allowed-tools: Skill`, and `argument-hint`, a two-sentence body, and one fenced `Skill(skill: "plan-agent:write-prompt", args: "$ARGUMENTS")` call. Why: `disable-model-invocation: true` blocks programmatic invocation, and the wrapper is the established in-repo workaround that keeps ambient triggering on the word "prompt" suppressed. Verify: the file is 15 lines or fewer, `grep -qF 'Skill(skill: "plan-agent:write-prompt"' kit/plugins/plan-agent/commands/write-prompt.md` exits 0, and `write-prompt/SKILL.md:5` still carries `disable-model-invocation: true`.

2. Prove the invocation seam before building on it — from a session with the plugin loaded, invoke `/plan-agent:write-prompt`, confirm it runs and appears in the session skill registry, then confirm a nested `build` to `build-proposal` to `write-prompt` call completes and note whether the `claude-fable-5` caller invoking an `opus` callee changes behavior. Why: risks 1 through 3 in the proposal (no documented `Skill()` return value, three-level nesting, and cross-model-pin behavior) are all unverified, and every later step assumes they hold. Verify: `write-prompt` is invocable, a prompt file is written to `docs/prompts/`, and a three-level nested invocation completes without a depth or permission error.

3. Create `kit/plugins/plan-agent/skills/write-prompt/references/proposal-prompt-template.md` following the shape of the existing four templates — a `## Template` fenced block, a `## Placeholder Guide` table, and a `## Assembled Example` — carrying `{{TLDR}}`, `{{CONTEXT}}`, `{{CORE_FINDING}}`, `{{COMPARISON_TABLE}}`, `{{LOCKED_DECISIONS}}`, `{{WORKSTREAMS}}`, `{{RISKS}}`, `{{OPEN_QUESTIONS}}`, `{{ROADMAP}}`, `{{APPENDICES}}`, and `{{CORE_INSTRUCTION}}`. Why: a 326-line proposal compressed into the `task` template's 10 slots loses appendices, roadmap phasing, and risk tables, and the proposal's Next-step section maps exactly onto a prompt's core instruction. Verify: all 11 placeholder tokens appear in both the template block and the Placeholder Guide table, and the Assembled Example contains no unsubstituted `{{` tokens.

4. Wire the `proposal` type through `kit/plugins/plan-agent/skills/write-prompt/SKILL.md` — add the fifth row to the Phase 1 type table and technique matrix, the Phase 3 XML layer mapping, the Phase 4 template-selection entry, and extend Phase 7 with `status:` (`gathering` or `converged`) and `modified:` frontmatter keys plus an in-place rewrite rule that replaces the `-2`/`-3` uniqueness guard for this type, guarded by a drift check that diffs the file against what the skill last wrote and asks via `AskUserQuestion` before overwriting hand edits. Why: the prompt file becomes the living document that deepens each round, so the write-once uniqueness guard would create a new file per round and break the record — but it is also now the authoritative deliverable, so silently clobbering a user's edits to it is worse than the duplicate it replaces. Verify: the type appears in all five phases, a round-two run overwrites the same filename rather than creating a `-2` variant, and a hand-edited file triggers the confirmation prompt instead of a silent overwrite.

5. Add a pre-gathered-answers bypass to `write-prompt` Phase 2 so a caller that has already interviewed the user skips the interview batch. Why: `build-proposal` Step 5 resolves decisions with the human already, and re-running Phase 2 would double-interview; the Claude Code docs are silent on any official pattern, so this is a documented repo-local `$ARGUMENTS` convention. Verify: Phase 2 documents the bypass token and its skip condition, and an invocation carrying the token produces a prompt with zero `AskUserQuestion` calls.

6. Update `kit/plugins/artifact-tools/skills/prompt-artifact/SKILL.md` — add `proposal` as a fifth filter chip at lines 148-149, make the frontmatter reader tolerate the new `status:` and `modified:` keys without breaking card rendering, and confirm the existing `<details>` collapse plus a horizontally scrolling `<pre>` handle a 300-line body without forcing page-level overflow. Why: the skill globs `$PROMPTS_DIR/*.md` and hard-codes four chip values, so a fifth type ships a gallery where proposal prompts are invisible to every filter, and proposal prompts are roughly 3x longer than any prompt the gallery has rendered so far. Verify: the chip list names all five types, publishing a library containing a `type: proposal` prompt renders a card reachable by its own chip, and the page body does not scroll horizontally at mobile width.

7. Rewrite `build-proposal`'s Step 6 to dual-write — invoke `write-prompt` with the proposal content and the Step 5 bypass token, derive the saved prompt path deterministically as `{prompts-dir}/proposal-{slug}-{YYYY-MM-DD}.md` from the slug and date the skill already holds rather than reading anything back, and additionally write the legacy `docs/proposals/<slug>.md` carrying a deprecation banner naming the prompt as authoritative — then rewrite Step 8 to hand off the prompt path, and retarget `--dir` to the prompts directory. Why: `Skill()` has no documented return value, and deriving the path removes the transcript dependency entirely instead of coupling `build-proposal` to `write-prompt`'s user-facing prose; locked decision 4 keeps `docs/proposals/` alive for one release so the inbound relative link at `docs/plans/merge-plan-interview-into-plan-agent.md:26` keeps resolving. Verify: a full `build-proposal` run produces both files at the derived paths, the proposal copy carries the deprecation banner, and the Step 8 handoff names the `docs/prompts/` path.

8. Preserve tier behavior across the refactor in `build-proposal/SKILL.md` — Tier 0 continues to answer directly and write **no** artifact of either kind, and Tier 1 emits a prompt populated only from the short subset of slots (`{{CONTEXT}}`, `{{CORE_FINDING}}`, `{{OPEN_QUESTIONS}}`, `{{CORE_INSTRUCTION}}`) with the remaining slots omitted rather than emitted empty. Why: `build/SKILL.md:189-193` documents a "No proposal written" fall-through that fires precisely when Tier 0 produces nothing, so making every tier write a file would silently break the chain, and the skill's own rule forbids emitting empty sections. Verify: a Tier 0 idea produces zero files in both directories and `build`'s fall-through still triggers, and a Tier 1 run produces a prompt with no empty slot headings.

9. Update `kit/plugins/plan-agent/skills/build-proposal/references/artifact-shape.md` — add the section-to-slot mapping table from the proposal's Appendix B, and fix line 102's `/plan-agent:implementation-plan docs/proposals/<slug>.md` to lead with objective text. Why: line 102 currently advertises the bare-`.md` handoff that `SKILL.md:207-214` forbids and test check 15 greps for, but the check only scans `SKILL.md`, so the reference has been teaching the conversion-mode trap unnoticed. Verify: `grep -qE 'implementation-plan +[^ ]+\.md' kit/plugins/plan-agent/skills/build-proposal/references/artifact-shape.md` exits non-zero.

10. Update `kit/plugins/plan-agent/skills/build/SKILL.md` Step 1b so the returned artifact is a prompt path — the `Skill(skill: "plan-agent:build-proposal")` call site at L179, the `implementation-plan` handoff string at L181-185, the dirty-tree exclusion at L100, and the abandonment contract at L216-218. Why: the chain interpolates whatever `build-proposal` reports without parsing it, so a changed artifact silently propagates unless every reference is updated together. Verify: no line in Step 1b refers to a proposal path as the chained artifact, and the `--dir` forwarding asymmetry documented at L180-185 still holds.

11. Update the three test files — rewrite `tests/plugins/test-build-proposal.sh` checks 10, 11, 14, and 15 to the dual-write contract, update `tests/plugins/test-build-skill.sh`'s Step 1b assertions at L178-187, and add `tests/plugins/test-write-prompt-proposal-type.sh` plus the objective test `tests/plugins/test-proposal-prompt-pipeline.sh`. Why: `test-build-skill.sh` runs in CI via `check-plugin-versions.yml:30` and `publish-dist.yml:44`, so leaving its assertions stale turns the release red. Verify: `bash tests/plugins/test-build-skill.sh` and `bash tests/plugins/test-proposal-prompt-pipeline.sh` both exit 0.

12. Update the documentation and bump versions — `kit/plugins/plan-agent/README.md` (the build-proposal and write-prompt sections, and add the missing `write-prompt/` entry to the Plugin Structure tree), `kit/plugins/artifact-tools/README.md`, `CLAUDE.md:38,81`, root `README.md:451,470,473`, both CHANGELOGs, and `.claude-plugin/marketplace.json` moving plan-agent from 5.0.0 to 6.0.0 with an artifact-tools patch bump. Why: the change removes an artifact contract, which is a major bump under the repo's semver rules, and `test-build-proposal.sh` check 12 asserts the marketplace version rises above `origin/main`. Verify: `BASE_REF=main node scripts/check-plugin-versions.mjs` exits 0 and no README or CLAUDE.md line still describes `docs/proposals/<slug>.md` as the sole deliverable.

## Acceptance Criteria

- [ ] `/plan-agent:write-prompt` is invocable and `write-prompt` appears in the session skill registry while `disable-model-invocation: true` remains in its frontmatter.
- [ ] `write-prompt` accepts a fifth `proposal` type and selects `references/proposal-prompt-template.md` for it.
- [ ] A saved proposal prompt carries `status:` (`gathering` or `converged`) and `modified:` frontmatter, and a second round overwrites the same file rather than creating a `-2` variant.
- [ ] A hand-edited prompt file triggers a confirmation prompt before the next round overwrites it.
- [ ] A Tier 0 idea writes no file in either directory and `build`'s "No proposal written" fall-through still fires; a Tier 1 idea writes a prompt with no empty slot headings.
- [ ] `build-proposal` derives the prompt path from slug and date without reading `write-prompt`'s output back.
- [ ] `write-prompt` Phase 2 runs zero `AskUserQuestion` calls when invoked with the pre-gathered-answers bypass token.
- [ ] A full `build-proposal` run writes both a `docs/prompts/` prompt and a `docs/proposals/` copy, and the proposal copy carries a deprecation banner naming the prompt as authoritative.
- [ ] `build-proposal`'s Step 8 handoff names the `docs/prompts/` path and leads with objective text, not a bare `.md` token.
- [ ] No file under `kit/plugins/plan-agent/skills/build-proposal/` matches `implementation-plan +[^ ]+\.md`, including `references/artifact-shape.md`.
- [ ] `prompt-artifact`'s library gallery offers five filter chips and renders `type: proposal` cards reachable by their own chip.
- [ ] `bash tests/plugins/test-build-skill.sh`, `bash tests/plugins/test-build-proposal.sh`, `bash tests/plugins/test-write-prompt-proposal-type.sh`, and `bash tests/plugins/test-proposal-prompt-pipeline.sh` all exit 0.
- [ ] `BASE_REF=main node scripts/check-plugin-versions.mjs` exits 0 with plan-agent at 6.0.0.
- [ ] `docs/plans/merge-plan-interview-into-plan-agent.md:26`'s relative link into `../proposals/` still resolves.

## Tests

Tier 1 — This plan creates and modifies executable test scripts, plugin skill definitions, and marketplace configuration
- Objective: build-proposal converges on a saved prompt authored by write-prompt. File: tests/plugins/test-proposal-prompt-pipeline.sh; Type: smoke; Asserts: the command wrapper exists and calls Skill with the write-prompt target, write-prompt declares the proposal type and its template file exists with all 11 placeholders, build-proposal Step 6 dual-writes and derives the prompt path from slug and date, Step 8 hands off a docs/prompts path, Tier 0 is documented as writing no artifact, prompt-artifact lists five filter chips, and no build-proposal file advertises a bare-.md handoff; Run: bash tests/plugins/test-proposal-prompt-pipeline.sh
- Unit: the fifth prompt type is wired through every write-prompt phase. File: tests/plugins/test-write-prompt-proposal-type.sh; Targets: write-prompt/SKILL.md Phases 1, 2, 3, 4, 7 and references/proposal-prompt-template.md; Key cases: type table row, technique matrix row, XML layer mapping, template selection path, status and modified frontmatter keys, in-place rewrite rule, drift check before overwrite, bypass token documented, all 11 placeholders present in both template and guide
- Integration: the build chain still resolves end-to-end with the new artifact. File: tests/plugins/test-build-skill.sh; Targets: build/SKILL.md Step 1b; Key cases: the build-proposal Skill call site, the proposal-versus-direct gate, the no-artifact fall-through, and the --dir forwarding asymmetry
- Integration: build-proposal's own contract under dual-write. File: tests/plugins/test-build-proposal.sh; Targets: build-proposal/SKILL.md and references/; Key cases: rewritten checks 10, 11, 14, 15 plus the existing marketplace-version check 12

## Verification

Run the four test scripts and `BASE_REF=main node scripts/check-plugin-versions.mjs`; all five must exit 0. `bash tests/plugins/test-proposal-prompt-pipeline.sh` is the end-to-end gate — it asserts every seam of the refactor in one run.

Then exercise the real pipeline rather than trusting static assertions. From a session with the plugin loaded, run `/plan-agent:build-proposal <a small test idea> --dir /tmp/proposal-check` and confirm: a prompt file appears under the resolved prompts directory with `type: proposal`, `status:`, and `modified:` frontmatter; a legacy copy appears under `docs/proposals/` carrying the deprecation banner; the Step 8 handoff line names the prompt path and leads with objective text. Run the same idea a second time against the same slug and confirm the prompt file is overwritten in place rather than a `-2` variant appearing.

Finally publish the prompt library via `prompt-artifact --library` and confirm the rendered gallery shows five filter chips and that the proposal card is hidden and shown by the `proposal` chip.

Step 2 is a hard gate: if `write-prompt` does not become invocable after the wrapper lands, or the three-level nesting or cross-model-pin behavior fails, stop and report rather than continuing to Step 3 — every later step assumes that seam holds.

## Unresolved Questions

- Is the 6.1.0 removal of `docs/proposals/` automatic on schedule, or gated on evidence that nothing depends on it? Proposal open question 3, deliberately left out of this plan's scope.
- This plan carries 12 steps against the Deep profile's 6-10 guidance, because scope was explicitly set to the full 6.0.0 release rather than the proposal's phased split. If it proves unwieldy in execution, the natural seam is after Step 6 — Steps 1-6 add capability without changing any user-facing behavior, and Steps 7-12 are the cutover.

## Resources

- docs/proposals/replace-proposal-doc-with-prompt.md — the decision record, risk register, and Appendix B section-to-slot mapping this plan implements
- https://code.claude.com/docs/en/skills.md — `disable-model-invocation` semantics (L257-258, L626); confirms it blocks programmatic Skill invocation
- https://code.claude.com/docs/en/tools-reference.md — Skill tool executes within the main conversation (L50); the basis for the synchronous, shared-transcript assumption
- kit/plugins/plan-agent/commands/deep-grill.md — the 15-line wrapper pattern Step 1 copies

## Next Steps

- Remove the deprecated proposals path in 6.1.0
  Completes the migration once the deprecation window closes.
  ```text
  In the agentics repo (github.com/shawn-sandy/agentics), remove the deprecated
  dual-write proposal path from the build-proposal skill. Delete the
  docs/proposals/ write branch and its deprecation banner from
  kit/plugins/plan-agent/skills/build-proposal/SKILL.md Step 6, remove the
  docs/proposals/ directory and its .gitkeep, and fix the now-dangling relative
  link at docs/plans/merge-plan-interview-into-plan-agent.md:26 to point at the
  prompt artifact instead. Update tests/plugins/test-build-proposal.sh to drop
  the dual-write assertions, update kit/plugins/plan-agent/README.md and
  CLAUDE.md, bump plan-agent to 6.1.0 in .claude-plugin/marketplace.json, and
  add a kit/plugins/plan-agent/CHANGELOG.md entry. Verify by running
  bash tests/plugins/test-build-proposal.sh and
  bash tests/plugins/test-proposal-prompt-pipeline.sh — both must exit 0 — and
  confirm no file outside docs/plans/ or docs/artifacts/ still references
  docs/proposals/.
  ```

- Wire test-build-proposal.sh into CI
  It has never run in any workflow and check 12 is red on main.
  ```text
  In the agentics repo (github.com/shawn-sandy/agentics), add
  tests/plugins/test-build-proposal.sh to the test matrix in
  .github/workflows/check-plugin-versions.yml and
  .github/workflows/publish-dist.yml, alongside the existing
  tests/plugins/test-build-skill.sh invocation. Fix whatever makes check 12
  (the dynamic marketplace-version comparison against origin/main) fail before
  wiring it in, so the workflow does not go red on merge. Context:
  docs/plans/wire-plugin-tests-into-ci.md:47 records that this test is
  deliberately unwired because check 12 is failing. Verify by running
  bash tests/plugins/test-build-proposal.sh locally — it must exit 0 — and by
  confirming both workflow files invoke it.
  ```

- Make write-prompt actually read its own best-practices reference
  119 lines of guidance are currently dead weight.
  ```text
  In the agentics repo (github.com/shawn-sandy/agentics), the file
  kit/plugins/plan-agent/skills/write-prompt/references/best-practices-reference.md
  declares at line 3 that it "is consumed by the write-prompt skill", but no
  phase in kit/plugins/plan-agent/skills/write-prompt/SKILL.md instructs
  reading it, so its 119 lines of Anthropic prompting guidance never load.
  Either wire it into Phase 3 or Phase 4 with an explicit Read instruction, or
  delete it and fold the load-bearing rules inline into the phase bodies —
  decide based on which keeps SKILL.md under the 500-line authoring budget.
  Bump the plan-agent patch version in .claude-plugin/marketplace.json and add
  a CHANGELOG entry. Verify by confirming either that SKILL.md names the
  reference path in a phase body, or that the file no longer exists and no
  file references it.
  ```

- Normalize the existing docs/prompts corpus
  One of the four saved prompts contradicts the documented body format.
  ```text
  In the agentics repo (github.com/shawn-sandy/agentics), the file
  docs/prompts/task-refactor-authentication-middleware-2026-06-04.md wraps its
  prompt body in a ```text fence (lines 10 and 27), contradicting
  kit/plugins/plan-agent/skills/write-prompt/SKILL.md line 282, which says to
  embed the prompt as plain text rather than the Phase 6 fenced display block.
  The other three files in docs/prompts/ are unfenced. Remove the fence so all
  four files share one body format. Verify by confirming no file in
  docs/prompts/ contains a fence immediately after its H1, and that
  kit/plugins/artifact-tools/skills/prompt-artifact/SKILL.md still renders the
  body correctly into its <pre> block.
  ```

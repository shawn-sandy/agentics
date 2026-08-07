---
status: todo
type: feature
created: 2026-08-07
workflow: never
issue: https://github.com/shawn-sandy/agentics/issues/534
glance: Every existing way to share work in this kit either reports what changed or writes a Markdown file nobody links to. This fills the one empty slot — a shareable page whose job is understanding — and we will know it worked when the plugin's continuous-integration guard validates five skills instead of four and the version reaches 1.12.0.
---

# Plan: Ship teach-artifact, the artifact-tools skill that teaches instead of recaps

## Objective

Add a fifth skill, `teach-artifact`, to the `artifact-tools` plugin. It reads the same two sources the existing recap commands already read — the current working session, or a pull request — and publishes a claude.ai page that teaches a reader how the system works, rather than reporting what changed.

## Context

The `artifact-tools` plugin already separates its publishing engine from its framing. The three recap commands (`eng-recap`, `team-recap`, `product-doc`) are short files of 60 to 68 lines each; all the real machinery lives in one shared 276-line reference, `references/recap-core.md`, which owns source resolution, the blocking secret-scanning gate, the page-build rules, and the record that lets a re-run republish to the same link. Each command declares only five things: its audience, its section list, its favicon, its inbox filename stem, and its republish key.

That structure is why this work is small. `teach-artifact` reuses `recap-core` unchanged and supplies a different frame, so version 1 ships zero new source-gathering code.

The gap it fills is real and was measured, not assumed. Two skills in the kit already teach — `social-media-tools:write-guide` writes long-form Markdown into a `guides/` folder, and `social-media-tools:share-explanation` produces a social-card image — but neither publishes a shareable page. The four skills that do publish pages all either recap a change or reproduce a document verbatim. A teaching page is the one combination nothing produces.

The main risk is overlap with `team-recap`. A teaching page about a session and a team recap of that session can drift into the same document. The mitigation is that the section spine must be teaching-shaped, and step 1 gives that spine its own file so it can be reviewed on its own terms. The stop condition is explicit: if the first real page reads as a `team-recap` variant, the skill has not earned its slot and should be reconsidered as a fourth recap command instead.

Three choices settled during planning shape what actually gets written. The skill opts into recap-core's 20-file diff-hunk budget in pull-request mode, as `eng-recap` does and the other two commands deliberately do not, because teaching how something works needs the real signatures and error paths that commit messages never carry. The mental-model section earns a diagram by default, inverting recap-core's rule that a diagram is earned only where something changed — a page teaching a system that did not change this week is exactly the page most in need of one. And every diagram carries a prose sentence alongside its caption, because recap-core's documented fallback ships diagram blocks as plain text whenever the browser pane is unavailable, so content living only inside an image is content that can disappear.

Two consequences were discovered by reading the tests rather than the source. The plugin's guard at `tests/plugins/test-artifact-tools.sh` hard-codes the four current skill names in its validation loop, and continuous integration runs it — so a fifth skill added without touching that file ships completely untested. And because the plan touches a second plugin's README, that plugin needs its own version bump; any edit under a plugin directory does.

This plan sets `workflow: never`. The renderer would otherwise offer to fan the work out across parallel agents, because it counts seven files across three top-level directories — but the steps are strictly sequential. The tests cannot be written before the skill exists, and the documentation cannot describe a shape that is not settled.

## Steps

1. Write the teaching-frame reference at kit/plugins/artifact-tools/references/teach-framing.md, giving it one fixed section spine used by both sources — the mental model first, then how the thing works today, then one path walked end to end as an ordered list naming the real file, function, or command at each point, then why it is built this way rather than the obvious alternative, then where to look next — plus two page rules and the reviewer test: the mental-model section earns a diagram by default while every other section keeps recap-core's stricter earned-diagram bar, every diagram carries both a caption saying what to look at and a prose sentence conveying the same relationship, and any draft whose section headings merely restate team-recap's fails review. Why: the frame is the only thing separating this skill from the three recap commands that already read these same sources, so it needs a file of its own that can be reviewed and argued with; the diagram prose is not decoration, because recap-core's documented fallback ships diagram blocks as plain text whenever the browser pane is unavailable, so a page whose content lives only inside an image loses that content entirely on that path. Verify: the file exists, `grep -c '^## ' kit/plugins/artifact-tools/references/teach-framing.md` returns at least 5, and the spine is written as one fixed list rather than a per-source branch.
2. Create kit/plugins/artifact-tools/skills/teach-artifact/SKILL.md carrying the name and description frontmatter, the plan-mode guard line copied verbatim, delegation to references/recap-core.md for source resolution and publishing, an opt-in to that reference's 20-file diff-hunk budget for pull-request mode, a link to references/teach-framing.md for the sections, and the five declarations every writer in this plugin makes — audience, sections, favicon, inbox stem `teach-artifact` (or `pr-<number>-teach` in pull-request mode), and republish key `teach-artifact-url:` with an explicit statement that it never writes the four keys belonging to its siblings. Why: this is the skill itself, and delegating both source and publishing to recap-core is exactly what keeps version 1 free of new gathering code; the diff budget is opted into because teaching how something works needs the actual signatures and error paths, which commit messages do not carry, and the key statement prevents a fifth writer from republishing over a sibling's page, since all five share one record per session. Verify: `bash tests/plugins/test-exitplanmode-guard.sh` and `bash tests/plugins/test-description-budget.sh` both exit 0, and `grep -q 'teach-artifact-url:' kit/plugins/artifact-tools/skills/teach-artifact/SKILL.md` succeeds.
3. Extend tests/plugins/test-artifact-tools.sh to cover the new skill: add `teach-artifact` to the loop that validates skill frontmatter, add it to the loop that asserts the secret-scanning gate is documented before publishing, correct the header comment and any message that says four skills, add an assertion that the file claims `teach-artifact-url:` and does not claim any sibling's key as its own, and add an assertion that parses the heading list out of references/teach-framing.md and fails if it matches the section list in commands/team-recap.md. Why: this guard runs in continuous integration and currently hard-codes the four existing skill names, so without this change the new skill ships with no test coverage at all while the suite still reports green; the heading comparison turns the single largest risk in this work — a teaching page that silently degrades into a second team-recap — into something the build catches instead of something a reviewer has to notice. Verify: `bash tests/plugins/test-artifact-tools.sh` exits 0, temporarily renaming the new SKILL.md makes it exit non-zero with a message naming teach-artifact, and temporarily pasting team-recap's section list into teach-framing.md makes it exit non-zero on the heading comparison.
4. Update kit/plugins/artifact-tools/README.md with a teach-artifact row in the Features table, a matching line in the Usage block showing what a user types to trigger it, and the one-line boundary statement that write-guide produces long-form Markdown you keep in the repository while teach-artifact produces a shareable page. Why: the README's generated-looking tables are how someone choosing between five similar skills decides, and the boundary statement is what stops this skill and write-guide from being read as duplicates. Verify: `grep -q 'teach-artifact' kit/plugins/artifact-tools/README.md` succeeds and the Features table shows five skill rows.
5. Add the CHANGELOG entry for 1.12.0 in kit/plugins/artifact-tools/CHANGELOG.md describing the new skill, and raise the artifact-tools version from 1.11.0 to 1.12.0 in .claude-plugin/marketplace.json only. Why: a new skill is a minor version change under this repository's rules, a continuous-integration guard fails any pull request whose version does not exceed the base branch, and setting a version inside the plugin's own manifest would silently override the marketplace value. Verify: `git fetch origin && BASE_REF=main node scripts/check-plugin-versions.mjs` exits 0 and reports artifact-tools at 1.12.0.
6. Add the same one-line boundary statement to kit/plugins/social-media-tools/README.md pointing readers from write-guide toward teach-artifact when they want a shareable page, and raise social-media-tools from 2.22.0 to 2.22.1 in .claude-plugin/marketplace.json. Why: the boundary only works if it is stated on both sides, and any edit inside a plugin directory requires that plugin's own version bump or the version guard fails the pull request. Verify: `git fetch origin && BASE_REF=main node scripts/check-plugin-versions.mjs` exits 0 and reports both plugins above their base-branch versions.

## Files

- kit/plugins/artifact-tools/references/teach-framing.md (new) — the fixed teaching section spine, the diagram and walkthrough rules, and the reviewer test that keeps it distinct from team-recap
- kit/plugins/artifact-tools/skills/teach-artifact/SKILL.md (new) — the skill, its five declarations, and its delegation to recap-core
- tests/plugins/test-artifact-tools.sh (modified) — extend both validation loops to cover a fifth skill and assert republish-key exclusivity
- kit/plugins/artifact-tools/README.md (modified) — Features row, Usage line, and the boundary statement
- kit/plugins/artifact-tools/CHANGELOG.md (modified) — the 1.12.0 entry
- .claude-plugin/marketplace.json (modified) — artifact-tools to 1.12.0 and social-media-tools to 2.22.1
- kit/plugins/social-media-tools/README.md (modified) — the other half of the boundary statement

## Tests

Tier 1 — This plan creates and modifies files the plugin runtime and the test suite both load
- Objective: the plugin ships a working fifth skill that teaches rather than recaps. File: tests/plugins/test-artifact-tools.sh; Type: smoke; Asserts: five skills validate against their real frontmatter, teach-artifact documents the blocking secret-scanning gate before it publishes, and teach-artifact claims teach-artifact-url: without claiming any sibling writer's key; Run: bash tests/plugins/test-artifact-tools.sh
- Unit: the teaching spine never collapses into a second recap. File: tests/plugins/test-artifact-tools.sh; Targets: the heading list parsed from references/teach-framing.md against the section list in commands/team-recap.md; Key cases: identical heading lists fail the build, and a spine missing the mental-model section fails
- Unit: skill description stays inside the discovery budget. File: tests/plugins/test-description-budget.sh; Targets: the description frontmatter in teach-artifact/SKILL.md; Key cases: 200 characters total or fewer, first sentence 80 characters or fewer
- Unit: the plan-mode guard is present and exact. File: tests/plugins/test-exitplanmode-guard.sh; Targets: the verbatim guard line in teach-artifact/SKILL.md; Key cases: the exact string is present, and prose paraphrasing it does not satisfy the check
- Unit: no documented command carries a shell expansion. File: tests/plugins/test-no-shell-expansion.sh; Targets: every command written into teach-artifact/SKILL.md and teach-framing.md; Key cases: no braced or bare variable expansion in command position, since the harness rejects those before any permission rule is consulted
- Integration: both touched plugins clear the version guard. File: scripts/check-plugin-versions.mjs; Targets: the artifact-tools and social-media-tools entries in marketplace.json; Key cases: each version exceeds the value on the base branch, and neither plugin manifest carries a version key of its own

## Acceptance Criteria

- [ ] `bash tests/plugins/test-artifact-tools.sh` exits 0, and its skill-validation loop names teach-artifact alongside the original four
- [ ] Renaming kit/plugins/artifact-tools/skills/teach-artifact/SKILL.md makes that same guard exit non-zero with a message naming teach-artifact
- [ ] `bash tests/plugins/test-description-budget.sh`, `bash tests/plugins/test-exitplanmode-guard.sh`, and `bash tests/plugins/test-no-shell-expansion.sh` each exit 0
- [ ] `git fetch origin && BASE_REF=main node scripts/check-plugin-versions.mjs` exits 0 with artifact-tools at 1.12.0 and social-media-tools at 2.22.1
- [ ] teach-artifact/SKILL.md names `teach-artifact-url:` as the key it writes, and names the four sibling keys only in the sentence forbidding itself from writing them
- [ ] The artifact-tools README Features table lists five skills, and both plugin READMEs carry the one-line boundary statement distinguishing write-guide from teach-artifact
- [ ] `bash tests/plugins/test-artifact-tools.sh` exits non-zero when team-recap's section list is pasted into teach-framing.md, proving the overlap guard is executable rather than advisory
- [ ] teach-framing.md states that the mental-model section earns a diagram by default, and that every diagram carries both a caption and a prose sentence conveying the same relationship

## Verification

Load the plugin locally with `claude --plugin-dir ./kit/plugins/artifact-tools` and ask it to publish a page teaching how this session's work fits together. Confirm three things in order: that `teach-artifact` activates rather than `session-artifact`, that the run reports the blocking secret-scanning gate's result before anything is published, and that the resulting page's headings come from teach-framing.md rather than matching team-recap's section list. That last check is the one that proves the objective — a page whose sections mirror team-recap's means the skill is a recap wearing a new name, and the plan has not succeeded regardless of what the tests say.

Then make the same request a second time. Read the record under `docs/plans/sessions/` and confirm the skill republished to the URL stored in `teach-artifact-url:` rather than minting a new link, and that `artifact-url:`, `eng-artifact-url:`, `team-artifact-url:`, and `product-artifact-url:` in that same record are byte-for-byte unchanged.

Finally run the full guard set from the repository root and confirm every command exits 0: `bash tests/plugins/test-artifact-tools.sh`, `bash tests/plugins/test-description-budget.sh`, `bash tests/plugins/test-exitplanmode-guard.sh`, `bash tests/plugins/test-no-shell-expansion.sh`, and `git fetch origin && BASE_REF=main node scripts/check-plugin-versions.mjs`.

## Next Steps

- Add a third source to teach-artifact: a skill or plugin directory
  Version 1 deliberately reuses only the session and pull-request modes recap-core already provides. Teaching how a skill works is the source with no equivalent anywhere in the kit, and step 1's reference is where the extension seam is documented.
  ```text
  In the agentics repo, extend the teach-artifact skill at kit/plugins/artifact-tools/skills/teach-artifact/SKILL.md to accept a third source: a path to a plugin skill directory such as kit/plugins/<plugin>/skills/<skill>/. When given one, read that skill's SKILL.md, its frontmatter, and every reference it links to, then publish a teaching page explaining how the skill activates, what its workflow does, and which references it loads at which step. Reuse the existing publishing path and the teach-artifact-url: republish key unchanged. Extend tests/plugins/test-artifact-tools.sh to assert the third source mode is documented. Bump artifact-tools by a minor version in .claude-plugin/marketplace.json and add a CHANGELOG.md entry. Before reporting done, run bash tests/plugins/test-artifact-tools.sh and git fetch origin && BASE_REF=main node scripts/check-plugin-versions.mjs, and confirm both exit 0.
  ```
- Wish list: let teach-artifact read an existing published artifact and produce a teaching companion to it
  Speculative. Would let a diff-artifact review page gain a matching explainer at a second URL, sharing nothing but the subject.
  ```text
  In the agentics repo, explore whether the teach-artifact skill at kit/plugins/artifact-tools/skills/teach-artifact/SKILL.md could take a published claude.ai artifact URL as a source, fetch it with WebFetch, and publish a companion teaching page under its own republish key. Report whether the fetched page carries enough structure to teach from, or whether the original source material is required. Do not implement anything; deliver the finding as a short written recommendation naming the specific obstacle if there is one.
  ```

## Resources

- kit/plugins/artifact-tools/references/recap-core.md — the 276-line shared engine this skill delegates to; its Source, Page build, Destination, and Republish record sections are what version 1 reuses unchanged
- tests/plugins/test-artifact-tools.sh — the continuous-integration guard whose hard-coded four-skill loop step 3 extends
- tests/plugins/test-recap-command-dedupe.sh — the guard proving each recap writer owns exactly one republish key; the reason step 2 states key exclusivity explicitly
- .claude/rules/plugin-patterns.md — the repository's rules for allowed-tools, the verbatim plan-mode guard, and the three-part skill description budget
- .claude/rules/marketplace.md — version-bump rules and the reason a version key must never appear in a relative-path plugin manifest
- docs/prompts/proposal-add-teach-artifact-skill.md — the proposal this plan was authored from, holding the locked decisions and the measured comparison

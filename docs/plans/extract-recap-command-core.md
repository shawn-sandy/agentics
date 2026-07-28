---
status: todo
type: refactor
created: 2026-07-27
effort: medium
glance: Three artifact-tools recap commands say the same thing three times — eng-recap and team-recap alone share 1,568 identical words. Pulling the shared workflow into one reference file leaves each command as a short framing brief, and we will know it worked when the three commands share fewer than 50 identical lines while each still publishes to its own artifact URL key.
---

# Plan: Say the recap workflow once, not three times

## Objective

Extract the shared recap workflow from `eng-recap`, `team-recap`, and
`product-doc` into a single `references/recap-core.md`, reducing each command
to the framing that actually differs: audience, sections, and republish key.

## Context

The Claude 5 context-engineering guidance names redundancy across context
layers as an anti-pattern: say a thing once, in the place that owns it. The
three `artifact-tools` recap commands violate this at scale. Measured across
the three files:

- `eng-recap` and `team-recap` share 168 identical lines / 1,568 words
- all three share 68 identical lines / 417 words
- combined they are 6,190 words

They are three framings of one workflow — gather the session or PR, scrub it,
build the page, publish, record the republish URL. Only the audience, the
section list, the plain-language rule, and the republish frontmatter key
genuinely differ.

The republish keys are the sharp edge. Four distinct keys live on the same
shared session record, and each of the three commands owns exactly one of
them: `session-artifact` owns `artifact-url:`, `eng-recap` writes
`eng-artifact-url:`, `team-recap` writes `team-artifact-url:`, and
`product-doc` writes `product-artifact-url:`. All three command files also
*name* `artifact-url:` in a prohibition — `product-doc.md` says "Never write
`artifact-url:`" precisely because that key belongs to `session-artifact`.

Collapsing the commands must not collapse the keys: two commands writing the
same key would silently overwrite each other's published artifact, and any
command reassigned to `artifact-url:` would clobber the reviewer-first session
recap. Step 3 pins each command's own key explicitly, and Step 4 verifies the
*assignments* rather than merely counting key names — a distinction that
matters because the prohibition text mentions keys a command must not write.

`artifact-tools` is the only plugin touched, so exactly one
`marketplace.json` version bump applies (minor — behavior preserved, structure
changed).

## Files

- kit/plugins/artifact-tools/references/recap-core.md (new) — the shared gather/scrub/build/publish workflow
- kit/plugins/artifact-tools/commands/eng-recap.md (modified) — reduce to engineer framing + `eng-artifact-url:`
- kit/plugins/artifact-tools/commands/team-recap.md (modified) — reduce to whole-team framing + its key
- kit/plugins/artifact-tools/commands/product-doc.md (modified) — reduce to product framing + `product-artifact-url:`
- .claude-plugin/marketplace.json (modified) — bump artifact-tools minor version
- kit/plugins/artifact-tools/CHANGELOG.md (modified) — record the refactor
- tests/plugins/test-recap-command-dedupe.sh (new) — objective test
- .github/workflows/check-plugin-versions.yml (modified) — wire the new test

## Steps

1. Diff the three command files pairwise and write the shared-line inventory to a scratch file, separating lines that are genuinely shared workflow from lines that only look identical (shared section *headings* whose content differs per audience). Why: collapsing a line that reads the same but means something different per audience is how a refactor silently changes behavior. Verify: the scratch file classifies every one of the 68 all-three shared lines as either "shared workflow" or "coincidental match".
2. Write `kit/plugins/artifact-tools/references/recap-core.md` containing only the Step 1 "shared workflow" lines — PR and session gathering including the 20-file diff cap and `--name-only` fallback, the blocking `security-scrub` gate, page build, publish, local-HTML fallback, and the republish-record protocol parameterised by key name. Why: one file that owns the workflow means a fix to the scrub gate lands in all three commands at once instead of one-third of the time. Verify: `recap-core.md` exists and contains no audience-specific words (`engineer`, `stakeholder`, `glossary`).
3. Rewrite each of the three commands to state its audience, its section list, its plain-language posture, and its republish key explicitly, then delegate the workflow to `references/recap-core.md`. Why: the differences are the whole reason three commands exist, so they are what the command file should contain. Verify: each command file is under 500 words, names its own republish key, and links `references/recap-core.md`.
4. Confirm each command still writes its own republish key and still carries the `artifact-url:` prohibition, checking assignments per file rather than counting key names across files. Why: a shared key silently overwrites another command's published artifact, and a command reassigned to `artifact-url:` would clobber the session recap. Verify: run the three per-file greps below — each prints its own key and nothing else — then confirm all three files still match `Never write .artifact-url:`; note that a bare `grep -o ... commands/*.md | sort -u` cannot prove this, because grep prefixes each match with its filename and the prohibition text names keys the command must *not* write (that form returns 9 lines today, not 3).
5. Bump `artifact-tools` to the next minor version in `.claude-plugin/marketplace.json` and add a `kit/plugins/artifact-tools/CHANGELOG.md` entry describing the extraction. Why: any edit under `kit/plugins/<name>/` requires a version bump higher than main, per repo convention. Verify: `BASE_REF=main node scripts/check-plugin-versions.mjs` exits 0.
6. Write `tests/plugins/test-recap-command-dedupe.sh` asserting the three commands share fewer than 50 identical lines, each is under 500 words, `references/recap-core.md` exists, and — per file, not across files — that `eng-recap.md` writes `eng-artifact-url:`, `team-recap.md` writes `team-artifact-url:`, `product-doc.md` writes `product-artifact-url:`, and none of the three assigns `artifact-url:` to itself. Why: without a check, the next feature added to all three commands re-introduces the duplication. Verify: `bash tests/plugins/test-recap-command-dedupe.sh` exits 0; pasting 60 lines of recap-core back into two commands makes it exit 1.
7. Add the new test to `.github/workflows/check-plugin-versions.yml`. Why: local-only tests stop running. Verify: the workflow names `test-recap-command-dedupe.sh` and parses as valid YAML.

## Tests

Tier 1 — This plan changes application code
- Objective: the three recap commands no longer duplicate the workflow, and each still targets its own artifact URL. File: tests/plugins/test-recap-command-dedupe.sh; Type: smoke; Asserts: pairwise identical lines across the three commands are under 50, each command is under 500 words, `references/recap-core.md` exists, and each command file writes its own key (`eng-artifact-url:` / `team-artifact-url:` / `product-artifact-url:`) with none assigning `artifact-url:` to itself; Run: bash tests/plugins/test-recap-command-dedupe.sh
- Integration: each command still produces a publishable recap. File: manual per Verification; Targets: /artifact-tools:eng-recap, :team-recap, :product-doc; Key cases: run each against the same merged PR and confirm three distinct artifacts with audience-appropriate sections

## Acceptance Criteria

- [ ] `kit/plugins/artifact-tools/references/recap-core.md` exists and holds the shared workflow
- [ ] Each of the three command files is under 500 words
- [ ] Pairwise identical lines between any two commands number fewer than 50
- [ ] `eng-recap.md` writes `eng-artifact-url:`, `team-recap.md` writes `team-artifact-url:`, and `product-doc.md` writes `product-artifact-url:`
- [ ] No command assigns `artifact-url:` to itself; all three retain the prohibition naming it as `session-artifact`'s key
- [ ] Each command still names its audience, its section list, and its republish key
- [ ] `BASE_REF=main node scripts/check-plugin-versions.mjs` exits 0
- [ ] `bash tests/plugins/test-recap-command-dedupe.sh` exits 0
- [ ] No plugin other than `artifact-tools` is modified

## Verification

Run `bash tests/plugins/test-recap-command-dedupe.sh` and confirm exit 0, then
paste 60 lines of `recap-core.md` into two of the commands, re-run, and confirm
exit 1 before reverting — proving the check detects regression rather than
passing unconditionally.

The behavioral check is the one that matters: pick one merged PR and run all
three of `/artifact-tools:eng-recap`, `/artifact-tools:team-recap`, and
`/artifact-tools:product-doc` against it. Confirm three separate artifacts
publish, that each carries the sections its audience expects (eng-recap has
architecture and no glossary; team-recap has a glossary and diagrams;
product-doc has features and known gaps), and that each writes its own
republish key on the shared session record without clobbering the others. Then
re-run one of the three and confirm it republishes to the *same* URL rather
than minting a new one.

Finally run `git diff --stat` and confirm no plugin outside `artifact-tools`
appears, other than the shared test and workflow files.

## Next Steps

- Apply the same extraction to the share-* skill family
  `social-media-tools` has eleven `share-*` skills that repeat an eleven-line template-locating shell block verbatim; the same core-plus-framing shape fits.
  ```text
  In the agentics repo, the social-media-tools plugin has eleven share-* skills
  that each repeat the same TEMPLATES_DIR locating block (the find ~/.claude
  -path "*/social-media-tools/templates" sequence) verbatim. Extract it to
  kit/plugins/social-media-tools/references/locate-templates.md and have each
  share-* SKILL.md reference it instead. Bump the social-media-tools minor
  version in .claude-plugin/marketplace.json and add a CHANGELOG entry. Verify
  by grepping for the literal find command across the skills and confirming it
  appears exactly once, then running one share-* skill end-to-end to confirm it
  still resolves its template directory.
  ```

## Resources

- The new rules of context engineering for Claude 5 generation models — https://claude.com/blog/the-new-rules-of-context-engineering-for-claude-5-generation-models — Rule 4, eliminating repetition across context layers
- CLAUDE.md, artifact-tools row — documents the four distinct republish keys on the shared session record that Step 4 must preserve

---
status: completed
type: fix
created: 2026-07-15
modified: 2026-07-15
repo-name: agentics
---

# Plan: Fix the artifact title mechanism

## Context

[artifact-tools 1.1.0](../../kit/plugins/artifact-tools/CHANGELOG.md) added
`references/titles.md` as the single source of artifact title rules, and told
authors to set the title "as the page's `<title>` for HTML sources, or as
frontmatter `title:` for Markdown sources." The second half is false.

The Artifact renderer does not parse YAML frontmatter. Publishing a Markdown
source emits the frontmatter block as visible body text — the opening `---`
becomes an `<hr>` and the YAML becomes a setext `<h2>` — and, with no `<title>`
in the document, the artifact title falls back to the source's filename,
extension included.

The failure is invisible from inside the rules: every title rule in `titles.md`
can be satisfied and the published title is still wrong. It surfaced only when a
`session-artifact` recap published as `add-plugin-version-guard-session.md` with
its YAML on the page. `session-artifact` is the only skill affected —
`diff-artifact`, `plan-artifact`, and `prompt-artifact` all publish HTML and set
a real `<title>`.

## Objective

Make every artifact-tools skill produce a readable, meaningful title by stating
the one mechanism that works (an HTML `<title>`), switching `session-artifact` to
publish an HTML render, and pinning both with a test so the false claim cannot
return.

## Files to modify

- [references/titles.md](../../kit/plugins/artifact-tools/references/titles.md) — replace the false frontmatter claim.
- [skills/session-artifact/SKILL.md](../../kit/plugins/artifact-tools/skills/session-artifact/SKILL.md) — publish HTML; fix the republish note.
- [CHANGELOG.md](../../kit/plugins/artifact-tools/CHANGELOG.md) — 1.2.1 entry.
- [.claude-plugin/marketplace.json](../../.claude-plugin/marketplace.json) — bump `artifact-tools` to 1.2.1.
- [tests/plugins/test-artifact-titles.mjs](../../tests/plugins/test-artifact-titles.mjs) — new; pins the invariant.
- [.github/workflows/publish-dist.yml](../../.github/workflows/publish-dist.yml) — run the new test.

## Steps

1. **Replace the frontmatter claim in `titles.md`** with the truth: an HTML
   `<title>` is the only mechanism; a Markdown source cannot set its own title and
   falls back to its filename; a `title:` key is a value to carry into a `<title>`.
   - *Why:* This is the root cause. Both downstream defects follow from authors
     trusting a mechanism that does not exist, so fixing only `session-artifact`
     would leave the next Markdown-publishing skill to rediscover the bug.
   - *Verify:* `tests/plugins/test-artifact-titles.mjs` assertions 1–3 pass, and
     all three fail when run against `origin/main`'s copy of the file.

2. **Switch `session-artifact` to publish an HTML render.** Rewrite the Overview
   premise ("publishes the Markdown directly ... at the lowest token cost"), add a
   render step producing one self-contained HTML file with `<title>` taken from
   the frontmatter `title:` and the frontmatter block dropped, and point the
   publish step at the HTML path.
   - *Why:* It is the only skill that publishes Markdown, so it is the only one
     that can never control its own title. The `.md` stays the committed record
     and the home of `artifact-url:`, mirroring how `plan-artifact` already keeps
     a `.md` spec beside published HTML.
   - *Verify:* `test-artifact-titles.mjs` assertions for HTML publishing and the
     dropped Markdown-direct claim pass, and fail against `origin/main`.

3. **Correct the republish note** to require `url` on every republish, not only
   across sessions.
   - *Why:* The render lands on a new scratchpad path each run and a differing
     `file_path` always claims a new URL, so the old "a later session mints a new
     page" framing understates it — a same-session republish rots the link too.
     Observed live: publishing the HTML needed an explicit `url` to hold the URL
     the `.md` already recorded.
   - *Verify:* The `required on every republish` assertion passes, and fails
     against `origin/main`.

4. **Add `tests/plugins/test-artifact-titles.mjs` and wire it into
   `publish-dist.yml`.**
   - *Why:* The false claim shipped once and was invisible to every existing
     check. A grep-level test is weak evidence of prose quality but strong
     evidence of this invariant, which is a fixed string either present or not.
   - *Verify:* `node tests/plugins/test-artifact-titles.mjs` prints `10 passed, 0
     failed`; the step appears in `publish-dist.yml` beside the other plugin tests.

5. **Bump `artifact-tools` to 1.2.1 and add the CHANGELOG entry.**
   - *Why:* Per `.claude/rules/marketplace.md` a fix is a patch, and without the
     bump the daily publish ships a byte-identical tree — the exact silent no-op
     the sibling version guard exists to catch.
   - *Verify:* `marketplace.json` reads `1.2.1`, above `main`'s `1.2.0`, and
     `scripts/check-plugin-versions.mjs` reports no violation for the plugin.

## Tests

> Tier: 1 (code-touching) — `SKILL.md` and `titles.md` are the plugin's runtime
> surface: they are what the model loads and acts on.

### Objective-Verification Test

- **File:** `tests/plugins/test-artifact-titles.mjs`
- **Type:** smoke test
- **Asserts:** the plan's objective directly — that `titles.md` names the HTML
  `<title>` as the only mechanism and no longer prescribes frontmatter, that every
  artifact skill points at the shared rules, and that `session-artifact` publishes
  HTML and requires `url` on republish.
- **Run:** `node tests/plugins/test-artifact-titles.mjs`

*Unit, integration, and E2E sub-sections are omitted: this change alters
instruction files and metadata, adding no functions to unit-test, no module
interactions to integrate, and no user flow a runner can drive. The one behavior
worth asserting — a published artifact's rendered title — requires a live publish
and is covered by the manual verification below.*

## Acceptance Criteria

- [ ] `titles.md` states that a Markdown source cannot set its own title and names the filename fallback.
- [ ] `titles.md` contains no instruction to set a title via frontmatter.
- [ ] `session-artifact` publishes an HTML render; the `.md` remains the committed record and holds `artifact-url:`.
- [ ] `session-artifact` requires `url` on every republish.
- [ ] `diff-artifact`, `plan-artifact`, and `prompt-artifact` are unmodified — they were never affected.
- [ ] `test-artifact-titles.mjs` passes on this branch and every assertion fails against `origin/main`.
- [ ] `artifact-tools` is `1.2.1` in `marketplace.json`, with a matching CHANGELOG entry and no `version` in `plugin.json`.

## Verification

- Run `node tests/plugins/test-artifact-titles.mjs` — expect `10 passed, 0 failed`.
- Re-run each assertion against `git show origin/main:...` — every one must be
  false, proving the tests discriminate rather than pass vacuously.
- Run `git diff --stat` — only the six files above changed; the three unaffected
  skills are untouched.
- End-to-end, requiring a live publish: run `/artifact-tools:session-artifact` on
  a session and confirm the artifact's tab and gallery name is the recap's
  subject in sentence case rather than `<slug>.md`, and that no YAML appears as
  page text. Confirmed manually for this session at the artifact recorded in
  `docs/plans/sessions/add-plugin-version-guard-session.md`.

## Next Steps *(optional)*

- Check the sibling extractor for the same assumption:
  ```text
  kit/plugins/artifact-tools/skills/session-artifact/scripts/export_session.py pre-fills a
  `title:` frontmatter key, and its module docstring records a sync contract with the sibling
  copy in kit/plugins/social-media-tools. artifact-tools 1.2.1 established that frontmatter
  cannot set an artifact title — only an HTML <title> can. Check whether social-media-tools'
  export-session skill (or save-artifact) publishes a Markdown source and would therefore ship
  a filename-derived title with visible YAML, the same defect artifact-tools 1.2.1 fixed. If it
  does, port the fix and bump social-media-tools. If it does not, say so and leave it alone.
  ```

- Reconsider whether the recap should be HTML-native:
  ```text
  artifact-tools' session-artifact currently writes a recap .md under {plansDirectory}/sessions/
  and then renders a separate HTML file to publish, because only HTML can carry an artifact
  <title> while only the .md can carry `artifact-url:` frontmatter. That means the recap content
  is authored once and emitted twice. Evaluate making the .html the single committed record with
  its URL stored in a <meta name="artifact-url"> tag, versus keeping today's .md-record +
  HTML-render split. Weigh: token cost per session export, diff readability of the committed
  record, and whether the plan-filename hook and plans galleries handle .html in that directory.
  Recommend one and explain the tradeoff; do not implement yet.
  ```

---
status: completed
type: feature
created: 2026-07-13
modified: 2026-07-14
issue: https://github.com/shawn-sandy/agentics/issues/392
glance: Teams get live, shareable claude.ai pages for the three things they review most — code diffs, working sessions, and implementation plans — without leaving Claude Code. Done means each skill publishes (or falls back cleanly to local HTML), every published page passed a secret scrub, and a smoke test guards the plugin's structure and marketplace registration.
---

# Plan: Create the artifact-tools plugin — publish diffs, sessions, and plans as claude.ai artifacts

## Objective

Ship a new `artifact-tools` plugin in `kit/plugins/` with three skills — `diff-artifact`, `session-artifact`, and `plan-artifact` — that turn branch diffs, session recaps, and implementation plans into live claude.ai artifact pages, with a scrub gate before every publish and a local-HTML fallback when publishing is unavailable.

## Context

Claude Code artifacts (per the official docs at code.claude.com/docs/en/artifacts) are self-contained pages published to a private claude.ai URL that update in place on republish. They carry hard constraints the skills must respect: a strict Content Security Policy (no external requests — everything inlined), a 16 MiB rendered-size cap, single-page only (in-page anchors, no relative links), and `.html`/`.md` sources — Markdown renders as styled HTML at the lowest token cost. Publishing requires a claude.ai login on Pro or higher; sharing beyond the author is Team/Enterprise only, so the fallback path is not an edge case — on Pro/Max it is how content actually reaches teammates.

The kit already owns most of the generation work: `social-media-tools:export-session` converts session JSONL to Markdown, `social-media-tools:security-scrub` produces a structured SCRUB RESULT gate, `social-media-tools:save-artifact` publishes HTML into the GitHub Pages artifacts gallery, and `plan-agent` plans are already self-contained HTML. This plugin adds the missing publish endpoints, plus the one genuinely new generator: an annotated diff walkthrough. A publish is external sharing, so every skill scrubs before it ships.

One mechanic drives the design: updating an artifact from a later session requires its URL — without it, a new session mints a new page. Each skill therefore writes the returned URL into the source file's frontmatter as `artifact-url:` so any future session can republish to the same link.

## Files

- kit/plugins/artifact-tools/.claude-plugin/plugin.json (new) — plugin manifest; name, description, keywords, homepage; no version key
- kit/plugins/artifact-tools/README.md (new) — overview, features, installation, usage, structure
- kit/plugins/artifact-tools/CHANGELOG.md (new) — 1.0.0 entry
- kit/plugins/artifact-tools/skills/diff-artifact/SKILL.md (new) — annotated diff walkthrough artifact
- kit/plugins/artifact-tools/skills/session-artifact/SKILL.md (new) — session recap artifact with learnings
- kit/plugins/artifact-tools/skills/session-artifact/scripts/export_session.py (new) — bundled transcript extractor, copied from social-media-tools so the plugin has no install-order dependency
- kit/plugins/artifact-tools/skills/plan-artifact/SKILL.md (new) — publish and republish plan HTML
- .claude-plugin/marketplace.json (modified) — register artifact-tools at 1.0.0
- tests/plugins/test-artifact-tools.sh (new) — structural smoke test

## Steps

1. Scaffold `kit/plugins/artifact-tools/` with `.claude-plugin/plugin.json` (name, description, author, license, keywords, homepage pointing at the plugin's directory per repo convention, repository — and no `version` key), plus `README.md` and `CHANGELOG.md` Why: the manifest is what Claude Code discovers, and for relative-path plugins the version lives only in marketplace.json — a version key here would silently override it Verify: `python3 -m json.tool kit/plugins/artifact-tools/.claude-plugin/plugin.json` exits 0 and `grep -c '"version"'` on the file returns 0.
2. Author `skills/diff-artifact/SKILL.md`: resolve the diff source (current branch vs the default branch by default; a commit range argument; or a PR number via `gh pr diff <n>`, degrading gracefully to branch mode with a clear message when gh or the GitHub remote is missing), run `social-media-tools:security-scrub` on the diff and hard-stop on findings with no override, build one self-contained annotated-diff HTML page — sticky changed-files sidebar with add/del counts anchor-linked to each file section, per-hunk margin annotations explaining the reasoning, severity coding that pairs each color with a text label (critical/warn/note) plus a legend, adaptive light/dark palettes via prefers-color-scheme, and a cap-and-summarize policy where files beyond a per-file annotation budget render as one-line summary rows so the page stays under the 16 MiB artifact cap — then publish via the `Artifact` tool, save the page in the `.claude/artifacts/` inbox with the returned URL recorded as an `artifact-url:` comment, and on publish failure keep the local HTML and offer `social-media-tools:save-artifact` Why: an annotated diff walkthrough is the one artifact type nothing in the kit produces today, and a diff published to claude.ai is external sharing so the scrub gate must be blocking, not advisory Verify: the SKILL.md frontmatter carries `name`, a three-part description under 200 chars, and `allowed-tools` including Bash, Read, Write, Glob, Skill, Artifact, AskUserQuestion, ToolSearch, ExitPlanMode; the body names the blocking scrub gate, the PR-mode degradation, the cap-and-summarize policy, the sidebar/theme/severity-legend page requirements, the fallback path, and the ExitPlanMode self-bootstrap.
3. Author `skills/session-artifact/SKILL.md` plus a bundled `scripts/export_session.py` (copied from social-media-tools' export-session skill so artifact-tools works standalone with no install-order dependency): locate the session transcript using the same JSONL lookup conventions (explicit path or session ID, else newest transcript for the project), run the bundled script to extract turns, then write the recap in reviewer-first order — Summary, Decisions (with rationale), Learnings (approaches tried and abandoned, gotchas discovered), Files touched — scrub it, save it under `{plansDirectory}/sessions/` so the recorded `artifact-url:` frontmatter is committed and survives for republish, and publish the `.md` directly as an artifact (Markdown sources render as styled pages at the lowest token cost); when publishing is unavailable the saved file is itself the fallback deliverable Why: session recaps are the team-review deliverable the user asked for, and bundling the extractor trades a small duplicate for zero cross-plugin coupling Verify: frontmatter and body pass the same checks as step 2, the script exists beside the skill, and the body defers transcript parsing to the bundled script rather than reading raw JSONL into context.
4. Author `skills/plan-artifact/SKILL.md`: accept a plan `.html` path (plan-agent output is already self-contained and CSP-compliant), read `artifact-url:` from the sibling `.md` spec's frontmatter and pass it to the `Artifact` tool's `url` parameter when present so republishing hits the same page, otherwise publish fresh and write the new URL back into the spec frontmatter (the renderer preserves unknown keys), and document the live-update loop — republish after progress edits so viewers see steps check off at the same link Why: plan HTML needs zero generation work, so this skill is a thin publish wrapper whose whole value is stable URLs across sessions Verify: the body documents both flows (first publish writes `artifact-url:`; republish reads it) and warns never to hand-edit the plan HTML, matching plan-agent's markdown-first rule.
5. Register `artifact-tools` in `.claude-plugin/marketplace.json` at version 1.0.0 (source `git-subdir`, path `kit/plugins/artifact-tools`, category `development`, specific tags like `artifacts`, `diff-review`, `session-recap`, `plan-publishing`) and write the matching 1.0.0 CHANGELOG entry Why: unregistered plugins are invisible to `/plugin install`, and the repo convention is one marketplace entry plus a CHANGELOG line per shipped change Verify: `python3 -m json.tool .claude-plugin/marketplace.json` exits 0 and the settings-hook JSON validation reports no errors after the edit.
6. Write `tests/plugins/test-artifact-tools.sh` following the existing `test-save-artifact.sh` pattern: assert plugin.json is valid JSON without a version key, all three SKILL.md files exist with `name`, `description`, and `allowed-tools` frontmatter, the bundled `export_session.py` exists, the marketplace entry exists at 1.0.0, and the diff/session skill bodies contain the scrub gate, cap-and-summarize, and fallback wording Why: structural smoke tests are this repo's regression net for plugins — they catch manifest drift and missing frontmatter before a release Verify: `bash tests/plugins/test-artifact-tools.sh` exits 0 on the finished plugin and exits non-zero when a required frontmatter line is deleted in a scratch copy.

## Tests

Tier 1 — the steps create plugin skill files and modify the marketplace manifest, which are this repo's application surface
- Objective: the artifact-tools plugin is complete, valid, and installable. File: tests/plugins/test-artifact-tools.sh; Type: smoke; Asserts: manifest valid with no version key, three skills present with required frontmatter, marketplace registration at 1.0.0, scrub gate and fallback documented in the diff and session skills; Run: bash tests/plugins/test-artifact-tools.sh

## Acceptance Criteria

- [ ] `claude --plugin-dir ./kit/plugins/artifact-tools` loads the plugin and lists the diff-artifact, session-artifact, and plan-artifact skills
- [ ] Every SKILL.md has `name`, a three-part description of 200 characters or fewer, and an `allowed-tools` line that includes ToolSearch alongside every deferred tool it calls
- [ ] `.claude-plugin/marketplace.json` contains an `artifact-tools` entry at version 1.0.0 and the file parses as valid JSON
- [ ] `kit/plugins/artifact-tools/.claude-plugin/plugin.json` has no `version` key
- [ ] The diff-artifact and session-artifact skill bodies make the security-scrub check a blocking gate before any publish
- [ ] All three skill bodies document the local-HTML fallback and the `artifact-url:` frontmatter write for cross-session republish
- [ ] The diff-artifact body specifies the cap-and-summarize size policy, sticky file sidebar, adaptive light/dark theme, and severity labels with a legend
- [ ] session-artifact bundles its own `export_session.py` and does not require social-media-tools to be installed
- [ ] `bash tests/plugins/test-artifact-tools.sh` exits 0

## Verification

Load the plugin with `claude --plugin-dir ./kit/plugins/artifact-tools` and confirm all three skills appear. Invoke `diff-artifact` on a branch with committed changes: it must run the scrub first, produce one self-contained HTML page, attempt the Artifact publish, and either report a claude.ai URL (recorded in the file) or fall back with a clear message and the local path. Invoke `session-artifact` with no arguments and confirm it finds the newest project transcript and produces a recap containing a Learnings section. Invoke `plan-artifact` on an existing plan under `docs/plans/` twice: the first run writes `artifact-url:` into the spec frontmatter, the second reads it and republishes to the same URL. Finally run the smoke test and confirm exit 0.

## Next Steps

- Wire published artifacts into the media-library gallery
  Fallback-saved pages already flow through save-artifact; published claude.ai URLs could be indexed too.
  ```text
  In the agentics repo, extend kit/plugins/artifact-tools so each successful
  publish also appends the artifact title and claude.ai URL to a small index
  under docs/artifacts/ (or the existing gallery), so published-but-private
  artifacts are discoverable later. Bump the artifact-tools version in
  .claude-plugin/marketplace.json and add a CHANGELOG entry.
  ```
- Dashboard artifact skill (wish list)
  Speculative until a recurring data source exists in this repo.
  ```text
  In the agentics repo, add a dashboard-artifact skill to
  kit/plugins/artifact-tools that renders a metrics dashboard artifact from a
  user-supplied data file (CSV or JSON), summarizing rather than inlining
  large datasets per the 16 MiB artifact cap. Register the new skill, bump
  the minor version in .claude-plugin/marketplace.json, and add a CHANGELOG
  entry.
  ```

## Resources

- Claude Code artifacts documentation — https://code.claude.com/docs/en/artifacts (constraints, sharing model, update-by-URL mechanic)
- kit/plugins/social-media-tools/skills/save-artifact/SKILL.md — fallback publishing pattern and ExitPlanMode bootstrap convention
- kit/plugins/social-media-tools/skills/export-session/SKILL.md — transcript lookup and script-based conversion conventions
- kit/plugins/social-media-tools/skills/security-scrub/SKILL.md — SCRUB RESULT gate contract
- .claude/rules/plugin-patterns.md and .claude/rules/skill-authoring.md — frontmatter, description format, deferred-tool rules

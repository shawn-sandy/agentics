---
status: completed
modified: 2026-08-26
type: feature
created: 2026-08-26
repo: agentics
artifact-url: https://claude.ai/code/artifact/5945dfdd-315d-4365-994a-bad8c07c0dea
hub-artifact-url: https://claude.ai/code/artifact/962de29f-bd92-431e-9707-1717be620827
glance: Plans already publish as artifacts, but their prototypes and companion HTML stay local files nobody can open from the shared link. A hub artifact bundles plan and related pages into one tabbed, republishable URL; done means one link shows the plan and its prototype together, and republishing keeps that link stable.
---

# Plan: Bundle a plan and its related HTML into one hub artifact

## Objective

Add a `publish-hub` skill to plan-agent that bundles a plan and its related
HTML files (prototype, extra companion pages) into a single self-contained
hub artifact on claude.ai, published to a stable URL recorded as
`hub-artifact-url:` in the spec frontmatter.

## Context

Since plan-agent 9.6 the `implementation-plan` skill publishes the rendered
plan as a claude.ai artifact by default — no local HTML unless `--file`. But
a plan's related HTML stays local: the prototype lives at
`docs/prototypes/<slug>.html` (frontmatter `prototype:` key) and companion
docs from `markdown-to-html` live wherever they were written. Someone opening
the shared plan URL cannot reach any of them.

The obvious route — uploading related HTML as artifact *assets* — is blocked
twice: the `assets` capability is not in this account's artifact runtime
roster (`artifact`, `downloads`, `mcp`, `self` only), and even where assets
exist the accepted types are image/video/PDF/font/text, not HTML. Assets are
files a page references, not sub-pages a viewer navigates to.

So the hub is a bundling problem, not a capability problem: one artifact page
with a tab bar, each related document embedded whole via `<iframe srcdoc>`.
The artifact CSP allows this — everything is inline, nothing external is
fetched. The alternative (one artifact per file, cross-linked — the pattern
`design` uses) was considered and rejected for this feature: N URLs to keep
straight and a republish loop touching every member, against the single
stable URL a hub gives.

## Decisions

- The hub publishes under a new `hub-artifact-url:` frontmatter key, never
  `artifact-url:` — a plain plan republish from `implementation-plan` Step 7
  or `artifact-tools:plan-artifact` would silently clobber a hub sharing that
  key; a separate key is additive and touches no existing skill. The renderer
  preserves unknown frontmatter keys, so it survives rebuilds.
- Every embedded document, the plan included, rides in an `<iframe srcdoc>`
  panel — uniform isolation, so the plan's own CSS/JS never collides with the
  shell or the prototype, and prototypes keep their inlined JavaScript.
- The design canvas (`design:` key) becomes an external-link tab, never an
  embedded one — it is already its own artifact with a live editor, and the
  artifact CSP blocks framing external URLs anyway.
- Related files resolve only from frontmatter keys that already exist
  (`prototype:`, `design:`) plus explicit `--extra <path>` arguments — no
  directory scanning, no discovery heuristics.
- The bundler is a plan-agent script, not an artifact-tools one — it imports
  the renderer's `scripts/lib/plan-spec.mjs` frontmatter parser and renders
  via `build-plan-html.mjs`, and a cross-plugin file dependency is worse than
  housing publish logic beside the renderer.
- Command-named activation only (`/plan-agent:publish-hub`), no hook —
  publishing must never fire ambiently.
- The `assets` capability is not designed around. When it appears in the
  account roster its right use is images (asset URLs instead of base64 data
  URIs), noted in Next Steps and nowhere else.

## Steps

1. [x] Create `kit/plugins/plan-agent/scripts/build-plan-hub.mjs` accepting
   `<spec>.md -o <out>.html [--extra <path>]... [--max-bytes <n>]`: parse
   frontmatter with `scripts/lib/plan-spec.mjs`, render the plan through
   `build-plan-html.mjs`, collect related HTML from the `prototype:` key plus
   `--extra` paths, and emit one theme-aware tab shell embedding each
   document in an `<iframe srcdoc>` (plan tab first, `design:` as an
   external-link tab), escaping `&` and `"` in every srcdoc value and
   exiting 1 naming the offending file when output would exceed the cap
   (default 15 MB, under the 16 MB artifact limit) or when the spec or a
   named related file is unreadable. Why: the artifact CSP requires one
   self-contained page, and entity-escaping plus the size guard belong in
   deterministic code, never in model output. Verify: run it against a
   fixture spec plus prototype; the output opens in a browser with working
   tabs and an interactive prototype, and a tiny `--max-bytes` run exits 1
   naming the file.
2. [x] Add `kit/plugins/plan-agent/bin/plan-agent-hub`, copying the
   `exec node "$(dirname "$0")/../scripts/..."` wrapper pattern from
   `bin/plan-agent-render` verbatim. Why: skills must invoke bin scripts by
   bare name — a documented `node "${CLAUDE_PLUGIN_ROOT}/..."` command never
   runs because the Bash tool rejects `${VAR}` expansion. Verify: invoking
   the wrapper by absolute path with the fixture arguments produces
   byte-identical output to calling the `.mjs` directly.
3. [x] Write `tests/plugins/test-build-plan-hub.mjs`: build a fixture spec and a
   quote-heavy prototype in a temp directory removed on exit, then assert the
   hub contains the plan title and the escaped prototype markup in separate
   tab panels, that `&`/`"` survive the srcdoc round trip, and that a missing
   spec and a `--max-bytes` overflow each exit 1 with the path named. Why:
   the bundler's contract (tabs, escaping, size guard, exit codes) is what
   every future publish depends on, and each assertion must fail if the
   behaviour regresses. Verify: `node tests/plugins/test-build-plan-hub.mjs`
   exits 0, and temporarily breaking the escaper makes it exit non-zero.
4. [x] Write `kit/plugins/plan-agent/skills/publish-hub/SKILL.md` — plan-mode
   guard line first, three-part description within the 200-char budget,
   `allowed-tools: Read, Edit, Glob, Bash, AskUserQuestion, SendUserFile,
   ToolSearch, ExitPlanMode, Artifact, WebFetch` — with this workflow:
   resolve the spec (argument, else Glob `docs/plans/*.md` and ask), run
   `plan-agent-hub <spec>.md -o "$SCRATCHPAD/<stem>-hub.html"`, re-read
   `hub-artifact-url:` fresh and pass it as `url` only when it parses as
   http(s) with a host, publish with a stable favicon and one-sentence
   description, write the returned URL back as `hub-artifact-url:`, verify
   via WebFetch that the fetched page contains the plan title, and report
   the URL; on a size-cap exit rerun without the named file and say what was
   dropped; on publish failure deliver the hub HTML via SendUserFile and
   never report an unreturned URL. Why: the stable-URL republish loop and
   the rendered-page check are the two behaviours that make a shared hub
   link trustworthy, and both already have proven shapes in
   `implementation-plan` Step 7 and `plan-artifact` Steps 2–4. Verify:
   publish a real plan twice through the skill — the second publish reuses
   the first URL and the spec diff shows exactly one `hub-artifact-url:`
   line added.
5. [x] Bump `plan-agent` from 9.7.1 to 9.8.0 in
   `.claude-plugin/marketplace.json` (MINOR — new skill) and add a matching
   `kit/plugins/plan-agent/CHANGELOG.md` entry. Why: the version lives only
   in marketplace.json and CI fails any plugin-touching PR whose version
   does not exceed the base branch. Verify: `git fetch origin && BASE_REF=main
   node scripts/check-plugin-versions.mjs` exits 0.
6. [x] Add the skill to `kit/plugins/plan-agent/README.md`'s components section
   and regenerate the root README's Plugin Reference Table with
   `node scripts/build-readme-table.mjs`. Why: the table is generated output
   — hand-editing it is a repo violation, and a shipped skill missing from
   the README is invisible to marketplace users. Verify: the regenerated
   table row lists `publish-hub` and `git diff README.md` shows only
   generator output.

## Files

- kit/plugins/plan-agent/scripts/build-plan-hub.mjs (new) — bundler: spec + related HTML → one tabbed hub page
- kit/plugins/plan-agent/bin/plan-agent-hub (new) — bare-name PATH wrapper for the bundler
- kit/plugins/plan-agent/skills/publish-hub/SKILL.md (new) — the publish workflow and republish loop
- tests/plugins/test-build-plan-hub.mjs (new) — bundler contract test: tabs, escaping, size guard, exit codes
- .claude-plugin/marketplace.json (modified) — plan-agent 9.7.1 → 9.8.0
- kit/plugins/plan-agent/CHANGELOG.md (modified) — 9.8.0 entry
- kit/plugins/plan-agent/README.md (modified) — components section gains publish-hub
- README.md (generated) — Plugin Reference Table regenerated

## Tests

Tier 1 — This plan creates plugin runtime scripts
- Objective: a plan spec with a `prototype:` key bundles into one hub page carrying both documents. File: tests/plugins/test-build-plan-hub.mjs; Type: smoke; Asserts: the emitted hub contains the plan title and the srcdoc-escaped prototype markup in separate tab panels; Run: node tests/plugins/test-build-plan-hub.mjs
- Unit: srcdoc escaping and guard exits. File: tests/plugins/test-build-plan-hub.mjs; Targets: the escape helper and the size/readability guards; Key cases: `&` and `"` escaped exactly once, quote-heavy prototype survives the round trip, missing spec exits 1, `--max-bytes` overflow exits 1 naming the file

## Acceptance Criteria

- [x] Running `plan-agent-hub` on a spec with a `prototype:` key emits one self-contained HTML file with a Plan tab and a Prototype tab, and the prototype's JavaScript still runs inside its panel
- [x] Publishing through the skill writes `hub-artifact-url:` into the spec, and a second publish updates the same URL instead of minting a new one
- [x] No existing skill changes: `implementation-plan`, `plan-artifact`, and the `artifact-url:` convention are untouched by the diff
- [x] A bundle exceeding the size cap fails with the offending file named, and the skill's retry-without-it path reports what was dropped
- [x] `node tests/plugins/test-build-plan-hub.mjs` exits 0
- [x] plan-agent is 9.8.0 in marketplace.json with a CHANGELOG entry, and both READMEs list the skill

## Verification

Bundle a real plan end to end: pick a plan whose spec carries a `prototype:`
key, run `plan-agent-hub docs/plans/<stem>.md -o /tmp-scratch/<stem>-hub.html`,
open the output in a browser, and confirm the tab bar switches between a
fully rendered plan and a working, interactive prototype with no console
errors in either theme. Then publish through `/plan-agent:publish-hub` twice:
the first run returns a URL and adds `hub-artifact-url:` to the spec; the
second run reuses that URL, and fetching it shows the plan title.

Close with the merge gate: `bash scripts/verify.sh` exits 0 (the repo-wide
suites pick up the new skill — the ExitPlanMode-guard grep and the
description-budget check must both pass on `publish-hub/SKILL.md`), and
`git fetch origin && BASE_REF=main node scripts/check-plugin-versions.mjs`
exits 0.

## Next Steps

- Reference plan images as artifact assets once the capability lands
  Smaller hub pages when the `assets` capability appears in the account roster — images by asset URL instead of base64 data URIs. HTML remains a non-asset type; this is images only.
  ```text
  In the agentics repo: check whether the artifact runtime roster now
  includes the assets capability (load the artifact-capabilities skill and
  read the available-capabilities line). If yes, extend
  kit/plugins/plan-agent/scripts/build-plan-hub.mjs to emit image
  references as asset URLs and teach skills/publish-hub/SKILL.md to
  upload_asset each referenced image after publishing. Bump the plan-agent
  minor version in .claude-plugin/marketplace.json, add a CHANGELOG entry,
  and verify with node tests/plugins/test-build-plan-hub.mjs plus one real
  publish whose page renders every image.
  ```

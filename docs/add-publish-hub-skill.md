# Bundle a plan and its related HTML into one hub artifact

> Adds a `publish-hub` skill to plan-agent that bundles a plan and its related HTML (prototype, companion pages) into one self-contained tabbed artifact at a stable `hub-artifact-url:` on claude.ai.

<!-- generated:start -->

**Status:** Shipped 2026-08-26 **Plan:** [add-publish-hub-skill.md](plans/add-publish-hub-skill.md)
**Type:** feature

## What shipped

- Created `scripts/build-plan-hub.mjs` — the bundler that renders a plan spec, embeds each related document in a `<iframe srcdoc>` panel, and enforces a 15 MB size cap
- Added `bin/plan-agent-hub` — the bare-name PATH wrapper required because skills cannot expand `${VAR}` in Bash calls
- Wrote `skills/publish-hub/SKILL.md` — the six-step skill: resolve spec, bundle, re-read `hub-artifact-url:`, publish, verify via WebFetch, report URL; plus retry-without-dropped-file path on size-cap failure
- Added `tests/plugins/test-build-plan-hub.mjs` — contract tests for tabs, srcdoc escaping, size guard, and exit codes
- Bumped plan-agent from 9.7.1 to 9.8.0 in `.claude-plugin/marketplace.json`; added 9.8.0 CHANGELOG entry; regenerated root README Plugin Reference Table

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/scripts/build-plan-hub.mjs` | Bundler: spec + related HTML → one tabbed hub page | Created |
| `kit/plugins/plan-agent/bin/plan-agent-hub` | Bare-name wrapper for the bundler | Created |
| `kit/plugins/plan-agent/skills/publish-hub/SKILL.md` | Publish-hub skill — six-step workflow and republish loop | Created |
| `tests/plugins/test-build-plan-hub.mjs` | Bundler contract test: tabs, escaping, size guard, exit codes | Created |
| `.claude-plugin/marketplace.json` | plan-agent 9.7.1 → 9.8.0 | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 9.8.0 entry | Modified |
| `kit/plugins/plan-agent/README.md` | Components section gains publish-hub | Modified |
| `README.md` | Plugin Reference Table regenerated | Modified |

## How it works

Plans published through `implementation-plan` get a `artifact-url:` pointing at a claude.ai page. But the prototype at `docs/prototypes/<slug>.html`, companion docs from `markdown-to-html`, and any other related HTML stay local — they cannot be reached from the shared plan link. Assets cannot be used as sub-pages, and external iframe framing is blocked by the artifact CSP, so the only viable approach is to bundle everything into one self-contained page.

`build-plan-hub.mjs` spawns `build-plan-html.mjs` as a CLI to render the plan (so the output is identical to what `plan-agent-render` produces), reads related HTML from the spec's `prototype:` frontmatter key and any `--extra` paths, and emits one tab shell where each document lives in its own `<iframe srcdoc>` panel. The `design:` key, if present, becomes an external-link tab rather than an embedded panel — it is already its own artifact and the CSP would block framing it. srcdoc escaping is minimal by design: `&` then `"` only, because the browser un-escapes the attribute value once before parsing it as a document, and escaping `<`/`>` would turn markup into text.

The bundler exits 1 naming the offending file when output would exceed the cap (default 15 MB, under the 16 MB artifact page limit) or when a named file is unreadable. The skill's retry path re-runs the bundler with `--skip <named-file>` and tells the user exactly what was dropped.

`bin/plan-agent-hub` is a thin wrapper using the `exec node "$(dirname "$0")/../scripts/..."` pattern copied verbatim from `bin/plan-agent-render`. Skills invoke bin scripts by bare name in the PATH; a `node "${CLAUDE_PLUGIN_ROOT}/..."` command would never execute because the Bash tool rejects `${VAR}` expansion.

The `publish-hub` skill stores the published URL as `hub-artifact-url:` rather than `artifact-url:`, so a plain plan republish through `implementation-plan` or `artifact-tools:plan-artifact` never clobbers a hub link that is already shared. On every run the skill re-reads `hub-artifact-url:` fresh immediately before calling `Artifact`, because another session step may have rewritten the file; passing the stored URL as `url` updates the existing page rather than minting a new one. After publishing, the skill fetches the page via `WebFetch` and checks that the plan title is present before reporting success.

## How to use it

```bash
# From the plan-agent plugin
/plan-agent:publish-hub docs/plans/<slug>.md
# With an extra companion page
/plan-agent:publish-hub docs/plans/<slug>.md --extra docs/designs/<slug>.html
```

On first run the skill adds `hub-artifact-url:` to the spec frontmatter and reports the URL. On subsequent runs it republishes to the same URL — the link stays stable as the plan evolves. If the bundle exceeds 15 MB, the skill reports which file was dropped and re-bundles automatically.

To build the hub locally without publishing:

```bash
node kit/plugins/plan-agent/scripts/build-plan-hub.mjs docs/plans/<slug>.md -o /tmp/<slug>-hub.html
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `be304fd` | 2026-08-26 | feat(plan-agent): publish-hub — bundle a plan and its related HTML into one hub artifact (9.8.0) (#603) |

<!-- generated:end -->

## References

- Plan: [add-publish-hub-skill.md](plans/add-publish-hub-skill.md)
- `kit/plugins/plan-agent/scripts/build-plan-hub.mjs` — bundler
- `kit/plugins/plan-agent/skills/publish-hub/SKILL.md` — skill workflow
- `tests/plugins/test-build-plan-hub.mjs` — contract tests

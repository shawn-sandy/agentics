# Bundle a plan and its related HTML into one hub artifact

> Add a `publish-hub` skill to plan-agent that bundles a plan and its related HTML files into a single self-contained hub artifact on claude.ai, published to a stable URL.

<!-- generated:start -->

**Status:** Shipped 2026-08-27  **Plan:** [add-publish-hub-skill.md](plans/add-publish-hub-skill.md)
**Type:** feature

## What shipped

- Added `kit/plugins/plan-agent/scripts/build-plan-hub.mjs` — a bundler that accepts a spec `.md` plus optional `--extra` HTML paths and emits one theme-aware tabbed page, each document embedded in an `<iframe srcdoc>` with proper entity escaping and a configurable size cap (default 15 MB)
- Added `kit/plugins/plan-agent/skills/publish-hub/SKILL.md` — the user-facing skill that resolves the spec, runs the bundler, publishes to a stable `hub-artifact-url:` in the spec frontmatter, verifies the returned page title via `WebFetch`, and retries without oversized files on a size-cap exit
- Added `tests/plugins/test-build-plan-hub.mjs` — bundler contract tests covering tab structure, srcdoc escaping, size guard exit codes, and unreadable-spec handling
- Bumped plan-agent from 9.7.1 to 9.8.0 (MINOR — new skill)
- Updated `kit/plugins/plan-agent/README.md` and regenerated the root `README.md` Plugin Reference Table

> See [CHANGELOG v9.8.0](../kit/plugins/plan-agent/CHANGELOG.md) for the authoritative feature list.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/scripts/build-plan-hub.mjs` | Hub bundler script | Created |
| `kit/plugins/plan-agent/skills/publish-hub/SKILL.md` | Skill instructions | Created |
| `tests/plugins/test-build-plan-hub.mjs` | Bundler contract test | Created |
| `.claude-plugin/marketplace.json` | Version bump 9.7.1 → 9.8.0 | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 9.8.0 entry | Modified |
| `kit/plugins/plan-agent/README.md` | Components section | Modified |
| `README.md` | Plugin Reference Table regenerated | Modified |
| `kit/plugins/plan-agent/bin/plan-agent-hub` | PATH wrapper for bundler | Removed (dropped in #658) |

## How it works

The bundler at `scripts/build-plan-hub.mjs` takes a plan spec path and optional `--extra <path>` arguments. It parses frontmatter via `scripts/lib/plan-spec.mjs`, renders the plan through `build-plan-html.mjs`, and collects related HTML from the `prototype:` frontmatter key plus any `--extra` paths. Each document is embedded as an `<iframe srcdoc>` panel in a theme-aware tab shell — the plan tab comes first, a `design:` key becomes an external-link tab (since artifact CSP blocks framing external URLs), and all other paths become embedded tabs.

The bundler entity-escapes `&` and `"` in every `srcdoc` value so prototypes with inline JavaScript survive the HTML round-trip intact. It exits 1 naming the offending file when the output would exceed the size cap (default 15 MB, under the artifact 16 MB limit), or when the spec or any named related file is unreadable.

The `publish-hub/SKILL.md` skill resolves the spec (from the argument or by globbing `docs/plans/*.md`), runs the bundler with `plan-agent-hub` to a scratchpad file, then reads the existing `hub-artifact-url:` frontmatter key and passes it as `url` on a republish so the shared link stays stable across iterations. After publishing it verifies the returned page contains the plan title by fetching the artifact URL with `WebFetch`. If the bundler exits with a size-cap error the skill reruns without the named file and reports what was dropped. On a publish failure it delivers the hub HTML via `SendUserFile` without reporting an unreturned URL.

The separate `hub-artifact-url:` frontmatter key was chosen deliberately over reusing `artifact-url:` so that a plain plan republish from `implementation-plan` or `artifact-tools:plan-artifact` cannot silently overwrite a hub link.

## How to use it

Activate by running `/plan-agent:publish-hub` with an optional plan file path:

```
/plan-agent:publish-hub                                    # auto-detects from current context
/plan-agent:publish-hub docs/plans/my-feature.md          # specific plan
/plan-agent:publish-hub docs/plans/my-feature.md --extra docs/prototypes/my-feature.html
```

A `prototype:` key in the plan frontmatter is picked up automatically — no `--extra` needed for the prototype. The first run adds `hub-artifact-url:` to the spec; every subsequent run republishes to that same URL.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `02136c1` | 2026-10-26 | fix(marketplace): drop bin/ wrappers so claude.ai installs all plugins (#658) |
| `c16fe83` | 2026-10-13 | feat(plan-agent): live UI previews inside plan pages (9.20.0) (#651) |
| `8728598` | 2026-08-27 | chore(vscode): share workspace extension recommendations (#606) |

<!-- generated:end -->

## References

- Plan: [add-publish-hub-skill.md](plans/add-publish-hub-skill.md)
- Changelog: [plan-agent CHANGELOG](../kit/plugins/plan-agent/CHANGELOG.md)

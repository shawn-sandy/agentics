# Bundle a plan and its related HTML into one hub artifact

> Add a `publish-hub` skill to plan-agent that bundles a plan and its related HTML files into a single self-contained hub artifact on claude.ai, published to a stable URL.

<!-- generated:start -->

**Status:** Shipped 2026-08-26  **Plan:** [add-publish-hub-skill.md](plans/add-publish-hub-skill.md)
**Type:** feature

## What shipped

- Added `build-plan-hub.mjs` bundler script that renders a plan and embeds related HTML files (prototype, extras) into a single tabbed page using `<iframe srcdoc>`, with entity-escaping and a configurable size cap (default 15 MB).
- Added `plan-agent-hub` bin wrapper using the `exec node` pattern so skills can invoke it by bare name without shell-variable expansion issues.
- Added `publish-hub/SKILL.md` skill that resolves the spec, runs the bundler, publishes the hub artifact under a separate `hub-artifact-url:` frontmatter key, verifies the rendered page, and handles the stable-URL republish loop.
- Added `tests/plugins/test-build-plan-hub.mjs` covering tab structure, srcdoc escaping, size-cap exit codes, and missing-spec error paths.
- Bumped plan-agent to 9.8.0 and updated README and CHANGELOG.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/scripts/build-plan-hub.mjs` | Hub bundler script | Created |
| `kit/plugins/plan-agent/bin/plan-agent-hub` | Bare-name PATH wrapper | Missing (dropped in #658) |
| `kit/plugins/plan-agent/skills/publish-hub/SKILL.md` | Publish workflow skill | Created |
| `tests/plugins/test-build-plan-hub.mjs` | Bundler contract tests | Created |
| `.claude-plugin/marketplace.json` | plan-agent version 9.7.1 → 9.8.0 | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 9.8.0 entry | Modified |
| `kit/plugins/plan-agent/README.md` | Added publish-hub to components | Modified |

## How it works

The bundler (`build-plan-hub.mjs`) accepts a spec `.md` file and optional `--extra` paths. It parses the spec's frontmatter with `plan-spec.mjs` to find the `prototype:` and `design:` keys, renders the plan through `build-plan-html.mjs`, and reads each related HTML file. The output is a single theme-aware shell page that embeds each document in an `<iframe srcdoc>` panel with a tab bar for navigation. The `design:` URL becomes an external-link tab rather than an embedded one, since the artifact CSP blocks framing external URLs.

Entity-escaping (`&` → `&amp;`, `"` → `&quot;`) happens before each document is inserted into the srcdoc attribute, so prototypes with inline JavaScript survive the round-trip intact. The bundler exits 1, naming the offending file, when the total output would exceed the size cap — keeping the constraint in deterministic code rather than model judgment.

The `publish-hub` skill resolves the spec file, runs `plan-agent-hub` into a scratchpad file, reads back `hub-artifact-url:` from the spec, and passes it as `url` when it's a valid https URL so the same artifact is updated rather than a new one minted. After publishing, it uses `WebFetch` to read the returned URL and confirms the plan title is present before reporting success. If the bundler exits non-zero due to a size-cap overflow, the skill reruns without the named file and reports what was dropped.

The `hub-artifact-url:` key is intentionally separate from `artifact-url:` to prevent a plain `implementation-plan` republish from clobbering the hub link. The renderer's frontmatter parser preserves unknown keys, so the hub URL survives any rebuild of the spec.

Note: the `bin/plan-agent-hub` wrapper was later dropped in PR #658 when the marketplace shifted away from bin/ wrappers for claude.ai installs. The bundler is still invocable via node directly.

## How to use it

Invoke with `/plan-agent:publish-hub`. The skill prompts to select a spec if no argument is given. After publishing, `hub-artifact-url:` is written into the spec frontmatter. A second run reuses that URL.

```
/plan-agent:publish-hub
/plan-agent:publish-hub docs/plans/my-feature.md
/plan-agent:publish-hub docs/plans/my-feature.md --extra docs/prototypes/extra.html
```

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `02136c1d` | 2026-10-26 | fix(marketplace): drop bin/ wrappers so claude.ai installs all plugins (#658) |
| `c16fe83f` | 2026-10-13 | feat(plan-agent): live UI previews inside plan pages (9.20.0) (#651) |
| `6d6bfeb3` | 2026-08-26 | fix(plan-agent): carry completion state to artifact-published plans (9.9.0) (#604) |

<!-- generated:end -->

## References

- Plan: [add-publish-hub-skill.md](plans/add-publish-hub-skill.md)

# Bundle a Plan and Its Related HTML into One Hub Artifact

> Plans already publish as artifacts, but their prototypes and companion HTML stay local files nobody can open from the shared link. A hub artifact bundles plan and related pages into one tabbed, republishable URL; done means one link shows the plan and its prototype together, and republishing keeps that link stable.

<!-- generated:start -->

**Status:** Shipped 2026-08-26  **Plan:** [add-publish-hub-skill.md](plans/add-publish-hub-skill.md)
**Type:** feature

## What shipped

- Added `scripts/build-plan-hub.mjs`, a bundler that takes a plan spec plus related HTML files and emits one self-contained tabbed hub page embedding each document in an `<iframe srcdoc>` panel, with `&` and `"` entity-escaped and a configurable size cap (default 15 MB, under the 16 MB artifact limit).
- Added `kit/plugins/plan-agent/bin/plan-agent-hub`, a bare-name PATH wrapper following the `exec node "$(dirname "$0")/../scripts/..."` pattern from `bin/plan-agent-render`, needed because `Bash` tool rejects `${VAR}` expansion in skill commands.
- Added `kit/plugins/plan-agent/skills/publish-hub/SKILL.md` with the publish workflow: resolve spec, run `plan-agent-hub`, re-read `hub-artifact-url:` for stable republishing, publish to claude.ai with the returned URL, write the URL back to the spec, verify via WebFetch that the fetched page contains the plan title, and deliver the URL.
- Added `tests/plugins/test-build-plan-hub.mjs` asserting the bundler's tab structure, srcdoc escaping, size guard, and exit codes.
- Bumped plan-agent to 9.8.0 and updated both README files.

## Files changed

| Path | Role | Status |
| --- | --- | --- |
| `kit/plugins/plan-agent/scripts/build-plan-hub.mjs` | Bundler — spec + related HTML → tabbed hub page | Created |
| `kit/plugins/plan-agent/bin/plan-agent-hub` | PATH wrapper — bare-name invocation for skill use | Created |
| `kit/plugins/plan-agent/skills/publish-hub/SKILL.md` | Skill — publish workflow and republish loop | Created |
| `tests/plugins/test-build-plan-hub.mjs` | Test — bundler contract: tabs, escaping, size guard, exit codes | Created |
| `.claude-plugin/marketplace.json` | Marketplace — plan-agent 9.7.1 to 9.8.0 | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Changelog — 9.8.0 entry | Modified |
| `kit/plugins/plan-agent/README.md` | Plugin docs — components section gains publish-hub | Modified |
| `README.md` | Root docs — Plugin Reference Table regenerated | Modified |

## How it works

The hub is a bundling problem, not a capability problem. The `assets` capability is not in this account's artifact runtime roster, and even where assets exist the accepted types are image/video/PDF/font/text, not HTML. The solution is one artifact page with a tab bar, each related document embedded whole via `<iframe srcdoc>`. The artifact CSP allows this because everything is inline and nothing external is fetched.

`build-plan-hub.mjs` parses frontmatter using `scripts/lib/plan-spec.mjs`, renders the plan through `build-plan-html.mjs`, collects related HTML from the `prototype:` frontmatter key and any `--extra <path>` arguments, then emits a theme-aware tab shell. The plan tab is always first. A `design:` key becomes an external-link tab rather than an embedded one — it is already its own artifact with a live editor, and the artifact CSP blocks framing external URLs. Entity-escaping (`&` → `&amp;`, `"` → `&quot;`) is applied to every srcdoc value so that inline JavaScript (common in prototypes) survives the round trip. When the output would exceed the size cap, the bundler exits 1 naming the offending file; the skill's retry path then reruns without that file and reports what was dropped.

The hub uses a separate `hub-artifact-url:` frontmatter key rather than the existing `artifact-url:`. A plain plan republish from `implementation-plan` Step 7 or `artifact-tools:plan-artifact` would silently clobber a hub that shared the key. The separate key is additive and touches no existing skill. The renderer preserves unknown frontmatter keys, so it survives rebuilds.

The skill's republish loop reads `hub-artifact-url:` fresh before each publish. If the key parses as an `http(s)` URL with a host, it is passed as `url` to the Artifact tool, updating the existing page in place. After publishing, the skill verifies via `WebFetch` that the fetched page contains the plan title — this is the check that makes the shared link trustworthy. The `bin/plan-agent-hub` wrapper is necessary because the `Bash` tool rejects `${CLAUDE_PLUGIN_ROOT}` expansion in command strings; a bare-name wrapper in PATH works around this.

## How to use it

```bash
/plan-agent:publish-hub                          # resolves spec interactively
/plan-agent:publish-hub docs/plans/<slug>.md     # explicit spec path
```

A second run on the same spec republishes to the same URL. The returned URL is written to `hub-artifact-url:` in the spec's frontmatter.

To build the hub HTML locally without publishing:

```bash
plan-agent-hub docs/plans/<slug>.md -o /tmp/<slug>-hub.html
```

## Commit history

| SHA | Date | Subject |
| --- | --- | --- |
| `be304fd` | 2026-08-26 | feat(plan-agent): publish-hub — bundle a plan and its related HTML into one hub artifact (9.8.0) (#603) |

<!-- generated:end -->

## References

- Plan: [add-publish-hub-skill.md](plans/add-publish-hub-skill.md)

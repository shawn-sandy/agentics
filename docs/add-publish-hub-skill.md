# Bundle a plan and its related HTML into one hub artifact

> Plans already publish as artifacts, but their prototypes and companion HTML stay local files nobody can open from the shared link. A hub artifact bundles plan and related pages into one tabbed, republishable URL; done means one link shows the plan and its prototype together, and republishing keeps that link stable.

<!-- generated:start -->

**Status:** Shipped 2026-08-26 **Plan:** [add-publish-hub-skill.md](plans/add-publish-hub-skill.md)
**Type:** feature

## What shipped

- Added `kit/plugins/plan-agent/scripts/build-plan-hub.mjs`: parses frontmatter via `plan-spec.mjs`, renders the plan through `build-plan-html.mjs`, collects related HTML from the `prototype:` key plus `--extra` paths, emits one theme-aware tab shell with each document embedded in `<iframe srcdoc>`; entity-escapes `&` and `"` in every srcdoc value; exits 1 when output exceeds the size cap (default 15 MB) or a named file is unreadable; `design:` becomes an external-link tab.
- Added `kit/plugins/plan-agent/bin/plan-agent-hub` bare-name PATH wrapper.
- Added `kit/plugins/plan-agent/skills/publish-hub/SKILL.md`: resolves the spec, runs `plan-agent-hub`, reads `hub-artifact-url:` for the stable republish URL, publishes, writes the returned URL back as `hub-artifact-url:`, verifies via WebFetch; on size-cap exit retries without the named file; on publish failure delivers the hub HTML via `SendUserFile`.
- Added `tests/plugins/test-build-plan-hub.mjs`: fixture spec + quote-heavy prototype; asserts tabs, escaped markup, missing-spec exit 1, `--max-bytes` overflow exit 1.
- Bumped plan-agent 9.7.1 → 9.8.0; updated `README.md` and root README Plugin Reference Table.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/scripts/build-plan-hub.mjs` | Hub bundler script | Created |
| `kit/plugins/plan-agent/bin/plan-agent-hub` | PATH wrapper | Created |
| `kit/plugins/plan-agent/skills/publish-hub/SKILL.md` | Publish workflow | Created |
| `tests/plugins/test-build-plan-hub.mjs` | Bundler contract test | Created |
| `.claude-plugin/marketplace.json` | plan-agent 9.7.1 → 9.8.0 | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 9.8.0 entry | Modified |
| `kit/plugins/plan-agent/README.md` | components section | Modified |
| `README.md` | Plugin Reference Table regenerated | Modified |

## How it works

The hub is a bundling solution: one artifact page with a tab bar, each related document embedded whole via `<iframe srcdoc>`. The artifact CSP allows this — everything is inline, nothing external is fetched. Each document's HTML is entity-escaped (`&` → `&amp;`, `"` → `&quot;`) before embedding, so the srcdoc attribute is always valid. The plan tab is always first; a `design:` frontmatter key becomes an external-link tab (framing external URLs is blocked by the artifact CSP).

The `hub-artifact-url:` frontmatter key is separate from `artifact-url:` — a plain plan republish from `implementation-plan` or `plan-artifact` cannot silently clobber a hub. A second publish reuses the stored URL and updates in place.

## How to use it

```
/plan-agent:publish-hub [docs/plans/<spec>.md]
```

If no spec is given, the skill globs `docs/plans/*.md` and asks. The hub is published to a new `hub-artifact-url:` on the first run and republished to the same URL on subsequent runs. Pass `--extra <path>` to include additional HTML files alongside the prototype.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `be304fd6` | 2026-08-26 | feat(plan-agent): publish-hub skill — bundle plan and prototype into one artifact (9.8.0) |

<!-- generated:end -->

## References

- Plan: [add-publish-hub-skill.md](plans/add-publish-hub-skill.md)

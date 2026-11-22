# Add live UI previews inside plan pages

> An optional `## Previews` section in plan specs lets `implementation-plan` author self-contained HTML previews that render as isolated, interactive iframes inside the plan page; `build` treats each preview as the structure target for its tagged steps.

<!-- generated:start -->

**Status:** Shipped 2026-10-13 **Plan:** [add-plan-ui-previews.md](plans/add-plan-ui-previews.md)
**Type:** feature

## What shipped

- Added `## Previews` parsing to `scripts/lib/plan-spec.mjs`: a shared splitter (lifted from Next Steps) handles bullet items with `(step N)` / `(steps N, M)` tags, description lines, and a fenced `html` block; `extractPreviews()` and `previewsMarkdown()` for round-trip support.
- Rendered previews in `scripts/build-plan-html.mjs` and `scripts/lib/plan-shell.mjs`: each item becomes a `<figure class="plan-preview">` holding an `<iframe src="data:text/html,...">` in an opaque origin; a `preview` chip (≥24×24px WCAG target) on each tagged step card; a Previews nav entry; a MutationObserver theme-sync script that reloads each `data:` URL with `data-theme` on its `<html>` when the plan's toggle changes. All preview-only bytes are conditional on previews existing, keeping preview-less plans byte-identical to their pre-change output.
- Updated `scripts/extract-plan-spec.mjs`, `scripts/rerender-plans.mjs`, and `scripts/backfill-plan-digests.mjs` to carry `extractPreviews(html)` through; re-copied the four shared files into `kit/plugins/plan-agent/scripts/`.
- Added `tests/fixtures/plan-previews/` golden fixtures and `tests/plugins/test-plan-previews.mjs` asserting parse, render, round-trip, golden byte-identity, and error cases.
- Added `tests/plugins/test-build-plan-hub.mjs` hub case asserting a preview survives bundling.
- Added `kit/plugins/plan-agent/skills/implementation-plan/guidelines/ui-previews.md` with the full authoring contract and a worked example; updated `section-catalog.md` and `writing-style.md`.
- Added `kit/plugins/plan-agent/skills/build/references/ui-previews.md` (the structure-target rule) and wired it from `build/SKILL.md` Step 2.
- Bumped `plan-agent` from `9.19.1` to `9.20.0` with matching CHANGELOG and README entries.

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `scripts/lib/plan-spec.mjs` | Previews parsing and round-trip | Modified |
| `scripts/build-plan-html.mjs` | Preview rendering | Modified |
| `scripts/lib/plan-shell.mjs` | Preview chrome and nav entry | Modified |
| `scripts/extract-plan-spec.mjs` | Previews extraction | Modified |
| `scripts/rerender-plans.mjs` | Previews carry-through | Modified |
| `scripts/backfill-plan-digests.mjs` | Previews carry-through | Modified |
| `kit/plugins/plan-agent/scripts/` (four files) | Byte-identical copies | Modified |
| `tests/fixtures/plan-previews/` | Golden fixtures | Created |
| `tests/plugins/test-plan-previews.mjs` | Smoke test | Created |
| `tests/plugins/test-build-plan-hub.mjs` | Hub bundling case | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/ui-previews.md` | Authoring contract | Created |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/section-catalog.md` | Previews entry | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/guidelines/writing-style.md` | HTML carve-out | Modified |
| `kit/plugins/plan-agent/skills/implementation-plan/SKILL.md` | Author previews in Step 2 | Modified |
| `kit/plugins/plan-agent/skills/build/references/ui-previews.md` | Structure-target rule | Created |
| `kit/plugins/plan-agent/skills/build/SKILL.md` | Load reference when previews present | Modified |
| `.claude-plugin/marketplace.json` | Marketplace registration | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | Version history | Modified |
| `kit/plugins/plan-agent/README.md` | Previews in Features | Modified |

## How it works

Preview HTML lives inline in the spec as a fenced `html` block under a `## Previews` bullet. The renderer renders each block as a `<figure>` holding an `<iframe>` whose `src` is the html's `data:text/html,…` URL. The `data:` scheme gives the iframe an opaque origin (`window.origin === "null"`) — it cannot read the plan page, its storage, or the artifact around it — without a `sandbox` attribute, which caused blank frames in the Claude desktop app.

A theme-sync MutationObserver watches `data-theme` changes on the plan page and reloads each preview's `data:` URL with the matching `data-theme` on its `<html>`. This keeps the preview in sync with the plan's light/dark toggle without injecting code into the author's HTML.

Every preview-only byte (the `plan-preview` chrome, step chips, nav entry, theme-sync script) is emitted only when the spec has at least one preview item, enforcing byte-identity for preview-less plans.

`build` loads `references/ui-previews.md` when the spec has `## Previews`. The rule: build each tagged step to its preview's structure, states, and copy; the project's real tokens and components win on visual detail; never edit a preview to match the build; note in one line when step prose and preview disagree.

## How to use it

Add a `## Previews` section to a plan spec. Each bullet is a preview item:

```markdown
## Previews

- Save button states (step 3)
  ```html
  <!doctype html>
  <html lang="en">…</html>
  ```
```

`implementation-plan` authors previews automatically when UI signals are present (and `--quick` is not set), following `guidelines/ui-previews.md` including contrast measurement.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `c16fe83f` | 2026-10-13 | feat(plan-agent): live UI previews inside plan pages (9.20.0) (#651) |

<!-- generated:end -->

## References

- Plan: [add-plan-ui-previews.md](plans/add-plan-ui-previews.md)

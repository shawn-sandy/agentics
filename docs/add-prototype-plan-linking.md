# Make a plan and its prototype aware of each other

> Adds bidirectional links between a plan spec and its generated prototype, embeds a durable data model in both files, and ships a PostToolUse hook that reports when the two have drifted apart.

<!-- generated:start -->

**Status:** Shipped 2026-08-18 **Plan:** [add-prototype-plan-linking.md](plans/add-prototype-plan-linking.md)
**Type:** feature

## What shipped

- Added `#proto-model` JSON block to `PROTOTYPE-SKELETON.html` so every generated prototype embeds a machine-readable entity/fields/action/successSignal model
- Extended `skills/prototype/SKILL.md` to serialize the Step 3 data model into `{{PROTO_MODEL}}` as compact single-line JSON, and to write `prototype:` and `proto-model:` back into the source plan's frontmatter before the HTML is written
- Threaded the `prototype:` frontmatter key through both renderer copies (`build-plan-html.mjs` and `scripts/lib/plan-shell.mjs`) to emit a `<meta name="plan-prototype">` tag and a visible "View prototype" header link with correct relative `href`
- Added a prototype chip to plans gallery cards across all three byte-identical `build-index.sh` copies, with non-empty visible text and no nested anchor
- Wrote `hooks/check-prototype-drift.py` to compare a prototype's embedded model against its DOM fields and against the `proto-model:` frontmatter of the plan named in `proto-source`, exiting 0 on every input
- Registered the drift check in `dispatch.py` inside the existing `is_prototype` branch after the gallery rebuild
- Shipped three new test files covering renderer output, gallery chips, and all drift-hook edge cases

## Files changed

| Path | Role | Status |
| ---- | ---- | ------ |
| `kit/plugins/plan-agent/skills/prototype/reference/PROTOTYPE-SKELETON.html` | HTML skeleton — gains `#proto-model` JSON block | Modified |
| `kit/plugins/plan-agent/skills/prototype/SKILL.md` | Skill instructions — pins `proto-source` format, serializes model, writes back to plan | Modified |
| `scripts/lib/plan-shell.mjs` | Renderer shell — adds optional `plan-prototype` meta and header link | Modified |
| `kit/plugins/plan-agent/scripts/lib/plan-shell.mjs` | Byte-identical re-copy of above | Modified |
| `scripts/build-plan-html.mjs` | Renderer entry — threads `prototype` key into `metaTags()` and `header()` | Modified |
| `kit/plugins/plan-agent/scripts/build-plan-html.mjs` | Byte-identical re-copy of above | Modified |
| `kit/plugins/plan-agent/hooks/build-index.sh` | Gallery builder — prototype chip on plan cards | Modified |
| `scripts/build-plans-index.sh` | Byte-identical re-copy of above | Modified |
| `docs/plans/build-index.sh` | Byte-identical re-copy of above | Modified |
| `kit/plugins/plan-agent/hooks/check-prototype-drift.py` | PostToolUse drift comparison hook | Created |
| `kit/plugins/plan-agent/hooks/dispatch.py` | Hook dispatcher — fan-out to drift check on prototype writes | Modified |
| `kit/plugins/plan-agent/README.md` | Plugin docs — new hook and key descriptions | Modified |
| `kit/plugins/plan-agent/CHANGELOG.md` | 4.4.0 entry | Modified |
| `.claude-plugin/marketplace.json` | plan-agent bumped 4.3.1 → 4.4.0 | Modified |
| `tests/plugins/test-prototype-plan-link.mjs` | Smoke test: renderer output and gallery chip | Created |
| `tests/plugins/test-prototype-drift.sh` | Unit + integration: drift-hook branches and dispatch fan-out | Created |
| `tests/plugins/test-build-plan-html.mjs` | Back-compat case for specs without `prototype:` | Modified |

## How it works

`/plan-agent:prototype` generates a prototype from a plan spec. Previously it stamped `<meta name="proto-source">` into the HTML and nothing else was linked. The plan spec had no way to know a prototype existed, and neither file preserved the data model that the skill derived.

The skeleton (`PROTOTYPE-SKELETON.html`) now carries a `<script type="application/json" id="proto-model">` block. The skill serializes the entity/fields/action/successSignal model as compact single-line JSON into `{{PROTO_MODEL}}` using the same script-breakout escaping rule already documented for `{{SEED_JSON}}`. The single-line requirement is absolute: the frontmatter parser in `plan-spec.mjs` is a naive line scanner, and a multiline value or an embedded `---` would silently truncate the block.

Before writing the prototype HTML, the skill resolves the plan spec by swapping `.html` to `.md` on the input path. If the sibling `.md` exists, it writes two keys into the frontmatter: `prototype: docs/prototypes/<slug>.html` and `proto-model: <compact JSON>`. If no sibling exists (69 of 84 non-index plans are legacy HTML with no spec), the prototype is still generated and a notice is printed; no spec file is created.

The renderer reads `parsed.metadata.prototype` and passes it to `shell.metaTags()` (emitting `<meta name="plan-prototype">` conditionally) and to `shell.header()` (rendering a "View prototype" anchor inside `.plan-header-actions`). The `href` is computed with `path.relative()` from the rendered plan's output directory to the repo-relative `prototype:` target, never hard-coded as `../prototypes/` — a custom `plansDirectory` would break that assumption.

`hooks/check-prototype-drift.py` reads a `PostToolUse` JSON payload on stdin, exits 0 immediately for non-prototype writes, then runs two comparisons: the prototype's `#proto-model` field names against `<th>` headers and form field `name`/`id` attributes in the same file, and the model against the `proto-model:` frontmatter of the plan its `proto-source` names. The plan path is resolved with a single-line regex (`^proto-model:\s*(.*)$` then `json.loads`), never a general YAML parser. The hook is unconditionally silent on missing files, absent blocks, out-of-tree paths, and parse failures, and always exits 0.

`dispatch.py` fans the drift check out inside the existing `is_prototype` branch after the gallery index rebuild, sharing the 55-second budget. No `hooks.json` change was needed.

## How to use it

After running `/plan-agent:prototype` on a plan spec that has a sibling `.md` file, the spec will carry:

```yaml
prototype: docs/prototypes/<slug>.html
proto-model: {"entity":"...","fields":[...],"action":"...","successSignal":"..."}
```

Re-render the plan with `plan-agent-render` and the output HTML will include a "View prototype" link in the header and a `<meta name="plan-prototype">` tag. The plans gallery will show a prototype chip on the card.

If the prototype's DOM is later hand-edited and a file write touches the prototype path, `check-prototype-drift.py` fires and prints a warning naming the two files and the diverging field. To re-sync, re-run `/plan-agent:prototype` on the plan (regeneration is deterministic). To resolve a divergence where the prototype is authoritative, edit the `proto-model:` line in the plan spec directly.

To opt out of drift checking in a repo, create `.claude/no-scope-guard` (shared with the scope-guard hook) — or, for prototype drift specifically, see the `check-prototype-drift.py` silent-exit conditions.

## Commit history

| SHA | Date | Subject |
| --- | ---- | ------- |
| `37cc607` | 2026-08-30 | docs(plan-agent): reconcile skill total and dispatch hook count (9.10.2) (#612) |
| `94c0569` | 2026-08-23 | feat(plan-agent): add design phase — canvas link, gallery, and drift check (#596) |
| `3ee6806` | 2026-08-18 | fix(plan-agent): close three build-feature gaps found in its first run (9.4.6) (#580) |

<!-- generated:end -->

## References

- Plan: [add-prototype-plan-linking.md](plans/add-prototype-plan-linking.md)
- `kit/plugins/plan-agent/hooks/check-prototype-drift.py` — drift comparison hook
- `kit/plugins/plan-agent/hooks/dispatch.py` — PostToolUse dispatcher
- `tests/plugins/test-prototype-plan-link.mjs` — renderer and gallery smoke test
- `tests/plugins/test-prototype-drift.sh` — drift-hook unit and integration tests

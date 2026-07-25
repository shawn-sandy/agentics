---
status: todo
type: feature
created: 2026-07-25
effort: high
glance: A prototype already knows which plan it came from, but the plan has no idea a prototype exists, and neither file records the data model they supposedly share. This puts a link on both ends and a durable model block in both files, so a hook can say "these two have drifted apart" instead of everyone finding out at implementation time.
---

# Plan: Make a plan and its prototype aware of each other

## Objective

Give every plan a back-link to its prototype, persist the prototype's derived
data model in both files, and add a `PostToolUse` hook that flags when a
prototype has drifted from its own model or from its plan's copy of it.

## Context

`/plan-agent:prototype` already stamps `<meta name="proto-source">` into every
prototype it generates, and `build-prototypes-index.sh` renders it on the
gallery card as "from `<plan>`". The link is one-directional: open a plan and
nothing tells you a prototype exists.

The deeper gap is that the two artifacts have no shared, machine-readable
overlap. Step 3 of the prototype skill derives a data model — entity, fields
with inferred types, primary action, success signal — and then discards it once
the skeleton is filled. Nothing durable survives to compare against later.

That asymmetry is why full bidirectional *sync* was rejected. Plans are
markdown-source plus rendered HTML; prototypes have no spec file, so the HTML
*is* the source. Propagating a prototype edit back into plan prose would need an
HTML-to-model parser over generated files, which `CLAUDE.md` forbids. The design
here is narrower and holds: **plan to prototype is regeneration** (re-run
`/plan-agent:prototype`, which Step 3 guarantees is deterministic), **prototype
to plan is detection** (compare two JSON blobs and report).

Three limitations, all accepted:

The drift hook compares structure, not intent. A hand-edit that changes the
prototype's rendered columns is caught, because the check compares the model
block against the prototype's own `<th>` headers and form field names. A
hand-edit that only changes copy, styling, or seed values is not caught, and
should not be.

Detection runs one way only — prototype HTML against plan frontmatter. A plan
whose `proto-model:` is hand-edited directly, bypassing the skill's write-back,
desyncs with no signal. Plans are user-owned prose rather than generated output,
so this is tolerated rather than guarded.

The frontmatter write-back has no transaction semantics. Two concurrent
sessions touching the same plan spec could drop one writer's update. Unlikely in
single-session use and not worth locking for.

`docs/prototypes/` currently holds only `index.html` — no real prototype exists
yet. Everything here is verified against fixtures rather than live artifacts.

Two duplication facts shape several steps below. The renderer exists twice —
`scripts/build-plan-html.mjs` and `scripts/lib/plan-shell.mjs` are the sources,
re-copied byte-for-byte under `kit/plugins/plan-agent/scripts/`, with
`tests/plugins/test-build-plan-html.mjs:557` asserting the parity. The plans-index
builder exists three times, all byte-identical. Every change here must land in
every copy, or the suite fails and gallery regeneration silently drops the chip.

## Files

- kit/plugins/plan-agent/skills/prototype/reference/PROTOTYPE-SKELETON.html (modified) — add the `#proto-model` JSON block
- kit/plugins/plan-agent/skills/prototype/SKILL.md (modified) — pin the `proto-source` format, serialize the model, write the link back into the source plan spec
- scripts/lib/plan-shell.mjs (modified) — optional `plan-prototype` meta tag and the header link (repo-root source)
- kit/plugins/plan-agent/scripts/lib/plan-shell.mjs (modified) — byte-identical re-copy of the above
- scripts/build-plan-html.mjs (modified) — thread the `prototype` frontmatter key into both `metaTags()` and `header()` (repo-root source)
- kit/plugins/plan-agent/scripts/build-plan-html.mjs (modified) — byte-identical re-copy of the above
- kit/plugins/plan-agent/hooks/build-index.sh (modified) — prototype chip on the plans gallery card
- scripts/build-plans-index.sh (modified) — byte-identical re-copy of the above
- docs/plans/build-index.sh (modified) — byte-identical re-copy of the above
- kit/plugins/plan-agent/hooks/check-prototype-drift.py (new) — the drift comparison
- kit/plugins/plan-agent/hooks/dispatch.py (modified) — fan out to the drift check on prototype writes
- kit/plugins/plan-agent/README.md (modified) — document the new hook and the `prototype:` / `plan-prototype` keys
- kit/plugins/plan-agent/CHANGELOG.md (modified) — 4.4.0 entry
- .claude-plugin/marketplace.json (modified) — bump plan-agent 4.3.1 to 4.4.0
- tests/plugins/test-prototype-plan-link.mjs (new) — objective test
- tests/plugins/test-prototype-drift.sh (new) — drift-hook cases
- tests/plugins/test-build-plan-html.mjs (modified) — back-compat case for specs with no `prototype:` key

## Steps

1. Add `<script type="application/json" id="proto-model">{{PROTO_MODEL}}</script>` to `PROTOTYPE-SKELETON.html` immediately after the existing `#seed` block at line 63. Why: the derived model needs a durable home in the prototype before anything can compare against it, and sitting beside `#seed` keeps both machine-readable blocks together. Verify: `grep -c 'id="proto-model"' kit/plugins/plan-agent/skills/prototype/reference/PROTOTYPE-SKELETON.html` prints 1.
2. Pin the `{{SOURCE_PLAN}}` contract in `skills/prototype/SKILL.md`: on the plan path it is the repo-relative path of the plan's markdown spec (`docs/plans/<slug>.md`), not a title or free text; on the idea, image, and Figma paths it stays empty. Why: the drift hook resolves the owning plan from `proto-source`, and today that token is undefined free text that only ever fed the gallery card's display string — without a format contract the whole comparison is unimplementable. Verify: the skill states the format explicitly and `build-prototypes-index.sh` still renders the value as its "from `<plan>`" card text.
3. Extend Step 5 of `skills/prototype/SKILL.md` to substitute `{{PROTO_MODEL}}` with the Step 3 model serialized as compact single-line JSON — keys `entity`, `fields` (each `{name, type}`), `action`, `successSignal` — using the same script-breakout escaping rule already documented for `{{SEED_JSON}}`, never HTML escaping. Why: `JSON.parse` on an HTML-escaped block fails the same way it would for the seed, and the existing rule is already written down one paragraph above. Verify: the skill text names `{{PROTO_MODEL}}` in its placeholder list and states the script-breakout rule applies to it.
4. Add a write-back step to `skills/prototype/SKILL.md` that runs **before** the prototype HTML is written in Step 6, resolving the plan-path input's `.html` to its sibling `.md` spec by extension swap and writing `prototype: docs/prototypes/<slug>.html` plus `proto-model: <compact single-line JSON>` into that spec's frontmatter — plan path only, skipped for idea, image, and Figma inputs. When the sibling `.md` does **not** exist, skip the write-back entirely, still generate the prototype, and print one line telling the user to run `node scripts/extract-plan-spec.mjs <plan>.html > <plan>.md` first if they want the back-link. The JSON must be single-line: never pretty-printed, never containing a raw newline or a bare `---`. Why: 69 of the 84 non-index plans under `docs/plans/` are legacy HTML with no spec sibling, so a blind extension swap would fail generation or write an empty spec for the majority of real inputs — and materializing a spec as a side effect of prototyping would silently rewrite a plan the user never asked us to touch. The frontmatter parser is also a naive line scanner, so an embedded newline or `---` silently truncates the block and corrupts `status` and `created` for all three consumers that re-scan it. Verify: run the skill against a fixture plan spec and confirm both keys land on one line each and `node scripts/extract-plan-spec.mjs` still parses the plan; run it against a legacy HTML plan with no sibling and confirm the prototype is still written, no spec is created, and the notice is printed.
5. Thread `prototype` through the renderer in three places: read `parsed.metadata.prototype` in `build-plan-html.mjs` near the existing `parsed.metadata.created` handling; pass it to `shell.metaTags()`, which emits `<meta name="plan-prototype">` conditionally; and extend `shell.header()`'s parameter list **and its call site in `build-plan-html.mjs`** to render an anchor inside `.plan-header-actions` beside the effort badge, with visible text `View prototype` and `aria-label="View the interactive prototype for this plan"`. Compute its `href` with `path.relative()` from the rendered plan's **output directory** to the repo-relative `prototype:` target — never a hard-coded `../prototypes/`. Apply every change to `scripts/build-plan-html.mjs` and `scripts/lib/plan-shell.mjs`, then re-copy both byte-for-byte to `kit/plugins/plan-agent/scripts/`. Why: `plansDirectory` is configurable, so a hard-coded `../prototypes/` resolves to `custom/prototypes/` for a plan rendered under `custom/plans/` while the prototype is written to `docs/prototypes/` — and nested plan directories break the same way; and `tests/plugins/test-build-plan-html.mjs:557` asserts the bundled renderer is byte-identical to the repo-root source, so editing only the bundled copy fails the suite and leaves callers of the root renderer without `prototype:` support. Verify: render a spec carrying `prototype:` from both `docs/plans/` and a custom plans directory and confirm the meta tag, a header anchor with non-empty accessible text, and an href that resolves in each; render one without it and confirm none do; `diff scripts/build-plan-html.mjs kit/plugins/plan-agent/scripts/build-plan-html.mjs` is empty.
6. Add a prototype chip to the plans gallery card alongside the existing `card-date` span, as a text-bearing span matching the existing `status-chip` / `type-chip` / `effort-chip` pattern, carrying a `title` explaining that the prototype opens from inside the plan. It must **not** be an anchor — the whole card is already wrapped in `<a class="gallery-card">` at line 149, and a nested `<a>` is invalid HTML that browsers silently unnest. Apply the identical change to all three byte-identical copies of the builder: `kit/plugins/plan-agent/hooks/build-index.sh`, `scripts/build-plans-index.sh`, and `docs/plans/build-index.sh`. Why: an icon-only chip gives screen reader and voice-control users no signal a prototype exists, while a nested anchor breaks the card's click target; and regenerating the gallery through either un-updated copy would drop the chip and overwrite an index that already had it. Verify: the emitted card contains a chip with non-empty text and no `<a` nested inside another `<a`; `diff` between all three builder copies is empty.
7. Write `hooks/check-prototype-drift.py`, reading the `PostToolUse` JSON payload on stdin and running two comparisons: (A) the prototype's `#proto-model` field names against the `<th>` headers and form field `name`/`id` attributes present in that same file, and (B) the prototype's `#proto-model` against the `proto-model:` frontmatter of the plan its `proto-source` names. Resolve that plan path under the plans directory only, and read its frontmatter with a single-line regex (`^proto-model:\s*(.*)$` then `json.loads`) in the style of `validate-plan-filename.py`'s `_is_completed` — not a general YAML parser. Stay silent when the plan is missing, when either `proto-model` is absent, or when either fails to parse. Each warning names the two files, the diverging field, and what to re-run. Always `sys.exit(0)` — never exit 2, even though `dispatch.py` would propagate it as actionable feedback. Why: (A) is the only check that catches a human hand-editing the prototype, which is the case the whole feature exists for; a second general-purpose Python frontmatter parser would silently diverge from the JS one in `plan-spec.mjs` over time; and exiting 0 matches every other hook in this plugin, keeping a drift report about some other plan from interrupting whatever the user is actually doing. Verify: run against a matching fixture pair (silent), a diverged pair (two warnings naming files and fields), and a plan with no `proto-model` (silent).
8. Register the drift check in `dispatch.py` by appending it to the `is_prototype` branch after the existing `build-prototypes-index.sh` call, sharing the same `deadline`. Why: `dispatch.py` already gates on `_PROTOTYPES_MARKER` and fans out, so no `hooks.json` change is needed — but the children share one 55s budget with a 5s per-child floor, so the cheaper check goes last and must stay cheap or it gets skipped by the fail-open path and drift silently stops being detected. Verify: `grep -n check-prototype-drift kit/plugins/plan-agent/hooks/dispatch.py` shows it inside the `is_prototype` block, after the index rebuild.
9. Write the three test files, document the new hook and the `prototype:` / `plan-prototype` keys in the plugin `README.md`, add the 4.4.0 CHANGELOG entry, and bump `plan-agent` from 4.3.1 to 4.4.0 in `.claude-plugin/marketplace.json`. Why: any edit under `kit/plugins/<name>/` requires a marketplace version bump, this is a feature so it is a minor one, and the plugin README documents every other hook individually. Verify: `BASE_REF=main node scripts/check-plugin-versions.mjs` exits 0.

## Tests

Tier 1 — This plan changes application code

Coverage note: the criteria covering `/plan-agent:prototype`'s own behaviour — the frontmatter write-back and the generated `#proto-model` block — are verified manually via steps 2 through 4's verify lines. A `SKILL.md` is agent instructions, not executable code, so no committed test can assert the skill performed them; the tests below cover the renderer, the gallery, and the hook only.

- Objective: a plan and its prototype reference each other and drift between them is detected. File: tests/plugins/test-prototype-plan-link.mjs; Type: smoke; Asserts: rendering a spec with `prototype:` emits the `plan-prototype` meta tag plus a header anchor with non-empty accessible text and a resolving relative href, rendering one without it emits neither, the plans gallery card gains a text-bearing chip with no nested anchor, and `check-prototype-drift.py` stays silent on a matched fixture pair while reporting on a diverged one; Run: node tests/plugins/test-prototype-plan-link.mjs
- Unit: drift-hook comparison branches. File: tests/plugins/test-prototype-drift.sh; Targets: check-prototype-drift.py; Key cases: model matches DOM and plan (silent), model diverges from own `<th>` headers, model diverges from plan frontmatter, plan exists but carries no `proto-model` yet (silent), `proto-source` names a plan that does not exist, `proto-source` resolving outside the plans directory, prototype has no `#proto-model` block, malformed JSON in either block — every case exits 0
- Integration: dispatch fan-out on prototype writes. File: tests/plugins/test-prototype-drift.sh; Targets: dispatch.py; Key cases: a synthetic prototype-write payload piped through `dispatch.py` runs both `build-prototypes-index.sh` and `check-prototype-drift.py`; a payload for an unrelated path spawns neither
- Unit: renderer back-compat and copy parity. File: tests/plugins/test-build-plan-html.mjs; Targets: metaTags, header; Key cases: a spec with no `prototype:` key renders byte-identical to its pre-change output; a spec rendered from a custom `plansDirectory` produces a resolving href; the existing byte-identical-copies assertion at line 557 still passes for both renderer files

## Acceptance Criteria

- [ ] A plan spec carrying `prototype:` renders a `plan-prototype` meta tag and a visible header link whose href resolves to the prototype file from the plan's own directory, including when the plan lives in a custom `plansDirectory`.
- [ ] The two renderer files and the three plans-index builders remain byte-identical across all their copies after the change.
- [ ] Running `/plan-agent:prototype` against a legacy HTML plan with no sibling `.md` still writes the prototype, creates no spec file, and prints a notice explaining how to get the back-link.
- [ ] A plan spec without `prototype:` renders byte-identically to its output before this change.
- [ ] The header prototype link and the gallery prototype chip both expose non-empty accessible text.
- [ ] Every prototype generated from the skeleton contains a parseable `#proto-model` JSON block, and its `proto-source` holds the repo-relative path of the plan's markdown spec.
- [ ] Running `/plan-agent:prototype` against a plan writes single-line `prototype:` and `proto-model:` keys into that plan's `.md` frontmatter before the prototype HTML is written, and prints no drift warning during generation; running it against an idea, image, or Figma input writes to no plan.
- [ ] The plans gallery card shows a prototype chip, and the emitted card HTML contains no nested anchor.
- [ ] `check-prototype-drift.py` reports divergence between a prototype's model and its rendered columns, and between a prototype's model and its plan's copy, naming both files and the diverging field.
- [ ] The drift hook exits 0 on every input, including missing files, missing blocks, out-of-tree paths, and malformed JSON.
- [ ] `BASE_REF=main node scripts/check-plugin-versions.mjs` exits 0 with plan-agent at 4.4.0.

## Verification

Build a fixture pair under a temp directory: a plan spec with single-line
`prototype:` and `proto-model:` keys, and a prototype HTML whose `#proto-model`
matches it and whose `proto-source` names the spec.

Render the spec with `node kit/plugins/plan-agent/scripts/build-plan-html.mjs
<spec>.md -o <spec>.html` and confirm the output contains `<meta
name="plan-prototype"` and a header anchor with visible text and an `aria-label`.
Open the rendered plan in a browser and click the link — it must resolve to the
prototype file, confirming the `../prototypes/` href computation.

Pipe a synthetic `PostToolUse` payload naming the prototype into
`python3 kit/plugins/plan-agent/hooks/check-prototype-drift.py` and confirm it
prints nothing and exits 0. Then edit one field name in the prototype's
`#proto-model` block, re-run, and confirm it prints two warnings — one for the
DOM mismatch, one for the plan mismatch, each naming both files and the field —
and still exits 0. Remove the `proto-model:` line from the plan spec and confirm
the run goes silent again rather than warning.

Finally run `node tests/plugins/test-prototype-plan-link.mjs`, `bash
tests/plugins/test-prototype-drift.sh`, `node
tests/plugins/test-build-plan-html.mjs`, and `bash
tests/plugins/test-build-prototypes-index.sh`; all four must pass, the last
confirming the existing gallery builder still works against a prototype carrying
the new block.

## Next Steps

- Reconcile skill — turn a detected drift into a proposed plan edit
  The hook only reports. A `/plan-agent:reconcile-prototype` skill would read both
  files, decide which side is authoritative, and propose the edit — an agent
  judgment call, deliberately not automated here.
  ```text
  Add a reconcile-prototype skill to the plan-agent plugin. It takes a prototype path,
  reads the prototype's #proto-model block and the proto-model frontmatter of the plan
  named in its proto-source meta, and when they diverge proposes concrete edits to whichever
  side is stale — asking the user which side is authoritative before writing anything.
  Reuse the comparison logic in kit/plugins/plan-agent/hooks/check-prototype-drift.py rather
  than reimplementing it.
  ```

- Handle a prototype that was moved, renamed, or deleted
  The link and chip assume the target still exists. Nothing currently notices when it stops existing.
  ```text
  In the agentics repo, kit/plugins/plan-agent/hooks/check-prototype-drift.py resolves a plan
  from a prototype's proto-source meta. Add the reverse check: when a plan spec carries a
  prototype: key pointing at a file that no longer exists, report it so the dead header link
  and gallery chip get noticed. Decide whether the renderer should also omit the link when the
  target is absent at render time, and say why.
  ```

- Wish list: drift badge on both galleries
  Surface staleness where people browse rather than only in hook output.
  ```text
  In the agentics repo, extend kit/plugins/plan-agent/hooks/build-index.sh and
  build-prototypes-index.sh so a plan or prototype whose linked counterpart has drifted
  renders a "drifted" badge on its gallery card. Reuse the comparison in
  check-prototype-drift.py. Keep the existing card markup valid — the plans card is already
  wrapped in an anchor, so the badge cannot be a nested link.
  ```

## Unresolved Questions

- Should a prototype regenerated from a changed plan overwrite the plan's `proto-model` silently?
  ```text
  In the agentics repo, look at the plan at docs/plans/add-prototype-plan-linking.md.
  Step 4 has the prototype skill write proto-model back into the source plan's frontmatter.
  Investigate whether that write should be unconditional or should prompt when the existing
  proto-model differs from the newly derived one, and recommend which — considering that
  regenerating from an edited plan is the intended sync direction, but silently overwriting
  also erases the evidence a drift check would have used.
  ```

## Resources

- kit/plugins/plan-agent/skills/prototype/reference/PROTOTYPE-SKELETON.html — the `proto-source` meta at line 6 and the `#seed` block at line 63 are the two existing anchors this plan builds on
- kit/plugins/plan-agent/hooks/build-prototypes-index.sh — line 119 shows how `proto-source` is already read and rendered; the drift hook reuses the same `get_meta` approach
- kit/plugins/plan-agent/scripts/lib/plan-spec.mjs — the frontmatter parser at line 330 accepts arbitrary `key: value` lines, which is why `prototype:` and `proto-model:` need no parser change, and why the written value must stay on one line
- kit/plugins/plan-agent/hooks/validate-plan-filename.py — its `_is_completed` single-line frontmatter regex is the precedent the drift hook's Python-side read follows

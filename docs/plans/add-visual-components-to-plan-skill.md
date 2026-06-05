---
status: todo
type: feature
created: 2026-06-05
repo-name: agentics
---

# Plan: Add visual components (file-tree, diagrams, charts, tables) to the implementation-plan skill

## Context

The `plan-agent:implementation-plan` skill generates self-contained HTML plan documents from a template. Today those plans are **text-only**: numbered step cards, acceptance-criteria checkboxes, a progress bar, and collapsible `<details>` blocks. There is no first-class way to show **which files a plan touches**, the **flow/architecture** it introduces, **comparisons/trade-offs**, or **tabular data** — exactly the visuals that make a plan scannable and concrete.

Two facts make this a low-risk, high-value change:

1. **A gold reference already exists in-repo.** [docs/plans/build-clean-plugin-dist.html](build-clean-plugin-dist.html) was hand-authored with a `.file-tree` (lines 848-890), a `.pipeline` flow diagram (893-937), and a 3-column comparison diagram (940-981) — all **pure CSS, design-token-driven**, and visually consistent with the rest of the template. These were authored ad-hoc for that one plan, never promoted into the template.
2. **The gallery scanner is insulated.** Both [plans-library/SKILL.md](../../kit/plugins/plan-agent/skills/plans-library/SKILL.md) and the auto-rebuild hook [hooks/build-index.sh](../../kit/plugins/plan-agent/hooks/build-index.sh) only regex-match `<meta name="plan-*">` tags and `<title>` from the head. Adding new `<body>` sections is completely transparent to them — no scanner changes needed.

**Hard constraint:** plans are **single self-contained `.html` files — no CDN, no external scripts** (SKILL.md line 218). So every visual must be **pure CSS / inline SVG**. Mermaid, Chart.js, etc. are out. The reference components already honor this.

**Decision (confirmed with user):** add all four components — file-tree, flow/pipeline diagram, comparison/bar chart, data table — as **opt-in**. The skill renders a visual *only when the plan content warrants it*; there are no mandatory placeholders that would clutter a small single-file plan.

## Objective

Promote four reusable, pure-CSS visual components (file-tree, flow/pipeline diagram, comparison/bar chart, data table) into the [SKELETON.html](../../kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.html) template as opt-in sections, and document in [SKILL.md](../../kit/plugins/plan-agent/skills/implementation-plan/SKILL.md) when and how the skill should reach for each — so generated plans can visually convey file changes, flows, comparisons, and tabular data.

## Files to modify

- [kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.html](../../kit/plugins/plan-agent/skills/implementation-plan/reference/SKELETON.html) — add component CSS into the `<style>` block (permanent), new `:root` tokens, and four opt-in `<body>` section blocks with keep/remove comments + conditional nav links.
- [kit/plugins/plan-agent/skills/implementation-plan/SKILL.md](../../kit/plugins/plan-agent/skills/implementation-plan/SKILL.md) — document the components in **Required Structure** and **HTML Output Requirements**, and add a short **Visual Components** guidance subsection.
- [kit/plugins/plan-agent/CHANGELOG.md](../../kit/plugins/plan-agent/CHANGELOG.md) — add a `v1.5.0` entry.
- [.claude-plugin/marketplace.json](../../.claude-plugin/marketplace.json) — bump plan-agent `version` `1.4.1` → `1.5.0` (MINOR: new capability, backward-compatible).

## Steps

1. **Port the three proven components into the SKELETON `<style>` block.** Copy the `.file-tree`/`.file-list`/`.file-badge` rules (reference lines 848-890), `.pipeline`/`.pipeline-node`/`.pipeline-arrow` rules (893-937), and `.allowlist-diagram`/`.allow-*`/`.diagram-subheading` rules (940-981) from [build-clean-plugin-dist.html](build-clean-plugin-dist.html) into SKELETON.html just before `</style>` (line 847). Rename the comparison classes from the build-specific `.allowlist-*`/`.allow-keep`/`.allow-drop`/`.allow-generated` to generic, reusable names (e.g. `.compare-grid`, `.compare-col`, `.compare-header`, with `--variant` modifiers for add/remove/neutral).
   - *Why:* Reuses already-validated, on-brand CSS instead of reinventing it — guarantees visual fidelity. Generic names let the comparison block serve any 2-3 way comparison, not just allowlists.
   - *Verify:* `grep -n "\.file-tree\|\.pipeline\|\.compare-grid" SKELETON.html` returns the new rules; open SKELETON.html in a browser and confirm no CSS parse errors (DevTools console clean).

2. **Tokenize the new component colors in `:root` and add net-new CSS for the bar chart and data table.** Add tokens for the hardcoded greens/ambers/reds/purples the ported CSS uses (e.g. `--del`, `--del-bg`, `--gen`, `--gen-bg`) to the `:root` block (SKELETON lines 16-34), and update the ported rules to use them. Then author two new pure-CSS components not present in the reference: (a) a **horizontal bar chart** (`.bar-chart` → `.bar-row` with a label, a `.bar-track`/`.bar-fill` sized by inline `style="--val:72%"`, and a visible numeric value) and (b) an **accessible data table** (`.plan-table` with `<caption>`, `<thead>`, `<th scope="col">`, zebra rows, token-driven borders).
   - *Why:* Eliminates one-off hex values so all visuals theme consistently; the bar chart and table are the two requested components the reference doesn't yet provide. Inline `--val` keeps the bar chart script-free.
   - *Verify:* Render a scratch HTML snippet using `.bar-chart` and `.plan-table`; confirm bars fill to the right widths and the table has a caption + scoped headers (inspect with DevTools accessibility pane).

3. **Add the four opt-in section blocks to the SKELETON `<body>`.** Insert (a) a **Files** section (`section.section-card.card-files#files`, after Context, before Steps) using `.file-tree`; (b) a **Diagram** section (`card-diagram#diagram`) using `.pipeline` and/or `.compare-grid`; (c) a **Chart** block (can live inside Diagram or as `card-chart#chart`) using `.bar-chart`; (d) a **Table** usage (the `.plan-table` pattern, usable inside any section). Wrap each optional block in a clearly delimited removal comment following the existing convention — e.g. `<!-- OPTIONAL Files section: keep and fill if the plan touches files; delete this whole block otherwise -->` — mirroring how `.plan-workflow` (lines 958-965) signals conditional removal. Include `{placeholder}` tokens inside each (e.g. `{file-tree-rows}`, `{diagram-nodes}`, `{chart-rows}`, `{table-rows}`).
   - *Why:* Opt-in means the markup ships ready-to-fill but is removed when unused; the comment convention is already understood by the skill (it does the same for workflow + unresolved-questions), so no new mechanism is introduced.
   - *Verify:* Open SKELETON.html in a browser with the optional blocks present — all four render with placeholder content; then delete one block and confirm the page still renders cleanly with no orphaned styling.

4. **Wire the new sections into the sidebar nav and confirm scroll-spy tolerates removal.** Add `<li>` entries (Files, Diagram) to the `.plan-nav` `<ul>` (SKELETON lines 928-937), documented as *add-only-when-section-kept*. Verify the scroll-spy `IntersectionObserver` (lines 1394-1415) and scroll-rail logic degrade gracefully when an optional section + its nav link are both removed (the observer iterates existing nodes, so missing sections are a no-op).
   - *Why:* The TOC must stay in sync — a nav link to a removed section is a dead anchor. The existing observer already handles a variable set of sections, so this is wiring + verification, not new JS.
   - *Verify:* In the browser, scroll through a plan containing the new sections and confirm the matching nav link highlights (`aria-current`); remove a section + its `<li>` and confirm no console errors and remaining nav links still highlight correctly.

5. **Document the components in SKILL.md.** In **Required Structure** (lines 203-214) add the optional sections: `files`, `diagram`, `chart`, `table` — each marked *(optional)* with a one-line "include when…" trigger. In **HTML Output Requirements** (lines 216-233) add bullets describing each component's classes, the keep/remove rule, the no-CDN/pure-CSS constraint, and the accessibility requirements (table `scope`/`caption`, bar-chart visible numeric labels, file badges not color-only). Add a short **Visual Components** subsection (after HTML Output Requirements) listing the four components, when each applies (Files → any multi-file plan; Diagram → process/architecture/data flow; Chart → distribution/before-after/trade-off; Table → structured mappings or option matrices), and that all are opt-in. Also note in the **Skeleton** section that optional visual blocks are removed when unused, like `.plan-workflow`.
   - *Why:* The template markup is inert without skill-side guidance telling Claude *when* to instantiate each visual and *how* to keep them accessible and self-contained. Anchoring triggers to plan content prevents gratuitous visuals.
   - *Verify:* Re-read SKILL.md and confirm Required Structure lists all four new optional sections, HTML Output Requirements describes each component + the opt-in/accessibility rules, and the new Visual Components subsection names the trigger for each.

6. **Bump version and update the changelog.** Add a `## v1.5.0 — 2026-06-05 — Add visual components (file-tree, diagrams, charts, tables) to plan template` entry to [CHANGELOG.md](../../kit/plugins/plan-agent/CHANGELOG.md) under `### Added`, following the existing newest-at-top format. Update the plan-agent `version` in [marketplace.json](../../.claude-plugin/marketplace.json) (line ~250) from `1.4.1` to `1.5.0`. Do **not** add a version to `plugin.json` (repo rule: relative-path plugins version only in marketplace.json).
   - *Why:* New skill capability is a MINOR bump per [marketplace.md](../../.claude/rules/marketplace.md); the changelog keeps the marketplace honest and discoverable.
   - *Verify:* `grep '"version"' .claude-plugin/marketplace.json` shows `1.5.0` for plan-agent; CHANGELOG top entry is v1.5.0; `plugin.json` still has no `version` field; the settings auto-validator reports marketplace.json JSON is valid.

## Acceptance Criteria

- [ ] SKELETON.html `<style>` contains pure-CSS rules for `.file-tree`, `.pipeline`, the renamed comparison grid, `.bar-chart`, and `.plan-table`, all using `:root` tokens (no stray hardcoded hex in the new rules).
- [ ] All four visual components are present in SKELETON.html as opt-in `<body>` blocks with explicit keep/remove comments and `{placeholder}` tokens.
- [ ] Removing any one optional visual block (and its nav `<li>`) leaves the plan rendering cleanly with no console errors and a consistent TOC.
- [ ] The gallery scanner is untouched and still lists the plan (meta tags + `<title>` unchanged).
- [ ] SKILL.md documents all four components: their classes, opt-in trigger conditions, accessibility requirements, and the no-CDN constraint.
- [ ] plan-agent version is `1.5.0` in marketplace.json with a matching v1.5.0 CHANGELOG entry; `plugin.json` has no version field.
- [ ] A test plan rendered in a browser displays a file-tree, a flow diagram, a bar chart, and a data table correctly and on-brand.

## Verification

End-to-end:

1. **Visual render check.** Open the updated `SKELETON.html` (or a generated test plan that exercises all four components) via a local server (`python3 -m http.server`) in the browser and confirm each component renders correctly, themed by the design tokens, with the existing progress bar / step cards / completion checklist unaffected.
2. **Opt-in / removal check.** Produce a second minimal test plan with all optional visual blocks removed; confirm it renders identically to a pre-change plan (no orphaned CSS, no dead nav anchors, clean console).
3. **Accessibility spot-check.** In DevTools, confirm the data table exposes a caption + column headers, the bar chart shows visible numeric values (not color-only), and file badges pair color with a text label.
4. **Gallery integrity.** Trigger the rebuild hook (write a plan into `docs/plans/`) and confirm [docs/plans/index.html](index.html) still lists plans with correct status/type/title — proving the new sections didn't disturb the scanner.
5. **Manifest validity.** Confirm `.claude/settings.json`'s marketplace.json auto-validator passes and the version guard (`scripts/check-version-bump.sh`) is satisfied at 1.5.0.

## Next Steps *(optional)*

- Retrofit visuals into existing plans:
  ```text
  Scan docs/plans/*.html (skip docs/plans/archive/) for plans that touch multiple files or describe a process flow but render text-only. For each strong candidate, add the new opt-in Files file-tree and/or Diagram section from the updated SKELETON.html, filling them from the plan's existing Steps/Context. Do not alter meta tags or titles. Report which plans you enhanced.
  ```

- Auto-derive a file-tree from a plan's "Files to modify" list:
  ```text
  Extend the plan-agent implementation-plan skill so that when the plan enumerates files to create/modify/delete, it automatically generates the opt-in Files file-tree section — grouping by directory and assigning new/modified/deleted badges — instead of relying on the author to hand-build it. Keep it pure CSS and self-contained.
  ```

### 🔭 Wish List

- Script-free "mini-Mermaid": a documented convention for expressing simple DAGs/flows in the `.pipeline` component so common architectures can be diagrammed from a compact author shorthand, all still inline-CSS and CDN-free.

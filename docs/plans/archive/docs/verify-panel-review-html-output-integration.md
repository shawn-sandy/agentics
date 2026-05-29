---
status: completed
type: docs
created: 2026-05-17
---

# Verification: Panel review recommendations integrated into `the-kit-plugins-product-plans-skills-pla-merry-tome.md`

## Context

The plan file `docs/plans/add-html-output-to-plan-review-agents.md`
went through the `product-plans:plan-review-agents` skill, which appended a
full `## Panel Review` section (lines 427–722) with a "Recommended Changes
to the Plan" subsection listing 19 specific edits the panel said were applied
via Pass 1. This verification cross-checks each claim against the live plan
body (lines 1–425).

## Result: All 19 recommendations are integrated

Verified by reading the plan body sections (`Reuse notes`, `Steps`,
`Verification`, `Next Steps`, `Unresolved Questions`) against section 12 of
the appended panel review.

| # | Panel recommendation | Body location | Status |
|---|---|---|---|
| 1 | Security & Escaping Contract in Step 1 spec scope | Step 1 (i), lines 115–126 (escape rules, CSP meta) | Integrated |
| 2 | Accessibility requirements in Step 1 spec scope | Step 1 (a)(b)(c)(d), lines 92–101, 134–139 (WCAG AA, landmarks, focus-visible) | Integrated |
| 3 | `<head>` requirements (charset, viewport, title, generator meta, CSP) | Step 1, lines 128–132 | Integrated |
| 4 | Collapsible default state + print expansion | Step 1 (f)(g), lines 106–111 | Integrated |
| 5 | Responsive breakpoint ≤768px | Step 1 (b), line 95 | Integrated |
| 6 | Section-presence grep (≥9) replacing line-count verify | Step 1 verify, lines 154–158 | Integrated |
| 7 | Named-variable `synthesized_report` contract in Reuse notes | Reuse notes, lines 81–84 | Integrated |
| 8 | Write failure mode clause in Step 3 | Step 3 (b), lines 200–204 | Integrated |
| 9 | Default theme `theme-default` in Step 3 | Step 3 (b), line 188 | Integrated |
| 10 | Progressive enhancement clause in Step 3 | Step 3 (b), lines 198–200 | Integrated |
| 11 | `review only` skip clause in Step 3 | Step 3 (a), lines 178–182 | Integrated |
| 12 | Path-safety (basename normalization, symlink check) in Step 3 | Step 3 (b), lines 191–195 | Integrated |
| 13 | Verification item 4 → `jq` command | Verification §4, line 291 | Integrated |
| 14 | Verification item 6 → fixture path + regression check + extended grep | Verification §6, lines 298–312 | Integrated |
| 15 | Verification items 7 (keyboard a11y) + 8 (XSS smoke test) | Verification §§7–8, lines 314–326 | Integrated |
| 16 | Floating filename-rename blockquote removed; formal Next Steps entry | Next Steps, lines 330–339 | Integrated |
| 17 | Dark mode out-of-scope + Next Steps entry | Next Steps, lines 379–388 | Integrated |
| 18 | Unresolved Questions section (three open decisions) | lines 390–425 | Integrated |
| 19 | Reference HTML skeleton requirement in Step 1 spec scope | Step 1, lines 145–149 | Integrated |

## Cross-cutting checks

- **Three blocking issues** flagged in section 4 of the review (XSS/escaping/CSP,
  Write failure mode, named-variable synthesis contract) are all present in the
  body — rows 1, 8, 7 above.
- **Three conflict resolutions** in section 13 (native `<details>` exclusivity;
  compact footer disclaimer; reference HTML skeleton scaffold) are all present —
  Step 1 (f) line 106–108, Step 1 lines 139–142, Step 1 lines 145–149.
- **Step renumbering** (existing "Clean up" step → Step 9) is captured by Step 4
  of the plan (line 217) and verified by Verification §2 (lines 282–285).

## Outstanding (by design, not gaps)

The plan now carries three explicit `## Unresolved Questions` (lines 390–425)
that the panel deferred to the user before implementation begins:

1. Markdown rendering trust boundary (preformatted vs rendered, with which renderer).
2. `review only` mode HTML output — confirm "skip Step 8 entirely" is desired.
3. Background-mode HTML path surfacing in `/product-plans:product-plans-bg`.

These are the legitimate open decisions, not missing integrations.

## Verification

- `grep -nE '^### |^## ' docs/plans/add-html-output-to-plan-review-agents.md`
  confirms the body sections referenced above are present in the order claimed.
- Spot-check rows 1, 7, 8, 13, 15 against the line numbers above — each
  recommendation's claimed location contains the recommendation's content.

## Next Steps *(optional)*

- Plan file already renamed from `the-kit-plugins-product-plans-skills-pla-merry-tome.md`
  to `add-html-output-to-plan-review-agents.md` before the first implementation
  commit (per plan-hygiene.md). Rename was done via filesystem `mv` + `git add`
  since the file was untracked; history preserved within the branch.

---
status: proposal
type: design
created: 2026-06-14
repo-name: acss-plugins
---

> **Trimmed worked exemplar — build-proposal Tier 2 regression corpus.**
> Source: <https://github.com/shawn-sandy/agentic-acss-plugins/blob/claude/design-md-spec-alignment-sitq7t/docs/plans/design-md-spec-alignment.md>
> @ `40c4735d1a1b7976f9b816d8beae1a3e5fa6ee29` (2026-06-15).
> Trimmed to front-matter + core finding + locked decisions + one appendix; the
> full proposal is ~940 lines with seven appendices and a phased roadmap.
> Sections are retained verbatim from the source for shape fidelity.

# Proposal: Aligning our markdown component patterns with `DESIGN.md`

> **This is a proposal for review, not an execution plan.** It captures the
> comparison between Google Labs' [`DESIGN.md`](https://github.com/google-labs-code/design.md)
> spec and our own markdown patterns, and proposes a two-part path: (A) let our
> components consume a `DESIGN.md`, and (B) publish a sibling spec for our
> component markdown. No spec text or code is written yet. The four load-bearing
> decisions are resolved (see Locked decisions); execution is split across two
> plans.

## The core finding

We have **two** markdown artifacts, at two different layers. `DESIGN.md`
overlaps with exactly one of them:

| Our artifact | Layer | Encodes | DESIGN.md overlap |
|---|---|---|---|
| `styles` skill + theme CSS (`light.css`/`dark.css`, `theme.schema.json`, OKLCH generator, `validate_theme.py`) | **Design-token layer** | Colors only — but with generation + WCAG contrast enforcement | **High** — this is the same layer |
| `component-<name>/reference.md` (9-section embedded-markdown shape) | **Implementation layer** | Full TSX/SCSS code, props interface, a11y contract | **None** — DESIGN.md has no equivalent |

> **`DESIGN.md` is a sibling to our `styles`/theme layer, not to our component
> `reference.md`.** Its `components` map is style tokens; our `reference.md` is
> a code-generation spec. They are complementary, which is *why* the work
> splits cleanly into two non-overlapping workstreams.

### Side-by-side: token layer

| Dimension | `DESIGN.md` | Our `styles`/theme layer |
|---|---|---|
| Authoring surface | YAML front-matter | CSS custom properties (`light.css`/`dark.css`) |
| Color roles | Recommended (non-normative): `primary`, `secondary`, `surface`, `on-surface`, `error` | **Enforced**: 15 required `--color-*` roles + 3 optional (18 total) |
| Typography tokens | First-class | **None** — no token home |
| Spacing tokens | First-class scale map | **None** — components use rem literals |
| Rounded (radius) tokens | First-class scale map | **None** — components use rem literals |
| Light/dark | Single palette; dark mode underspecified | Both modes, auto-mirrored |
| Contrast enforcement | Lint warns | **`validate_theme.py` gate** (10 WCAG AA pairs) |

The two systems are strikingly close on colors, and our contrast gate is
*stronger* than DESIGN.md's lint. The gaps are **typography, spacing, and
rounded** — DESIGN.md has token homes for all three; we have none.

## Locked decisions

Settled before this draft:

1. **Deliverable: proposal doc only.** No spec text and no adapter code in this
   pass — this document is the artifact, for review first.
2. **Token scope: full parity with `DESIGN.md`.** Give our token layer a home
   for **typography, spacing, and rounded** in addition to colors — not stay
   colors-only. This changes how components reference dimensions (rem literals →
   tokens).

Resolved in the 2026-06-14 review:

3. **Parse route: Route 1 — consume the `css-tailwind` export.** The adapter
   shells `npx @google/design.md export --format css-tailwind` and parses the
   CSS custom properties in Python stdlib. Accepts a Node/`npx` dependency in
   exchange for never drifting from the alpha grammar.
4. **`missing-primary` is a hard error.** `validate_design_md.py` rejects a
   DESIGN.md with no primary (follows the spec's normative MUST) — the primary
   is the OKLCH seed the pipeline needs.
5. **`COMPONENT.md` lives in `style-agent`.** The spec is framework-agnostic and
   publishable; acss-kit's `reference.md` docs conform to it rather than owning
   it.
6. **The component sweep ships as phased PRs.** Token homes → button pilot (with
   a golden-output test) → bulk-migrate the remaining 14.

## Appendix A — M3 → our-roles translation table (draft)

Derived from the real `paws-and-paths` example (M3 naming) against our 15
required + 3 optional roles. This is the load-bearing artifact for
`design_md_to_tokens.py`; both **collapse** (many M3 → one of ours) and
**synthesize** (M3 has no slot → OKLCH) appear.

| Our role | Source M3 token(s) | Strategy |
|---|---|---|
| `--color-background` | `background` (fallback `surface`) | direct |
| `--color-surface` | `surface` / `surface-container-lowest` | direct |
| `--color-surface-raised` | `surface-container-high` / `-highest` | collapse ladder |
| `--color-text` | `on-surface` / `on-background` | direct |
| `--color-text-muted` | `on-surface-variant` | direct |
| `--color-border` | `outline-variant` | M3 `-variant` is the *softer* outline |
| `--color-border-strong` | `outline` | M3 `outline` is the *stronger* one |
| `--color-primary` | `primary` | direct |
| `--color-primary-hover` | `primary-container` / `inverse-primary` | best-effort state |
| `--color-danger` | `error` | alias |
| `--color-success` | *(none in M3)* | **synthesize via OKLCH** (hue ≈ 145°) |
| `--color-warning` | *(none in M3)* | **synthesize** (hue ≈ 85°) |
| `--color-focus-ring` | *(none)* | **synthesize** (usually = `primary`) |

Dropped on collapse (no target role, acceptable loss): `surface-tint`, the
`*-container`/`on-*-container` accent pairs, and all `*-fixed`/`*-fixed-dim`
variants. The table itself should ship as a `styles` reference doc so the
mapping is reviewable and testable in isolation.

## Next step

On approval, convert this proposal into execution plans (the spec + adapter
work split across two phased plans). The proposal stops here; planning owns the
*how*.

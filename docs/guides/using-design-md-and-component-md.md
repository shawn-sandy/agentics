# Using `DESIGN.md` and `COMPONENT.md`

> A developer-friendly walkthrough of the two-file design system used by the `acss-kit` plugin and friends. `DESIGN.md` owns your tokens, `*.component.md` owns your components, and a coding agent stitches them into idiomatic code for any framework.

## 1. The big picture: why two files?

```text
+----------------+  {colors.primary}    +-----------------------+
|   DESIGN.md    | -------------------> |   button.component.md |
|  (tokens)      |  {spacing.sm}        |  (component spec)     |
|                |  {rounded.md}        |                       |
+----------------+ -------------------> +-----------------------+
        |                                          |
        |           agent reads both               |
        v                                          v
   theme CSS                            React / Astro / Vue / WC
```

- **`DESIGN.md`** is your *visual identity*. Colors, spacing scale, type ramp, rounded radii. Source-of-truth for tokens.
- **`*.component.md`** is a *single component*. Semantic structure, styles, behavior, accessibility — written once, framework-neutral. Pulls tokens by path (`{colors.primary}`).
- An **agent** (or generator) reads both and emits idiomatic code for your target framework.

The two files are loosely coupled through the **file format**, never through shared code or a shared component list. A button's COMPONENT.md doesn't know which DESIGN.md will theme it; it just declares it needs `{colors.primary}`.

The core observation: a component's semantic structure (HTML), styling (CSS + tokens), and accessibility contract are framework-agnostic web primitives. Only two things are framework-specific — template syntax and reactivity/state binding. COMPONENT.md captures the neutral majority as the source of truth and treats frameworks as **projection targets**.

This is *source portability* rather than *runtime portability*: contrast Web Components which compile once and ship a runtime bundle. Here you generate owned, idiomatic code with zero runtime coupling.

## 2. `DESIGN.md` — the token source

`DESIGN.md` is the [Google Labs design-token format](https://github.com/google-labs-code/design.md). All the data lives in YAML front-matter; the body is human prose.

### Minimal skeleton

```markdown
---
colors:
  primary: '#855300'        # quote the hex — a bare # opens a YAML comment
  on-primary: '#ffffff'
  surface: '#fffbf7'
  text: '#1c1410'
spacing:
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
rounded:
  sm: 4px
  md: 8px
  lg: 16px
typography:
  label-md:
    fontFamily: "system-ui, sans-serif"
    fontSize: 14px
    fontWeight: 500
    lineHeight: 1.4
components:                 # freeform per-project notes — never referenced from COMPONENT.md
  hero: "use surface + lg radius"
---

# My Project — Design System
```

### The non-negotiable rules

| Rule | Why |
|---|---|
| A `primary` color **must** be defined | `acss-kit` hard-fails without it — `primary` seeds the OKLCH color palette and all derived roles. |
| Quote your hex values (`'#855300'`) | A bare `#` opens a YAML comment and silently truncates your color. |
| Unique `##` section headings | Duplicate headings are a spec error. |
| `{token.path}` refs must resolve | A reference to an undefined token uses the CSS fallback and emits a warning. |

### Validate before commit

```bash
python3 plugins/acss-kit/scripts/validate_design_md.py DESIGN.md
```

This shells out to `npx @google/design.md lint` under the hood — you need Node and `npx` available.

### A note on the `components:` block

The `components:` block in `DESIGN.md` is freeform per-project metadata — notes to yourself or your team. It's deliberately **not** referenceable from a COMPONENT.md (`{components.hero}` is an error). The two-file boundary is enforced by the spec: COMPONENT.md can only reach into primitive groups (`colors`, `spacing`, `rounded`, `typography`).

When `acss-kit` imports a DESIGN.md exported from Figma or Material 3, it translates role names: `on-surface` → `--color-text`, `outline-variant` → `--color-border`, `error` → `--color-danger`. Roles M3 omits (`success`, `warning`, `focus-ring`) are OKLCH-synthesized on import.

## 3. `COMPONENT.md` — the framework-neutral component spec

One file = one component. Filename convention: `<name>.component.md`.

### The structure

A COMPONENT.md is **bipartite**:

1. **YAML front-matter** — the machine-readable contract (props, tokens, a11y criteria, targets).
2. **Markdown body** — the canonical semantic structure, styles, behavior, and accessibility — all written once for any framework.
3. **(Optional) `## Target: <framework>` adapter blocks** — idiom hints or full templates per framework, after the neutral body.

### Front-matter — the contract

```yaml
---
spec: component.md                  # required — format marker
version: alpha                      # required — pin a commit SHA when depending on it
name: button                        # required — kebab-case id
element: button                     # required — the semantic host element
role: button                        # optional — explicit ARIA role (omit when implicit)
tokens:
  background: "{colors.primary}"    # primitive groups only
  textColor:  "{colors.on-primary}"
  rounded:    "{rounded.md}"
  paddingInline: "{spacing.md}"
props:
  type:
    values: [button, submit, reset]
    required: true
  disabled:
    type: boolean
    maps-to: "aria-disabled"        # how it surfaces in the DOM
    a11y: "stays in tab order; blocks activation"
  size:
    values: [xs, sm, md, lg, xl, 2xl]
    maps-to: "data-btn"
slots: [children]
variants:
  outline: { maps-to: "data-style=outline" }
  pill:    { maps-to: "data-style=pill" }
behavior: disabled-activation-guard  # ref to a Behavior section id; omit for presentational
a11y: [1.4.11, 2.1.1, 2.4.7, 2.5.8, 4.1.2]
targets: [react, html, astro, angular, vue, svelte, web-component]
---
```

### Required body sections

| Section | Required | What it contains |
|---|---|---|
| `## Overview` | optional | One paragraph: purpose + key accessibility note. |
| `## Semantic Structure` | **yes** | The canonical structure as semantic HTML: element tree, `data-*` variant hooks, ARIA, slot placeholders (`<!-- slot: children -->`). This is what every target projects from. |
| `## Props` | optional | Human-readable table elaborating the front-matter `props`. |
| `## Tokens & CSS Variables` | optional | Component CSS custom properties, each `var(--x, <fallback>)`. |
| `## Styles` | **yes** | Pure CSS — selectors, `[data-*]` variants, `[aria-disabled]`, `:focus-visible`. Travels as-is everywhere. |
| `## Behavior` | yes if stateful | A behavior **spec** (triggers, state transitions, ARIA effects) **plus** a vanilla `init(root)` reference implementation. Omit for purely presentational components. |
| `## Accessibility` | **yes** | Keyboard, ARIA, focus, target size, contrast, WCAG 2.2 AA criteria addressed. |
| `## Examples` | optional | Usage as neutral HTML. |

### A tiny worked Semantic Structure

```html
<!-- ## Semantic Structure -->
<button
  type="{type}"
  data-btn="{size}"
  data-color="{color}"
  data-style="{variant}"
  aria-disabled="{disabled}"
>
  <!-- slot: children -->
</button>
```

The agent treats `{size}`, `{color}`, and `{disabled}` as prop-driven attributes. Anywhere `data-*` appears in the structure, a matching CSS selector lives in `## Styles`.

### How abstract props become real code

The "abstract prop model" (`values` / `type` / `required` / `default` / `maps-to`) carries enough information for an agent to emit a TS interface, an Angular `@Input()`, a Vue `defineProps`, or plain attributes — without you writing each variant by hand.

`maps-to` is the magic word: it ties an abstract prop to a real DOM expression (`maps-to: "data-btn"` means `data-btn="${size}"`). Selectors in `## Styles` hang off the same attribute, which is why one CSS block themes every projection.

For **presentational** components (image, link, list — no `behavior` field), projection is lossless: the agent reads the neutral body and emits idiomatic code with zero per-framework adapter. For **stateful** components (dialog, menu), the `init(root)` vanilla reference is the canonical semantics that React hooks, Vue composables, and Svelte actions all realize.

### Target adapters (`## Target: <framework>`)

After the neutral body, you *may* include adapter blocks:

````markdown
## Target: react

generation: { export: Button, file: button.tsx, scss: button.scss, imports: "UI from '../ui'" }

```tsx
// idiomatic React/TSX template + TS props live here
```
````

**When present**, the generator uses the adapter directly. **When absent**, the generator projects from the neutral body. Recommended policy:

- Presentational components → no adapters needed.
- Stateful/compound components → ship adapters for targets where projection is non-obvious.

## 4. The day-to-day workflow

Here's the loop most often used with `acss-kit`:

```bash
# 1. Scaffold or update your DESIGN.md
/acss-kit:theme-create        # generate light/dark from a seed hex
/acss-kit:design-export       # round-trip the current theme back to DESIGN.md

# 2. Validate it
python3 plugins/acss-kit/scripts/validate_design_md.py DESIGN.md

# 3. Add or update a component from its COMPONENT.md
/acss-kit:kit-add button      # reads button.component.md, emits SCSS + idiomatic TSX

# 4. Bulk install everything tracked
/acss-kit:kit-sync            # writes .acss-kit/manifest.json for safe upgrades

# 5. After upgrading the plugin, re-copy unmodified files
/acss-kit:kit-update          # sha256 drift detection — never clobbers user edits
```

The two-file split makes each command's job clear:

- `theme-*` skills touch **DESIGN.md** only.
- `kit-*` skills touch **COMPONENT.md** files and generated outputs.
- `style-tune`, `theme-update`, `utility-tune` work over the same primitive token namespace.

## 5. Quick reference: spec contract

| Scenario | Behavior |
|---|---|
| Unknown body section | Preserve; do not error |
| Missing a required section | Error; reject the file |
| Duplicate section heading | Error; reject the file |
| Unknown front-matter key | Accept with warning |
| Unknown `## Target:` framework | Preserve; best-effort projection |
| `tokens:` reference to `components.*` | Error — primitive groups only |
| Reference to an undefined `{token.path}` | Use the CSS fallback; warn |

## 6. Mental model — when to reach for which file

| You want to... | Edit which file? |
|---|---|
| Change the brand primary across every component | **`DESIGN.md`** → `colors.primary` |
| Tighten the spacing scale | **`DESIGN.md`** → `spacing.*` |
| Add a new variant to one component | **`*.component.md`** → `variants:` + `## Styles` selector |
| Add a new prop to one component | **`*.component.md`** → `props:` + `## Semantic Structure` placeholder |
| Override how React (only) renders this component | **`*.component.md`** → `## Target: react` block |
| Add a brand-new component | New **`my-thing.component.md`** file |

## What to do next

- Read the real `COMPONENT.md` spec inside the `style-agent` plugin (`docs/component-md/spec.md`).
- Read a fully worked example: the `acss-kit` plugin's `component-button/button.component.md`.
- For a wider lens on the runtime-portable vs source-portable trade-off, see the framework-agnostic design systems review in the `acss-plugins` docs.

Pin a commit SHA when you depend on this format — `version: alpha` means it will change.

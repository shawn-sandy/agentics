# Fidelity Ladder and MDX Safety Rules

Loaded on demand by `artifact-to-post`. Two independent concerns: **which form
each block takes** (the ladder) and **what will not compile** (the safety rules).

## (a) The fidelity ladder

Applied per content block. Take the **highest rung that holds** — never
screenshot something that could have been a table.

### Rung 1 — Native Markdown

Headings, prose, lists, tables, blockquotes, fenced code. The majority of any
document lands here. No HTML, no scoping, nothing to escape beyond the prose
rules in section (b).

### Rung 2 — Scoped inline HTML (no JS)

For interactivity the browser provides for free: `<details>`/`<summary>`,
`<dialog>`, `<input type="range">`, native `<table>` with sticky headers.

Wrap the block in a single container and prefix **every** rule from the
artifact's CSS with that container's selector:

```html
<div class="artifact-embed artifact-embed--slug">
  <style>{`
    .artifact-embed--slug details { border: 1px solid #ccc; }
    .artifact-embed--slug summary { cursor: pointer; }
  `}</style>
  <details>
    <summary>Show the numbers</summary>
    <p>…</p>
  </details>
</div>
```

This is the design-token fix. Unscoped, the artifact's `h2 { … }` repaints the
whole site; scoped, it cannot reach past the container. And unlike a screenshot,
the disclosure still opens.

Drop any artifact rule targeting `html`, `body`, `:root`, or `*` — those cannot
be meaningfully scoped, and they are exactly the ones that leak.

### Rung 3 — Scoped HTML plus the artifact's own inline `<script>`

Charts, calculators, anything whose behavior lives in JS the artifact already
carries. Same scoping rules as rung 2, plus the original `<script>`.

**Rung 3 is version-sensitive.** Whether a `<script>` inside MDX is bundled,
hoisted, or dropped depends on the target site's Astro/MDX version. The site
build is the authority — never assume. If the build or the browser shows the
script inert, demote that block to rung 4 and record the observed behavior for
that Astro version at the bottom of this file.

Scripts must not depend on globals the artifact loaded from a CDN — the site's
CSP may block them. A block whose script needs an external library is a rung-4
block.

### Rung 4 — Screenshot plus a link

Last resort, for blocks that genuinely cannot be ported: canvas rendering,
WebGL, heavy third-party embeds. Capture into the configured images directory,
emit an `<img>` with real alt text, and link to the live artifact underneath so
the reader can still interact with the original.

A rung-4 block is a small failure, not a neutral choice. Prefer demoting one
block to rung 4 over screenshotting the whole page.

### Ceiling

`interactivity_ceiling` in `CONTENT.md` caps **how interactive an embed may
be** — that is, it caps rungs 2 and 3 only. A site that forbids inline scripts
sets the ceiling at 2; every rung-3 candidate then falls to rung 4.

**Rung 4 is never capped.** It is the fallback, not the top of the ladder — it
is the *least* interactive outcome, so no ceiling can forbid it. A ceiling of 3
does not mean "rung 4 is off limits"; it means scripts are allowed.

**Never drop a block.** If a block cannot be ported at its natural rung, it
falls to rung 4 and is captured as an image. Deleting content because of a
ceiling is a bug, not a policy — the reader loses something the artifact had,
silently.

## (b) MDX safety rules

MDX parses Markdown as JSX. Constructs that are inert in `.md` are fatal in
`.mdx`.

### In unfenced prose

| Hazard | Why it fails | Fix |
|--------|--------------|-----|
| `{` / `}` | Opens a JSX expression | Escape as `\{` and `\}` |
| `{ id }` | Parsed as an expression referencing an undefined `id` | `\{ id \}` |
| `<T>` | Parsed as an unknown JSX component | Wrap in a code span: `` `<T>` `` |
| `Array<string>` | `<string>` parsed as a JSX tag | Wrap in a code span: `` `Array<string>` `` |
| `<https://example.com>` | Autolink read as a JSX tag | Use a normal Markdown link |

The canonical failure cases are `Array<string>`, `{ id }`, `<T>`, and bare
autolinks. If a rule ever gets deleted, those are the ones to restore first.

### What must be left untouched

Fenced code blocks and inline code spans are already safe — MDX does not parse
them as JSX. **Do not escape inside them.** Escaping a fenced block is a visible
bug: readers see `\{` in the sample they are meant to copy.

The safety pass therefore operates on prose regions only: split on fence
delimiters, skip fenced regions, skip inline code spans, transform the rest.

### Ordering

The safety pass runs **after** the human prose rewrite. The rewrite is what
introduces the hazards — a writer explaining a generic naturally types
`Array<string>` into prose. Running the pass first means shipping a build
failure the pass was written to prevent. Do not reorder these steps.

### In HTML emitted at rungs 2–3

That HTML lands in a JSX parser — but **which** JSX runtime decides the
attribute names, and the two runtimes disagree. Check the target first:
`@astrojs/mdx` in `package.json` means Astro's runtime; Next.js,
`@mdx-js/react`, or plain `@mdx-js/mdx` means React's.

These four are parser-level and apply to **every** runtime:

- all void tags self-closed: `<br />`, `<img … />`, `<input … />`, `<hr />`
- `<!-- comment -->` → `{/* comment */}`
- CSS and script bodies go inside a template literal expression —
  `<style>{\`…\`}</style>` — so braces in the CSS are not read as JSX
- expression braces in attribute values are JSX, not text

#### Astro (`@astrojs/mdx`) — the default target

Astro compiles MDX with `jsxImportSource: 'astro'` and serializes intrinsic
elements straight to HTML. Attribute names pass through **verbatim**, except a
short special-case list. So keep the artifact's own HTML attributes:

- **`for`, not `htmlFor`.** This is the one that actually breaks a page.
  `htmlFor` is not mapped — it renders literally as `htmlFor="…"`, the browser
  ignores it, and the label/input association is silently lost. No build error,
  no console warning.
- **`class`, not `className`.** Both work (Astro rewrites `className` → `class`),
  but `class` is the native form and matches what you pasted from the artifact.
- **`style` as a string** — `style="color: red"`. An object works too (Astro
  kebab-cases the keys), but the string form is already in the artifact.
- **`tabindex`, `colspan`, `readonly`** — lowercase HTML spellings. The camelCase
  variants happen to survive (HTML attribute names are case-insensitive), so
  converting them is pointless churn.

The rule of thumb for Astro: **change nothing you don't have to.** Only the four
parser-level rules above are mandatory.

#### React-based MDX pipelines

If the target is Next.js, `@mdx-js/react`, or `@mdx-js/mdx` on the React
runtime, the opposite holds and these become required:

- `class` → `className`, `for` → `htmlFor`
- `tabindex` → `tabIndex`, `colspan` → `colSpan`, `readonly` → `readOnly`
- `style` as an object, not a string: `style={{ color: 'red' }}`

## Observed rung-3 behavior by Astro version

Record real observations here; leave inference out.

| Astro / `@astrojs/mdx` | Inline `<script>` in MDX | Notes |
|------------------------|--------------------------|-------|
| _(unverified)_ | _(unverified)_ | Fill in from a real site build — see the skill's verification phase |

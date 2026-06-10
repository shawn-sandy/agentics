# Props Extraction Reference

## Goal

Produce `{{PROPS_ROWS}}`: a sequence of HTML `<tr>` rows — one row per prop — for the card's full-API props table. Columns, in order: name · type · required · default · description.

- Emit only `<tr>` elements, joined by single newlines. The card template supplies the surrounding `<table>`, `<thead>`, and `<tbody>`.
- Use the Typed Path below whenever the component declares types; use the Inference Fallback only when it does not.

## Typed Path (preferred)

Locate the component's prop types in this priority order and use the first source that exists:

1. `interface XxxProps { ... }` or `type XxxProps = { ... }` — the named type referenced by the component's props parameter.
2. Inline prop type annotation on the function signature — `function Button({ size }: { size?: string })`.
3. `React.FC<Props>` generic — `const Button: React.FC<ButtonProps> = ...`; resolve the generic argument to its declaration.
4. `propTypes` — `Button.propTypes = { ... }` on untyped JS components.

Extract five fields per prop:

| Field | Rule |
|-------|------|
| name | The property key, verbatim. |
| type | The TS type text, verbatim but compacted — collapse newlines and runs of whitespace to single spaces; drop trailing `;` or `,`. For `propTypes`, use the validator text with the `PropTypes.` prefix and `.isRequired` suffix removed (e.g. `PropTypes.arrayOf(PropTypes.string).isRequired` becomes `arrayOf(string)`). |
| required | `yes` when the property has no `?` modifier; `no` when it does. For `propTypes`: `yes` when the validator chain ends in `.isRequired`, otherwise `no`. |
| default | The destructuring default from the component signature (`{ size = "md" }` gives `"md"`) or the matching `defaultProps` entry. No default: use `—`. |
| description | The JSDoc `/** ... */` block directly above the prop, or a trailing `//` comment on the prop's line. Strip comment markers; keep it to one sentence. None: use `—`. |

## Inference Fallback (no explicit types)

When none of the typed sources exist:

1. Derive the prop list from the function-signature destructuring (`function Card({ title, onClose })`) plus any `props.x` member accesses in the component body and JSX.
2. Infer each type heuristically by name:

| Name pattern | Inferred type |
|--------------|---------------|
| `onXxx` | `function` |
| `isXxx`, `hasXxx`, `disabled` | `boolean` |
| `children` | `ReactNode` |
| `className` | `string` |
| `count`, `index` | `number` |
| anything else | `unknown` |

3. Set the required cell to `—` for every prop — requiredness cannot be determined without types.
4. Note the inference in the description cell: `Type inferred from usage.` When a real trailing comment exists, keep the comment and append the note after it.
5. Destructuring defaults still apply on this path: `{ size = "md" }` fills the default cell.

## Row Template

One row per prop, exactly this markup:

```html
<tr><td><code>NAME</code></td><td><code>TYPE</code></td><td>yes|no|—</td><td><code>DEFAULT</code> or —</td><td>DESCRIPTION or —</td></tr>
```

- Wrap the name, type, and default values in `<code>`.
- When there is no default, the cell is a bare `—` with no `<code>` wrapper; same for an empty description.
- The required cell is plain text: `yes`, `no`, or `—` (inference fallback only).

## Escaping (mandatory)

HTML-escape every cell value — name, type, default, and description — in this exact order: `&` to `&amp;` first, then `<` to `&lt;`, then `>` to `&gt;`, then `"` to `&quot;`. Escaping `&` first prevents double-escaping the entities the later passes produce.

Type strings are the highest-risk cells: generics, arrows, and quoted union members contain `<`, `>`, and `"` that break the table markup if left raw. A type like `ReactNode | string` passes through unchanged only because it contains none of the four characters — never skip the pass.

- `Record<string, number>` becomes `Record&lt;string, number&gt;`
- `(e: MouseEvent) => void` becomes `(e: MouseEvent) =&gt; void`
- `"sm" | "md"` becomes `&quot;sm&quot; | &quot;md&quot;`
- `A & B` becomes `A &amp; B`

## Large Prop Sets

- Cap the table at 12 prop rows.
- With 12 or fewer props, keep source declaration order and emit no overflow row.
- With more than 12, order required props first, alphabetical by name within each group, and keep the first 12.
- When capped, append one final overflow row, where N is the count of omitted props (total minus 12):

```html
<tr><td colspan="5">+ N more props — see source</td></tr>
```

## Worked Example

Source — `Button.tsx`:

```tsx
interface ButtonProps {
  /** Visible label rendered inside the button. */
  label: string;
  onClick: (event: React.MouseEvent<HTMLButtonElement>) => void;
  size?: "sm" | "md" | "lg";
  disabled?: boolean;
  children?: React.ReactNode;
}

export function Button({ label, onClick, size = "md", disabled, children }: ButtonProps) {
  // ...
}
```

Exact `{{PROPS_ROWS}}` output — five props, source order, no overflow row:

```html
<tr><td><code>label</code></td><td><code>string</code></td><td>yes</td><td>—</td><td>Visible label rendered inside the button.</td></tr>
<tr><td><code>onClick</code></td><td><code>(event: React.MouseEvent&lt;HTMLButtonElement&gt;) =&gt; void</code></td><td>yes</td><td>—</td><td>—</td></tr>
<tr><td><code>size</code></td><td><code>&quot;sm&quot; | &quot;md&quot; | &quot;lg&quot;</code></td><td>no</td><td><code>&quot;md&quot;</code></td><td>—</td></tr>
<tr><td><code>disabled</code></td><td><code>boolean</code></td><td>no</td><td>—</td><td>—</td></tr>
<tr><td><code>children</code></td><td><code>React.ReactNode</code></td><td>no</td><td>—</td><td>—</td></tr>
```

Row-by-row checks: `label` has no `?` so required is `yes`, and its JSDoc fills the description. `onClick` keeps the verbatim function type with `<`, `>`, and the `=>` arrow escaped. `size` is optional, its union quotes are escaped, and the destructuring default `"md"` fills the default cell as `&quot;md&quot;`. `disabled` and `children` are optional with no default and no description, so those cells are `—`.

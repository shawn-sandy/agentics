# tabs-demo

Demo project for the `tdd-loop` skill. Not part of the agentics-kit marketplace product surface.

Implements an accessible WAI-ARIA Tabs component using the `tdd-loop` autonomous red-green loop:
the test suite was written first and committed as `test:`, then the implementation was produced
by the skill's iteration loop and committed as `feat:`.

## Setup

```bash
npm install
```

## Scripts

| Script | Command | Purpose |
|--------|---------|---------|
| `test` | `vitest run` | Run test suite once |
| `test:watch` | `vitest` | Watch mode |
| `typecheck` | `tsc --noEmit` | Type-check without emitting |
| `lint` | `eslint src/` | Lint with jsx-a11y rules |

## Acceptance Criteria (Tabs component)

1. Renders `role="tablist"` with N `role="tab"` and N `role="tabpanel"` elements.
2. Exactly one tab has `aria-selected="true"`; its panel is visible, others have `hidden`.
3. Clicking a tab selects it and shows its panel.
4. `ArrowRight` / `ArrowLeft` move focus + selection between tabs (wraps at ends).
5. `Home` / `End` jump to first / last tab.
6. Tabs link panels via `aria-controls` ↔ panel `id`; panel references tab via `aria-labelledby`.
7. Tabs with `disabled` prop render with `aria-disabled="true"` and are skipped by keyboard nav and clicks.
8. Roving tabindex: selected tab `tabindex="0"`, all others `tabindex="-1"`.
9. Each tabpanel has `tabindex="0"` so screen reader users can Tab into panel content.

## Component API

```tsx
import { Tabs } from "./src/Tabs";

<Tabs
  tabs={[
    { id: "tab1", label: "Tab 1", content: <p>Panel 1</p> },
    { id: "tab2", label: "Tab 2", content: <p>Panel 2</p>, disabled: true },
  ]}
  defaultTab="tab1"
/>
```

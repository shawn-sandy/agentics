# demo-tdd-loop.sh

Contributor setup script for the `tdd-loop` skill end-to-end demo. Scaffolds an
isolated React + Vitest project under `examples/tabs-demo/` that is intentionally
**not committed** to the repo — generated fresh on demand.

## Usage

```bash
# Scaffold the project and install dependencies (~30 s)
bash examples/demo-tdd-loop.sh

# Remove the generated project and exit
bash examples/demo-tdd-loop.sh --clean
```

The script is idempotent: if `examples/tabs-demo/` already exists it prints
a notice and exits without overwriting anything. Run with `--clean` first to
reset.

## What it creates

```
examples/tabs-demo/
├── package.json          # React 18, Vitest 3, @testing-library/react, eslint-plugin-jsx-a11y
├── tsconfig.json         # strict mode, vitest/globals + @testing-library/jest-dom types
├── vitest.config.ts      # jsdom environment, globals: true
├── eslint.config.js      # flat config: jsx-a11y + @typescript-eslint/parser
├── .gitignore
├── README.md             # 9-criterion WAI-ARIA Tabs acceptance spec (the tdd-loop target)
└── src/
    └── setup.ts          # imports @testing-library/jest-dom
```

**Prerequisites:** Node.js 18+ and npm on `$PATH`. The script runs
`npm install --prefix` so your shell's working directory doesn't matter.

## After setup: run the demo

The script prints the exact steps after finishing:

**1. Open a Claude Code session at the repo root:**

```bash
cd ~/devbox/agentics
claude
```

**2. Create a feature branch** (`tdd-loop` refuses to run on `main`/`master`):

```
/git-agent:branch-agent feat/tabs-component
```

**3. Invoke the skill:**

```
/code-testing-agent:tdd-loop Implement an accessible Tabs component at
examples/tabs-demo/src/Tabs.tsx satisfying the criteria in
examples/tabs-demo/README.md. Test file: examples/tabs-demo/src/Tabs.test.tsx.
```

The skill will write the failing test suite, commit it as `test:`, loop on the
implementation (up to 20 iterations), run typecheck + lint, commit as `feat:`,
and open a PR.

## The demo target

The acceptance criteria in `examples/tabs-demo/README.md` cover the full
WAI-ARIA APG Tabs pattern:

1. `role="tablist"` container with N `role="tab"` + N `role="tabpanel"` elements
2. Exactly one `aria-selected="true"` tab; its panel visible, others `hidden`
3. Click selects tab and shows its panel
4. `ArrowRight` / `ArrowLeft` move focus + selection (wraps at ends)
5. `Home` / `End` jump to first / last tab
6. `aria-controls` ↔ panel `id`; panel `aria-labelledby` → tab `id`
7. `disabled` prop → `aria-disabled="true"`, skipped by keyboard nav and clicks
8. Roving tabindex: selected `tabindex="0"`, others `tabindex="-1"`
9. Each tabpanel has `tabindex="0"` for screen reader Tab-into-panel support

## Related

- [tdd-loop skill reference](create-tdd-loop-skill.md)
- [`kit/plugins/code-testing-agent/CHANGELOG.md`](../kit/plugins/code-testing-agent/CHANGELOG.md) — v3.3.0

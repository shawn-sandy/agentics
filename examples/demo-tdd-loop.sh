#!/usr/bin/env bash
# demo-tdd-loop.sh
#
# Sets up the tabs-demo project and prints the tdd-loop invocation so
# contributors can watch the skill work end-to-end.
#
# Usage:
#   bash examples/demo-tdd-loop.sh           # scaffold + install
#   bash examples/demo-tdd-loop.sh --clean   # remove the project and exit
#
# After running this script, follow the printed instructions to invoke
# the tdd-loop skill inside a Claude Code session.

set -euo pipefail

DEMO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/tabs-demo"

# ── clean mode ───────────────────────────────────────────────────────────────

if [[ "${1:-}" == "--clean" ]]; then
  if [[ -d "$DEMO_DIR" ]]; then
    rm -rf "$DEMO_DIR"
    echo "Removed $DEMO_DIR"
  else
    echo "Nothing to clean — $DEMO_DIR does not exist."
  fi
  exit 0
fi

# ── guard: already exists ─────────────────────────────────────────────────────

if [[ -d "$DEMO_DIR" ]]; then
  echo "tabs-demo already exists at $DEMO_DIR"
  echo "Run with --clean to remove it first, or cd into it and invoke the skill."
  exit 0
fi

echo "Creating tabs-demo scaffold at $DEMO_DIR ..."

mkdir -p "$DEMO_DIR/src"

# ── package.json ──────────────────────────────────────────────────────────────

cat > "$DEMO_DIR/package.json" <<'PKGJSON'
{
  "name": "tabs-demo",
  "type": "module",
  "private": true,
  "version": "0.0.1",
  "description": "tdd-loop demonstration: accessible WAI-ARIA Tabs component",
  "scripts": {
    "test": "vitest run",
    "test:watch": "vitest",
    "typecheck": "tsc --noEmit",
    "lint": "eslint src/"
  },
  "dependencies": {
    "react": "^18.3.1",
    "react-dom": "^18.3.1"
  },
  "devDependencies": {
    "@testing-library/jest-dom": "^6.9.1",
    "@testing-library/react": "^16.3.0",
    "@testing-library/user-event": "^14.5.2",
    "@typescript-eslint/parser": "^8.0.0",
    "@types/react": "^18.3.12",
    "@types/react-dom": "^18.3.1",
    "eslint": "^9.0.0",
    "eslint-plugin-jsx-a11y": "^6.10.2",
    "jsdom": "^26.0.0",
    "typescript": "^5.7.0",
    "vitest": "^3.0.0"
  }
}
PKGJSON

# ── tsconfig.json ─────────────────────────────────────────────────────────────

cat > "$DEMO_DIR/tsconfig.json" <<'TSCONFIG'
{
  "compilerOptions": {
    "target": "ES2020",
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "moduleResolution": "bundler",
    "jsx": "react-jsx",
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true,
    "skipLibCheck": true,
    "types": ["vitest/globals", "@testing-library/jest-dom"]
  },
  "include": ["src"]
}
TSCONFIG

# ── vitest.config.ts ──────────────────────────────────────────────────────────

cat > "$DEMO_DIR/vitest.config.ts" <<'VITESTCFG'
import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    environment: "jsdom",
    globals: true,
    setupFiles: ["./src/setup.ts"],
  },
});
VITESTCFG

# ── eslint.config.js ──────────────────────────────────────────────────────────

cat > "$DEMO_DIR/eslint.config.js" <<'ESLINTCFG'
import jsxA11y from "eslint-plugin-jsx-a11y";
import tsParser from "@typescript-eslint/parser";

export default [
  jsxA11y.flatConfigs.recommended,
  {
    files: ["src/**/*.{ts,tsx}"],
    languageOptions: {
      parser: tsParser,
      parserOptions: { ecmaFeatures: { jsx: true } },
    },
  },
];
ESLINTCFG

# ── src/setup.ts ──────────────────────────────────────────────────────────────

cat > "$DEMO_DIR/src/setup.ts" <<'SETUP'
import "@testing-library/jest-dom";
SETUP

# ── .gitignore ────────────────────────────────────────────────────────────────

cat > "$DEMO_DIR/.gitignore" <<'GITIGNORE'
node_modules/
dist/
coverage/
GITIGNORE

# ── README.md ─────────────────────────────────────────────────────────────────

cat > "$DEMO_DIR/README.md" <<'DEMOREADME'
# tabs-demo

Demo project for the `tdd-loop` skill. Not part of the agentics-kit marketplace product surface.

## Acceptance Criteria (Tabs component)

1. Renders `role="tablist"` with N `role="tab"` and N `role="tabpanel"` elements.
2. Exactly one tab has `aria-selected="true"`; its panel is visible, others have `hidden`.
3. Clicking a tab selects it and shows its panel.
4. `ArrowRight` / `ArrowLeft` move focus + selection between tabs (wraps at ends).
5. `Home` / `End` jump to first / last tab.
6. Tabs link panels via `aria-controls` <-> panel `id`; panel references tab via `aria-labelledby`.
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
DEMOREADME

# ── install dependencies ──────────────────────────────────────────────────────

echo "Installing dependencies (this may take a moment) ..."
npm install --silent --prefix "$DEMO_DIR"

echo ""
echo "────────────────────────────────────────────────────────────────────"
echo " tabs-demo is ready at:"
echo "   $DEMO_DIR"
echo ""
echo " Next steps:"
echo ""
echo " 1. Open a Claude Code session at the repo root:"
echo "      cd $(dirname "$DEMO_DIR")"
echo "      claude"
echo ""
echo " 2. Create a feature branch (tdd-loop refuses to run on main):"
echo "      /git-agent:branch-agent feat/tabs-component"
echo ""
echo " 3. Invoke the tdd-loop skill:"
echo "      /code-testing-agent:tdd-loop Implement an accessible Tabs"
echo "      component at examples/tabs-demo/src/Tabs.tsx satisfying the"
echo "      criteria in examples/tabs-demo/README.md. Test file:"
echo "      examples/tabs-demo/src/Tabs.test.tsx."
echo ""
echo " The skill will write the failing test suite, commit it as test:,"
echo " loop on the implementation, run typecheck + lint, commit as feat:,"
echo " and open a PR."
echo "────────────────────────────────────────────────────────────────────"

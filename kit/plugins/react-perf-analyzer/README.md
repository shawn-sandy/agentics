# react-perf-analyzer

Identifies React component source patterns that commonly correlate with poor scores on four W3C/WICG Web Performance metrics — produces a heuristic report with prioritized recommendations and a `PerformanceObserver` starter snippet.

For actual runtime measurements, the `/react-perf-analyzer:test` command runs Lighthouse against any live URL.

## Overview

`react-perf-analyzer` provides two complementary modes:

| Mode | How | When to use |
|------|-----|-------------|
| **Static analysis** (skill) | Auto-activates from intent | Before running the app — find likely problems early |
| **Runtime testing** (command) | `/react-perf-analyzer:test [url]` | Against a running app — get actual scored measurements |

**Metrics covered:**

| Metric | API Spec | Target | Poor |
|--------|----------|--------|------|
| Interaction to Next Paint (INP) | [Event Timing](https://w3c.github.io/event-timing/) | <200ms | >500ms |
| Cumulative Layout Shift (CLS) | [Layout Instability](https://wicg.github.io/layout-instability/) | <0.1 | >0.25 |
| Long Animation Frames (LoAF) | [Long Animation Frames](https://w3c.github.io/long-animation-frames/) | <50ms/frame | — |
| Long Tasks | [Long Tasks](https://w3c.github.io/longtasks/) | <50ms | — |

---

## Installation

```bash
# Load for local testing
claude --plugin-dir ~/path/to/plugins/react-perf-analyzer

# Install from the agentics-kit marketplace
/plugin marketplace add ~/path/to/agentics
/plugin install react-perf-analyzer@agentics-kit
```

---

## Usage

### Static Analysis — Skill (Auto-Activated)

The skill activates automatically when you describe a performance problem or ask for an analysis. No command needed.

**Trigger phrases:**

```
"Analyze the performance of my ProductList component"
"Check for INP issues in src/components/Modal.tsx"
"Find what's causing layout shifts in my app"
"Why is my component slow? Give me a performance report"
"Are there any long tasks in this React component?"
"Review my useEffect for performance problems"
```

**Providing a target file:**

You can name a specific file path, component name, or let the skill detect from your git-changed files:

```
# Explicit file path
"Analyze src/components/DataTable.tsx for performance issues"

# Component name only
"Check the SearchBar component for INP problems"

# From git changes (skill detects automatically)
"Analyze the performance of my recent changes"
```

**What the skill produces:**

1. **SSR/RSC caveat** (if applicable) — warns if the component may be a Server Component where browser APIs don't apply
2. **React version note** — caveats recommendations for React 18 concurrent features or React 19 compiler
3. **Executive Summary** — four-metric score table (Good / Needs Improvement / Poor) based on pattern count and severity
4. **Findings** — per-metric list of heuristic patterns with severity (High / Medium / Low) and approximate line references
5. **Prioritized Recommendations** — ordered by impact, with before/after code examples
6. **PerformanceObserver Starter Snippet** — ready-to-add instrumentation for all four metrics with correct CLS session windowing and LoAF → longtask fallback

**Example skill output (excerpt):**

```
## React Performance Analysis: DataTable.tsx

> Scope: Heuristic analysis of DataTable.tsx. Imported code is out of scope.
> React version: 18 (detected from package.json).

### Executive Summary

| Metric              | Score            | Findings  |
|---------------------|------------------|-----------|
| Event Timing (INP)  | Needs Improvement| 2 patterns|
| Layout Instability  | Good             | 0 patterns|
| Long Animation Frames| Good            | 0 patterns|
| Long Tasks          | Poor             | 3 patterns|

### Findings

#### Long Tasks
- **[High]** Line ~45: `rows.sort(compareFn)` in render body — expensive sort runs on
  every render; wrap in `useMemo` with `[rows, compareFn]` as dependencies
- **[High]** Line ~82: `<tr>` mapped over `data` (potentially 500+ items) — no
  virtualization; large DOM causes significant reconciliation work
- **[Medium]** Line ~12: `style={{ borderColor: theme.primary }}` passed as prop to
  memoized `<Cell>` — new object reference on every render breaks React.memo

### Prioritized Recommendations

1. **Memoize the row sort** (Long Tasks — High)
   ...
```

---

### Runtime Testing — `/react-perf-analyzer:test` Command

Runs Google Lighthouse against a live URL and returns actual Web Vitals scores with element-level findings.

**Basic usage:**

```
/react-perf-analyzer:test http://localhost:3000/dashboard
/react-perf-analyzer:test https://staging.myapp.com/products
```

**With a Storybook story URL:**

The command detects Storybook URLs automatically (via `localhost:6006` or `?path=/story/`).

```
# Test a single story
/react-perf-analyzer:test http://localhost:6006/?path=/story/button--primary

# Test all stories (command will fetch the Storybook index and ask)
/react-perf-analyzer:test http://localhost:6006
```

When testing all Storybook stories, the command:
1. Fetches the story index from `http://localhost:6006/index.json`
2. Lists all discovered stories
3. Tests each via its `iframe.html` URL (component only, no Storybook chrome)
4. Presents an aggregated summary table across all stories

**What the command produces:**

1. **Scores table** — actual Lighthouse scores (0–100) and values for INP, CLS, TBT, FCP, LCP
2. **CLS element findings** — specific DOM elements causing layout shifts with shift values
3. **Long Tasks findings** — specific scripts/resources with task durations
4. **Render-blocking resources** — assets delaying FCP/LCP
5. **Prioritized recommendations** — backed by real measurements, not heuristics
6. Optional **cross-reference** with static analysis findings — confirms which heuristic patterns are real problems vs. theoretical

**Example command output (excerpt):**

```
## Lighthouse Performance Report

URL: http://localhost:6006/iframe.html?id=datatable--large&viewMode=story
Tested: 2026-03-08 14:32

### Scores

| Metric                        | Score | Value  | Rating            |
|-------------------------------|-------|--------|-------------------|
| INP (Interaction to Next Paint)| 68   | 310ms  | Needs Improvement |
| CLS (Cumulative Layout Shift)  | 100  | 0.00   | Good              |
| TBT (Total Blocking Time)*    | 22    | 1840ms | Poor              |
| FCP (First Contentful Paint)  | 91    | 1.1s   | Good              |
| LCP (Largest Contentful Paint)| 88    | 2.3s   | Good              |

*TBT is Lighthouse's lab proxy for Long Tasks.

### Long Tasks / TBT Findings
- `main.chunk.js` — 1240ms task (sorting 2000 rows without memoization)
- `vendor.chunk.js` — 600ms task (lodash deep clone in event handler)

### Recommendations

1. **Memoize row sorting with useMemo** (Long Tasks — confirmed by Lighthouse)
   The 1240ms long task maps directly to the unsorted rows recalculated on every render.
   ...
```

**URL types supported:**

| URL type | Example | Notes |
|----------|---------|-------|
| Storybook story | `http://localhost:6006/?path=/story/button--primary` | Single story, isolated component |
| Storybook root | `http://localhost:6006` | Auto-discovers and tests all stories |
| Local dev server | `http://localhost:3000/page` | Real app context |
| Staging | `https://staging.myapp.com` | Pre-production environment |
| Production | `https://myapp.com` | Real-user equivalent |

**Prerequisites for the command:**
- Chrome or Chromium must be installed (`google-chrome`, `chromium`, or `chromium-browser` on PATH)
- Target URL must be reachable (start your dev server or Storybook first)
- `npx` is used to run Lighthouse — no global install required

---

### Recommended Workflow

For best results, use both modes together:

```
# Step 1: Static analysis while writing code (no server needed)
"Analyze the performance of src/components/DataTable.tsx"

# Step 2: Start your app or Storybook
npm run storybook   # or: npm run dev

# Step 3: Runtime test to confirm and measure
/react-perf-analyzer:test http://localhost:6006/?path=/story/datatable--large

# Step 4: Fix issues, then re-test to verify
/react-perf-analyzer:test http://localhost:6006/?path=/story/datatable--large
```

---

## What It Analyzes (Static Skill)

**Event Timing / INP:**
- Heavy synchronous work in event handlers
- Missing `startTransition` for non-urgent state updates (React 18+)
- Unthrottled/undebounced `onChange`/`onInput` handlers
- Synchronous fetch or blocking I/O inside click/submit handlers

**Layout Instability / CLS:**
- Images and iframes without explicit `width`/`height` or `aspect-ratio`
- Dynamic content inserted above existing page content
- JS-driven inline style mutations on layout properties (`top`, `left`, `width`, `height`)
- Missing `font-display` for custom fonts

**Long Animation Frames / LoAF:**
- Chained `useEffect` render cascades (effect A sets state → effect B reads it → repeat)
- `requestAnimationFrame` loops with heavy per-frame work
- Canvas/WebGL loops without `cancelAnimationFrame` cleanup
- JS-driven CSS transitions (use CSS `transition` on compositor-only properties instead)

**Long Tasks:**
- Expensive computation in render body without `useMemo`
- Large list renders (100+ items) without virtualization
- Inline object/array literals as props to `React.memo`-wrapped children
- Synchronous large data transformation in `useEffect`
- Heavy third-party imports not code-split

---

## Limitations

- **Heuristic analysis only (skill)** — findings are patterns that correlate with poor performance, not confirmed measurements. Always validate with Lighthouse or runtime instrumentation.
- **Single-file scope (skill)** — imported utilities and context providers are not analyzed unless explicitly provided.
- **Lab data (command)** — Lighthouse runs in a simulated throttled environment. Lab scores may differ from real-user field data. For field data, use the PerformanceObserver snippet from the skill or the [Chrome User Experience Report (CrUX)](https://developer.chrome.com/docs/crux).
- **INP approximation (command)** — Lighthouse's simulated INP is an approximation; precise INP requires manual interaction with the PerformanceObserver snippet active.
- **SSR/RSC aware (skill)** — components lacking `"use client"` in a Next.js project receive a warning that browser performance APIs don't apply to server-rendered execution.

---

## Instrumentation

The PerformanceObserver snippet in the skill instruments all four entry types. Add to your app's entry point (`main.tsx`, `_app.tsx`, or `index.ts`):

```typescript
if (typeof window !== 'undefined' && 'PerformanceObserver' in window) {
  // Event Timing — INP
  new PerformanceObserver((list) => { /* ... */ })
    .observe({ type: 'event', buffered: true, durationThreshold: 100 });

  // Layout Instability — CLS (with session windowing)
  new PerformanceObserver((list) => { /* ... */ })
    .observe({ type: 'layout-shift', buffered: true });

  // Long Animation Frames (Chrome 123+) → falls back to longtask
  new PerformanceObserver((list) => { /* ... */ })
    .observe({ type: 'long-animation-frame', buffered: true });
}
```

The full snippet (including correct CLS session windowing and the LoAF → longtask fallback) is generated at the end of each static analysis report.

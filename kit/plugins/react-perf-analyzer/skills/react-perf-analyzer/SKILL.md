---
name: react-perf-analyzer
description: Use when the user asks to analyze React component performance, profile component rendering speed, check for INP issues, audit layout stability, detect long tasks or slow animations, find performance bottlenecks in React components, or produce a performance report with fix recommendations. Does not cover general code quality, architecture reviews, or runtime profiling — for those use code-review-agent.
allowed-tools: Read, Glob, Grep, Bash, Edit, Write, AskUserQuestion, TodoWrite
---

# React Performance Analyzer

Identifies source-level heuristics in React components that commonly correlate with poor scores on four W3C/WICG Web Performance metrics. Produces a structured report with a severity-scored executive summary, per-metric findings, prioritized recommendations, and a `PerformanceObserver` starter snippet for runtime measurement.

> **Important:** This is static heuristic analysis — not runtime measurement. Findings represent patterns that commonly cause performance problems. Actual INP, CLS, LoAF, and Long Task scores require instrumenting a running app. All recommendations should be validated against real profiler data.
>
> **For actual runtime measurements**, use `/react-perf-analyzer:test [url]` with a Storybook story URL (`http://localhost:6006/?path=/story/...`), a local dev server (`http://localhost:3000`), or any live page URL. It runs Lighthouse and reports real scores with element-level findings.

---

## Table of Contents

- [Step 0 — Track Progress](#step-0)
- [Step 1 — Resolve Target Files](#step-1)
- [Step 2 — Apply Heuristic Checklist](#step-2)
- [Step 3 — Detect React Version Signals](#step-3)
- [Step 4 — Score Each Metric Area](#step-4)
- [Step 5 — Compile and Present Report](#step-5)
- [Report Format](#report-format)
- [Scope and Limitations](#scope)

---

## Step 0 — Track Progress {#step-0}

Before starting, use `TodoWrite` to create one todo item per step (Steps 1–5). Mark each complete as you finish it.

---

## Step 1 — Resolve Target Component File(s) {#step-1}

Determine which files to analyze using this priority order:

1. **Explicit file path or component name** provided by the user in the current message
2. **Git-changed `.tsx`/`.jsx` files** — run `git diff --name-only HEAD` and filter for React component files
3. **Ask the user** — if neither of the above yields a clear target, ask: "Which component file or directory should I analyze?"

**File filtering rules:**
- Include: `.tsx`, `.jsx` files that contain `function`, `const`, or `class` component definitions
- Skip: `.ts` utility files (no JSX), test files matching `*.test.*` or `*.spec.*`, Storybook stories matching `*.stories.*`
- If a directory is provided, analyze all component files within it

**SSR/RSC detection (critical):**
- Check whether the file contains `"use client"` at the top
- If the file is in a Next.js project (look for `next.config.*` in the repo root or parent directories) and lacks `"use client"`, the component may be a React Server Component
- Server Components execute on the server — browser performance APIs (`PerformanceObserver`, INP, CLS, LoAF, Long Tasks) do not apply to their execution
- In this case: add a prominent warning at the top of the report and proceed with limited analysis (only patterns that affect the client bundle or hydration)

---

## Step 2 — Apply Heuristic Checklist Per Metric {#step-2}

Read each target file fully. For every pattern matched, record:
- **Approximate line number** (or function/hook name if line is uncertain)
- **Severity:** High, Medium, or Low (see definitions below)
- **Why it correlates** to the metric — one sentence

Analyze imports at the top of the file. If an import looks like it could be a heavy computation or large library, note it as a potential Long Tasks contributor, but clarify that the imported file is out of scope for deeper analysis.

### Severity Definitions

| Level | Meaning |
|-------|---------|
| **High** | Pattern reliably causes poor metric scores in most production scenarios |
| **Medium** | Pattern commonly causes problems; depends on data size or frequency |
| **Low** | Pattern may contribute under specific conditions (large data, slow devices) |

---

### Event Timing / INP Patterns

INP (Interaction to Next Paint) measures the latency from a user gesture to the next frame paint. Target: <200ms. Poor: >500ms. ([W3C Event Timing spec](https://w3c.github.io/event-timing/))

Check for:

1. **[High] Heavy synchronous work in event handlers** — `onClick`, `onKeyDown`, `onChange`, `onSubmit` bodies that contain loops, deep object clones (`JSON.parse(JSON.stringify(...)))`), array sorting/filtering of large datasets, or DOM queries, without breaking work into smaller chunks or using `scheduler.postTask`
2. **[High] Missing `startTransition` for non-urgent state updates** — state updates triggered by user interaction that re-render large component trees, where the work is not time-sensitive (e.g., search results rendering, tab switching). React 18+ provides `startTransition` to mark these as deferrable.
3. **[Medium] Unthrottled or undebounced input handlers** — `onChange` or `onInput` handlers that trigger state updates on every keystroke without `useDebounce`, `useDeferredValue`, or a manual debounce. Every keystroke triggers a full synchronous render.
4. **[Medium] Synchronous fetch or blocking I/O in event handlers** — `await fetch(...)` or other async operations initiated directly inside click/submit handlers before the UI has updated, causing the browser to delay the next paint while waiting

---

### Layout Instability / CLS Patterns

CLS (Cumulative Layout Shift) measures the sum of unexpected layout shifts during the page's life. Target: <0.1. Poor: >0.25. ([WICG Layout Instability spec](https://wicg.github.io/layout-instability/))

Check for:

1. **[High] Images or iframes without explicit dimensions** — `<img>`, `<Image>` (Next.js), or `<iframe>` elements that lack both `width` and `height` attributes (or equivalent CSS `aspect-ratio`). The browser cannot reserve space before the resource loads, causing layout shifts when it arrives.
2. **[High] Dynamic content injected above existing content** — patterns where new elements are prepended or inserted before existing visible content (e.g., notification banners, cookie consent bars, ad slots rendered after initial paint). Check for conditional rendering at the top of the JSX tree or `unshift`-style DOM mutations.
3. **[Medium] Inline style mutations changing layout properties after initial paint** — `useEffect` or event handlers that set `style.position`, `style.top`, `style.left`, `style.width`, or `style.height` on mounted elements. These trigger layout recalculations that shift surrounding content.
4. **[Low] Missing `font-display` awareness** — `@import url(...)` for external fonts (Google Fonts etc.) or `@font-face` declarations without `font-display: swap` or `font-display: optional`. Flash of Invisible Text (FOIT) followed by font swap can cause layout shifts if glyphs have different metrics.

---

### Long Animation Frames / LoAF Patterns

LoAF tracks animation frames that take longer than 50ms to render. ([W3C Long Animation Frames spec](https://w3c.github.io/long-animation-frames/))

Check for:

1. **[High] Chained `useEffect` render cascades** — `useEffect` A sets state → triggers re-render → `useEffect` B reads updated state and sets more state → triggers another re-render. Each link adds to the frame budget. Look for multiple `useEffect` hooks where the dependencies of one include state set by another.
2. **[High] `requestAnimationFrame` loops with heavy per-frame work** — `rAF` callbacks that perform layout reads (`getBoundingClientRect`, `offsetWidth`), large state updates, or complex calculations on every frame without frame-budget awareness
3. **[Medium] Canvas or WebGL render loops without cleanup** — `useEffect` bodies that start a render loop (`rAF` or `setInterval`) but do not cancel it in the cleanup function (`return () => cancelAnimationFrame(id)`). Uncanceled loops continue consuming frame budget after the component unmounts or conditions change.
4. **[Medium] JS-driven CSS transitions or animations** — `useEffect` + `requestAnimationFrame` used to drive CSS property changes frame-by-frame, rather than using CSS `transition` or `animation` properties (which run on the compositor thread and avoid the main thread entirely)

---

### Long Tasks Patterns

Long Tasks are main-thread tasks that block responsiveness for >50ms. ([W3C Long Tasks spec](https://w3c.github.io/longtasks/))

Check for:

1. **[High] Expensive computation in the render function body** — complex calculations, large array operations, deep object traversals, or regex operations called directly during render without `useMemo`. These run on every render, blocking the main thread.
2. **[High] Large list renders without virtualization** — `Array.map()` over datasets that could plausibly exceed 100 items, rendered as DOM elements, without `react-window`, `@tanstack/react-virtual`, or similar. Each rendered element adds to the reconciliation work.
3. **[Medium] Inline object or array literals as props to memoized children** — passing `style={{ color: 'red' }}`, `options={[1, 2, 3]}`, or `config={{ ... }}` as props to `React.memo`-wrapped child components. New object reference on every render defeats memoization, causing unnecessary child re-renders.
4. **[Medium] Synchronous transformation of large data in `useEffect`** — `useEffect` bodies that sort, filter, or transform large arrays synchronously before setting state. The entire transformation runs as one synchronous task, blocking the thread for its duration.
5. **[Low] Heavy third-party imports not code-split** — top-level `import` of large libraries (chart libraries, PDF renderers, rich text editors) that are only used in some render paths. These inflate the initial JS parse/evaluation task. Check for `import` statements that could be `const X = await import(...)` (dynamic import) inside a handler or `useEffect`.

---

## Step 3 — Detect React Version Signals {#step-3}

Look for the following signals in the component file and, if accessible, `package.json`:

| Signal | Inference |
|--------|-----------|
| `startTransition`, `useDeferredValue` used | React 18+ concurrent features already adopted — caveat INP recommendations accordingly |
| `package.json` shows `"react": "^19.*"` | React 19 compiler may auto-memoize — caveat `useMemo`/`React.memo` recommendations with "verify compiler is active" |
| `package.json` shows `"react": "^18.*"` | React 18 — `startTransition` is available; recommend it for applicable findings |
| Neither signal found | Note: React version unknown; recommendations assume React 18 |

Include a one-line React version note at the top of the findings section.

---

## Step 4 — Score Each Metric Area {#step-4}

After completing the checklist, assign a score to each of the four metric areas:

| Score | Criteria |
|-------|---------|
| **Good** | 0 heuristic matches in this category |
| **Needs Improvement** | 1–2 matches, all Low or Medium severity |
| **Poor** | 3+ matches, OR any single High severity match |

Scores are heuristic estimates based on pattern frequency and severity. They are not equivalent to Lighthouse scores or real Web Vitals measurements.

---

## Step 5 — Compile and Present Report {#step-5}

Present the full report in the format below. Do not omit sections — if a category has no findings, write "No patterns found."

---

## Report Format {#report-format}

```
## React Performance Analysis: [ComponentName or File Path]

> **Scope:** Heuristic analysis of [filename]. Imported code is out of scope.
> React version: [detected version or "unknown — assuming React 18"].
> Actual runtime scores require the PerformanceObserver snippet below.
```

[If SSR caveat applies, insert here:]
```
> **SSR Warning:** This component does not have a `"use client"` directive and
> may be a React Server Component. Browser performance APIs (INP, CLS, LoAF,
> Long Tasks) do not apply to server-side execution. Analysis below covers
> patterns that affect the client bundle and hydration only.
```

### Executive Summary

| Metric | Score | Findings |
|--------|-------|----------|
| Event Timing (INP) | Good / Needs Improvement / Poor | N patterns |
| Layout Instability (CLS) | ... | N patterns |
| Long Animation Frames | ... | N patterns |
| Long Tasks | ... | N patterns |

---

### Findings

#### Event Timing / INP
- **[High]** Line ~N: `handlerName` — [description of pattern and why it harms INP]
- **[Medium]** Line ~N: [pattern] — [explanation]

_(If none: "No patterns found.")_

#### Layout Instability / CLS
- **[High]** Line ~N: `<img src="..." />` — Missing `width` and `height` attributes; browser cannot reserve space before image loads, causing layout shift on arrival.

_(If none: "No patterns found.")_

#### Long Animation Frames
...

#### Long Tasks
...

---

### Prioritized Recommendations

Ordered by estimated impact (highest first). Include a concise before/after code example for each recommendation where applicable.

1. **[ComponentName] Add `startTransition` around the search state update** _(INP — High)_

   Currently:
   ```tsx
   onClick={() => setSearchResults(filter(data, query))}
   ```
   Recommended:
   ```tsx
   import { startTransition } from 'react';
   onClick={() => startTransition(() => setSearchResults(filter(data, query)))}
   ```
   This marks the update as non-urgent, allowing React to keep the UI responsive while rendering results.

2. **Add `width` and `height` to `<img>` elements** _(CLS — High)_
   ...

_(Continue for all High findings, then Medium, then Low.)_

---

### PerformanceObserver Starter Snippet

> **This is a starter template** — add it to your app's entry point (e.g., `main.tsx`, `_app.tsx`, or `index.ts`) to capture real runtime measurements. Review and adapt before using in production.
>
> Browser support note: `long-animation-frame` requires Chrome 123+. `longtask` has broader support but is deprecated in favor of `long-animation-frame`. Guard all observers with `typeof window !== 'undefined'` if your app uses SSR.

```typescript
// React Performance Observer — Starter Template
// Add to your app entry point. Remove or gate behind a feature flag in production.

if (typeof window !== 'undefined' && 'PerformanceObserver' in window) {

  // 1. Event Timing — Interaction to Next Paint (INP)
  // Spec: https://w3c.github.io/event-timing/
  // Target: <200ms | Poor: >500ms
  try {
    const eventObserver = new PerformanceObserver((list) => {
      for (const entry of list.getEntries()) {
        if (entry.duration > 200) {
          console.warn('[Perf] Slow interaction (INP candidate):', {
            name: entry.name,
            duration: Math.round(entry.duration) + 'ms',
            processingStart: Math.round(entry.processingStart) + 'ms',
            startTime: Math.round(entry.startTime) + 'ms',
          });
        }
      }
    });
    eventObserver.observe({ type: 'event', buffered: true, durationThreshold: 100 });
  } catch (e) {
    console.info('[Perf] Event Timing API not supported');
  }

  // 2. Layout Instability — Cumulative Layout Shift (CLS)
  // Spec: https://wicg.github.io/layout-instability/
  // Target: <0.1 | Poor: >0.25 (cumulative, session-windowed)
  try {
    let clsScore = 0;
    let sessionEntries: PerformanceEntry[] = [];
    let sessionStart = 0;
    const CLS_WINDOW_GAP = 1000;    // 1 second gap ends a session window
    const CLS_WINDOW_LIMIT = 5000;  // 5 second max session window

    const clsObserver = new PerformanceObserver((list) => {
      for (const entry of list.getEntries()) {
        const shift = entry as PerformanceEntry & { hadRecentInput: boolean; value: number };
        if (!shift.hadRecentInput) {
          const lastEntry = sessionEntries[sessionEntries.length - 1] as typeof shift;
          if (sessionEntries.length === 0
            || entry.startTime - lastEntry.startTime > CLS_WINDOW_GAP
            || entry.startTime - sessionStart > CLS_WINDOW_LIMIT) {
            sessionEntries = [entry];
            sessionStart = entry.startTime;
          } else {
            sessionEntries.push(entry);
          }
          clsScore = sessionEntries.reduce((sum, e) => sum + ((e as typeof shift).value ?? 0), 0);
          if (clsScore > 0.1) {
            console.warn('[Perf] CLS session score:', clsScore.toFixed(4));
          }
        }
      }
    });
    clsObserver.observe({ type: 'layout-shift', buffered: true });
  } catch (e) {
    console.info('[Perf] Layout Instability API not supported');
  }

  // 3. Long Animation Frames (LoAF) — Chrome 123+
  // Spec: https://w3c.github.io/long-animation-frames/
  // Threshold: >50ms
  try {
    const loafObserver = new PerformanceObserver((list) => {
      for (const entry of list.getEntries()) {
        console.warn('[Perf] Long Animation Frame:', {
          duration: Math.round(entry.duration) + 'ms',
          startTime: Math.round(entry.startTime) + 'ms',
        });
      }
    });
    loafObserver.observe({ type: 'long-animation-frame', buffered: true });
  } catch (e) {
    // long-animation-frame not supported (non-Chromium browsers)
    // Fall back to Long Tasks
    try {
      const longTaskObserver = new PerformanceObserver((list) => {
        for (const entry of list.getEntries()) {
          console.warn('[Perf] Long Task:', {
            duration: Math.round(entry.duration) + 'ms',
            startTime: Math.round(entry.startTime) + 'ms',
          });
        }
      });
      longTaskObserver.observe({ type: 'longtask', buffered: true });
    } catch (e2) {
      console.info('[Perf] Neither long-animation-frame nor longtask API supported');
    }
  }
}
```

---

## Scope and Limitations {#scope}

- **Analysis scope:** The provided component file only. Patterns in imported utilities, context providers, or parent components are not analyzed unless those files are also provided.
- **Not covered:** Runtime performance (actual INP/CLS/LoAF/Long Task values), network performance, server rendering time, build bundle size analysis, third-party script impact.
- **Not covered by this skill:** General code quality, architecture review, security vulnerabilities — use `code-review-agent` for those.
- **React version caveat:** Recommendations assume React 18 unless otherwise detected. React 19 compiler users should verify whether auto-memoization already addresses any memoization recommendations before acting on them.

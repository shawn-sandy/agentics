---
status: in-progress
created: 2026-03-08
---

# Plan: React Performance Analyzer Plugin

## Context

No performance profiling plugin exists in the marketplace. This plugin fills that gap with a skill that identifies **source-level heuristics that commonly correlate with poor scores** on four W3C/WICG Web Performance metrics — it does not run the app or produce actual runtime measurements. The skill reads React component source, applies a concrete pattern checklist per metric, and produces a structured report with prioritized recommendations. A `PerformanceObserver` starter template is offered at the end of the report for developers who want real runtime data.

**Metrics covered (per W3C/WICG specs):**
- **Event Timing API** — INP: interaction-to-paint latency; >200ms is poor
- **Layout Instability API** — CLS: unexpected layout shifts; >0.25 is poor
- **Long Animation Frames API** — LoAF: main-thread frames >50ms
- **Long Tasks API** — main-thread tasks blocking >50ms

> **Scope:** Static heuristic analysis only. Runtime scores require adding the instrumentation snippet to the app. Analysis is scoped to the provided file; imported code is noted as out of scope.

---

## Files to Create

```
plugins/react-perf-analyzer/
  .claude-plugin/
    plugin.json              # Plugin metadata (v1.0.0)
  skills/
    react-perf-analyzer/
      SKILL.md               # Skill instructions
  CHANGELOG.md
  README.md                  # Required by convention
```

## Files to Modify

- `.claude-plugin/marketplace.json` — add new plugin entry (version must match plugin.json)

---

## Implementation Steps

### 1. Create `plugins/react-perf-analyzer/.claude-plugin/plugin.json`

```json
{
  "name": "react-perf-analyzer",
  "version": "1.0.0",
  "description": "Identifies React component source patterns that commonly correlate with poor Event Timing (INP), Layout Instability (CLS), Long Animation Frames, and Long Tasks scores — produces a heuristic report with recommendations",
  "author": { "name": "Agentics Project" },
  "license": "MIT",
  "keywords": ["react", "performance", "web-vitals", "cls", "inp", "long-tasks", "long-animation-frames", "event-timing", "profiling", "optimization"],
  "homepage": "https://github.com/shawn-sandy/agentics/tree/main/plugins/react-perf-analyzer",
  "repository": "https://github.com/shawn-sandy/agentics"
}
```

### 2. Create `plugins/react-perf-analyzer/skills/react-perf-analyzer/SKILL.md`

**Frontmatter:**
```yaml
---
name: react-perf-analyzer
description: Use when the user asks to analyze React component performance, profile component rendering speed, check for INP issues, audit layout stability, detect long tasks or slow animations, find performance bottlenecks in React components, or produce a performance report with fix recommendations. Does not cover general code quality, architecture reviews, or runtime profiling — for those use code-review-agent.
---
```

**Skill body — steps:**

**Step 0 — Create progress todos** using `TodoWrite` before starting.

**Step 1 — Resolve target component file(s)**
- Priority: explicit file path from user → git-changed `.tsx`/`.jsx` files → ask
- Skip non-component files: `.ts` utilities, test files (`*.test.*`, `*.spec.*`), Storybook stories (`*.stories.*`)
- If the file lacks `"use client"` in a Next.js-structured project, note that the component may be a Server Component and browser performance APIs will not apply — still analyze but add a prominent SSR caveat to the report

**Step 2 — Apply heuristic checklist per metric**

For each pattern found, record: file + approximate line, severity (High/Medium/Low), and why it correlates to the metric.

*Event Timing / INP patterns:*
- Heavy synchronous work directly inside `onClick`/`onKeyDown`/`onChange` handlers without yielding (e.g., large loops, deep object clones)
- Missing `startTransition` for non-urgent state updates triggered by user interaction (React 18+)
- Unthrottled/undebounced `onInput`/`onChange` handlers that trigger expensive renders
- Synchronous fetch calls or blocking I/O inside event handlers

*Layout Instability / CLS patterns:*
- `<img>` or `<iframe>` elements without explicit `width` and `height` attributes or aspect-ratio CSS
- Dynamic content inserted above existing page content (prepend vs append patterns)
- Inline style mutations that change `position`, `top`, `left`, `width`, or `height` after initial paint
- Missing or incorrect `font-display` value in `@font-face` or Google Fonts imports

*Long Animation Frames / LoAF patterns:*
- Chained `useEffect` calls where one sets state that triggers another (render cascade)
- JS-driven CSS transitions via `requestAnimationFrame` with heavy work per frame
- Canvas or WebGL render loops not using `cancelAnimationFrame` or running unconditionally
- Long `useEffect` bodies without a debounce or task-yielding strategy

*Long Tasks patterns:*
- Expensive computation in the render function body not wrapped in `useMemo`
- Large list renders (>100 items) without virtualization (`react-window`, `react-virtual`)
- Inline object/array literals as props passed to `React.memo`-wrapped children (breaks memoization)
- Synchronous data transformation of large payloads in `useEffect` or render

**Step 3 — Detect React version signals**
- Look for `startTransition` usage → React 18+ concurrent features already in use
- Look for missing `useMemo`/`useCallback` in a React 19 project → React 19 compiler may auto-memoize; caveat recommendations accordingly
- If React version is detectable from `package.json`, note it; otherwise note it is unknown

**Step 4 — Score each metric area**
- **Good** — 0 heuristic matches
- **Needs Improvement** — 1–2 matches, Low/Medium severity
- **Poor** — 3+ matches, or any High severity match

**Step 5 — Compile and present report**

Output structure:
```
## React Performance Analysis: [ComponentName]

> Note: This is a heuristic analysis of source patterns. Actual runtime scores
> require instrumentation in a running app.

### Executive Summary
| Metric | Score |
|--------|-------|
| Event Timing (INP) | Good / Needs Improvement / Poor |
| Layout Instability (CLS) | ... |
| Long Animation Frames | ... |
| Long Tasks | ... |

### Findings

#### Event Timing / INP
- [severity] Line ~N: [pattern description] — [why it matters]

#### Layout Instability / CLS
...

#### Long Animation Frames
...

#### Long Tasks
...

### Prioritized Recommendations
1. [Highest-impact fix with code example]
2. ...

### PerformanceObserver Starter Snippet
> Add this to your app entry point to collect real runtime measurements.
[code block — clearly labeled as a starter template, not production-ready]
```

**Notes on the instrumentation snippet:** Include snippets for all four `PerformanceObserver` entry types (`event`, `layout-shift`, `long-animation-frame`, `longtask`). Label each clearly. Note browser support (LoAF requires Chrome 123+) and that SSR environments must guard with `typeof window !== 'undefined'`.

### 3. Create `plugins/react-perf-analyzer/CHANGELOG.md`

v1.0.0 initial release entry.

### 4. Create `plugins/react-perf-analyzer/README.md`

Sections: Overview, What It Analyzes, Limitations (heuristic, not runtime), Usage, Instrumentation.

### 5. Update `.claude-plugin/marketplace.json`

Add to the `plugins` array:
```json
{
  "name": "react-perf-analyzer",
  "source": "./plugins/react-perf-analyzer",
  "version": "1.0.0",
  "description": "Identifies React component source patterns that commonly correlate with poor Event Timing (INP), Layout Instability (CLS), Long Animation Frames, and Long Tasks scores — produces a heuristic report with recommendations",
  "category": "testing",
  "tags": ["react", "performance", "web-vitals", "cls", "inp", "long-tasks", "event-timing", "profiling"]
}
```

---

## Key Decisions

- **Skill-only (no command) for v1.0.0.** Auto-activation covers the common "hey look at my component" use case. A `/react-perf-analyzer:analyze` command is a natural v1.1.0 addition.
- **Heuristic framing, not measurement.** Every output is labeled as a heuristic estimate correlated to the metric, not an actual score.
- **PerformanceObserver snippet is a starter template.** Included at the end of the report with explicit caveats — not guaranteed production-ready.
- **SSR/RSC caveat.** Any file missing `"use client"` in a Next.js context gets a warning before the findings.
- **Import analysis out of scope.** The skill analyzes the provided file only and notes this limitation explicitly.

---

## Verification

1. Confirm version sync: `grep '"version"' plugins/react-perf-analyzer/.claude-plugin/plugin.json .claude-plugin/marketplace.json`
2. Load locally: `claude --plugin-dir ~/devbox/agentics/plugins/react-perf-analyzer`
3. Trigger skill: "analyze the performance of my React component" or "check for CLS issues"
4. Confirm report structure: Executive Summary table, per-metric findings, prioritized recommendations, instrumentation snippet with caveats

---

> **Plan file rename:** After approval, rename to `react-perf-analyzer-plugin.md`.

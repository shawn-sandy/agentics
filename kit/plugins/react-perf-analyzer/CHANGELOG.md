# Changelog: react-perf-analyzer

## [1.3.0] - 2026-05-12

### Changed

- `disable-model-invocation: true` on `react-perf-analyzer` — manual invocation only via `/react-perf-analyzer:react-perf-analyzer`; no longer auto-triggers on intent match.

## [1.2.0] - 2026-04-09

### Changed
- Explicitly declare `allowed-tools` frontmatter on all skills.
  Makes tool requirements explicit and removes reliance on session baseline
  permissions. No behavior change — tools were already available via session default.

## [1.1.0] — 2026-03-08

### Added
- `/react-perf-analyzer:test [url]` command — runs Lighthouse against any HTTP URL
  (Storybook story, local dev server, staging, or production) and reports actual
  INP, CLS, TBT, FCP, and LCP scores with element-level findings and prioritized recommendations
- Storybook-aware: detects `localhost:6006` or `?path=/story/` URLs and offers
  single-story or all-stories testing mode (fetches Storybook index to discover stories)
- Optional cross-reference mode: correlates Lighthouse findings with static analysis
  heuristics from the `react-perf-analyzer` skill — flags confirmed vs. runtime-only findings
- Updated `react-perf-analyzer` skill to reference `/react-perf-analyzer:test` for real measurements

## [1.0.0] — 2026-03-08

### Added
- Initial release of `react-perf-analyzer` plugin
- `react-perf-analyzer` skill — static heuristic analysis of React component source files
- Checklist-based pattern detection for four W3C/WICG Web Performance metrics:
  - Event Timing / INP (4 patterns)
  - Layout Instability / CLS (4 patterns)
  - Long Animation Frames / LoAF (4 patterns)
  - Long Tasks (5 patterns)
- Executive summary table with Good / Needs Improvement / Poor scoring per metric
- Prioritized recommendations with before/after code examples
- `PerformanceObserver` starter snippet for all four entry types with session-windowed CLS calculation and LoAF → Long Tasks fallback
- SSR/RSC detection: warns when `"use client"` is absent in a Next.js project
- React version signal detection: caveats recommendations for React 18 concurrent features and React 19 compiler

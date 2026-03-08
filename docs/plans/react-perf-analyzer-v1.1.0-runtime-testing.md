# Plan: Add Runtime URL Testing to react-perf-analyzer (v1.1.0)

## Context

The current v1.0.0 skill performs **static heuristic analysis** — pattern matching on source code. The user has asked the right question: static analysis is useful for finding _likely_ problems, but actual performance scores (INP, CLS, LoAF, Long Tasks) require running the app and observing real browser behavior.

The best answer to "Storybook URL, file/webpage, or all of the above?" is: **all of the above — the mechanism is the same**. Any live URL (Storybook story, local dev server, staging, production) can be instrumented identically. Storybook adds the benefit of component isolation; a dev server adds real app context. Both should be supported.

**Chosen mechanism: Lighthouse CLI via `npx lighthouse`**
- Universally available (`npx lighthouse [url]` — no install required)
- Returns INP, CLS, TBT (proxy for Long Tasks), FCP, LCP as actual scored values
- JSON output is structured and parseable
- Works with any HTTP URL — Storybook, localhost, staging, production
- No browser automation coding required

A new **command** (`/react-perf-analyzer:test`) handles the runtime path. The existing **skill** handles static analysis. Both are part of the same plugin.

---

## Why a Command, Not a Skill, for Runtime Testing

Skills auto-activate from intent — they do not accept parameters. The runtime test requires a URL argument (`$ARGUMENTS`). Commands accept `$ARGUMENTS` directly. This is the same pattern the `dev-tools` plugin uses for its `/dev-tools:format` command.

---

## Files to Create

```
plugins/react-perf-analyzer/
  commands/
    test.md                  # New: /react-perf-analyzer:test [url]
```

## Files to Modify

```
plugins/react-perf-analyzer/
  .claude-plugin/plugin.json       — bump version 1.0.0 → 1.1.0
  CHANGELOG.md                     — add v1.1.0 entry
  skills/react-perf-analyzer/
    SKILL.md                       — add "For real measurements, use /react-perf-analyzer:test" note
.claude-plugin/marketplace.json    — update react-perf-analyzer version 1.0.0 → 1.1.0
```

---

## Implementation Steps

### 1. Create `plugins/react-perf-analyzer/commands/test.md`

**Frontmatter:** `description: Run Lighthouse against a URL (Storybook story, local dev server, or any live page) and report actual INP, CLS, TBT, FCP, and LCP scores with prioritized fix recommendations`

**Command body — steps:**

**Step 0 — Parse `$ARGUMENTS`**
- If `$ARGUMENTS` is empty → ask: "Please provide a URL. This can be a Storybook story URL (e.g., `http://localhost:6006/?path=/story/button`), a local dev server (e.g., `http://localhost:3000/`), or any live page URL."
- Validate the URL starts with `http://` or `https://`

**Step 1 — Detect Storybook**
- If the URL contains `localhost:6006` or `?path=/story/` → treat as Storybook
- Storybook mode: offer to test all stories by iterating `http://localhost:6006/?path=/story/[name]`
- Ask: "Should I test this story only, or list all available stories and test each?"

**Step 2 — Run Lighthouse**

```bash
npx --yes lighthouse $URL \
  --output=json \
  --output-path=./perf-report.json \
  --chrome-flags="--headless --no-sandbox" \
  --only-categories=performance \
  --quiet
```

- Parse `perf-report.json` for: `interactive`, `speed-index`, `total-blocking-time`, `cumulative-layout-shift`, `first-contentful-paint`, `experimental-interaction-to-next-paint`
- Map scores: ≥90 = Good, 50–89 = Needs Improvement, <50 = Poor

**Step 3 — For each metric, surface the Lighthouse diagnostics**
- Lighthouse's `audits` section includes specific nodes causing CLS, long tasks, etc.
- Extract and list them: which element caused the shift, which script caused the long task

**Step 4 — Correlate to source (optional)**
- If the user has also run the static skill on the same component → cross-reference Lighthouse findings with heuristic findings
- Flag any heuristic findings that did NOT show up in Lighthouse (low priority)
- Flag any Lighthouse findings with no static match (investigation needed)

**Step 5 — Present report**

```
## Lighthouse Performance Report: [URL]
Tested: [timestamp]

### Scores
| Metric | Score | Value | Rating |
|--------|-------|-------|--------|
| INP (Interaction to Next Paint) | 72 | 210ms | Needs Improvement |
| CLS (Cumulative Layout Shift) | 45 | 0.31 | Poor |
| TBT (Total Blocking Time)* | 80 | 180ms | Needs Improvement |
| FCP (First Contentful Paint) | 91 | 1.2s | Good |
| LCP (Largest Contentful Paint) | 85 | 2.1s | Good |

*TBT is a lab proxy for Long Tasks (field metric: Long Tasks / LoAF)

### CLS Findings
- Element: `<img src="/hero.jpg">` — no width/height — caused 0.22 shift

### Long Task Findings
- Script: `vendor.chunk.js` (line N) — 240ms task blocking main thread

### Recommendations
[Same prioritized format as the skill, but backed by real measurements]
```

---

### 2. Update `skills/react-perf-analyzer/SKILL.md`

Add a short note near the top of the Summary section:

> **For actual runtime measurements**, use `/react-perf-analyzer:test [url]` with a Storybook story URL, local dev server, or any live page. The analysis below is static — it finds patterns that commonly cause poor scores, but actual scores require a running app.

---

### 3. Bump version to 1.1.0

In `plugins/react-perf-analyzer/.claude-plugin/plugin.json`: `"version": "1.1.0"`

In `.claude-plugin/marketplace.json`: `"version": "1.1.0"` for the `react-perf-analyzer` entry

### 4. Add CHANGELOG v1.1.0 entry

```md
## [1.1.0] — 2026-03-08

### Added
- `/react-perf-analyzer:test [url]` command — runs Lighthouse against any HTTP URL
  (Storybook story, local dev server, staging, or production) and reports actual
  INP, CLS, TBT, FCP, and LCP scores with prioritized recommendations
- Storybook-aware: detects `localhost:6006` or `?path=/story/` and offers
  single-story or all-stories testing mode
- Optional correlation mode: cross-references Lighthouse findings with static analysis
  heuristics from the skill
```

---

## Architecture Summary

| Mode | Trigger | Mechanism | Output |
|------|---------|-----------|--------|
| Static analysis | Skill auto-activates on intent | Source file pattern checklist | Heuristic scores + recommendations |
| Runtime testing | `/react-perf-analyzer:test [url]` | `npx lighthouse` via Bash | Actual Web Vitals scores + element-level findings |

**URL types all supported identically:**
- Storybook story URL (`localhost:6006/?path=/story/button`)
- Dev server (`localhost:3000`)
- Staging/production (`https://app.example.com`)

---

## Verification

1. Version sync: `grep '"version"' plugins/react-perf-analyzer/.claude-plugin/plugin.json .claude-plugin/marketplace.json` → both show `1.1.0`
2. Run command: `/react-perf-analyzer:test http://localhost:6006/?path=/story/button--primary`
3. Confirm: Lighthouse runs, `perf-report.json` is created, scores are parsed and reported
4. Run command with empty args: confirm skill prompts for URL
5. Load plugin: `claude --plugin-dir ~/devbox/agentics/plugins/react-perf-analyzer`

---

> **Plan file rename:** After approval, rename to `react-perf-analyzer-v1.1.0-runtime-testing.md`

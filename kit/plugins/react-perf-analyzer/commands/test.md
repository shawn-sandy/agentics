---
description: Run Lighthouse against a URL (Storybook story, local dev server, or any live page) and report actual INP, CLS, TBT, FCP, and LCP scores with prioritized fix recommendations
---

# React Performance Test Command

Runs Google Lighthouse against a live URL and reports actual Web Vitals scores — INP, CLS, TBT (Long Tasks proxy), FCP, and LCP — with element-level findings and prioritized recommendations.

Supports any HTTP URL: Storybook story, local dev server, staging, or production.

---

## Step 0 — Parse URL from `$ARGUMENTS`

If `$ARGUMENTS` is empty or not a valid URL, ask:

> "Please provide a URL to test. Examples:
> - Storybook story: `http://localhost:6006/?path=/story/button--primary`
> - Local dev server: `http://localhost:3000/`
> - Any live page: `https://app.example.com/dashboard`"

Validate that the URL starts with `http://` or `https://`. If it does not, prefix `http://` and confirm with the user.

---

## Step 1 — Detect Storybook Mode

Check whether the URL indicates a Storybook instance:
- URL contains `localhost:6006`, or
- URL contains `?path=/story/`

**If Storybook detected:**

Ask: "I can see this is a Storybook URL. Should I:
1. Test this story only
2. Discover and test all available stories (I'll fetch the Storybook index to list them)"

**If option 2 selected:**

Fetch the Storybook stories index:
```bash
curl -s "http://localhost:6006/index.json" 2>/dev/null || curl -s "http://localhost:6006/stories.json" 2>/dev/null
```

Parse the JSON to extract story IDs and titles. Build a list of story URLs in the format:
`http://localhost:6006/iframe.html?id=[story-id]&viewMode=story`

> Use the `iframe.html` endpoint for Lighthouse — it loads the story directly without the Storybook UI chrome, giving cleaner performance data.

Test each story sequentially and aggregate results into a summary table at the end.

---

## Step 2 — Run Lighthouse

For each URL to test, run:

```bash
npx --yes lighthouse "$URL" \
  --output=json \
  --output-path=./perf-report.json \
  --chrome-flags="--headless --no-sandbox --disable-gpu" \
  --only-categories=performance \
  --quiet
```

**If Lighthouse is already installed** (check `node_modules/.bin/lighthouse` or global install), use it directly to skip the `npx --yes` download.

**If the command fails:**
- Check whether Chrome is installed: `which google-chrome || which chromium || which chromium-browser`
- If Chrome is missing, inform the user and suggest: `npx @puppeteer/browsers install chrome`
- If the URL is unreachable (connection refused), remind the user to start their dev server or Storybook first

After the run, verify `perf-report.json` was created:
```bash
test -f ./perf-report.json && echo "Report generated" || echo "Lighthouse failed to write report"
```

---

## Step 3 — Parse the Lighthouse Report

Read `./perf-report.json` and extract the following fields:

| Field path in JSON | Metric |
|--------------------|--------|
| `audits.experimental-interaction-to-next-paint.numericValue` | INP (ms) |
| `audits.cumulative-layout-shift.numericValue` | CLS (score) |
| `audits.total-blocking-time.numericValue` | TBT (ms) — Long Tasks proxy |
| `audits.first-contentful-paint.numericValue` | FCP (ms) |
| `audits.largest-contentful-paint.numericValue` | LCP (ms) |
| `audits.*.score` | 0–1 score for each audit |

**Score thresholds (Lighthouse convention):**

| Score | Rating |
|-------|--------|
| ≥ 0.9 (90) | Good |
| 0.5–0.89 (50–89) | Needs Improvement |
| < 0.5 (< 50) | Poor |

**INP-specific thresholds (Web Vitals):**
- Good: < 200ms
- Needs Improvement: 200–500ms
- Poor: > 500ms

**CLS-specific thresholds:**
- Good: < 0.1
- Needs Improvement: 0.1–0.25
- Poor: > 0.25

Also extract **opportunity and diagnostic audits** that Lighthouse provides per metric:
- `audits.layout-shift-elements.details.items` — DOM elements causing CLS
- `audits.long-tasks.details.items` — scripts/tasks exceeding 50ms
- `audits.render-blocking-resources.details.items` — resources blocking FCP/LCP
- `audits.uses-optimized-images.details.items` — unoptimized images

---

## Step 4 — Correlate With Static Analysis (Optional)

If the user has previously run the `react-perf-analyzer` skill on the same component's source file, offer to cross-reference findings:

> "Would you like me to compare these Lighthouse findings against the static analysis from the skill? This can help identify which heuristic patterns are confirmed by real measurements."

If yes:
- Static findings with a corresponding Lighthouse audit → **Confirmed** (high priority to fix)
- Static findings with no Lighthouse match → **Unconfirmed** (may still be worth addressing on slower devices)
- Lighthouse findings with no static match → **Runtime-only** (often caused by imported code or third-party scripts not visible in component source)

---

## Step 5 — Present the Report

```
## Lighthouse Performance Report

URL: [url]
Tested: [date/time]
[Storybook story: "[story name]" | Page: "[page title]"]

---

### Scores

| Metric | Score | Value | Rating |
|--------|-------|-------|--------|
| INP (Interaction to Next Paint) | [0-100] | [N]ms | Good / Needs Improvement / Poor |
| CLS (Cumulative Layout Shift) | [0-100] | [N.NN] | Good / Needs Improvement / Poor |
| TBT (Total Blocking Time)* | [0-100] | [N]ms | Good / Needs Improvement / Poor |
| FCP (First Contentful Paint) | [0-100] | [N]s | Good / Needs Improvement / Poor |
| LCP (Largest Contentful Paint) | [0-100] | [N]s | Good / Needs Improvement / Poor |

*TBT is Lighthouse's lab proxy for Long Tasks. It measures the sum of task time
exceeding 50ms during page load. For live Long Tasks monitoring, see the
PerformanceObserver snippet from the `react-perf-analyzer` skill.

---

### CLS Findings
[If CLS score < 0.9:]
Elements causing layout shifts:
- `[element selector]` — shift value: [N.NN] — [reason if available]

[If no CLS findings or score is Good:]
No significant layout shift sources detected.

---

### Long Tasks / TBT Findings
[If TBT > 0ms:]
Tasks exceeding 50ms:
- `[script/resource name]` — duration: [N]ms — [source URL if available]

[If none:]
No long tasks detected during page load.

---

### Render-Blocking Resources
[If any:]
- `[resource URL]` — blocking for [N]ms

---

### Prioritized Recommendations

[For each Poor or Needs Improvement metric, one or more concrete recommendations,
ordered by impact. Include the Lighthouse audit name for reference.]

1. **Fix layout shift from `[element]`** _(CLS — Poor)_
   Add explicit `width` and `height` attributes (or CSS `aspect-ratio`) to prevent
   the browser from reflowing when the resource loads.

2. **Break up long task in `[script]`** _(TBT — Needs Improvement)_
   Use `scheduler.yield()` or `setTimeout` chunking to break the [N]ms task into
   smaller pieces that yield to the browser between chunks.

[Continue for all findings...]

---

### Cleanup
```
[Delete temp file] rm ./perf-report.json
```
```

---

## Storybook Multi-Story Summary (if all-stories mode)

After testing all stories, present an aggregated table:

```
## Storybook Performance Summary

| Story | INP | CLS | TBT | FCP | LCP |
|-------|-----|-----|-----|-----|-----|
| Button/Primary | Good | Good | Good | Good | Good |
| Modal/Default | Poor (420ms) | Good | Needs Improvement | Good | Good |
| DataTable/Large | Poor | Good | Poor (890ms) | Good | Needs Improvement |

Stories requiring immediate attention:
1. Modal/Default — INP 420ms (likely heavy state update in open handler)
2. DataTable/Large — TBT 890ms (likely unvirtualized large list render)
```

---

## Notes

- Lighthouse runs in a simulated throttled environment (4G, mid-tier mobile CPU). Lab scores may differ from real-user field data. For field data, use the Chrome User Experience Report (CrUX) or add the `PerformanceObserver` snippet from the skill.
- INP (`experimental-interaction-to-next-paint`) requires user interaction to measure accurately. Lighthouse's simulated INP is an approximation. For precise INP, use the skill's `PerformanceObserver` snippet with manual interaction.
- For CI/CD integration, consider `@lhci/cli` (Lighthouse CI) instead of running this command manually.

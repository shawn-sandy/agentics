# Plan: Scope Screenshot to `.card` Element

## Context

The social-media-tools plugin generates social media cards (diff, feature, quote, blog, snippet) and screenshots them for sharing. Currently the screenshot captures the entire page/viewport — including the `<body>` background and the copy panels below the card. The actual shareable content lives exclusively inside the `.card` element. Capturing the full page produces oversized PNGs with unwanted chrome around the card.

The fix is to pass `selector: ".card"` to Playwright's `browser_take_screenshot` call so only the card element is captured. All five skills (`code-share`, `blog-share`, `video-share`, `project-share`, `github-code-share`) already delegate their screenshot phase to a single shared reference file, so this is a one-file change.

---

## What to Change

### `kit/plugins/social-media-tools/references/rendering-pipeline.md`

**Step 3 — Playwright screenshot** (line 42) currently reads:

```
3. Call `browser_take_screenshot` with `path: $SAVE_PATH_PNG` to write directly to disk
```

Change it to:

```
3. Call `browser_take_screenshot` with `path: $SAVE_PATH_PNG` and `selector: ".card"` to capture only the card element and write directly to disk
```

No other files need editing — all skills read this reference file and follow its procedure.

---

## Verification

1. Invoke any skill (e.g., `code-share`) and let it run through Phase 5.
2. Confirm the saved PNG contains only the card — no body background, no copy-panel text area below.
3. Check that the PNG dimensions match the card's declared width (600–760 px depending on template) rather than the full viewport width.

---

## Files Modified

| File | Change |
|------|--------|
| `kit/plugins/social-media-tools/references/rendering-pipeline.md` | Add `selector: ".card"` to Step 3 screenshot call |
| `docs/plans/the-social-media-tools-tender-grove.md` | This plan file (include in commit per convention) |

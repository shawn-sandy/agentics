# Bug Report Template

Use this body skeleton when `source` is `bug`. Populate every `{{...}}` placeholder from gathered context. Remove sections that are genuinely not applicable (e.g. no package.json → omit Dependencies).

```markdown
## Summary

{{One-sentence description of the bug.}}

## Steps to Reproduce

1. {{First step}}
2. {{Second step}}
3. {{Continue as needed}}

## Expected Behavior

{{What should happen}}

## Actual Behavior

{{What actually happens}}

## Environment

| Item | Value |
|------|-------|
| Node.js | {{node --version output}} |
| npm | {{npm --version output}} |
| OS / Browser | {{e.g. macOS 15 / Chrome 124}} |
| Package version | {{package version from package.json if relevant}} |

## Related Files

{{List file paths identified via Grep/Glob that are likely related to the bug}}

## Recent Changes

```
{{git log --oneline -5 output}}
```

## Additional Context

{{Anything else that would help: screenshots, error logs, stack traces, workarounds discovered.}}
```

## Worked example

A filled body — match this length and specificity. Sections without real
content are removed, not padded.

Title: `[BUG] Gallery build crashes on card titles containing "&"`

```markdown
## Summary

`node scripts/build-gallery.mjs` exits 1 when any saved card title contains an ampersand.

## Steps to Reproduce

1. Save a card titled `Tips & Tricks` under `docs/media/social/`
2. Run `node scripts/build-gallery.mjs`

## Expected Behavior

The gallery builds and the card title renders as `Tips & Tricks`.

## Actual Behavior

Build fails with `TypeError: Cannot read properties of undefined (reading 'trim')` in `renderCard()` — the title is split on `&` and only the first half survives.

## Environment

| Item | Value |
|------|-------|
| Node.js | v22.11.0 |
| npm | 10.9.0 |
| OS / Browser | macOS 15 / n/a (CLI build) |

## Related Files

- `scripts/build-gallery.mjs` (`renderCard()`)
```

## Suggested labels

`bug`, `needs-investigation`

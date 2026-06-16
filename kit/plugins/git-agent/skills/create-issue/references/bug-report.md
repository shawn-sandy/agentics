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

## Suggested labels

`bug`, `needs-investigation`

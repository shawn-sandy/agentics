# Self-Review Checklist and Amend Procedure

Procedure detail for **Step 4.5: Self-Review Before Push**. The policy that
governs this step — it runs by default, `--no-review` opts out, it never blocks
the ship, and `<base>` comes from Step 7 rather than being detected twice — lives
in `SKILL.md`. This file is the checklist and the fix procedure.

## The diff

With `<base>` already resolved by Step 7's procedure, run:

```
git diff <base>...HEAD
```

## The four regression checks

Critique the diff as a hostile reviewer would. Check specifically for:

1. **Dropped accessibility attributes** — removed `aria-*`, `role`, `alt`, or
   live-region markup that the previous version had.
2. **Double-escaping or encoding changes** in generated output — HTML entities
   escaped twice, or raw text now passing through an escape it did not before.
3. **Edge cases in string parsing or truncation** — off-by-one slices, splitting
   on a character that occurs inside the data (e.g. hyphens), unhandled empty
   input.
4. **Responsive or desktop regressions** in image or layout changes — a
   breakpoint, `srcset`, width, or height silently changed or halved.

Report findings as a short list. For each one, state the file, the line, and
what breaks.

## Amend procedure

**If findings exist:** fix them, then fold the fixes into the commit from
Step 4:

```
git add -A && git commit --amend --no-edit
```

The Step 4 commit is not yet pushed, so amending is safe. Re-run the checks
against the amended diff once. Do not loop a third time — report anything still
outstanding and continue to Step 5.

**If no findings:** output "Self-review: no findings." and continue.

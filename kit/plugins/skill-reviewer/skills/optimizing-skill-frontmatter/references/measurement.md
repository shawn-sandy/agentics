# Measuring descriptions

Loaded by Steps 2, 5, and 6.

## Step 2 — Measure current descriptions

Extract the description value from each file’s YAML frontmatter and measure its length:

```bash
grep -n "^description:" <file> | head -1
```

Use only the **first match** — YAML frontmatter always appears before the body, so the first result is the frontmatter `description:`. Body lines (examples, worked output) may also contain `description:` and must be ignored.

Then count the value’s character length (excluding the `description:` prefix).

**Skip rule:** a file qualifies for SKIP only if it meets **all three** conditions: (1) total description ≤200 chars, (2) short description (first sentence) ≤80 chars, and (3) all three components present — a short description, a capability sentence, and a “Use when…” trigger phrase. A file is a REWRITE candidate if any condition fails: total >200, first sentence >80, missing short description, missing capability, or missing trigger. Do not exit silently. Instead:

1. Print a row showing: `{path} | {current chars} | {current description text}`
2. Call `AskUserQuestion` with three options:
   - **Rewrite anyway** — proceed to Step 3 for this file
   - **Keep as-is** — accept the current description and continue to the next file
   - **Skip all remaining** — stop processing and jump to Step 6

Report a table of all files, current char count, and SKIP/REWRITE status before calling `AskUserQuestion` for each SKIP candidate.

## Step 5 — Verify results

After all edits, re-measure both total length and short description length:

```bash
for f in <edited-files>; do
  line=$(grep "^description:" "$f" | head -1)
  val="${line#description: }"
  val="${val%\"}"
  val="${val#\"}"
  val="${val%\'}"
  val="${val#\'}"
  # Total length
  total=${#val}
  # Short description: first sentence (up to and including the first ". ")
  short="${val%%. *}"
  short_len=${#short}
  echo "total=${total} short=${short_len} $f"
done
```

Confirm every `total` ≤200 and every `short` ≤80. Report any violations for a second rewrite pass. Flag separately: total-only violations (capability too long) vs. short-only violations (first sentence needs trimming).

## Step 6 — Sweep the rest of the project

Re-measure every file from the `$PROJECT_SKILLS` list captured in Step 0:

```bash
for f in $PROJECT_SKILLS; do
  line=$(grep "^description:" "$f" | head -1)
  val="${line#description: }"
  val="${val%\"}"
  val="${val#\"}"
  val="${val%\'}"
  val="${val#\'}"
  echo "${#val} $f"
done
```

Print a table with columns `path | chars | status` where status is:
- `DONE` — already processed this session
- `REWRITE` — >200 chars
- `SKIP` — ≤200 chars and compliant phrasing

Then call `AskUserQuestion` with three options:
- **Optimize all over 200** — process every REWRITE file automatically using Steps 3–5
- **Pick specific files** — prompt for a selection, then loop back to Step 2 with the chosen subset
- **Stop here** — end the skill run and proceed to the Budget advisory

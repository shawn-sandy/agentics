---
name: security-scrub
description: "Scans code content or diffs for secrets, credentials, and sensitive data before public sharing. Use when the user asks to check code for secrets, review a diff for leaks, or before sharing any code change."
allowed-tools: Bash, Read, Grep
---

# security-scrub

Scan content for secrets and sensitive data. Produces a structured `SCRUB RESULT` block that callers must check before proceeding.

## Overview

Five mandatory steps — none can be skipped. The caller (human or skill) provides the content to scan either as inline text or a file path.

## Step 1 — Load rules

`Read` the `references/scrub-rules.md` file adjacent to this SKILL.md to get the current pattern table, file-path block list, and masking format.

## Step 2 — Pattern scan

Run `Grep` against the content for HIGH, MEDIUM, and LOW patterns from the table. Also check any file paths referenced in the content against the file-path block list.

Key regex groups to scan:

```
sk-[A-Za-z0-9]{20,}
ghp_[A-Za-z0-9]{36}
ghs_[A-Za-z0-9]{36}
AKIA[A-Z0-9]{16}
xoxb-|xoxp-
-----BEGIN .* PRIVATE KEY
eyJ[A-Za-z0-9_-]{20,}\.eyJ
[A-Z_]{3,}=[[:alnum:]_-]{32,}
password\s*[=:]\s*\S{4,}
secret\s*[=:]\s*\S{4,}
token\s*[=:]\s*\S{8,}
api_key\s*[=:]\s*\S{8,}
```

File path patterns to block: `.env`, `credentials`, `id_rsa`, `.pem`, `~/.ssh/`, `~/.aws/credentials`

## Step 3 — Classify findings

Classify each match as HIGH / MEDIUM / LOW per the pattern table in `references/scrub-rules.md`.

- Any HIGH finding → overall result is `BLOCKED`
- Any MEDIUM finding with no HIGH → overall result is `WARN`
- No findings → overall result is `PASS`

## Step 4 — Mask values before reporting

For any matched value: show first 4 chars + `***` + last 4 chars.
Example: `sk-abcdefgh1234WXYZ` → `sk-a***WXYZ`

Never output unmasked secret values.

## Step 5 — Emit structured report

Output exactly this block (fill in the brackets):

```
SCRUB RESULT: [PASS | BLOCKED | WARN]
---
Findings:
  - [HIGH|MEDIUM|LOW] <pattern-name>: <masked-value> (line N)
ALLOWLIST verdict: [PASS | BLOCKED]
Reason: <one sentence>
```

If no findings, output:
```
Findings: none
```

**`ALLOWLIST verdict: BLOCKED`** when the content originates from a blocked file path (see file-path block list). This overrides `SCRUB RESULT: PASS`.

Callers must treat `SCRUB RESULT: BLOCKED` or `ALLOWLIST verdict: BLOCKED` as a hard stop — do not proceed with sharing.

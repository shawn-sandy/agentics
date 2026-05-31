---
name: security-scrub
description: "Scans code and diffs for secrets and sensitive data. Detects credentials, tokens, and PII to prevent leaks before sharing. Use when the user asks to check for secrets or review a diff for leaks."
allowed-tools: AskUserQuestion, Bash, Read, Grep
---

# security-scrub

Scan content for secrets and sensitive data. Produces a structured `SCRUB RESULT` block that callers must check before proceeding.

## Overview

Six mandatory steps — none can be skipped. The caller (human or skill) provides the content to scan either as inline text or a file path.

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
xoxb-[0-9]{11}-[0-9]{11}-[A-Za-z0-9]{24}
xoxp-[A-Za-z0-9-]{72,}
eyJ[A-Za-z0-9_-]{20,}\.eyJ
[A-Z_]{3,}=[[:alnum:]_-]{32,}
password\s*[=:]\s*\S{4,}
secret\s*[=:]\s*\S{4,}
token\s*[=:]\s*\S{8,}
api_key\s*[=:]\s*\S{8,}
```

For the private-key pattern (`-----BEGIN ...`), pass via `-e` to avoid the leading dash being parsed as a grep option:
```
grep -E -e '-----BEGIN (RSA|EC|OPENSSH|PGP) PRIVATE KEY'
```

File path patterns to block: `.env`, `credentials`, `id_rsa`, `.pem`, `~/.ssh/`, `~/.aws/credentials`

## Step 3 — Classify findings

Classify each match as HIGH / MEDIUM / LOW per the pattern table in `references/scrub-rules.md`.

- Any HIGH finding → overall result is `BLOCKED`
- Any MEDIUM finding with no HIGH → overall result is `WARN`
- LOW findings only (no HIGH or MEDIUM) → overall result is `PASS`; list findings as informational notes
- No findings → overall result is `PASS`

## Step 4 — Mask values before reporting

For any matched value: show first 4 chars + `***` + last 4 chars.
Example: `sk-abcdefgh1234wxyz` → `sk-a***wxyz`

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

## Step 6 — User gate

After emitting the SCRUB RESULT block, apply the appropriate gate based on the result. Emit a `GATE RESULT` line at the end so callers have a machine-readable signal.

**BLOCKED** (`SCRUB RESULT: BLOCKED` or `ALLOWLIST verdict: BLOCKED`):
- Do NOT call `AskUserQuestion`.
- Output: `GATE RESULT: BLOCKED — hard stop. Sharing is not permitted.`
- Return immediately. The caller must not proceed.

**WARN** (MEDIUM findings, no HIGH):
- Call `AskUserQuestion` with one question:
  - Header: `Security warning`
  - Question: `The security scan found potential issues (see MEDIUM findings above). Are you sure you want to continue?`
  - Options: `Continue anyway` (description: "Proceed despite warnings — review findings first") / `Cancel — stop here` (description: "Abort sharing; no content will be sent")
- If user selects **Cancel**: output `GATE RESULT: CANCELLED — user declined to proceed.` and return.
- If user selects **Continue anyway**: output `GATE RESULT: APPROVED.` and return.

**PASS with LOW findings only**:
- Call `AskUserQuestion` with one question:
  - Header: `Scrub passed`
  - Question: `Security scan passed with informational notes (see LOW findings above). Continue?`
  - Options: `Continue` (description: "Proceed with sharing") / `Cancel` (description: "Abort sharing")
- If user selects **Cancel**: output `GATE RESULT: CANCELLED — user declined to proceed.` and return.
- If user selects **Continue**: output `GATE RESULT: APPROVED.` and return.

**PASS with no findings**:
- Do NOT call `AskUserQuestion`.
- Output: `GATE RESULT: APPROVED (clean — auto-proceeding).`
- Return immediately.

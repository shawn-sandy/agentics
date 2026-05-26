# Plan: Add Discovery + Security-Scrub Skills to `social-media-tools`

## Context

Developers want to discover interesting code changes from their git history and share them on social media on a regular schedule — without accidentally leaking secrets, credentials, or sensitive implementation details. The existing `social-media-tools` plugin (`kit/plugins/social-media-tools`, plugin name `code-share`) already handles social formatting and card generation (6-phase `code-share` skill), but has no discovery or security-filtering layer. This plan extends that plugin with two new skills, two commands, and one background agent that sit upstream: scan → scrub → draft → human review → hand off to `code-share`.

---

## Plugin: `code-share` (extended)

**Location:** `kit/plugins/social-media-tools/` (existing plugin, extending in place)  
**Plugin name:** `code-share` (per `plugin.json` — used for command invocation: `/code-share:digest`)  
**Version bump:** MINOR (new skills/commands/agent added) — update version only in `marketplace.json`

### New files to add

```
kit/plugins/social-media-tools/
├── skills/
│   ├── scan-for-shares/          ← NEW
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── interesting-patterns.md
│   └── security-scrub/           ← NEW
│       ├── SKILL.md
│       └── references/
│           └── scrub-rules.md
├── commands/                     ← NEW directory
│   ├── digest.md
│   └── digest-bg.md
└── agents/                       ← NEW directory
    └── agent-digest.md
```

Existing files (`skills/code-share/`, `templates/`, `scripts/`, `plugin.json`, `CHANGELOG.md`) are unchanged except `CHANGELOG.md` gets a new version entry.

---

## Components

### `plugin.json`

No changes needed. Existing `plugin.json` has `name: "code-share"` which governs command invocation prefix.

---

### Skill: `security-scrub`

**File:** `skills/security-scrub/SKILL.md`  
**Frontmatter:**
```yaml
name: security-scrub
description: "Scans diff content for secrets and sensitive data before public sharing. Use when the user asks to check code for secrets or before sharing any code change."
allowed-tools: Bash, Read, Grep
```

**Workflow (5 steps, mandatory — cannot be skipped):**

1. **Pattern scan** — `Grep` for: `sk-|ghp_|ghs_|AKIA|xoxb-|xoxp-|-----BEGIN|[A-Z_]{3,}=[[:alnum:]_]{20,}|password\s*=|secret\s*=|token\s*=|api_key\s*=`  
   Also grep file paths for: `.env`, `credentials`, `secrets`, `id_rsa`, `.pem`, internal URLs (`10.`, `192.168.`, `.internal`)
2. **Classify** — HIGH (block), MEDIUM (warn), LOW (note) per the extended table in `references/scrub-rules.md`
3. **Mask before reporting** — show first 4 + `***` + last 4 for any matched value (pattern from `memory-tools` skill)
4. **Emit scrub report** — structured block: `SCRUB RESULT: [PASS | BLOCKED | WARN]` with finding details
5. **Allowlist check** — content must come from public-facing files only; no `.env`, no credential stores, no internal paths → `ALLOWLIST verdict: [PASS | BLOCKED]`

Callers must check `ALLOWLIST verdict` before proceeding. `BLOCKED` means stop.

**Reference:** `skills/security-scrub/references/scrub-rules.md` — extended pattern table, file-path block list, never-share rules (JWT tokens, DB connection strings, `~/.ssh/` content).

---

### Skill: `scan-for-shares`

**File:** `skills/scan-for-shares/SKILL.md`  
**Frontmatter:**
```yaml
name: scan-for-shares
description: "Scans recent git history or a codebase path for shareable code and drafts social media content for code-share. Use when the user asks to find commits or code worth sharing, create a code digest, or generate a post from the codebase."
allowed-tools: Bash, Read, Grep, Glob, AskUserQuestion, Write, Skill
```

**Two modes — determined by arguments:**

| Flag | Mode | Source |
|------|------|--------|
| *(default)* | **History mode** | `git log` on current branch |
| `--codebase <path>` | **Codebase mode** | `Read`/`Glob` on given path |

**Design decisions confirmed:**
- History scope: current branch only (HEAD..base or --days=N)
- Codebase scope: user-supplied path (e.g. `--codebase src/auth/`)
- Output: `.claude/digests/code-digest-[YYYY-MM-DD].md` (auto-created with `mkdir -p`)
- Review gate: single multi-select `AskUserQuestion` for all candidates at once
- Scoring table: loaded from `references/interesting-patterns.md` at runtime (user-tunable)

**Workflow (7 steps):**

1. **Configure** — parse `$ARGUMENTS`. History flags: `--days=N` (default 7), `--base` (auto-detect main/master), `--max=20`. Codebase flags: `--codebase <path>` (required in codebase mode). Shared: `--background`.
2. **Collect**
   - *History*: `git log --oneline --after="N days ago" --format="%H %s" HEAD` + `git log --oneline [base]..HEAD`. Deduplicate. Get per-commit stats via `git diff [hash]~1 [hash] --stat`.
   - *Codebase*: `Glob` the given path for source files; `Read` each file. Collect file path + excerpt as the candidate unit.
3. **Score by heuristics** — `Read references/interesting-patterns.md` to load scoring table each run. History: score by commit message prefix + lines changed. Codebase: score by file patterns (public API surface, elegant algorithms, unusual constructs, well-documented functions). Include candidates with score ≥ 2 (or ≥ 1 as fill-up if < 3).
4. **Security scrub (mandatory)** — for each candidate: get the diff (history) or file content (codebase), invoke `security-scrub` skill. BLOCKED → remove; WARN → flag. Never skip.
5. **Build digest entries** — structured blocks with: `source` (commit hash or file path), `subject`, `card-type` (feature-card/diff-card/quote-card), `platform-suggestion`, `summary`, `key-change`, `code-share-prompt` (ready-to-paste `/code-share` invocation).
6. **Human review gate** — when `--background` is absent: single `AskUserQuestion` with `multiSelect: true` listing all PASS candidates. When `--background` is present: auto-include PASS, auto-exclude BLOCKED/WARN.
7. **Output digest** — `mkdir -p .claude/digests/` then write `.claude/digests/code-digest-[YYYY-MM-DD].md`. Report count and path. **STOP — do not invoke `code-share` automatically.**

**Reference:** `skills/scan-for-shares/references/interesting-patterns.md` — scoring table for both modes (re-read each run), codebase pattern heuristics, card-type decision tree, platform heuristics.

---

### Command: `digest`

**File:** `commands/digest.md`  
**Invocation:** `/code-share:digest [--days=7] [--base=main] [--max=20] | --codebase <path>`  
**Frontmatter:**
```yaml
description: Scan recent git history or a codebase path for shareable code and draft code-share prompts
argument-hint: "[--days=7] [--base=main] [--max=20] | --codebase <path>"
allowed-tools: Skill, AskUserQuestion, ToolSearch, ExitPlanMode
```
Exits plan mode (deferred — bootstrap via `ToolSearch select:ExitPlanMode` first), then invokes `scan-for-shares` with `$ARGUMENTS`. After digest is written, asks user if they want to use `code-share` — does not invoke it automatically.

---

### Command: `digest-bg`

**File:** `commands/digest-bg.md`  
**Invocation:** `/code-share:digest-bg [--days=7] [--base=main] [--max=20] | --codebase <path>`  
**Frontmatter:**
```yaml
description: Run the git history or codebase scan in the background and write the digest while you keep working
argument-hint: "[--days=7] [--base=main] [--max=20] | --codebase <path>"
allowed-tools: Agent, ToolSearch, ExitPlanMode
```
Exits plan mode, dispatches `agent-digest` with `run_in_background: true` + `$ARGUMENTS`. Returns immediately with one-line ack. Does not poll.

---

### Agent: `agent-digest`

**File:** `agents/agent-digest.md`  
**Frontmatter:**
```yaml
name: agent-digest
tools: Skill, Bash, Read, Grep, Write
model: sonnet
maxTurns: 20
background: true
```
Confirms git repo, invokes `scan-for-shares` with `--background`, writes digest file to `.claude/digests/`, then **proactively reports the output path** as a completion message to the user. Does not post, analyze further, or interact with the user beyond the completion notice.

Note: agents use `tools:` (not `allowed-tools:`) — matches `agent-commit.md` pattern.

---

## Marketplace update

In `.claude-plugin/marketplace.json`:
- Find the existing `code-share` plugin entry (path `kit/plugins/social-media-tools`) and bump its `version` (MINOR bump — e.g. `0.1.0` → `0.2.0`)
- Bump top-level marketplace `"version"` from `"3.6.0"` → `"3.7.0"`
- Update `description` and `tags` on the entry to reflect the new discovery + scrub capabilities

---

## Scheduling (documented in CHANGELOG only — no plugin code needed)

Claude Code has no native timer. Note in CHANGELOG that users can schedule via:
1. **GitHub Actions** — `cron:` trigger running `claude --plugin-dir ... -p "/code-share:digest-bg --days=7"`
2. **System cron** — standard crontab entry
3. **Claude routine** — `~/.claude/settings.json` `routines` key when available

Human review always required before posting — no auto-post path exists.

---

## Implementation order

All new files go inside `kit/plugins/social-media-tools/`:

1. `skills/security-scrub/references/scrub-rules.md`
2. `skills/security-scrub/SKILL.md`
3. `skills/scan-for-shares/references/interesting-patterns.md`
4. `skills/scan-for-shares/SKILL.md`
5. `agents/agent-digest.md`
6. `commands/digest.md`
7. `commands/digest-bg.md`
8. Update `CHANGELOG.md` with MINOR version entry
9. Update `.claude-plugin/marketplace.json` — bump `code-share` plugin version + bump top-level to `3.7.0`

---

## Key patterns to reuse

| Pattern | Source file |
|---------|-------------|
| Secret scan regex | `kit/plugins/memory-tools/skills/agentic-memory-doctor/SKILL.md` |
| Background agent frontmatter | `kit/plugins/git-agent/agents/agent-commit.md` |
| Background command dispatch | `kit/plugins/product-plans/commands/product-plans-bg.md` |
| Deferred ExitPlanMode bootstrap | `kit/plugins/git-agent/skills/commit-agent/SKILL.md` |
| Git diff/log commands | `kit/plugins/git-agent/agents/agent-pr.md` |
| Social card input format | `kit/plugins/social-media-tools/skills/code-share/SKILL.md` |

---

## Verification

1. Load plugin locally: `claude --plugin-dir ./kit/plugins/social-media-tools`
2. Run `/code-share:digest --days=7` in a repo with recent commits — confirm digest written to `.claude/digests/`
3. Run `/code-share:digest --codebase src/` — confirm codebase mode reads files, scores, and writes digest
4. Confirm a commit (or file) containing a fake secret pattern (e.g. `sk-test1234abcd`) is BLOCKED by `security-scrub`
5. Confirm a clean `feat:` commit or well-documented function produces a PASS scrub result and a valid digest entry
6. Run `/code-share:digest-bg --days=7` — confirm it returns immediately and `.claude/digests/` file appears with a proactive completion message
6. Copy a `code-share-prompt` from the digest and run `/code-share:code-share [prompt]` — confirm card generation works end-to-end
7. Run `/validate-plugin social-media-tools` to check plugin structure
8. Confirm `marketplace.json` JSON is valid (auto-validated by `.claude/settings.json` hook on save)

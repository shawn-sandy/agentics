# code-share

> Plugin directory: `kit/plugins/social-media-tools`

Discover shareable code, blog posts, videos, and GitHub snippets — scrub for secrets, draft platform-aware copy, and generate styled dark-mode social cards for LinkedIn, Twitter/X, and Bluesky.

Two complementary workflows: a **discovery pipeline** (scan git history or a codebase path → scrub → review → digest) and a **card generation pipeline** (draft copy → render dark-mode card image).

## Features

| Component | Type | Description |
|-----------|------|-------------|
| `code-share` | Skill | Draft copy + render dark-mode card for local git commits and diffs |
| `blog-share` | Skill | Fetch blog post metadata from a URL or local `.md`; generate card + copy |
| `video-share` | Skill | Fetch YouTube/Vimeo metadata via oEmbed; generate card + copy |
| `github-code-share` | Skill | Fetch a public GitHub file/snippet; security-scrub + generate card + copy |
| `scan-for-shares` | Skill | Discover shareable commits or codebase patterns; write a `.claude/digests/` file |
| `security-scrub` | Skill | Scan any code or diff for secrets, credentials, and sensitive data |
| `/code-share:digest` | Command | Interactive discovery scan with multi-select candidate review |
| `/code-share:digest-bg` | Command | Fire-and-forget background digest scan |
| `agent-digest` | Agent | Background agent; proactively reports output path when done |

## Installation

```bash
# From the agentics marketplace
/plugin marketplace add shawn-sandy/agentics
/plugin install code-share@agentics-kit

# Local dev
claude --plugin-dir ./kit/plugins/social-media-tools
```

## Usage

### Discover what's worth sharing

```bash
# Scan the last 7 days of git history (interactive review gate)
/code-share:digest

# Scan further back or against a specific base branch
/code-share:digest --days=14
/code-share:digest --base=develop

# Scan a codebase path instead of git history
/code-share:digest --codebase src/auth/

# Run in the background while you keep working
/code-share:digest-bg --days=7
```

The digest is written to `.claude/digests/code-digest-YYYY-MM-DD.md`. Each entry includes a ready-to-paste `/code-share:code-share` prompt.

### Generate a social media post

Skills activate automatically — just describe what you want to share.

**Share a code change (git-based):**
> "Write a LinkedIn post about today's changes"
> "Tweet about the v0.3.0 release"

**Share a blog post or article:**
> "Share this blog post: https://dev.to/example/my-article"
> "Write a LinkedIn post about ./posts/my-article.md"

**Share a video:**
> "Write a tweet about this YouTube talk: https://youtu.be/abc123"
> "Post about this Vimeo video on LinkedIn"

**Share a GitHub code snippet:**
> "Share this function on Twitter: https://github.com/owner/repo/blob/main/src/auth.ts#L42-L68"
> "Post about this file: https://github.com/owner/repo/blob/main/src/parser.py"

**Use a prompt from the digest:**
> `/code-share:code-share feature-card for LinkedIn: the new security-scrub skill`

### Scrub code for secrets before sharing

The `security-scrub` skill activates automatically when you ask to check code for leaks:

> "Check this diff for credentials before I share it"  
> "Scrub this file for sensitive data"

## Card Types

| Type | Best for | Template |
|------|----------|----------|
| `diff-card` | Code changes, rule updates, config diffs | `templates/diff-card.html` |
| `feature-card` | Releases, new features, version announcements | `templates/feature-card.html` |
| `quote-card` | Insights, opinions, pull quotes | `templates/quote-card.html` |
| `blog-card` | Blog post or article shares | `templates/blog-card.html` |
| `video-card` | YouTube or Vimeo video shares | `templates/video-card.html` |
| `snippet-card` | GitHub code file or snippet shares | `templates/snippet-card.html` |

See [`skills/code-share/references/variables.md`](skills/code-share/references/variables.md) for the full variable reference for each card type.

## Plugin Structure

```
social-media-tools/
├── .claude-plugin/
│   └── plugin.json
├── CHANGELOG.md
├── README.md
├── agents/
│   └── agent-digest.md                    ← background digest agent
├── commands/
│   ├── digest.md                           ← /code-share:digest
│   └── digest-bg.md                        ← /code-share:digest-bg
├── scripts/
│   └── find_free_port.py                   ← port helper for Playwright
├── skills/
│   ├── blog-share/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── platforms.md               ← LinkedIn/Twitter/Bluesky format rules
│   ├── code-share/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── variables.md               ← template variable reference (all 6 cards)
│   ├── github-code-share/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── language-map.md            ← file extension → language + badge colour
│   ├── scan-for-shares/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── interesting-patterns.md    ← scoring table (user-tunable)
│   ├── security-scrub/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── scrub-rules.md             ← pattern table and block list
│   └── video-share/
│       ├── SKILL.md
│       └── references/
│           └── platforms.md               ← oEmbed endpoints + copy format rules
└── templates/
    ├── blog-card.html
    ├── diff-card.html
    ├── feature-card.html
    ├── quote-card.html
    ├── snippet-card.html
    └── video-card.html
```

## Components

### Skill: `blog-share`

**File:** `skills/blog-share/SKILL.md`  
**Activation:** automatic — triggers when the user asks to share or post a blog post or article.

**Inputs:**

| Input | Values | Notes |
|-------|--------|-------|
| Source | URL or local `.md` path | Relative paths resolved via `realpath` |
| Platform | LinkedIn, Twitter/X, Bluesky | Required |
| Tone | Professional, Casual, Punchy | Default varies by platform |
| Hook angle | Free text | Optional framing direction |

**Workflow:** fetch OG metadata (URL) or read front matter (local file) → draft copy per platform rules in `references/platforms.md` → populate `blog-card.html` → Playwright screenshot → deliver copy + PNG.

`READ_TIME` is only computed for local `.md` files (word count / 200 wpm). For URL sources it is omitted — HTML body parsing is too fragile. All fetched text is HTML-escaped before card substitution.

---

### Skill: `video-share`

**File:** `skills/video-share/SKILL.md`  
**Activation:** automatic — triggers when the user asks to share a video, post about a talk, or promote video content.

**Supported platforms:** YouTube (`youtube.com`, `youtu.be`) and Vimeo (`vimeo.com`).

**Workflow:** fetch metadata via oEmbed API → if 4xx (private/deleted), ask user for title and channel → draft copy → populate `video-card.html` (with conditional thumbnail zone) → Playwright screenshot → deliver copy + PNG.

`PLATFORM_COLOR` is hardcoded from URL detection only (`#ff0000` YouTube, `#1ab7ea` Vimeo) — never sourced from fetched content.

---

### Skill: `github-code-share`

**File:** `skills/github-code-share/SKILL.md`  
**Activation:** automatic — triggers when the user asks to share a code file or snippet from a GitHub repository.

**Public repositories only.** Private repos return a 4xx from the raw URL — the skill stops with a clear error message.

**Accepted URL forms:**
- `https://github.com/{owner}/{repo}/blob/{branch}/{path}#L10-L25` (standard + optional line range)
- `https://raw.githubusercontent.com/{owner}/{repo}/{branch}/{path}` (raw URL, skip conversion)

**Workflow:** parse URL fragment (`#L10-L25`) from string before any network call → fetch raw content → extract line range (or first 80 lines) → write to temp file → `security-scrub` → draft copy → HTML-escape code → populate `snippet-card.html` → Playwright screenshot → deliver copy + PNG.

---

### Skill: `scan-for-shares`

**File:** `skills/scan-for-shares/SKILL.md`  
**Activation:** automatic — triggers when the user asks to find commits worth sharing, create a code digest, or generate a post from the codebase.

**Two modes:**

| Arguments | Mode | Source |
|-----------|------|--------|
| *(default)* | History | `git log` on current branch |
| `--codebase <path>` | Codebase | `Read`/`Glob` on given path |

Scoring weights (commit type, codebase patterns, card-type decision tree, platform heuristics) are stored in `skills/scan-for-shares/references/interesting-patterns.md` and re-read on every run — edit that file to tune what surfaces in your digests.

Security scrub is mandatory on every candidate. The review gate presents all candidates in a single multi-select prompt. Output goes to `.claude/digests/code-digest-YYYY-MM-DD.md`.

---

### Skill: `security-scrub`

**File:** `skills/security-scrub/SKILL.md`  
**Activation:** automatic — triggers when the user asks to check code for secrets or before sharing any code change.

Scans for 20+ pattern categories (API keys, JWTs, private keys, DB connection strings, internal IPs). Masks matched values (`sk-a***WXYZ`) before reporting. Emits a structured `SCRUB RESULT` block with a separate `ALLOWLIST verdict` — callers treat either `BLOCKED` as a hard stop.

Pattern table and file-path block list are in `skills/security-scrub/references/scrub-rules.md`.

---

### Command: `/code-share:digest`

**File:** `commands/digest.md`  
Interactive front-end for `scan-for-shares`. Runs the scan, presents candidates for review, and writes the approved entries to `.claude/digests/`.

```
/code-share:digest [--days=7] [--base=main] [--max=20] | --codebase <path>
```

---

### Command: `/code-share:digest-bg`

**File:** `commands/digest-bg.md`  
Background variant. Dispatches `agent-digest` and returns immediately; the agent reports the output path on completion.

```
/code-share:digest-bg [--days=7] [--base=main] [--max=20] | --codebase <path>
```

---

### Agent: `agent-digest`

**File:** `agents/agent-digest.md`  
Dispatched by `/code-share:digest-bg`. Runs `scan-for-shares --background` (auto-includes PASS candidates, skips interactive review), writes the digest, and sends one proactive completion message. Does not post or invoke `code-share`.

---

### Skill: `code-share`

**File:** `skills/code-share/SKILL.md`
**Activation:** automatic — triggers when the user asks to write a post, tweet, or share a code change.

**Inputs (collected automatically or via prompt):**

| Input | Values | Default |
|-------|--------|---------|
| Platform | `LinkedIn`, `Twitter/X`, `Bluesky` | — (required) |
| Content type | `diff-card`, `feature-card`, `quote-card` | auto-detected from git |
| Tone | `Professional`, `Casual`, `Punchy` | Professional (LinkedIn), Punchy (Twitter/X, Bluesky) |

**Workflow (6 phases):**

1. **Clarify** — runs `git diff`, `git log`, and `CHANGELOG.md` to auto-detect content type; only asks for what it can't infer
2. **Draft copy** — writes platform-aware copy within character limits (LinkedIn 1,500 / Twitter 280 / Bluesky 300)
3. **Pick template** — selects `diff-card`, `feature-card`, or `quote-card` and locates the `templates/` directory
4. **Populate** — substitutes `{{VARIABLES}}` in the HTML template and writes to `~/.claude/tmp/code-share-card.html`
5. **Screenshot** — starts a local HTTP server, takes a Playwright screenshot to `~/.claude/tmp/code-share-card.png`, then kills the server
6. **Deliver** — presents copy in a fenced block with character count, attaches the PNG via `SendUserFile`

**Fallback:** if Playwright MCP is unavailable, the skill skips the screenshot and provides the HTML path for a manual browser screenshot.

## Scheduling

Claude Code has no native timer, but `/code-share:digest-bg` works well with external schedulers:

```yaml
# GitHub Actions — weekly digest on Monday at 9am
on:
  schedule:
    - cron: '0 9 * * 1'
jobs:
  digest:
    steps:
      - run: claude --plugin-dir kit/plugins/social-media-tools -p "/code-share:digest-bg --days=7"
```

Human review is always required before posting — no path in this plugin auto-posts.

## Requirements

- **Playwright MCP** — required for the screenshot pipeline. If unavailable, the skill falls back to providing the HTML path for a manual screenshot.
- **Python 3** — used by `find_free_port.py` and `http.server` for the local card server.
- **Git** — used in Phase 1 to auto-detect recent changes and commits.

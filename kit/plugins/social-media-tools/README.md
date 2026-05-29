# social-media-tools

> Plugin directory: `kit/plugins/social-media-tools`

Discover shareable code, blog posts, videos, GitHub snippets, selected/pasted code, and project updates — scrub for secrets, draft objective-driven platform-aware copy, and generate styled dark-mode social cards for LinkedIn, Twitter/X, and Bluesky.

Three complementary workflows:

- **Discovery pipeline** — scan git history or a codebase path → scrub → review → write a digest.
- **Card generation pipeline** — draft copy → render a dark-mode card image from one of six templates.
- **Background router** — describe what you want to share in plain language; the `social-share` router classifies it and dispatches the right skill unattended.

No path in this plugin auto-posts — human review is always required before anything reaches a social network.

## Features

| Component | Type | Description |
|-----------|------|-------------|
| `social-share` | Skill | **Router** — classifies a natural-language request and dispatches the right skill in the background with zero questions |
| `share-code` | Skill | Draft copy + render dark-mode card for local git commits and diffs |
| `share-blog` | Skill | Fetch blog post metadata from a URL or local `.md`; generate card + copy |
| `share-video` | Skill | Fetch YouTube/Vimeo metadata via oEmbed; generate card + copy |
| `share-github` | Skill | Fetch a public GitHub file/snippet; security-scrub + generate card + copy |
| `share-selection` | Skill | Turn selected/highlighted/open/pasted code into an objective-driven card + copy |
| `share-project` | Skill | Generate a card for a project topic (features / bugs / changes / release) from git + CHANGELOG |
| `share-scan` | Skill | Discover shareable commits or codebase patterns; write a `.claude/digests/` file |
| `media-library` | Skill | Browse saved posts interactively, or snapshot the catalog to `.claude/digests/` in the background |
| `security-scrub` | Skill | Scan any code or diff for secrets, credentials, and sensitive data (sub-step utility) |
| `/social-media-tools:social-share-bg` | Command | Fire-and-forget background share — explicit entry point for the router |
| `/social-media-tools:digest` | Command | Interactive discovery scan with multi-select candidate review |
| `/social-media-tools:digest-bg` | Command | Fire-and-forget background digest scan |
| `agent-social-share` | Agent | Background agent; runs the chosen skill non-interactively and reports `SOCIAL-SHARE: DONE` |
| `agent-digest` | Agent | Background agent; runs `share-scan --background` and proactively reports the digest path |

## Installation

```bash
# From the agentics marketplace
/plugin marketplace add shawn-sandy/agentics
/plugin install social-media-tools@agentics-kit

# Local dev
claude --plugin-dir ./kit/plugins/social-media-tools
```

## Usage

### Discover what's worth sharing

```bash
# Scan the last 7 days of git history (interactive review gate)
/social-media-tools:digest

# Scan further back or against a specific base branch
/social-media-tools:digest --days=14
/social-media-tools:digest --base=develop

# Scan a codebase path instead of git history
/social-media-tools:digest --codebase src/auth/

# Run in the background while you keep working
/social-media-tools:digest-bg --days=7
```

The digest is written to `.claude/digests/code-digest-YYYY-MM-DD.md`. Each entry includes a ready-to-paste `/social-media-tools:social-share-bg` prompt.

### Share anything — router dispatches in the background

The `social-share` router skill classifies your request and runs the right workflow
unattended. Just describe what you want to share:

```
"share what I just built"
"post today's changes"
"share this: https://youtu.be/abc123"
"we just launched v2.0, post about it"
"share my progress this week"
```

Or use the explicit command:

```bash
/social-media-tools:social-share-bg share my latest commit
/social-media-tools:social-share-bg https://github.com/owner/repo/blob/main/src/auth.ts#L10-L40
/social-media-tools:social-share-bg we just shipped v2 on Twitter
/social-media-tools:social-share-bg browse my saved posts   # snapshots catalog to .claude/digests/
```

A one-line ack is returned immediately. The background agent notifies you when the card is
saved under `docs/media/social/` (card skills) or the catalog snapshot is written to
`.claude/digests/media-library-YYYY-MM-DD.md` (`media-library`).

### Generate a social media post (interactive)

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
> `/social-media-tools:social-share-bg feature-card for LinkedIn: the new security-scrub skill`

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

See [`references/variables.md`](references/variables.md) for the full variable reference for each card type.

## Plugin Structure

```
social-media-tools/
├── .claude-plugin/
│   └── plugin.json
├── CHANGELOG.md
├── README.md
├── agents/
│   ├── agent-digest.md                    ← background digest agent
│   └── agent-social-share.md              ← background social share agent (all card skills + media-library)
├── commands/
│   ├── digest.md                          ← /social-media-tools:digest
│   ├── digest-bg.md                       ← /social-media-tools:digest-bg
│   └── social-share-bg.md                 ← /social-media-tools:social-share-bg
├── references/                            ← shared pipeline logic (all card skills)
│   ├── copy-panels.md                     ← {{COPY_PANELS}} markup + escaping rules
│   ├── language-map.md                    ← file extension → language + badge colour
│   ├── non-interactive-mode.md            ← --background contract (skip rules + completion lines)
│   ├── platforms.md                       ← canonical char limits + universal copy rules
│   ├── rendering-pipeline.md              ← find_free_port → HTTP server → Playwright → kill
│   ├── reuse-check.md                     ← scan docs/media/social/ + offer reuse
│   ├── saving-and-delivery.md             ← persistent save block + deliver phase
│   └── variables.md                       ← per-template variable maps (all 6 cards)
├── scripts/
│   └── find_free_port.py                  ← port helper for Playwright
├── skills/
│   ├── media-library/
│   │   └── SKILL.md                       ← browse interactively or snapshot catalog to .claude/digests/
│   ├── security-scrub/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── scrub-rules.md             ← pattern table and block list
│   ├── share-blog/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── platforms.md               ← blog copy format rules + examples
│   ├── share-code/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── variables.md               ← redirects to plugin-root references/
│   ├── share-github/
│   │   └── SKILL.md
│   ├── share-project/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── topics.md                  ← per-topic extraction patterns + tone guide
│   ├── share-scan/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── interesting-patterns.md    ← scoring table (user-tunable)
│   ├── share-selection/
│   │   └── SKILL.md                       ← share selected/highlighted/open/pasted code
│   ├── share-video/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── platforms.md               ← oEmbed endpoints + video copy format rules
│   └── social-share/
│       └── SKILL.md                       ← router: classifies + dispatches agent-social-share
└── templates/
    ├── blog-card.html
    ├── diff-card.html
    ├── feature-card.html
    ├── quote-card.html
    ├── snippet-card.html
    └── video-card.html
```

## Components

### Skill: `social-share` (router)

**File:** `skills/social-share/SKILL.md`  
**Activation:** automatic — triggers when the user asks to share what they're working on, or to post code, a blog, a video, or a project update without naming a specific skill.

The entry point for everything. It classifies a natural-language request (first-match-wins rules), resolves a default platform, captures any inline code to a temp file, and dispatches `agent-social-share` to run the matching skill in the background. Returns a one-line ack immediately; the agent reports the saved card path (card skills) or catalog path (`media-library`) on completion. Use `/social-media-tools:social-share-bg` for the explicit command form.

---

### Skill: `share-blog`

**File:** `skills/share-blog/SKILL.md`  
**Activation:** automatic — triggers when the user asks to share or post a blog post or article.

**Inputs:**

| Input | Values | Notes |
|-------|--------|-------|
| Source | URL or local `.md` path | Relative paths resolved via `realpath` |
| Platform | LinkedIn, Twitter/X, Bluesky, All sites | Required — "All sites" embeds a copy snippet per site |
| Tone | Professional, Casual, Punchy | Default varies by platform |
| Hook angle | Free text | Optional framing direction |

**Workflow:** fetch OG metadata (URL) or read front matter (local file) → draft copy per platform rules in `references/platforms.md` → populate `blog-card.html` → Playwright screenshot → deliver copy + PNG.

`READ_TIME` is only computed for local `.md` files (word count / 200 wpm). For URL sources it is omitted — HTML body parsing is too fragile. All fetched text is HTML-escaped before card substitution.

---

### Skill: `share-video`

**File:** `skills/share-video/SKILL.md`  
**Activation:** automatic — triggers when the user asks to share a video, post about a talk, or promote video content.

**Supported platforms:** YouTube (`youtube.com`, `youtu.be`) and Vimeo (`vimeo.com`).

**Workflow:** fetch metadata via oEmbed API → if 4xx (private/deleted), ask user for title and channel → draft copy → populate `video-card.html` (with conditional thumbnail zone) → Playwright screenshot → deliver copy + PNG.

`PLATFORM_COLOR` is hardcoded from URL detection only (`#ff0000` YouTube, `#1ab7ea` Vimeo) — never sourced from fetched content.

---

### Skill: `share-github`

**File:** `skills/share-github/SKILL.md`  
**Activation:** automatic — triggers when the user asks to share a code file or snippet from a GitHub repository.

**Public repositories only.** Private repos return a 4xx from the raw URL — the skill stops with a clear error message.

**Accepted URL forms:**
- `https://github.com/{owner}/{repo}/blob/{branch}/{path}#L10-L25` (standard + optional line range)
- `https://raw.githubusercontent.com/{owner}/{repo}/{branch}/{path}` (raw URL, skip conversion)

**Workflow:** parse URL fragment (`#L10-L25`) from string before any network call → fetch raw content → extract line range (or first 80 lines) → write to temp file → `security-scrub` → draft copy → HTML-escape code → populate `snippet-card.html` → Playwright screenshot → deliver copy + PNG.

---

### Skill: `share-selection`

**File:** `skills/share-selection/SKILL.md`  
**Activation:** automatic — triggers when the user asks to share, post, or tweet selected, highlighted, open, or pasted code. Distinct from `share-code` (which scans git history): this skill shares the specific code the user points at and never falls back to git.

**Content sources (first match wins):** lines highlighted in the IDE → a selected/open file (read from disk, `FILENAME`/`LANGUAGE` from the path) → a pasted fenced code block. Non-code files (binary, lockfiles, minified bundles) are declined; a file over the ~80-line snippet cap prompts the user to choose a region.

**Objective-driven:** the post copy is shaped by a user **objective** — inferred from the prompt, asked only if absent — alongside platform and tone.

**Workflow:** capture selection + objective → `security-scrub` → draft objective-driven copy → auto-pick template (diff-like → `diff-card.html`, otherwise `snippet-card.html`) → HTML-escape + populate (language/colour from `references/language-map.md`) → Playwright screenshot → deliver copy + PNG. Reuses the shared `references/` pipeline.

---

### Skill: `share-project`

**File:** `skills/share-project/SKILL.md`  
**Activation:** manual-invoke only (`disable-model-invocation: true`) — reached via the `social-share` router or an explicit dispatch, not by passive intent matching.

Generates a card for a project **topic** — features, bugs, changes, or release — by pulling topic-relevant content from git history, `CHANGELOG.md`, `README.md`, and manifest files.

**Inputs:** `--topic` (features / bugs / changes / release), `--platform`, and an optional project `--path`; missing values are prompted for in interactive mode (the router always supplies topic and platform).

**Workflow:** locate templates → parse inputs → reuse-check `docs/media/social/` → extract project metadata → gather topic-relevant content → `security-scrub` → draft platform-aware copy → populate template, save, screenshot → deliver copy + PNG + saved path. Per-topic extraction patterns and tone live in `skills/share-project/references/topics.md`.

---

### Skill: `media-library`

**File:** `skills/media-library/SKILL.md`  
**Activation:** automatic — triggers when the user asks to browse the media library or find a prior post.

Every card-generating skill saves its populated HTML (including the post copy) to `docs/media/social/`. This skill lists saved cards by type and date so you can retrieve copy for reposting and see which skill regenerates each card.

- **Interactive mode** — lists posts and lets you pick one to view/reuse via `AskUserQuestion`.
- **Background mode** (`--background`) — skips prompts and snapshots the catalog to `.claude/digests/media-library-YYYY-MM-DD.md`, emitting the file-output completion line. Card-skill flags (`--platform`, `--tone`) are silently ignored.

---

### Skill: `share-scan`

**File:** `skills/share-scan/SKILL.md`  
**Activation:** automatic — triggers when the user asks to find commits worth sharing, create a code digest, or generate a post from the codebase.

**Two modes:**

| Arguments | Mode | Source |
|-----------|------|--------|
| *(default)* | History | `git log` on current branch |
| `--codebase <path>` | Codebase | `Read`/`Glob` on given path |

Scoring weights (commit type, codebase patterns, card-type decision tree, platform heuristics) are stored in `skills/share-scan/references/interesting-patterns.md` and re-read on every run — edit that file to tune what surfaces in your digests.

Security scrub is mandatory on every candidate. The review gate presents all candidates in a single multi-select prompt. Output goes to `.claude/digests/code-digest-YYYY-MM-DD.md`.

---

### Skill: `security-scrub`

**File:** `skills/security-scrub/SKILL.md`  
**Activation:** automatic — triggers when the user asks to check code for secrets or before sharing any code change.

Scans for 20+ pattern categories (API keys, JWTs, private keys, DB connection strings, internal IPs). Masks matched values (`sk-a***WXYZ`) before reporting. Emits a structured `SCRUB RESULT` block with a separate `ALLOWLIST verdict` — callers treat either `BLOCKED` as a hard stop.

Pattern table and file-path block list are in `skills/security-scrub/references/scrub-rules.md`.

---

### Command: `/social-media-tools:social-share-bg`

**File:** `commands/social-share-bg.md`  
Explicit, fire-and-forget entry point for the `social-share` router. Classifies the request, picks the right skill, and runs it in the background, returning immediately.

```
/social-media-tools:social-share-bg <what to share — plain language, URL, or code>
```

---

### Command: `/social-media-tools:digest`

**File:** `commands/digest.md`  
Interactive front-end for `share-scan`. Runs the scan, presents candidates for review, and writes the approved entries to `.claude/digests/`.

```
/social-media-tools:digest [--days=7] [--base=main] [--max=20] | --codebase <path>
```

---

### Command: `/social-media-tools:digest-bg`

**File:** `commands/digest-bg.md`  
Background variant. Dispatches `agent-digest` and returns immediately; the agent reports the output path on completion.

```
/social-media-tools:digest-bg [--days=7] [--base=main] [--max=20] | --codebase <path>
```

---

### Agent: `agent-digest`

**File:** `agents/agent-digest.md`  
Dispatched by `/social-media-tools:digest-bg`. Runs `share-scan --background` (auto-includes PASS candidates, skips interactive review), writes the digest, and sends one proactive completion message. Does not post or invoke any card skill.

---

### Agent: `agent-social-share`

**File:** `agents/agent-social-share.md`  
Dispatched by the `social-share` skill and the `/social-media-tools:social-share-bg` command. Receives a pre-classified target skill plus flags, invokes that skill in non-interactive (`--background`) mode, and relays a single completion line — a card path for card-generating skills, or a catalog file path for file-producing skills like `media-library`. Runs as a background subagent (`model: sonnet`) with no user interaction.

---

### Skill: `share-code`

**File:** `skills/share-code/SKILL.md`
**Activation:** automatic — triggers when the user asks to write a post, tweet, or share a code change.

**Inputs (collected automatically or via prompt):**

| Input | Values | Default |
|-------|--------|---------|
| Platform | `LinkedIn`, `Twitter/X`, `Bluesky`, `All sites` | — (required) |
| Content type | `diff-card`, `feature-card`, `quote-card` | auto-detected from git |
| Tone | `Professional`, `Casual`, `Punchy` | Professional (LinkedIn), Punchy (Twitter/X, Bluesky) |

When **All sites** is selected, the card embeds a separate, individually copyable snippet for each platform (LinkedIn, Twitter/X, Bluesky) — each with its own **Copy** button — instead of one combined box.

**Workflow (6 phases):**

1. **Clarify** — runs `git diff`, `git log`, and `CHANGELOG.md` to auto-detect content type; only asks for what it can't infer
2. **Draft copy** — writes platform-aware copy within character limits (LinkedIn 1,500 / Twitter 280 / Bluesky 300)
3. **Pick template** — selects `diff-card`, `feature-card`, or `quote-card` and locates the `templates/` directory
4. **Populate** — substitutes `{{VARIABLES}}` in the HTML template and writes to `~/.claude/tmp/code-share-card.html`
5. **Screenshot** — starts a local HTTP server, takes a Playwright screenshot to `~/.claude/tmp/code-share-card.png`, then kills the server
6. **Deliver** — presents copy in a fenced block with character count, attaches the PNG via `SendUserFile`

**Fallback:** if Playwright MCP is unavailable, the skill skips the screenshot and provides the HTML path for a manual browser screenshot.

## Scheduling

Claude Code has no native timer, but `/social-media-tools:digest-bg` works well with external schedulers:

```yaml
# GitHub Actions — weekly digest on Monday at 9am
on:
  schedule:
    - cron: '0 9 * * 1'
jobs:
  digest:
    steps:
      - run: claude --plugin-dir kit/plugins/social-media-tools -p "/social-media-tools:digest-bg --days=7"
```

Human review is always required before posting — no path in this plugin auto-posts.

## Requirements

- **Playwright MCP** — required for the screenshot pipeline. If unavailable, the skill falls back to providing the HTML path for a manual screenshot.
- **Python 3** — used by `find_free_port.py` and `http.server` for the local card server.
- **Git** — used in Phase 1 to auto-detect recent changes and commits.

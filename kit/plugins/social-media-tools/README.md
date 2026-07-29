# social-media-tools

> Plugin directory: `kit/plugins/social-media-tools`

Discover teachable code, blog posts, videos, GitHub snippets, selected/pasted code, and project updates — scrub for secrets, draft instructional platform-aware copy, and generate styled dark-mode social cards for LinkedIn, Twitter/X, Bluesky, and Substack.

Every post leads with a **concrete, applicable takeaway** about agentic development — a principle, technique, or pattern the reader can learn from and apply. The plugin's teaching-first voice turns your body of work into a running, shareable curriculum, not a highlight reel.

Two complementary workflows:

- **Discovery pipeline** — scan git history or a codebase path → scrub → review → write a digest.
- **Card generation pipeline** — draft instructional copy → render a dark-mode card image from one of seven templates.

No path in this plugin auto-posts — human review is always required before anything reaches a social network.

## Features

| Component | Type | Description |
|-----------|------|-------------|
| `social-share` | Skill | **Router** — classifies a natural-language request and runs the right skill |
| `share-session` | Skill | Generate a narrative session recap card with teachable takeaways, lessons learned, and platform copy |
| `export-session` | Skill | Export a session JSONL transcript to Markdown under `{plansDirectory}/sessions/` for reference and education |
| `share-code` | Skill | Draft copy + render dark-mode card for local git commits and diffs |
| `share-blog` | Skill | Fetch blog post metadata from a URL or local `.md`; generate card + copy |
| `share-video` | Skill | Fetch YouTube/Vimeo metadata via oEmbed; generate card + copy |
| `share-github` | Skill | Fetch a public GitHub file/snippet; security-scrub + generate card + copy |
| `share-selection` | Skill | Turn selected/highlighted/open/pasted code into an objective-driven card + copy |
| `share-react` | Skill | Share a React component as one card: static rendered preview (up to 3 states), implementation code, and a full typed props table |
| `share-project` | Skill | Generate a card for a project topic (features / bugs / changes / release) from git + CHANGELOG |
| `share-scan` | Skill | Discover teachable commits or codebase patterns; write a `.claude/digests/` file |
| `media-library` | Skill | Browse saved posts interactively and retrieve copy for reposting |
| `share-init` | Skill | Analyze the project and generate a `SOCIAL.md` config with default platform, tone (including Instructional / Educational), hashtags, focus areas, and audience |
| `security-scrub` | Skill | Scan any code or diff for secrets, credentials, and sensitive data (sub-step utility) |
| `write-guide` | Skill | Write a long-form internal developer guide (system, rule, how-to, concept, change recap, or saved memory) to `docs/`, assembled from a section library with five non-binding archetype starting points, verifying every URL and on-disk fact before it lands |
| `share-explanation` | Skill | Explain how a project file, component, or concept works — reads the source, synthesizes the underlying principles, and generates a card + copy |
| `/social-media-tools:digest` | Command | Interactive discovery scan with multi-select candidate review |

## Installation

### Via Marketplace (recommended)

```bash
/plugin install social-media-tools@agentics-kit
```

### Local Development

```bash
claude --plugin-dir ./kit/plugins/social-media-tools
```

## Usage

### Commands

| Invocation | Description |
|-----------|-------------|
| `/social-media-tools:digest [--days=7] [--base=main] [--max=20] \| --codebase <path>` | Interactive discovery scan — runs share-scan, presents candidates for review, and writes approved entries to `.claude/digests/` |

### Skills

| Skill | Activation | Trigger |
|-------|-----------|---------|
| `social-share` | Automatic | Share what you're working on, post code, a blog, video, or project update |
| `share-session` | Automatic | Share my session, session recap, what I worked on, what I did today, session summary |
| `export-session` | Automatic | Export, save, or archive a session as Markdown |
| `share-code` | Automatic | Post or share a code change, write a LinkedIn post about today's changes |
| `share-blog` | Automatic | Share a blog post or article on social media |
| `share-video` | Automatic | Share a video on social media |
| `share-github` | Automatic | Share a code snippet from a GitHub repository |
| `share-selection` | Automatic | Share, post, or tweet selected, highlighted, or pasted code |
| `share-react` | Automatic | Share a React component, share this component with its props, post my Button component |
| `share-project` | Manual invoke only — use `/social-media-tools:share-project` explicitly | Reached via `social-share` router with `--topic` flag or explicit dispatch; not activated by passive intent matching |
| `share-scan` | Automatic | Find commits worth sharing, create a digest, scan codebase for shareable code |
| `media-library` | Automatic | Browse the media library, find a prior post, view saved posts |
| `share-init` | Automatic | Set up social sharing preferences, create a SOCIAL.md, configure sharing defaults |
| `security-scrub` | Automatic | Check for secrets, review a diff for leaks, scrub this file for sensitive data |
| `write-guide` | Automatic | Write a guide on X, document this rule, deep-dive X, explain X as a guide, capture this session's lessons as a guide |
| `share-explanation` | Automatic | Explain how X works, how does this component work, break down this concept |
| `save-artifact` | Automatic | Save or share an artifact, save this claude.ai artifact URL, save this HTML page, stash the artifact I just built |

### Discover what's worth sharing

```bash
# Scan the last 7 days of git history (interactive review gate)
/social-media-tools:digest

# Scan further back or against a specific base branch
/social-media-tools:digest --days=14
/social-media-tools:digest --base=develop

# Scan a codebase path instead of git history
/social-media-tools:digest --codebase src/auth/
```

The digest is written to `.claude/digests/code-digest-YYYY-MM-DD.md`. Each entry includes a ready-to-paste share prompt.

### Share anything — router picks the right skill

The `social-share` router skill classifies your request and runs the right workflow.
Just describe what you want to share:

```
"share a lesson from what I just built"
"post today's changes with a takeaway"
"share this: https://youtu.be/abc123"
"we just launched v2.0, share the key technique"
"share what I learned this week"
```

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
> "share feature-card for LinkedIn: the new security-scrub skill"

### Set up project sharing defaults

The `share-init` skill analyzes your project and generates a `SOCIAL.md` file at the project root. This file configures default platform, tone, hashtags, focus areas, audience, and avoid patterns for all share skills.

```
"set up social sharing preferences"
"create a SOCIAL.md for this project"
```

Once created, share skills automatically read `SOCIAL.md` and use its defaults — no more re-answering platform and tone every time. Edit the file anytime to adjust.

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
| `session-card` | Session recap — lessons learned, takeaways, token usage | `templates/session-card.html` |
| `react-card` | React components — preview + implementation + props table | `templates/react-card.html` |

See [`references/variables.md`](references/variables.md) for the full variable reference for each card type.

Posts close with a contextual learn-more invitation — one varied line naming the
topic the reader gets more of, framed as continued learning rather than
audience-building, and never a bare "follow me". On Twitter/X and Bluesky the
takeaway wins and the line is dropped when the character budget is tight. The
rule and its per-platform placement live in
[`references/platforms.md`](references/platforms.md).

## Plugin Structure

```
social-media-tools/
├── .claude-plugin/
│   └── plugin.json
├── CHANGELOG.md
├── README.md
├── commands/
│   └── digest.md                          ← /social-media-tools:digest
├── references/                            ← shared pipeline logic (all card skills)
│   ├── copy-panels.md                     ← {{COPY_PANELS}} markup + escaping rules
│   ├── language-map.md                    ← file extension → language + badge colour
│   ├── platforms.md                       ← canonical char limits + universal copy rules
│   ├── rendering-pipeline.md              ← find_free_port → HTTP server → Playwright → kill
│   ├── reuse-check.md                     ← scan docs/media/social/ + offer reuse
│   ├── saving-and-delivery.md             ← persistent save block + deliver phase
│   ├── social-config.md                   ← SOCIAL.md format + loading convention
│   └── variables.md                       ← per-template variable maps (all 7 cards)
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
│   ├── share-explanation/
│   │   └── SKILL.md                       ← explain how a file, component, or concept works
│   ├── share-github/
│   │   └── SKILL.md
│   ├── share-init/
│   │   └── SKILL.md                       ← generate SOCIAL.md project sharing config
│   ├── share-project/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── topics.md                  ← per-topic extraction patterns + tone guide
│   ├── share-react/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── props-extraction.md        ← typed props table extraction rules
│   ├── share-scan/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── interesting-patterns.md    ← scoring table (user-tunable)
│   ├── share-selection/
│   │   └── SKILL.md                       ← share selected/highlighted/open/pasted code
│   ├── export-session/
│   │   ├── SKILL.md                       ← export session JSONL to Markdown in {plansDirectory}/sessions
│   │   └── scripts/
│   │       └── export_session.py          ← JSONL → Markdown converter
│   ├── share-session/
│   │   └── SKILL.md                       ← narrative session recap card (lessons learned, takeaways, tokens)
│   ├── share-video/
│   │   ├── SKILL.md
│   │   └── references/
│   │       └── platforms.md               ← oEmbed endpoints + video copy format rules
│   └── social-share/
│       └── SKILL.md                       ← router: classifies + invokes target skill
└── templates/
    ├── blog-card.html
    ├── diff-card.html
    ├── feature-card.html
    ├── gallery.html
    ├── quote-card.html
    ├── react-card.html
    ├── session-card.html
    ├── snippet-card.html
    └── video-card.html
```

## Components

### Skill: `social-share` (router)

**File:** `skills/social-share/SKILL.md`  
**Activation:** automatic — triggers when the user asks to share what they're working on, or to post code, a blog, a video, or a project update without naming a specific skill.

The entry point for everything. It classifies a natural-language request (first-match-wins rules), resolves a default platform, captures any inline code to a temp file, and invokes the matching skill directly. Waits for the skill to complete and reports the saved card path.

---

### Skill: `share-session`

**File:** `skills/share-session/SKILL.md`  
**Activation:** automatic — triggers when the user asks to share their session, create a session recap, summarize what they worked on, or share a session summary.

Generates a teaching-first session recap card — the primary content is a short summary of the techniques and lessons learned during the session. Token usage, duration, and commit count appear as secondary stats in the card footer.

**Workflow:** read session context → draft takeaway-first summary + lessons learned → populate `session-card.html` → Playwright screenshot → deliver copy + PNG.

---

### Skill: `share-blog`

**File:** `skills/share-blog/SKILL.md`  
**Activation:** automatic — triggers when the user asks to share or post a blog post or article.

**Inputs:**

| Input | Values | Notes |
|-------|--------|-------|
| Source | URL or local `.md` path | Relative paths resolved via `realpath` |
| Platform | LinkedIn, Twitter/X, Bluesky, Substack, All sites | Required — "All sites" embeds a copy snippet per site |
| Tone | Professional, Casual, Punchy | Default varies by platform |
| Hook angle | Free text | Optional framing direction |

**Workflow:** fetch OG metadata (URL) or read front matter (local file) → draft copy per platform rules in `references/platforms.md` → populate `blog-card.html` → Playwright screenshot → deliver copy + PNG.

`READ_TIME` is only computed for local `.md` files (word count / 200 wpm). For URL sources it is omitted — HTML body parsing is too fragile. All fetched text is HTML-escaped before card substitution.

---

### Skill: `share-video`

**File:** `skills/share-video/SKILL.md`  
**Activation:** automatic — triggers when the user asks to share a video, post about a talk, or share video content.

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

Lists posts and lets you pick one to view/reuse via `AskUserQuestion`.

---

### Skill: `share-init`

**File:** `skills/share-init/SKILL.md`  
**Activation:** automatic — triggers when the user asks to set up social sharing preferences, create a SOCIAL.md, or configure sharing defaults.

Analyzes the project — manifest files, tech stack, git history, and sensitive paths — then interviews for platform, tone, and audience preferences. Writes a `SOCIAL.md` file at the git root that all share skills read for defaults (platform, tone, hashtags, focus areas, audience, avoid patterns).

**Workflow:** locate plugin assets → check for existing `SOCIAL.md` (offer update/replace/cancel) → analyze project identity, stack, commit themes, and sensitive paths → interview (platform, tone, audience) → write `SOCIAL.md` to project root.

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

### Command: `/social-media-tools:digest`

**File:** `commands/digest.md`  
Interactive front-end for `share-scan`. Runs the scan, presents candidates for review, and writes the approved entries to `.claude/digests/`.

```
/social-media-tools:digest [--days=7] [--base=main] [--max=20] | --codebase <path>
```

---

### Skill: `share-code`

**File:** `skills/share-code/SKILL.md`  
**Activation:** automatic — triggers when the user asks to write a post, tweet, or share a code change.

**Inputs (collected automatically or via prompt):**

| Input | Values | Default |
|-------|--------|---------|
| Platform | `LinkedIn`, `Twitter/X`, `Bluesky`, `Substack`, `All sites` | — (required) |
| Content type | `diff-card`, `feature-card`, `quote-card` | auto-detected from git |
| Tone | `Professional`, `Casual`, `Punchy` | Professional (LinkedIn), Punchy (Twitter/X, Bluesky) |

When **All sites** is selected, the card embeds a separate, individually copyable snippet for each platform (LinkedIn, Twitter/X, Bluesky, Substack) — each with its own **Copy** button — instead of one combined box.

**Workflow (6 phases):**

1. **Clarify** — runs `git diff`, `git log`, and `CHANGELOG.md` to auto-detect content type; only asks for what it can't infer
2. **Draft copy** — writes platform-aware copy within character limits (LinkedIn 1,500 / Twitter 280 / Bluesky 300 / Substack 500)
3. **Pick template** — selects `diff-card`, `feature-card`, or `quote-card` and locates the `templates/` directory
4. **Populate** — substitutes `{{VARIABLES}}` in the HTML template and writes to `~/.claude/tmp/code-share-card.html`
5. **Screenshot** — starts a local HTTP server, takes a Playwright screenshot to `~/.claude/tmp/code-share-card.png`, then kills the server
6. **Deliver** — presents copy in a fenced block with character count, attaches the PNG via `SendUserFile`

**Fallback:** if Playwright MCP is unavailable, the skill skips the screenshot and provides the HTML path for a manual browser screenshot.

## Requirements

- **Playwright MCP** — required for the screenshot pipeline. If unavailable, the skill falls back to providing the HTML path for a manual screenshot.
- **Python 3** — used by `find_free_port.py` and `http.server` for the local card server.
- **Git** — used in Phase 1 to auto-detect recent changes and commits.

> **Note — Playwright MCP is an external dependency, not bundled.** This plugin's
> `plugin.json` does not declare the Playwright MCP server, so card rendering relies
> on Playwright being provisioned separately (e.g. installed as its own plugin or
> configured in your `mcpServers`). The rendering pipeline already documents a manual
> fallback (`references/rendering-pipeline.md`): when Playwright is unavailable, the
> populated HTML is left in `~/.claude/tmp/` to screenshot by hand. Provisioning or
> formally declaring Playwright as a plugin dependency is a separate, planned
> enhancement.

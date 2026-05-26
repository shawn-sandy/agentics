# code-share

> Plugin directory: `kit/plugins/social-media-tools`

Draft platform-aware social media copy and generate styled dark-mode card images for LinkedIn, Twitter/X, and Bluesky. Three card types (diff, feature, quote) with a Playwright screenshot pipeline.

## Features

| Skill | Trigger phrases | Output |
|-------|----------------|--------|
| `code-share` | "write a LinkedIn post", "tweet about this", "share this change", "post about this release" | Platform-aware copy + dark-mode PNG card |

## Installation

```bash
# From the agentics marketplace
/plugin marketplace add shawn-sandy/agentics
/plugin install code-share@agentics-kit

# Local dev
claude --plugin-dir ./kit/plugins/social-media-tools
```

## Usage

The skill activates automatically when you ask to share or post about code changes. It auto-detects context from your git history before asking questions.

**Share a recent diff:**
> "Write a LinkedIn post about today's changes"

**Announce a release:**
> "Tweet about the v0.1.1 release"

**Share a thought leadership quote:**
> "Post a Bluesky quote about this approach"

## Card Types

| Type | Best for | Template |
|------|----------|----------|
| `diff-card` | Code changes, rule updates, config diffs | `templates/diff-card.html` |
| `feature-card` | Releases, new features, version announcements | `templates/feature-card.html` |
| `quote-card` | Insights, opinions, pull quotes | `templates/quote-card.html` |

See [`skills/code-share/references/variables.md`](skills/code-share/references/variables.md) for the full variable reference for each card type.

## Plugin Structure

```
social-media-tools/
├── .claude-plugin/
│   └── plugin.json
├── CHANGELOG.md
├── README.md
├── scripts/
│   └── find_free_port.py
├── skills/
│   └── code-share/
│       ├── SKILL.md
│       └── references/
│           └── variables.md
└── templates/
    ├── diff-card.html
    ├── feature-card.html
    └── quote-card.html
```

## Components

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

## Requirements

- **Playwright MCP** — required for the screenshot pipeline. If unavailable, the skill falls back to providing the HTML path for a manual screenshot.
- **Python 3** — used by `find_free_port.py` and `http.server` for the local card server.
- **Git** — used in Phase 1 to auto-detect recent changes and commits.

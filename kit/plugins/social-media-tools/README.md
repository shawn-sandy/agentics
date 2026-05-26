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

## Requirements

- **Playwright MCP** — required for the screenshot pipeline. If unavailable, the skill falls back to providing the HTML path for a manual screenshot.
- **Python 3** — used by `find_free_port.py` and `http.server` for the local card server.
- **Git** — used in Phase 1 to auto-detect recent changes and commits.

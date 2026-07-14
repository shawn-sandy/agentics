# artifact-tools

Publish the three things teams review most — code diffs, working sessions, and
implementation plans — as live claude.ai artifact pages, without leaving Claude
Code.

## Overview

Claude Code artifacts are self-contained pages published to a private claude.ai
URL that update in place on republish. This plugin adds the publish endpoints for
the work already happening in a session, plus the one generator nothing else in
the kit provides: an annotated diff walkthrough.

`diff-artifact` and `session-artifact` scrub for secrets before publishing — a
publish is external sharing, and both carry raw code. (`plan-artifact` publishes
prose you already wrote, so it has no scrub gate.) All three record the returned
URL so later sessions republish to the *same* link, and all three fall back to
local HTML when publishing is unavailable.

## Features

| Skill | What it publishes |
|-------|-------------------|
| `diff-artifact` | An annotated diff walkthrough — branch, commit range, or PR — with a sticky file sidebar, per-hunk reviewer notes, and severity labels |
| `session-artifact` | A reviewer-first session recap: Summary, Decisions (with rationale), Learnings, Files touched |
| `plan-artifact` | A `plan-agent` HTML plan, republished to a stable URL as steps check off |

Skills activate automatically when your request matches — "publish this diff for
review", "share a recap of this session", "publish this plan".

## Installation

```bash
# Load locally for testing
claude --plugin-dir ./kit/plugins/artifact-tools

# Or install from the marketplace
/plugin marketplace add shawn-sandy/agentics
/plugin install artifact-tools@agentics-kit
```

Publishing requires a claude.ai login on Pro or higher. Sharing an artifact
beyond its author is a Team/Enterprise feature — on Pro and Max the local-HTML
fallback is how pages actually reach teammates, so it is a first-class path, not
an error case.

## Usage

```text
Publish this diff for review              → diff-artifact (branch vs default)
Publish the diff for PR #42               → diff-artifact (PR mode)
Publish a walkthrough of abc123..def456   → diff-artifact (range mode)
Share a recap of this session             → session-artifact
Publish docs/plans/add-dark-mode.html     → plan-artifact
```

## Plugin Structure

```
artifact-tools/
├── .claude-plugin/
│   └── plugin.json
├── README.md
├── CHANGELOG.md
└── skills/
    ├── diff-artifact/
    │   └── SKILL.md
    ├── session-artifact/
    │   ├── SKILL.md
    │   └── scripts/
    │       └── export_session.py
    └── plan-artifact/
        └── SKILL.md
```

## Components

### diff-artifact

Resolves the diff from a branch (default), a commit range, or a PR number via
`gh` — degrading to branch mode with a clear message when `gh` or the GitHub
remote is missing. Runs the scrub gate, annotates each meaningful hunk with the
*reasoning* behind the change, and builds one self-contained page.

Annotation is capped at 20 files and 8 hunks per file to stay under the 16 MiB
artifact cap; files beyond the budget render as one-line summary rows, and the
final report says how many were summarized rather than annotated.

### session-artifact

Finds the session transcript (explicit path, session ID, or newest for the
project) and extracts turns with a bundled `export_session.py` — the script keeps
the raw JSONL out of context. The recap is saved under
`{plansDirectory}/sessions/` so its `artifact-url:` frontmatter is committed and
survives for republish, then published as Markdown (the lowest-token artifact
source).

The extractor is a deliberate copy of the `social-media-tools` original so this
plugin installs standalone. Keep the two in sync when either changes.

### plan-artifact

A thin publish wrapper — plan HTML needs no generation. Reads `artifact-url:`
from the plan's sibling `.md` spec and passes it to the `Artifact` tool's `url`
parameter so republishes hit the same page; on a first publish it writes the URL
back into the spec.

Never hand-edit the plan HTML — it is generated, and the next rebuild overwrites
the edit. Edit the `.md` spec.

## Security

`diff-artifact` and `session-artifact` run `social-media-tools:security-scrub`
before every publish. A `BLOCKED` verdict is a hard stop with no override. If the
scrub skill is unavailable, the skills say so and ask before continuing — they
never skip the gate silently.

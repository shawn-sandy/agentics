# artifact-tools

Publish the four things teams review most — code diffs, working sessions,
implementation plans, and saved prompts — as live claude.ai artifact pages,
without leaving Claude Code.

## Overview

Claude Code artifacts are self-contained pages published to a private claude.ai
URL that update in place on republish. This plugin adds the publish endpoints for
the work already happening in a session, plus the one generator nothing else in
the kit provides: an annotated diff walkthrough.

`diff-artifact`, `session-artifact`, and `prompt-artifact` scrub for secrets
before publishing — a publish is external sharing, and each carries raw code or
raw prompt text. (`plan-artifact` publishes prose you already wrote, so it has no
scrub gate.) All four record the returned URL so later sessions republish to the
*same* link, and all four fall back to local HTML when publishing is unavailable.

## Features

| Skill | What it publishes |
|-------|-------------------|
| `diff-artifact` | An annotated diff walkthrough — branch, commit range, or PR — with a sticky file sidebar, per-hunk reviewer notes, and severity labels |
| `session-artifact` | A reviewer-first session recap: Summary, Decisions (with rationale), Learnings, Files touched |
| `plan-artifact` | A `plan-agent` HTML plan, republished to a stable URL as steps check off |
| `prompt-artifact` | A prompt saved by `plan-agent:write-prompt` — one prompt, or the whole library with `--library` — behind a verbatim copy button |

Skills activate automatically when your request matches — "publish this diff for
review", "share a recap of this session", "publish this plan", "share this
prompt".

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
Share docs/prompts/task-refactor.md       → prompt-artifact (single)
Publish my prompt library --library       → prompt-artifact (library mode)
```

## Plugin Structure

```
artifact-tools/
├── .claude-plugin/
│   └── plugin.json
├── README.md
├── CHANGELOG.md
├── references/
│   └── titles.md          # shared artifact-title rules, read by every skill
└── skills/
    ├── diff-artifact/
    │   └── SKILL.md
    ├── session-artifact/
    │   ├── SKILL.md
    │   └── scripts/
    │       └── export_session.py
    ├── plan-artifact/
    │   └── SKILL.md
    └── prompt-artifact/
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

### prompt-artifact

Publishes prompts saved by `plan-agent:write-prompt`, resolving the prompts
directory exactly the way that skill does (`promptsDirectory` from settings, then
`{git-root}/docs/prompts`, then cwd-relative) — a divergence here would publish
from the wrong place.

Default mode publishes one prompt and records `artifact-url:` in its frontmatter.
`--library` publishes one filterable gallery of every saved prompt and tracks its
URL in a `.artifact-url` sidecar in the prompts directory, since a gallery has no
source `.md` to hold frontmatter. **Commit the sidecar** — ignoring it gives every
clone its own gallery URL, which is exactly the link-rot the stable-URL design
exists to prevent.

The copy button is the point of the page. It copies from `pre.textContent`, which
returns the HTML-escaped prompt with its entities already decoded — a verified
byte-for-byte round-trip back to the source text. Two things silently break it:
a newline directly after `<pre>` (the parser eats it, costing the first line
break) and indenting the `<pre>` to match surrounding markup (which indents every
copied line).

## Security

`diff-artifact`, `session-artifact`, and `prompt-artifact` run
`social-media-tools:security-scrub` before every publish. A `BLOCKED` verdict is a
hard stop with no override. If the scrub skill is unavailable, the skills say so
and ask before continuing — they never skip the gate silently.

In `prompt-artifact`'s library mode a finding in **any** prompt stops the whole
publish rather than dropping that one card. A gallery that silently omits work
would read as complete, and the leak would stay on disk unfixed.

`diff-artifact` scrubs **twice**, and the second scan is the one that counts:
the first covers the raw diff, but annotating a hunk can quote surrounding file
context the diff never contained. So the finished page is rescanned immediately
before publishing, which is what actually covers everything that ships.

Neither gate catches local filesystem paths, since those aren't secrets. That's
why the bundled `export_session.py` records only the transcript basename — an
absolute path would leak the local username and repo layout into a shared page.

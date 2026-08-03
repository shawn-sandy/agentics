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
| `prompt-artifact` | A prompt saved by `plan-agent:prompt` — one prompt, or the whole library with `--library` — behind a verbatim copy button |

Skills activate automatically when your request matches — "publish this diff for
review", "share a recap of this session", "publish this plan", "share this
prompt".

| Command | What it does |
|---------|--------------|
| `/artifact-tools:product-doc [session-id\|path\|#PR]` | Runs `session-artifact` reframed for the product team and stakeholders — features, bug fixes, decisions with rationale, logic and behavior changes, and implementation-plan details. Sources from the session transcript, or from a pull request when given `#453` or a PR URL |
| `/artifact-tools:team-recap [session-id\|path\|#PR]` | Runs `session-artifact` as a detailed, visual recap for the whole team — an at-a-glance stat strip, change cards, mermaid diagrams of what moved, a before/after table, decisions with rejected options, open items, and a glossary. Sources from the session transcript, or from a pull request when given `#455` or a PR URL. Readable by engineers and non-engineers in one pass |
| `/artifact-tools:eng-recap [session-id\|path\|#PR]` | Runs `session-artifact` for engineers only — architecture and code paths, decisions, tradeoffs and rejected options, learnings, tests and what is knowingly untested, review follow-ups and tech debt. Assumes the vocabulary and leads with the technical fact, the inverse of `team-recap`. In PR mode it reads the diff hunks, capped at 20 files |

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
/artifact-tools:product-doc               → recap for product + stakeholders
/artifact-tools:product-doc #453          → same recap, sourced from a PR
/artifact-tools:team-recap                → visual recap for the whole team
/artifact-tools:eng-recap                 → engineering recap for the next maintainer
/artifact-tools:eng-recap #455            → same recap, sourced from a PR (diff included)
```

## Plugin Structure

```
artifact-tools/
├── .claude-plugin/
│   └── plugin.json
├── README.md
├── CHANGELOG.md
├── bin/
│   └── artifact-export-session  # on the Bash tool's PATH; call by bare name
├── commands/
│   ├── product-doc.md     # product-team framing over session-artifact
│   ├── team-recap.md      # whole-team visual framing over session-artifact
│   └── eng-recap.md       # engineering framing over session-artifact
├── references/
│   ├── titles.md          # shared artifact-title rules, read by every skill
│   └── recap-core.md      # the recap workflow, read by all three commands
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

### product-doc (command)

`/artifact-tools:product-doc` is a thin framing layer over `session-artifact` for
when the reader is a PM, designer, support lead, or exec rather than a code
reviewer. It asks for prose any non-engineer can follow, and replaces the recap's Learnings section with a release-note shape:
Features, Bug fixes, Decisions, Logic and behavior changes, Implementation plan
details, Known gaps and follow-ups. Empty sections are dropped rather than
printed as bare headings. Everything downstream — the scrub gate, the HTML
render, publishing, the marker check — is the skill's, unchanged.

Two sources feed the same document. With no argument (or a session ID or
`.jsonl` path) it reads the session transcript. With `#453`, a PR URL, or
`--pr 453` it reads the pull request instead — `gh pr view`, the changed-file
list, the commit bodies, and the review discussion — preferring commit bodies over
the diff, since those carry the *why* a stakeholder needs. Without `gh` or a
GitHub remote, PR mode says so and falls back to session mode rather than
failing.

The rendered HTML is filed where every other saved artifact lives: the
`.claude/artifacts/` inbox, published into the committed `docs/artifacts/`
gallery via `social-media-tools:save-artifact`. Without that skill the command
copies the page into the inbox itself under a collision-safe name (hence `Bash`
in its `allowed-tools`) and reports it as saved but unpublished.

Both modes keep a record under `{plansDirectory}/sessions/` to hold the
published URL: session mode shares `session-artifact`'s record, PR mode gets its
own `pr-<number>.md`. Neither writes `artifact-url:` — that key belongs to the
reviewer recap, and reusing it would republish the product recap over that page.
`product-doc` reads and writes `product-artifact-url:` instead. Re-running
against the same PR therefore updates the same page as the PR evolves, so a link
sent on day one still shows the merged state on day five.

### team-recap (command)

`/artifact-tools:team-recap` is the third framing over `session-artifact`, for
when the reader is the whole team at once — the engineer picking this up next and
the teammate who only needs to know what moved. Where `product-doc` writes
stakeholder prose and `session-artifact` writes a reviewer's checklist, this one
writes a page you can skim: an at-a-glance stat strip, one card per change,
mermaid diagrams for anything whose shape changed, a before/after table of
changed rules and defaults, decisions with the options that lost, learnings,
open items, files touched, and a glossary of every internal term used.

Diagrams are `<pre class="mermaid">` blocks, which artifacts render natively —
the artifact CSP blocks external scripts and assets outright, so there is no
chart library to reach for. Each diagram must earn its place: draw one only
where structure or flow actually changed, and caption what to look at.

Sources match `product-doc`'s. With no argument (or a session ID or `.jsonl`
path) it reads the session transcript; with `#455`, a PR URL, or `--pr 455` it
reads the pull request instead — `gh pr view`, the changed-file list, the commit
bodies, and the review discussion. Without `gh` or a GitHub remote it says so and
falls back to session mode. Learnings is usually empty in PR mode: a diff records
what shipped, never what was tried and abandoned.

Filing works exactly as it does for `product-doc` — the `.claude/artifacts/`
inbox and the `docs/artifacts/` gallery via `social-media-tools:save-artifact`,
with a collision-safe local copy when that skill is absent. Its republish key is
`team-artifact-url:`, distinct from both `artifact-url:` and
`product-artifact-url:`, because all three commands share one record — per
session in session mode, per PR number in PR mode. Re-running against the same PR
therefore updates the same page as the PR evolves.

### eng-recap (command)

`/artifact-tools:eng-recap` is the fourth framing over `session-artifact` — the
third recap *command*, after `product-doc` and `team-recap` — and the only one
written for a single audience: the engineer who has to touch this
code next, opening these files with no memory of the work.

It exists because the other two both pay a translate-for-non-engineers tax, and
that tax is what crowds out the detail a maintainer needs. `team-recap` states
the rule outright — lead with the plain-language statement, spell out every
internal name. This command inverts it deliberately: lead with the technical
fact, assume the vocabulary, carry no glossary, and use code wherever code is
the shortest correct statement. The reclaimed space is the whole point.

Eight sections: an at-a-glance stat strip, architecture and code paths (what a
maintainer has to read first), decisions with rationale, tradeoffs and rejected
options, learnings, tests and verification including what is *knowingly*
untested, review follow-ups and tech debt, and files touched. Tradeoffs and
Learnings stay distinct on purpose — a tradeoff is a decision that was weighed,
a learning is a dead end that was walked, and collapsing them loses the dead
ends.

Sources match its siblings': no argument reads the session transcript, `#455` or
a PR URL reads the pull request, and the same `gh` + GitHub-remote preflight
falls back to session mode when either is missing. One departure: this is the
only recap command that reads the **diff hunks**, because an engineering reader
is the one audience for whom a changed signature or a new invariant is the
point. That read is capped at 20 files — `diff-artifact`'s budget, so the plugin
carries one number — falls back to `--name-only` past the cap, and must report
how many files were summarized rather than read. Commit bodies still lead for
the *why*; hunks only supply the *what*. Learnings is usually empty in PR mode,
since a diff records what shipped and never what was abandoned.

Diagrams, filing, and the `docs/artifacts/` gallery work exactly as they do for
`team-recap`, including the SVG-inlining step that keeps the mermaid runtime out
of the committed copy. Its republish key is `eng-artifact-url:` — the fourth
distinct key on the shared per-session record, and the reason
`tests/plugins/test-artifact-tools.sh` enforces key uniqueness across all four
writers.

### plan-artifact

A thin publish wrapper — plan HTML needs no generation. Reads `artifact-url:`
from the plan's sibling `.md` spec and passes it to the `Artifact` tool's `url`
parameter so republishes hit the same page; on a first publish it writes the URL
back into the spec.

Never hand-edit the plan HTML — it is generated, and the next rebuild overwrites
the edit. Edit the `.md` spec.

### prompt-artifact

Publishes prompts saved by `plan-agent:prompt`, resolving the prompts
directory exactly the way that skill does (`promptsDirectory` from settings, then
`{git-root}/docs/prompts`, then cwd-relative) — a divergence here would publish
from the wrong place.

Default mode publishes one prompt and records `artifact-url:` in its frontmatter.
`--library` publishes one filterable gallery of every saved prompt and tracks its
URL in a `.artifact-url` sidecar in the prompts directory, since a gallery has no
source `.md` to hold frontmatter.

The gallery's filter chips cover all five prompt types — `task`, `system`,
`creative`, `analytical`, and `proposal` — and a type with no saved prompts still
gets its chip, since an absent chip reads as a broken filter while an empty one
reads as an empty category. The frontmatter reader takes the keys it needs and
ignores the rest: `proposal` prompts written by `plan-agent:build-proposal` also
carry `status:`, `modified:`, and `generated-sha:`, and an unrecognized key must
never abort the read or blank a card. `modified:` renders beside `created:` when
present. Proposal bodies run roughly 3x longer than anything else in the
directory, so the `<pre>` scrolls horizontally inside its own card rather than
widening the page. **Commit the sidecar** — ignoring it gives every
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

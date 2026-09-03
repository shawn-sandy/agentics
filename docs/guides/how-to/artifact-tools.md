# How do I... artifact-tools

Publish diffs, session recaps, plans, prompts, and explainers as live claude.ai artifact pages without leaving Claude Code.

Install: `/plugin marketplace add shawn-sandy/agentics`, then `/plugin install artifact-tools@agentics-kit`

## diff-artifact

Publishes an annotated walkthrough of a diff — branch, commit range, or PR — with per-hunk reviewer notes and a sticky file sidebar.

- **Command** — `/artifact-tools:diff-artifact [branch | abc123..def456 | #42]`
- **Say it instead** — "Publish this diff for review"
- **What happens** — Resolves the diff (current branch by default), runs a blocking `security-scrub` gate, annotates each meaningful hunk, saves a copy under `.claude/artifacts/`, then publishes and fetches the URL to confirm the page rendered.
- **Watch out** — A `BLOCKED` scrub verdict is a hard stop with no override; PR mode degrades to a branch diff when `gh` or the GitHub remote is missing.

## plan-artifact

Publishes a `plan-agent` HTML plan and republishes it to the same URL so viewers watch steps check off live.

- **Command** — `/artifact-tools:plan-artifact [docs/plans/<plan>.html]`
- **Say it instead** — "Publish docs/plans/add-dark-mode.html"
- **What happens** — Reads `artifact-url:` from the plan's sibling `.md` spec: absent, it publishes fresh and writes the returned URL back; present, it republishes to that same page. It then fetches the URL to confirm the title rendered.
- **Watch out** — Never hand-edit the plan HTML — it is generated, and the next rebuild overwrites the edit silently. Edit the `.md` spec and rebuild.

## prompt-artifact

Publishes a prompt saved by `plan-agent:prompt` — one prompt, or the whole filterable library.

- **Command** — `/artifact-tools:prompt-artifact [prompt-path] [--library]`
- **Say it instead** — "Share docs/prompts/task-refactor.md" or "Publish my prompt library --library"
- **What happens** — Resolves the prompts directory, scrubs every prompt body as a blocking gate, builds a page whose copy button returns the prompt text verbatim, then publishes and records the URL so both modes republish to one link.
- **Watch out** — In library mode a finding in any single prompt stops the whole publish; an empty prompts directory stops before publishing rather than shipping an empty gallery.

## session-artifact

Publishes a reviewer-first recap of a Claude Code session — Summary, Decisions with rationale, Learnings, Files touched.

- **Command** — `/artifact-tools:session-artifact [session-id | transcript.jsonl]`
- **Say it instead** — "Share a recap of this session"
- **What happens** — Extracts the newest transcript for the project with the bundled `artifact-export-session` script, writes the recap to `{plansDirectory}/sessions/`, runs the blocking scrub, renders it to HTML, publishes it, and records `artifact-url:` in the `.md` for later republishes.
- **Watch out** — From a worktree the transcript directory is keyed to the worktree path, not the main repo, so the newest-transcript lookup can come up empty; point the skill at the main repo's entry under `~/.claude/projects/`.

## teach-artifact

Publishes a page teaching how the system behind a session or a pull request actually works, for someone who was not there.

- **Command** — `/artifact-tools:teach-artifact [session-id | path | #PR]`
- **Say it instead** — "Publish a page teaching how this works" or "Publish an explainer for PR #455"
- **What happens** — Reads the session transcript or the PR (including diff hunks, capped at 20 files), writes the five-part teaching spine in present tense, runs the blocking scrub, then publishes and records `teach-artifact-url:`.
- **Watch out** — PR mode needs both `gh` auth and a GitHub remote; without them it names the missing piece and continues in session mode.

## Related commands

- `/artifact-tools:eng-recap [session-id|path|#PR]` — Publishes an engineering-only recap: architecture and code paths, decisions, tradeoffs and rejected options, learnings, tests, and review follow-ups. Reads the diff hunks, capped at 20 files.
- `/artifact-tools:product-doc [session-id|path|#PR]` — Publishes a recap for the product team and stakeholders: features, bug fixes, decisions, logic changes, and implementation-plan details.
- `/artifact-tools:team-recap [session-id|path|#PR]` — Publishes a visual whole-team recap: stat strip, change cards, mermaid diagrams, a before/after table, open items, and a glossary.

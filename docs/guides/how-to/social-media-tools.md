# How do I... social-media-tools

Turn code, commits, blog posts, videos, React components, artifacts, and whole sessions into platform-aware social copy and dark-mode card images — with a mandatory secret scrub in front of every share.

Install: `/plugin marketplace add shawn-sandy/agentics`, then `/plugin install social-media-tools@agentics-kit`

## export-session

Converts a Claude Code session transcript into a readable Markdown file.

- **Command** — `/social-media-tools:export-session [<transcript.jsonl> | <session-id>]`
- **Say it instead** — "Export this session to markdown"
- **What happens** — Defaults to the newest transcript for the current project, then runs the bundled `social-export-session` script, which writes `<date>-<slug>.md` with YAML frontmatter into `<plansDirectory>/sessions/` (default `docs/plans/sessions/`).
- **Watch out** — From a worktree the project transcript directory may not exist; the skill falls back to matching the main repo path under `~/.claude/projects/`.

## media-library

Builds and opens a filterable HTML gallery of every social card you have saved.

- **Command** — `/social-media-tools:media-library`
- **Say it instead** — "Browse my media library"
- **What happens** — Scans `docs/media/social/` newest-first by the date in each filename, fills the bundled `gallery.html`, writes `docs/media/social/index.html`, verifies the card count, and opens it in the browser.
- **Watch out** — Stops with "No saved posts found" when `docs/media/social/` has no cards, and refuses to open the gallery if the written index's card count does not match the files it parsed.

## save-artifact

Saves an HTML Artifact page into the local artifacts inbox and publishes it to the artifacts gallery.

- **Command** — `/social-media-tools:save-artifact [<claude.ai artifact URL> | <path.html>]`
- **Say it instead** — "Save the artifact I just built"
- **What happens** — Resolves the source (URL via `WebFetch`, an explicit path, or the in-chat artifact), runs `security-scrub` as a blocking gate, copies to `.claude/artifacts/<name>-YYYY-MM-DD.html`, then runs plan-agent's `build-artifacts-index.sh` to publish under `docs/artifacts/`.
- **Watch out** — Publishing needs plan-agent installed; without it the page stays in the gitignored `.claude/artifacts/` inbox and nothing is committable.

## security-scrub

Scans content for secrets, credentials, and sensitive data, then emits a pass/block verdict.

- **Command** — `/social-media-tools:security-scrub <file path or pasted content>`
- **Say it instead** — "Check this diff for secrets before I share it"
- **What happens** — Loads the pattern table from `references/scrub-rules.md`, greps HIGH/MEDIUM/LOW patterns plus a blocked file-path list, masks every match, and prints a `SCRUB RESULT` block followed by a machine-readable `GATE RESULT` line.
- **Watch out** — Every share skill calls this as a blocking gate: a HIGH finding or a blocked path (`.env`, `credentials`, `id_rsa`, `.pem`) is a hard stop, not a warning.

## share-blog

Drafts platform-aware copy and a dark-mode card for a blog post URL or local markdown file.

- **Command** — `/social-media-tools:share-blog <url | path.md>`
- **Say it instead** — "Share this blog post on LinkedIn"
- **What happens** — Pulls OG tags from the URL or YAML front matter from the file, asks platform and tone, fills `blog-card.html`, saves `blog-<slug>-<date>.html` to `docs/media/social/`, and screenshots it through a local HTTP server plus Playwright.
- **Watch out** — Read time is computed only for local markdown; URL sources leave the read-time badge empty by design.

## share-code

Turns your recent git changes into platform-aware copy and a card image.

- **Command** — `/social-media-tools:share-code [--platform=<name>]`
- **Say it instead** — "Write a LinkedIn post about today's changes"
- **What happens** — Auto-detects context from `git diff HEAD~1`, the last five commit subjects, and CHANGELOG, picks diff/feature/quote card, scrubs that content, then saves the HTML and PNG to `docs/media/social/`.
- **Watch out** — It only looks one commit back plus the last five subjects; for older work run the `digest` command instead.

## share-explanation

Answers "how does X work" from the actual source, then packages the answer as a social card.

- **Command** — `/social-media-tools:share-explanation <target> [--platform=<name>] [--tone=<name>]`
- **Say it instead** — "How does the security-scrub skill work?"
- **What happens** — A five-tier lookup resolves the target inside the git root, reads the source files, synthesizes the explanation, scrubs it, and saves an `explain-` card to `docs/media/social/` alongside the written explanation.
- **Watch out** — The git root is a hard search boundary, and the skill stops when no tier matches the named target.

## share-github

Fetches a file from a public GitHub repo and renders a syntax-highlighted snippet card.

- **Command** — `/social-media-tools:share-github <github-blob-or-raw-url[#L10-L25]>`
- **Say it instead** — "Share this GitHub snippet on Twitter"
- **What happens** — Parses owner/repo/branch/path and the `#L` fragment before fetching, WebFetches the raw file, scrubs the snippet, fills `snippet-card.html`, and saves HTML plus PNG to `docs/media/social/`.
- **Watch out** — Public repos only — a 4xx on the raw URL stops the skill; with no `#L` fragment it uses lines 1–80.

## share-init

Analyzes the project and writes a `SOCIAL.md` config of default sharing preferences.

- **Command** — `/social-media-tools:share-init`
- **Say it instead** — "Set up my social sharing defaults"
- **What happens** — Detects name, stack, recurring topics, hashtags, and sensitive paths from manifests, git log, CHANGELOG, and `.gitignore`, asks platform/tone/audience in one batched prompt, and writes `SOCIAL.md` at the git toplevel.
- **Watch out** — If a `SOCIAL.md` already exists it asks to update, replace, or cancel — it never overwrites silently, and it never chains into a share skill afterwards.

## share-project

Generates copy and a card for a project update — features, bugs, changes, or a release.

- **Command** — `/social-media-tools:share-project --topic <features|bugs|changes|release> [--platform <name>] [--path <dir>] [--days=N]`
- **Say it instead** — Not available; this skill is command-only (`disable-model-invocation: true`).
- **What happens** — Reads project metadata from manifests plus topic-matched commits, CHANGELOG, and README excerpts, scrubs them, populates `feature-card.html` or `diff-card.html`, and saves HTML plus PNG to `docs/media/social/`.
- **Watch out** — `--days` defaults to 30, but the `changes` topic always uses a fixed 7-day window; a `release` topic with no release data stops instead of guessing.

## share-react

Turns one React component into a card with a static preview, its source, and a props table.

- **Command** — `/social-media-tools:share-react [<path.tsx|.jsx>] [--source=<path>] [--platform=<name>] [--tone=<name>]`
- **Say it instead** — "Share my Button component"
- **What happens** — Takes the component from a path, IDE selection, or paste, scrubs it, extracts props from types or inference, hand-builds a static preview of up to three states, and saves `react-<name>-<date>.html` plus PNG to `docs/media/social/`.
- **Watch out** — Non-component `.tsx`/`.jsx` (tests, stories, route modules, hooks-only files) is handed off to `share-selection`, and sources over 80 lines prompt for a region rather than truncating.

## share-scan

Finds commits or files worth sharing and writes a reviewed digest of ready-to-run share prompts.

- **Command** — `/social-media-tools:digest [--days=7] [--base=main] [--max=20] | --codebase <path>` (the `digest` command wraps this skill)
- **Say it instead** — "Find commits worth sharing this week"
- **What happens** — Scores candidates from git history or a codebase path, scrubs each one, cross-references `docs/media/social/` to tag already-shared items, then writes `.claude/digests/code-digest-YYYY-MM-DD.md` from your multi-select review.
- **Watch out** — It never invokes `share-code` for you — you copy a `share-code prompt` out of the digest and run it yourself.

## share-selection

Turns highlighted, open, or pasted code into an objective-driven social card.

- **Command** — `/social-media-tools:share-selection [--code-file=<path>] [--objective=<text>] [--platform=<name>]`
- **Say it instead** — "Tweet this snippet"
- **What happens** — Takes code from an IDE highlight, the open file, or a fenced paste, scrubs it, classifies it as a diff or snippet card, and saves HTML plus PNG to `docs/media/social/`.
- **Watch out** — It never falls back to git history, and it refuses non-code sources outright — binaries, images, lockfiles, and minified bundles.

## share-session

Recaps what the current session accomplished as a narrative card with a stats strip.

- **Command** — `/social-media-tools:share-session [--session=<path>] [--platform=<name>] [--tone=<name>]`
- **Say it instead** — "Share a recap of what I worked on today"
- **What happens** — Runs `session_usage.py` for token and duration data, derives git stats bounded to the session window, scrubs the full narrative, and saves `session-<date>.html` plus PNG to `docs/media/social/`.
- **Watch out** — It stops when the transcript cannot be located — set `$CLAUDE_CODE_SESSION_ID` or pass `--session=<path>`; cards report tokens only, never dollar amounts.

## share-video

Drafts copy and a card for a YouTube or Vimeo video URL.

- **Command** — `/social-media-tools:share-video <youtube-or-vimeo-url>`
- **Say it instead** — "Share this YouTube video on Bluesky"
- **What happens** — Detects the host from the URL, pulls title, channel, and thumbnail from the oEmbed API, fills `video-card.html`, and saves HTML plus PNG to `docs/media/social/`.
- **Watch out** — On a 4xx from oEmbed it asks you for the title and channel and renders the card without a thumbnail.

## social-share

Router that classifies a share request and dispatches to the right share-* skill.

- **Command** — `/social-media-tools:social-share <what you want to share> [--platform=<name>]`
- **Say it instead** — "Share what I'm working on"
- **What happens** — Evaluates twelve first-match-wins rules over your text and session context (GitHub URL, video URL, blog URL or `.md`, React component, selection, release/progress wording, media library, explain, session, git diff, fallback), then invokes the matching skill with `--platform` resolved from your words, then `SOCIAL.md`, then `all`.
- **Watch out** — With nothing matched, no git repository, and no source supplied it stops with "nothing to share" rather than picking a skill.

## write-guide

Writes a long-form developer guide on a project topic, with every fact verified against its source.

- **Command** — `/social-media-tools:write-guide <topic>`
- **Say it instead** — "Write a guide on how our review-bot rules work"
- **What happens** — Gathers facts from the conversation, named files, memory, git history, and code search, verifies every external URL with `WebFetch` and every path or symbol with `Read`/`Grep`, then saves a `verb-target` kebab-case Markdown file to `<plansDirectory>/guides/`.
- **Watch out** — It declines README updates, API reference docs, marketing copy, and blog posts (those go to `share-blog`) instead of writing them.

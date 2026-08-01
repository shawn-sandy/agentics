# Gathering, building, and publishing a recap

Loaded by the `eng-recap`, `team-recap`, and `product-doc` commands. Each of
those states its audience, its section list, its favicon, its inbox stem, and
its republish key; everything below is the same for all three.

Run the `artifact-tools:session-artifact` skill with the calling command's
framing overrides. Everything not overridden stays the skill's: transcript
location, extraction, the blocking `security-scrub` gate, publishing, and the
post-publish marker check.

## Source

Pick the first mode `$ARGUMENTS` matches. Both modes produce the same document
from the same downstream pipeline; only the raw material differs.

| Mode | Trigger | Raw material |
|------|---------|--------------|
| **Session** (default) | no argument, a session ID, or a `.jsonl` path | the session transcript, per the skill |
| **PR** | `#455`, a PR URL, or `--pr <n>` | the pull request, gathered below |

In **PR mode**, skip the skill's transcript-location and extraction steps and
hand it the PR brief as the source instead. In PR mode, read "session" in the
calling command's section list as "pull request".

Preflight first — run this alone and read its output. PR mode needs both `gh`
and a GitHub remote, and an unguarded `gh` call emits shell errors instead of
degrading:

```bash
if gh auth status >/dev/null 2>&1 &&
   git remote get-url origin 2>/dev/null | grep -qi 'github\.com'; then
  echo "PR_MODE_OK"
else
  echo "PR_MODE_UNAVAILABLE"
fi
```

On `PR_MODE_UNAVAILABLE`, say which piece is missing and continue in session
mode — do not run the block below. On `PR_MODE_OK`, gather the PR into one brief
in the scratchpad:

```bash
PR=<number-or-url>

# Resolve the PR's own repository, not the local checkout's. Argument-less
# `gh repo view` means "view current repo", so a PR URL pointing at another
# repository would pair a foreign PR number with the local owner/name and read
# review threads off the wrong repo — returning nothing, or an unrelated local
# PR that happens to share the number. A PR's canonical `url` is always on its
# base repo, which is exactly where its review threads live.
PR_URL=$(gh pr view "$PR" --json url --jq .url)
NUM=${PR_URL##*/}
OWNER=$(echo "$PR_URL" | cut -d/ -f4)
REPO=$(echo "$PR_URL" | cut -d/ -f5)

gh pr view "$PR" --json number,title,body,url,author,state,mergedAt,labels
gh pr diff "$PR" --name-only                              # no --stat flag exists

# Commit bodies come from the API, not from a local fetch. `headRefName` is only
# a branch name: for a fork PR, a deleted head branch, or a PR URL pointing at
# another repository, that ref does not exist on this origin, so a
# `git fetch origin "$HEAD"` fails and takes the commit bodies down with it —
# and those carry the *why*, which nothing else in this brief supplies.
gh pr view "$PR" --json commits \
  --jq '.commits[] | .messageHeadline + "\n" + .messageBody + "\n---"'

# Top-level discussion only.
gh pr view "$PR" --json comments,reviews \
  --jq '{comments: [.comments[].body], reviews: [.reviews[] | {state, body}]}'

# Inline review threads, with resolution status. The payload above carries
# neither: `comments` is top-level issue comments, and `reviews` keeps only each
# review's own state and body — not the thread comments and not whether anyone
# resolved them. Unresolved findings live here or nowhere.
gh api graphql -f query='
query($owner:String!,$repo:String!,$num:Int!){
  repository(owner:$owner,name:$repo){ pullRequest(number:$num){
    reviewThreads(first:100){ totalCount pageInfo{ hasNextPage }
      nodes{ isResolved path
        comments(first:20){ pageInfo{ hasNextPage }
          nodes{ author{login} body } } } } } } }' \
  -F owner="$OWNER" -F repo="$REPO" -F num="$NUM" \
  --jq '.data.repository.pullRequest.reviewThreads
        | {truncated: .pageInfo.hasNextPage, of: .totalCount,
           threads: [.nodes[] | {resolved: .isResolved, path,
             comments: [.comments.nodes[].body],
             more_comments: .comments.pageInfo.hasNextPage}]}'
```

If the PR reference itself is bad, the first `gh pr view` fails and `$PR_URL` —
and with it `$NUM`, `$OWNER`, and `$REPO` — comes back empty. Report that and
stop rather than gathering a partial brief.

Prefer the commit bodies over the diff — they say *why*, which is the thing a
diff never carries. Take the change list from `gh pr diff --name-only`, the
decisions from the PR body and review discussion.

Use each thread's `isResolved` to sort it: **`false` → the calling command's
open-items section** (Review follow-ups, Open items, or Known gaps, whichever
that command names), **`true` → Decisions** (what the finding was and what
changed because of it). Guessing resolution from comment text is what the
GraphQL query exists to avoid.

Both connections are capped — 100 threads, 20 comments each. **If `truncated`
or any `more_comments` is true, say so in the recap.** An unresolved finding
past the cap would otherwise vanish from the open-items section, and a silently
partial list reads as a complete one.

Bot review comments arrive as HTML-commented boilerplate; take the finding and
drop the scaffolding. A resolved finding belongs in Decisions (what was changed
and why), not in the open-items section.

A PR carries no record of what was tried and abandoned, so **Learnings** is
usually empty in PR mode — say so under the heading rather than mining the diff
for something that looks like a lesson.

Falling back to session mode is deliberate, not a failure path — a recap of the
work in hand still beats no recap.

## Diff budget — opt-in

Only a command that says it reads the **diff hunks** runs this section. Commit
bodies carry the *why*, and most audiences need nothing below that. Where the
hunks do carry signal — a changed signature, a new invariant, an error path that
did not exist last week — that signal is not free: an unbounded `gh pr diff` on
a large PR consumes the context the recap itself needs, which is the same
failure `session-artifact` avoids by refusing to read the transcript JSONL
directly. So it is capped:

- Read full hunks for at most **20 files**, matching `diff-artifact`'s budget so
  the plugin carries one number rather than two.
- Beyond that budget, take the remaining paths from `gh pr diff --name-only`
  and describe them from the commit bodies alone.
- **Report how many files were summarized rather than read**, in the recap
  itself. A partial read that reads as complete is worse than no read at all.

`gh pr diff` takes **no pathspec** — its synopsis is
`gh pr diff [<number> | <url> | <branch>] [flags]`, and passing a filename as a
second positional argument fails outright with `accepts at most 1 arg(s)`. So
take the diff once and split it locally:

```bash
gh pr diff "$PR" > "$SCRATCH/pr.diff"
TOTAL=$(gh pr diff "$PR" --name-only | wc -l | tr -d ' ')

# Each file's section starts at `diff --git`; keeping the first 20 sections
# keeps their hunks intact.
awk '/^diff --git /{n++} n<=20' "$SCRATCH/pr.diff"

if [ "$TOTAL" -gt 20 ]; then
  echo "NOTE: $((TOTAL - 20)) file(s) past the 20-file budget — name-only:"
  gh pr diff "$PR" --name-only | tail -n +21
fi
```

Read the capped output, not `$SCRATCH/pr.diff` — writing the whole diff to disk
is free, reading it into context is the thing being budgeted. Commit bodies
still lead for the *why*; hunks only supply the *what*.

## Page build

The page must be readable at a glance, not a wall of prose. Read the
`artifact-design` skill before writing the HTML (the `Artifact` tool requires it
anyway), then build with these constraints:

- **Diagrams are mermaid**, in `<pre class="mermaid">` blocks — artifacts render
  them natively. A strict CSP blocks every external script, stylesheet, font, and
  image, so there is no chart library and no remote asset. Everything else is
  hand-written HTML and inline CSS.
- **Every diagram is earned.** Draw one only where structure, flow, or state
  actually changed, and give each a one-line caption saying what to look at. A
  diagram of something that did not change is noise.
- **Theme-aware.** Style light and dark; let mermaid take its default theme
  rather than pinning colors that vanish in one of them.
- **Wide content scrolls in its own container** (`overflow-x: auto`) — the page
  body never scrolls sideways.
- No emoji as UI. Status and impact are text labels.
- Omit any section the source produced nothing for rather than printing an empty
  heading, unless the calling command marks that section as always kept.

## Destination

Publish to the same gallery as every other saved artifact, with the calling
command's favicon, kept stable across republishes.

**File the rendered SVG, not the mermaid runtime.** There are three ways to get
a gallery copy and only one is worth having:

| Source | Diagrams | Cost |
|---|---|---|
| Your rendered HTML as-is | show as plain text | none, but the page's best parts are missing |
| The published page fetched back | render | ships a multi-megabyte minified library that repo static analysis reads as first-party source — on this repo, eight high-severity CodeQL alerts, none in the recap |
| **Rendered HTML with the SVG inlined** | **render** | **none — mermaid's output is plain SVG with no script** |

Take the third. Mermaid renders to SVG in the browser; capture that output once
and paste it in, and the diagrams ship as markup instead of as a library.

1. Strip the `<!-- frame-runtime -->…<!-- /frame-runtime -->` block (claude.ai
   iframe plumbing that resolves nowhere else) from the fetched published page
   and serve it over `http://127.0.0.1` — `file://` is blocked, and a page
   served from one port cannot POST to another.
2. Open it in the browser pane and read back
   `[...document.querySelectorAll('.mermaid-diagram svg')].map(s => s.outerHTML)`.
   Have the page `fetch()` that JSON to a POST endpoint on the same server
   rather than returning it through the transcript — it is tens of kilobytes,
   and it has to survive byte-exact.
3. Replace each `<pre class="mermaid">` block in your rendered HTML with its
   SVG, and wrap the page into a standalone document (`<!doctype html>`,
   `<html>`, `<head>` with the `<title>` and a viewport meta, `<body>`) — the
   render targets an artifact frame that supplies those.
4. Confirm the result has no `<script>` and no `on*=` attributes before filing.
   Mermaid bakes its palette in at render time, so the diagram cannot follow the
   viewer's theme: give its container a fixed light card that works on both
   grounds rather than letting a light diagram vanish in dark mode.

Hand that file to `social-media-tools:save-artifact`, which owns the dated
filename, the collision suffix, and the gallery index rebuild:

```
Skill(skill: "social-media-tools:save-artifact", args: "<path to the standalone HTML>")
```

If that skill is not installed, copy it into the inbox yourself, picking a free
name the way `save-artifact` does — a second recap on the same day must not
overwrite the first. `stem` is the calling command's:

```bash
mkdir -p .claude/artifacts
stem="<the calling command's stem>"
target=".claude/artifacts/${stem}-$(date +%F).html"
n=2
while [ -e "$target" ]; do
  target=".claude/artifacts/${stem}-$(date +%F)-${n}.html"
  n=$((n + 1))
done
cp "<standalone HTML>" "$target" && echo "Saved → $target (not published to the gallery)"
```

Either way, report the gallery path alongside the artifact URL.

Skip the SVG capture only if the browser pane is unavailable — then file the
rendered HTML with its diagram blocks as text and say so, rather than falling
back to the published page. That fallback is the one with the library in it, and
it also trips the scrub: minified grammar tables are full of `Token:` and
`secret:` lookalikes. If the user asks for it anyway, say plainly that those
matches are library-internal and none are in the recap, then let them decide —
the gallery is committed and served publicly, so the gate stays theirs.

## Republish record

The recap needs a record that survives the session, because that record is what
holds the published URL — without it, a second run mints a new link and the one
you shared goes stale. Both modes keep theirs under `{plansDirectory}/sessions/`:
session mode in the skill's `<verb>-<target>-session.md`, PR mode in
`pr-<number>.md`.

In session mode, find that record the way the skill does — by its frontmatter,
not by rebuilding its name:

```bash
grep -rl 'session-id: "<session-id>"' <plansDirectory>/sessions/ 2>/dev/null
```

Read the calling command's own key from that record before publishing, pass it
to `Artifact`'s `url` parameter, and write it back after.

**Write only the key the calling command declares, and leave every other key
untouched.** All four writers share one record — per session in session mode,
per PR number in PR mode — so reusing another writer's key republishes this page
over the recap that key belongs to. The keys sit side by side in one record and
none of them touches another.

PR mode's record is keyed on the PR number, so re-running against the same PR
updates the same page as the PR evolves — which is the point: the link you send
on day one still shows the merged state on day five.

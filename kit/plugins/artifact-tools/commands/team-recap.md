---
description: Publish a detailed, visual recap of this session or a pull request for the whole team — diagrams, before/after, decisions, and open items, readable by engineers and non-engineers alike
allowed-tools:
  - Skill
  - Bash
---

# Team Recap

Write an artifact explaining what changed in this session — or in a pull request
— for **everyone on the team**: the engineer who will touch this code next and
the teammate who only needs to know what moved.

Run the `artifact-tools:session-artifact` skill with the framing overrides below.
Everything not listed stays the skill's: transcript location, extraction, the
blocking `security-scrub` gate, publishing, and the post-publish marker check.

## Source

Pick the first mode `$ARGUMENTS` matches. Both modes produce the same document
from the same downstream pipeline; only the raw material differs.

| Mode | Trigger | Raw material |
|------|---------|--------------|
| **Session** (default) | no argument, a session ID, or a `.jsonl` path | the session transcript, per the skill |
| **PR** | `#455`, a PR URL, or `--pr <n>` | the pull request, gathered below |

In **PR mode**, skip the skill's transcript-location and extraction steps and
hand it the PR brief as the source instead.

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
BASE=$(gh pr view "$PR" --json baseRefName --jq .baseRefName)
HEAD=$(gh pr view "$PR" --json headRefName --jq .headRefName)
git fetch -q origin "$BASE" "$HEAD" 2>/dev/null

gh pr view "$PR" --json number,title,body,url,author,state,mergedAt,labels
gh pr diff "$PR" --name-only                              # no --stat flag exists
git log --format='%s%n%b%n---' "origin/$BASE".."origin/$HEAD"
gh pr view "$PR" --json comments,reviews \
  --jq '{comments: [.comments[].body], reviews: [.reviews[] | {state, body}]}'
```

If the PR number itself is bad, `gh pr view` fails on the first line and `$BASE`
is empty — report that and stop rather than gathering a partial brief.

Read the sections below out of that material: **What changed** from the commit
subjects and the changed-file list, **Decisions** from the PR body and review
discussion, **Open items** from unresolved review threads and anything the PR
body defers, **Files touched** from `gh pr diff --name-only`. Prefer the commit
bodies over the diff — they say *why*, which is the thing a diff never carries.
Draw a diagram only where the diff shows structure or flow actually moved.

Bot review comments arrive as HTML-commented boilerplate; take the finding and
drop the scaffolding. A resolved finding belongs in Decisions (what was changed
and why), not in Open items.

A PR carries no record of what was tried and abandoned, so **Learnings** is
usually empty in PR mode — say so under the heading rather than mining the diff
for something that looks like a lesson.

Falling back to session mode is deliberate, not a failure path — a recap of the
work in hand still beats no recap.

## Audience

Mixed, in one document — not two versions of it. Write so a non-engineer can
follow the *what* and *why* top-to-bottom without opening the code, while an
engineer still finds the file paths, function names, and rationale they need.

- Lead every section with the plain-language statement, then the technical
  detail. Never the reverse.
- Spell out every internal name, acronym, or repo-specific term the first time
  it appears, and collect them in the Glossary.
- Code appears only when it is the clearest way to say the thing — a config
  value, a signature that changed, a command someone will run.

## Visual requirements

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

## Sections

In this order. Omit any section the source produced nothing for rather than
printing an empty heading. In PR mode, read "session" below as "pull request".

1. **At a glance** — a compact stat strip: changes shipped, files touched,
   decisions made, open items. Then two or three sentences on where the session
   landed. A reader who stops here should still know what happened.
2. **What changed** — one card per change. Each carries: a plain-language title,
   who it affects (users, teammates, nobody yet), what is different now, and how
   to reach it (command, flag, path, URL).
3. **How it works now** — the mermaid section. Flow, sequence, or state diagrams
   for anything whose shape changed. Caption each one.
4. **Before and after** — a two-column table for changed behavior, defaults,
   limits, and edge-case handling. One row per rule, in the reader's words.
5. **Decisions** — each with its rationale *and* the options weighed and
   rejected. A decision without its why is unreviewable; a rejected option is
   what stops the next person re-litigating it.
6. **Learnings** — what was tried and abandoned, and the gotchas found. Keep the
   heading and say so explicitly if the session produced none.
7. **Open items** — deferred, stubbed, or unverified work, each with enough
   context to pick up cold.
8. **Files touched** — grouped by area, one line each on why it changed.
9. **Glossary** — every term from the page that a new teammate would have to ask
   about, in one sentence each.

## Destination

Same gallery as every other saved artifact. Publish with the favicon `🧭`, kept
stable across republishes.

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
overwrite the first:

```bash
mkdir -p .claude/artifacts
stem="team-recap"           # PR mode: "pr-<number>-recap"
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

## Republish key

The recap needs a record that survives the session, because that record is what
holds the published URL — without it, a second run mints a new link and the one
you shared goes stale. Both modes keep theirs under `{plansDirectory}/sessions/`,
under the same key:

| Mode | Record | Key |
|------|--------|-----|
| Session | the skill's `<verb>-<target>-session.md` | `team-artifact-url:` |
| PR | `pr-<number>.md` | `team-artifact-url:` |

In session mode, find that record the way the skill does — by its frontmatter,
not by rebuilding its name:

```bash
grep -rl 'session-id: "<session-id>"' <plansDirectory>/sessions/ 2>/dev/null
```

Read the key before publishing, pass it to `Artifact`'s `url` parameter, and
write it back after.

**Never write `artifact-url:` or `product-artifact-url:`.** All three commands
share one record — per session in session mode, per PR number in PR mode — so
reusing another command's key republishes this page over the recap that key
belongs to. `product-doc` in PR mode writes `product-artifact-url:` into the same
`pr-<number>.md`; the two keys sit side by side and neither touches the other.

PR mode's record is keyed on the PR number, so re-running against the same PR
updates the same page as the PR evolves — which is the point: the link you send
the team on day one still shows the merged state on day five.

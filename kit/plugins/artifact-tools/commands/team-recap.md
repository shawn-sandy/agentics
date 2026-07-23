---
description: Publish a detailed, visual recap of this session for the whole team — diagrams, before/after, decisions, and open items, readable by engineers and non-engineers alike
allowed-tools:
  - Skill
  - Bash
---

# Team Recap

Write an artifact explaining what changed in this session, for **everyone on the
team** — the engineer who will touch this code next and the teammate who only
needs to know what moved.

Run the `artifact-tools:session-artifact` skill with the framing overrides below.
Everything not listed stays the skill's: transcript location, extraction, the
blocking `security-scrub` gate, publishing, and the post-publish marker check.

`$ARGUMENTS` is optional — a session ID or a `.jsonl` path, passed straight
through to the skill. With no argument it recaps the newest session.

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

In this order. Omit any section the session produced nothing for rather than
printing an empty heading.

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
target=".claude/artifacts/team-recap-$(date +%F).html"
n=2
while [ -e "$target" ]; do
  target=".claude/artifacts/team-recap-$(date +%F)-${n}.html"
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

The recap's URL lives in the skill's session record under
`{plansDirectory}/sessions/`, keyed `team-artifact-url:`. Read it before
publishing, pass it to `Artifact`'s `url` parameter, and write it back after.

**Never write `artifact-url:` or `product-artifact-url:`.** All three commands
share one record per session — the filename is deterministic — so reusing another
command's key republishes this page over the recap that key belongs to.

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

**File the HTML you rendered, not the published page fetched back.** Fetching
the published page yields a copy whose diagrams render offline, because
publishing injects the mermaid runtime — but that runtime is a multi-megabyte
minified library, and once committed, repo static analysis reads it as
first-party source. On this repo that meant eight high-severity CodeQL alerts,
none of them in the recap. Not worth it for one gallery copy.

So the filed page is your own rendered HTML, wrapped into a standalone document
(add `<!doctype html>`, `<html>`, `<head>` with the `<title>` and a viewport
meta, `<body>`) — the render targets an artifact frame that supplies those. Its
two mermaid blocks show as plain text; add one line to the footer pointing at
the artifact URL, where they render.

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

If the user asks for a gallery copy whose diagrams render offline, fetch the
published page instead and strip the `<!-- frame-runtime -->…<!-- /frame-runtime -->`
block first (claude.ai iframe plumbing that resolves nowhere else). Tell them
what it costs before doing it: a multi-megabyte committed file, scanner findings
against the bundled library, and a scrub that reports MEDIUM matches — minified
grammar tables are full of `Token:` and `secret:` lookalikes. Say plainly that
those matches are library-internal and none are in the recap, then let them
decide. The gallery is committed and served publicly, so the gate stays theirs.

## Republish key

The recap's URL lives in the skill's session record under
`{plansDirectory}/sessions/`, keyed `team-artifact-url:`. Read it before
publishing, pass it to `Artifact`'s `url` parameter, and write it back after.

**Never write `artifact-url:` or `product-artifact-url:`.** All three commands
share one record per session — the filename is deterministic — so reusing another
command's key republishes this page over the recap that key belongs to.

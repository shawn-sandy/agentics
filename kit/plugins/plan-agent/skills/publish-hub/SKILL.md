---
name: publish-hub
description: "Bundles a plan and its related HTML into one tabbed hub artifact. Publishes plan, prototype, and extras to one stable claude.ai URL. Use when asked to publish or share a plan hub."
allowed-tools: Read, Edit, Glob, Bash, AskUserQuestion, SendUserFile, ToolSearch, ExitPlanMode, Artifact, WebFetch
argument-hint: "<plan.md> [--extra <path>]... - omit the plan to pick from the plans directory"
---

# Publish Hub

**If in plan mode**, call `ExitPlanMode` first — this workflow mutates state.

Bundle a plan spec and its related HTML — the prototype from its `prototype:`
frontmatter key, plus any `--extra` companion pages — into one self-contained
tabbed hub page, and publish that page as a single claude.ai artifact at a
stable URL recorded as `hub-artifact-url:` in the spec frontmatter. The plan's
own `artifact-url:` (the plain plan page) is a different artifact and is never
touched here.

## Step 1 — Resolve the spec

Use the argument if one was given. Otherwise Glob the plans directory
(`docs/plans/*.md`) and ask via `AskUserQuestion`, newest first. Related
files come only from the spec's `prototype:` key, its `design:` key (an
external-link tab), and explicit `--extra <path>` arguments — never from
directory scanning.

## Step 2 — Bundle

```bash
plan-agent-hub <spec>.md -o "$SCRATCHPAD/<stem>-hub.html" [--extra <path>]...
```

The bundler renders the plan, embeds each document in its own tab panel, and
enforces a size cap (default 15 MB, under the 16 MB artifact limit).

On a size-cap failure it exits 1 naming the largest embedded document. When
that is a related file, rerun adding `--skip <named-file>` and tell the user
exactly which file was dropped and why. When the message says the rendered
plan itself is the largest, there is nothing to skip — report that the plan
is too large to bundle under the cap and stop. On any other exit 1
(unreadable spec or related file), report the named path and stop — do not
publish a partial hub the user did not ask for.

## Step 3 — Re-read `hub-artifact-url:` immediately before publishing

Read the spec's frontmatter fresh — never trust a value from earlier in the
session; another step may have rewritten the file, and publishing to a second
URL silently strands whatever link the user already shared. If it carries a
`hub-artifact-url:` **that parses as an `http(s)` URL with a host**, pass it
as `Artifact`'s `url` so the hub updates its existing page. Anything else —
a truncated value, a non-http scheme — is not a page to update: say so in one
line and publish fresh.

## Step 4 — Publish

```text
Artifact(file_path: "$SCRATCHPAD/<stem>-hub.html", favicon: "🗂️", description: "<one sentence>", url: <hub-artifact-url when Step 3 found one>)
```

Keep the title and favicon stable across republishes — they are how users
find the tab again.

## Step 5 — Write the URL back

On a first publish, `Edit` the spec's frontmatter to add
`hub-artifact-url: <returned URL>` (on a republish, confirm it is unchanged).
This line is what makes every future republish hit the same link — skip it
and the next session silently mints a second page. Verify the write: re-read
the frontmatter and confirm exactly one `hub-artifact-url:` line carrying the
returned URL.

## Step 6 — Verify the page rendered

Fetch the returned URL with `WebFetch` and confirm the fetched page contains
the plan's title. A returned URL is not evidence the page rendered — a blank
artifact returns a URL too. If the title is absent, report the failure **with
the URL**, and do not report the publish as successful.

## Step 7 — Report

Give the user the hub URL and list the tabs it carries (Plan, Prototype,
each extra, and Design when linked).

**Fallback — publishing unavailable.** If `Artifact` is unavailable or the
call fails, say so in one line and deliver the hub HTML via `SendUserFile`.
Never report a URL that was not returned by a successful publish, and leave
any existing `hub-artifact-url:` exactly as it is — a failed republish is a
transient outage, not a retirement.

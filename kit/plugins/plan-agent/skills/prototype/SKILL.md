---
name: prototype
model: opus
description: "Generates a runnable static-HTML prototype from a plan, idea, or design. Produces one self-contained, framework-free clickable file under docs/prototypes/. Use when asked to prototype a mockup."
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion, ToolSearch, ExitPlanMode, SendUserFile, mcp__claude-in-chrome__tabs_context_mcp, mcp__claude-in-chrome__tabs_create_mcp, mcp__claude-in-chrome__navigate, mcp__claude-in-chrome__computer
---

## Plan Agent — Prototype

Turn a completed HTML plan — or a raw one-line idea — into a runnable,
framework-free static-HTML prototype under `docs/prototypes/`, so a developer
can click through the real data shapes, the core flow, and the idea's actual
success signal before writing production code.

## Overview

Generates a runnable static-HTML prototype from a plan or idea. Produces one
self-contained, framework-free clickable file under `docs/prototypes/`. The
prototype is a single `.html` file (inline CSS + vanilla JS, an inline JSON
seed, a localStorage-backed store) — no CDN, no framework, no build step — so
it opens by double-click on `file://` and publishes to GitHub Pages alongside
the Plans gallery.

## Invocation & Arguments

Two activation paths, both driven by this one `SKILL.md`:

- **Command:** `/plan-agent:prototype <plan.html | one-line idea>` — `$ARGUMENTS`
  carries the input.
- **Model invocation (ambient):** auto-activates on intent like "prototype
  this plan" or "make a clickable prototype of …". `$ARGUMENTS` is empty;
  derive the input from the triggering message or recent context.

## Step 0 — Exit plan mode

**If in plan mode**, call `ExitPlanMode` first — this workflow mutates state.

Produce no plan document — execute the workflow directly.

## Step 1 — Resolve the input

Read `$ARGUMENTS` (or the conversation-derived text on the model path):

- If the **first token ends in `.html`**, treat it as a **plan path**. Reduce
  it to its basename for safety, then resolve it under the plans directory
  (configured `plansDirectory`, else `docs/plans/`). Read the file.
- If the **first token ends in an image extension** (`.png`, `.jpg`, `.jpeg`,
  `.gif`, `.webp`, `.svg`), treat it as an **image path** — a screenshot or
  mockup of the UI to prototype.
- If the **first token is a `figma.com` URL** (or the user names a Figma file /
  pastes a Figma link), treat it as a **design path**.
- Otherwise the whole argument string is a **raw idea**.

### The `{{SOURCE_PLAN}}` contract

`{{SOURCE_PLAN}}` is a **path, never a title or free text** — the drift hook
resolves the owning plan from it, and the gallery card renders it as its
"from `<plan>`" text:

- **Plan path:** the repo-relative path of the plan's **Markdown spec** —
  `docs/plans/<slug>.md` (swap the resolved `.html` for `.md`), even when the
  sibling `.md` does not exist.
- **Idea, image, and Figma paths:** empty string.

## Step 2 — Gather the model inputs

- **Idea path:** run a single batched `AskUserQuestion` with three questions —
  the core **entity** (the thing being tracked), the primary **action** (what
  the user does with it), and an observable **success signal** (what proves it
  works). Give example phrasing in each question, and fall back to a sensible
  default when an answer is blank (entity → "Item", action → "Add", success
  signal → "total count").
- **Plan path:** read the plan and extract its objective, steps, and domain
  nouns. No interview.
- **Image path:** `Read` the image directly (the Read tool renders PNG/JPG/etc.
  visually). Infer the model from what the UI shows — the dominant repeated
  record becomes the **entity**, its visible labels/columns become **fields**
  (infer each type from the value shown), the primary button/CTA becomes the
  **action**, and any visible count/total/badge becomes the **success signal**.
  No interview unless the image is too ambiguous to read a single entity from —
  then fall back to the three-question interview above.
- **Design path (Figma):** load the Figma MCP tools with `ToolSearch`
  (`get_screenshot` and `get_design_context` / `get_metadata`), passing the
  Figma URL. Read the returned screenshot + layer metadata and infer the model
  exactly as for an image path. If no Figma MCP server is connected, say so and
  ask the user to either connect it or paste a screenshot instead — do not
  guess a model from the URL alone.

## Step 3 — Derive a deterministic data model

From the inputs, derive — by the same rule every time, so two runs match:

- The primary domain noun → **the entity**.
- Its attributes → **columns / form fields**, each with an inferred type
  (`string` / `number` / `date` / `bool`). When unsure, default to `string`.
- Generate **2–3 seed rows** of realistic sample data.
- Map the **success signal** to a visible **summary** (e.g. a count or sum
  shown in a badge).

## Step 4 — Echo the model back

Before writing anything, echo the derived model to the user — **entity**,
**fields (with types)**, **action**, and **success signal** — so they can
catch a wrong interpretation before a file exists. Adjust if corrected.

## Step 5 — Fill the skeleton

Read `reference/PROTOTYPE-SKELETON.html` and substitute every `{{token}}` by
string replacement:

- **HTML-escape every text and attribute value** (`&`, `<`, `>`, `"`, `'`)
  before inserting it — the prototype is published to a live `*.github.io`
  origin. This covers `{{TITLE}}`, `{{SOURCE_PLAN}}`, `{{STORE_KEY}}`,
  `{{PRIMARY_ACTION}}`, `{{SUMMARY}}`, and the meta-tag values.
- **Build the structural fragments `{{COLUMNS}}` and `{{FORM_FIELDS}}` from
  already-escaped text, then inject the final HTML unescaped.** These tokens
  carry markup (`<th>` / `<input>` elements), so escaping the whole fragment
  would render raw tags — escape each interpolated label/key *inside* them, not
  the surrounding tags.
- **`{{SEED_JSON}}` is JSON-serialized with script-breakout escaping only**
  (e.g. encode `</script>` as `<\/script>`) — never HTML-escaped: `load()`
  reads the JSON block as text and HTML entities are not decoded, so `&quot;`
  would break `JSON.parse`.
- **`{{PROTO_MODEL}}` is the Step 3 model, serialized the same way** — the
  script-breakout rule above applies to it exactly as to `{{SEED_JSON}}`, never
  HTML escaping, or `JSON.parse` breaks identically. Emit **compact single-line
  JSON** with the keys `entity` (string), `fields` (array of `{name, type}`),
  `action` (string), and `successSignal` (string). The `fields` order and
  `name` values must match the `data-field` keys in `{{COLUMNS}}` exactly —
  that pairing is what the drift check compares.
- Placeholders: `{{TITLE}}`, `{{SOURCE_PLAN}}`, `{{STORE_KEY}}`,
  `{{SEED_JSON}}`, `{{PROTO_MODEL}}`, `{{COLUMNS}}`, `{{FORM_FIELDS}}`,
  `{{PRIMARY_ACTION}}`, `{{SUMMARY}}`, plus the `proto-source` /
  `proto-created` meta tags.
- Derive `{{STORE_KEY}}` from the file slug so each prototype isolates its own
  localStorage.

## Step 6 — Link the plan back (plan path only)

Derive the prototype slug first (see Step 7), then — **before** the prototype
HTML is written — write the back-link into the source plan's Markdown spec.
**Plan path only:** skip this entire step for idea, image, and Figma inputs,
which have no owning plan.

- Resolve the spec by swapping the resolved plan `.html` for `.md`
  (`docs/plans/<slug>.md`) — the same value `{{SOURCE_PLAN}}` carries.
- **If that `.md` does not exist:** skip the write-back, still generate the
  prototype, and print exactly one line telling the user to run
  `node <path-to-plan-agent-plugin>/scripts/extract-plan-spec.mjs PLAN.html > PLAN.md` (substituting the real
  plan filename — the shell reads `<` as a redirection, so it cannot be a placeholder here) first if they
  want the back-link. Most committed plans are legacy HTML with no spec
  sibling; materializing one as a side effect would silently rewrite a plan the
  user never asked us to touch.
- **If it exists:** `Edit` its YAML frontmatter to carry both keys, adding them
  when absent and replacing the existing values when present:

  ```yaml
  prototype: docs/prototypes/<slug>.html
  proto-model: {"entity":"Workout","fields":[{"name":"date","type":"date"}],"action":"Log","successSignal":"total count"}
  ```

- **Both values stay on one line each.** Never pretty-print the JSON, never let
  it contain a raw newline or a bare `---`. The frontmatter parser is a naive
  line scanner: an embedded newline or `---` truncates the block and corrupts
  `status` and `created` for every consumer that re-scans it.
- Re-render the plan HTML afterwards so the header link and the gallery chip
  appear: `node scripts/build-plan-html.mjs docs/plans/<slug>.md`. (The
  `PostToolUse` hook normally does this on the spec write; run it explicitly if
  the hook is disabled.)

## Step 7 — Write the prototype

Derive a `verb-target` kebab-case slug from the entity/action (e.g.
`track-gym-workouts`). `mkdir -p docs/prototypes` first, then write to
`docs/prototypes/<slug>.html`. Note: `validate-plan-filename.py` is
plans-directory-scoped and does **not** enforce prototype filenames, so this
skill owns the naming convention — never emit a placeholder/auto-generated
slug.

## Step 8 — Scrub before publishing

Before writing a prototype whose seed came from an external source — a **plan,
image, or Figma design** — run a quick secret/PII scrub on the extracted seed
values (it publishes to a public Pages origin). Mockups and screenshots often
show real names, emails, or tokens; drop or mask anything that looks like a
credential, token, key, email, or other PII.

## Step 9 — Index, preview, report

- The `PostToolUse` hook auto-rebuilds `docs/prototypes/index.html` on the
  write. If it did not run (e.g. hook disabled), run `plan-agent-prototypes-index`
  — it ships with this plugin in `bin/`, which Claude Code puts on the Bash
  tool's `PATH`, and defaults to the current directory. Invoke it by bare name,
  never by path.
- Open the prototype in the browser, screenshot it, and `SendUserFile` the
  prototype path.
- Report **what to validate**: the data shapes, the core flow, and whether the
  success signal reads true.

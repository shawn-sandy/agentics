# Content-first `share-session` recap card

## Context

The `share-session` skill (in the `social-media-tools` plugin) generates a dark-mode
"session recap" social card from the live Claude Code session transcript. Today that card is
**usage-first**: an 8-tile grid of token counts (total/input/output/cache), cache-hit rate,
duration, files changed, and commits. The only "content" it shows is `{{SUMMARY}}` — which is
just the **first user prompt** truncated to 160 chars, not a real account of what the session
did.

The user wants the skill to share a **summary of the content of the session** — what was
actually accomplished — and considers that summary **more important than the usage/token
metrics**. This plan reshapes the card so the narrative of what got done is the hero and the
usage numbers ride along as a compact secondary strip.

**Decisions confirmed with the user:**
- Card layout → **Content hero + metrics strip** (narrative + accomplishment bullets dominate; tokens/usage demoted to a small strip).
- Summary content → **Narrative + accomplishment bullets** (1–2 sentence narrative plus 3–5 concrete bullets).

## Key architectural point

`share-session` runs in two modes, and the content summary must be sourced differently:

- **Interactive** — Claude is running *inside* the live session and already has the full
  conversation in context, so it authors the narrative + accomplishments directly from memory.
- **Background** (`session-bg` / `social-share-bg` → `agent-social-share` subprocess) — runs
  in a *separate* process with no conversation context, so it must reconstruct the summary from
  the session JSONL. This requires `session_usage.py` to emit richer raw material.

## Files to modify

1. `kit/plugins/social-media-tools/scripts/session_usage.py`
2. `kit/plugins/social-media-tools/templates/session-card.html`
3. `kit/plugins/social-media-tools/skills/share-session/SKILL.md`
4. `kit/plugins/social-media-tools/references/variables.md`
5. `.claude-plugin/marketplace.json` (version bump)
6. `kit/plugins/social-media-tools/CHANGELOG.md`
7. This plan file (commit alongside, per repo convention)

---

## 1. Enrich `session_usage.py`

Add four **bounded** JSON output keys, all collected in the existing single streaming pass
(preserve the defensive/streaming style; no new imports):

| New key | Type | Source |
|---------|------|--------|
| `user_prompts` | `list[str]` | up to 12 user message texts (≤280 chars each), in order — skip tool-result-only / `<…>`-prefixed turns |
| `assistant_snippets` | `list[str]` | up to 12 assistant `text` block snippets (≤280 chars each) |
| `tool_breakdown` | `dict[str,int]` | per-tool-name call counts, e.g. `{"Edit": 14, "Bash": 9}` |
| `files_touched` | `list[str]` | unique `file_path`/`path`/`notebook_path` from `Edit`/`Write`/`MultiEdit`/`NotebookEdit` tool_use inputs (cap 40) |

Implementation: in `parse_session()`, extend the **existing** assistant `content` walk (the loop
that currently only counts `tool_use`) to also (a) increment `tool_breakdown[name]`, (b) capture
file paths for the file-editing tools, and (c) capture `text` block snippets. In the user branch,
after the existing `first_user_prompt` capture, append to `user_prompts` (with the skip rule).
Add the four keys to the returned dict. Caps keep output small even for multi-MB sessions.

## 2. Restructure `session-card.html` (content hero + metrics strip)

Replace the 8-tile metrics grid with a content-first layout. New variable set:

- **Hero:** `{{NARRATIVE}}` (1–2 sentence prose) + `{{ACCOMPLISHMENTS}}` (`<li>` items, no
  wrapping `<ul>` — template provides it, mirroring `feature-card.html`'s `{{BULLETS}}`).
- **Compact strip (demoted):** `{{TOTAL_TOKENS}} · {{DURATION}} · {{CACHE_HIT_RATE}} ·
  {{FILES_CHANGED}} · {{COMMITS}}` rendered small below the content.
- **Keep:** `{{TITLE}}`, `{{MODEL}}`, `{{COPY_PANELS}}`, and the existing `copyPost()` `<script>`
  + `.copy-panel` styling verbatim.
- **Remove:** `{{SUMMARY}}`, `{{INPUT_TOKENS}}`, `{{OUTPUT_TOKENS}}`, `{{CACHE_READ}}`.

Add `.content` / `.narrative` / `.accomplishments` / `.metrics-strip` CSS reusing the existing
`--bg`/`--surface`/`--border`/`--text`/`--muted`/`--accent` custom properties; remove the now-unused
`.metrics`/`.tile*` rules. Update the top HTML comment block to document the new variables and the
mandatory HTML-escape order.

## 3. Rewrite `share-session/SKILL.md`

- **`description`** — lead with the content capability and broaden triggers, e.g.:
  `"Session recap card summarizing what you accomplished — narrative plus highlights, with token usage as a secondary stat. Use when asked to share my session, session recap, what I worked on, what I did today, or session summary."`
- **Intro + Quick Reference** — reframe from "token usage … card" to "what the session
  accomplished … card; usage rides along as a stats strip. Tokens only — no dollar amounts."
- **Phase 1b** — add `USER_PROMPTS`, `ASSISTANT_SNIPPETS`, `TOOL_BREAKDOWN`, `FILES_TOUCHED` to
  the extracted fields.
- **Phase 1d/1e** — remove the `SUMMARY_RAW = FIRST_USER_PROMPT` line. Add **Phase 1e — Build
  the content summary** producing `NARRATIVE` (≤240 chars) + `ACCOMPLISHMENTS` (3–5 bullets, ≤90
  chars each):
  - *Interactive:* summarize directly from conversation memory; be specific (features, files,
    fixes), not generic.
  - *Background (`--background`):* reconstruct faithfully from `user_prompts`,
    `assistant_snippets`, `files_touched`, `tool_breakdown`, and git commit subjects (Phase 1c).
    Never invent unevidenced work; if signals are sparse, fall back to the first prompt as
    narrative and files/commits as accomplishments.
- **Phase 2 — Scrub** — write **NARRATIVE + every ACCOMPLISHMENT** (newline-joined) to
  `~/.claude/tmp/scrub-input.txt` and scrub that, instead of just the first prompt (the summary
  now carries real session content — file paths, feature names — so the scrub scope must widen).
  Keep the `BLOCKED`/`WARN`/`PASS` handling.
- **Phase 3 — Draft Copy** — lead with **what was accomplished**; token/duration/cache become a
  single trailing supporting stat line, not the headline. Still tokens-only, never dollars.
- **Phase 4 — Populate** — drop `{{SUMMARY}}`/`{{INPUT_TOKENS}}`/`{{OUTPUT_TOKENS}}`/`{{CACHE_READ}}`;
  add `{{NARRATIVE}}` (HTML-escaped) and `{{ACCOMPLISHMENTS}}` (HTML-escape each bullet's text,
  wrap each in `<li>…</li>`, concatenate — no wrapping `<ul>`). Keep the mandatory escape-order block.

## 4. Document `session-card.html` in `variables.md`

Add a Contents entry and a new `## session-card.html` section (mirroring the `feature-card.html`
pattern) listing all variables above, the HTML-escape requirement, and the accomplishment-item
`<li>` format. (This section is currently missing entirely.)

## 5. Version bump — MINOR → `1.3.0`

Additive enhancement + behavior change to an existing skill; nothing removed and the invocation
contract is unchanged → **MINOR**.

- `.claude-plugin/marketplace.json`: change the `social-media-tools` entry `"version"` from
  `1.2.0` → `1.3.0` (optionally add `session-summary`/`recap` to its `tags`). Do **not** touch
  `plugin.json` (no version field there — repo convention). The edit must leave valid JSON
  (`.claude/settings.json` auto-validates on Write/Edit).
- `kit/plugins/social-media-tools/CHANGELOG.md`: prepend a `v1.3.0 — 2026-05-29` entry
  summarizing the content-first card, the four new `session_usage.py` fields, the template
  restructure (new `{{NARRATIVE}}`/`{{ACCOMPLISHMENTS}}`; removed `{{SUMMARY}}`/input/output/cache
  vars), the widened scrub scope, and the new `variables.md` section.

---

## Verification

1. **Script:** `python3 kit/plugins/social-media-tools/scripts/session_usage.py "$(ls -t ~/.claude/projects/*/*.jsonl | head -1)" | python3 -m json.tool` — confirm the 4 new keys are present, non-empty for a real session, and within their caps.
2. **Interactive:** invoke `Skill(skill: "social-media-tools:share-session")` in a session with real work; confirm the card leads with a narrative + accomplishment bullets reflecting *actual* work (not the first prompt), with a small stats strip, and a PNG saved under `docs/media/social/session-*.png`.
3. **Background:** `/social-media-tools:session-bg --platform=all`; confirm `agent-social-share` reconstructs a faithful summary from the JSONL (no live context) and emits `SOCIAL-SHARE: DONE skill=share-session …`.
4. **Scrub gate:** seed a fake secret into a prompt; confirm `BLOCKED` halts before card generation.
5. **JSON validity:** `marketplace.json` parses and reads version `1.3.0`.
6. **Render sanity:** open the saved HTML — narrative + bullets are the visual focus, the metrics strip is secondary, and the copy panel button still copies.

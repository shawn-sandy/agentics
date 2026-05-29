---
status: completed
type: feature
created: 2026-05-28
modified: 2026-05-28
repo-name: agentics
---

# Plan: Add a `session-share` skill to the social-media-tools (code-share) plugin

## Context

The `social-media-tools` plugin (internal name **`code-share`**, namespace `/code-share:…`) already turns code, blogs, videos, GitHub snippets, and selected code into dark-mode social cards. There is no way to share *the coding session itself* — what you worked on plus your token usage — as a post.

A developer mid-flow wants to fire off a "session recap" card (usage stats front-and-center) without breaking concentration. All the runtime pieces already exist:

- **Live session + usage are recoverable at runtime.** `$CLAUDE_CODE_SESSION_ID` resolves the transcript at `~/.claude/projects/<encoded-cwd>/<id>.jsonl`; every `assistant` line carries `message.usage` (`input_tokens`, `output_tokens`, `cache_creation_input_tokens`, `cache_read_input_tokens`). A robust JSONL line-iterator already exists at `kit/plugins/skill-reviewer/skills/auditing-allowed-tools/scripts/session_tool_scan.py` to model on. Transcripts store **tokens only — no dollars** (decision: tokens-only display, no pricing table).
- **`selection-share` is the closest model** — captures live context, runs `security-scrub`, is `--background`-aware, emits a machine-parseable `SOCIAL-SHARE: DONE` line.
- **Card pipeline is shared** — `templates/`, `references/rendering-pipeline.md`, `scripts/find_free_port.py`, save to `docs/media/social/`.
- **Background dispatch is reusable** — `agents/agent-social-share.md` calls `Skill(skill: "code-share:<TARGET_SKILL>")`, so a new `session-bg` command can route `TARGET_SKILL=session-share` through it with no new agent.

**Decisions (from clarify):** usage stats front-and-center · tokens only (no `$`) · background command + foreground skill · new dedicated `session-card.html` template.

## Objective

Add a `session-share` skill that summarizes the current Claude Code session (usage tokens, duration, model, files/commits, one-line narrative) into a dark-mode "session recap" card, triggerable in the background via `/code-share:session-bg` for zero-interruption use while coding.

## Files created / modified

All paths under `kit/plugins/social-media-tools/` unless noted.

- **Created** `scripts/session_usage.py`
- **Created** `templates/session-card.html`
- **Created** `skills/session-share/SKILL.md`
- **Created** `commands/session-bg.md`
- **Modified** `references/variables.md`
- **Modified** `skills/media-library/SKILL.md`
- **Modified** `/Users/shawnsandy/devbox/agentics/.claude-plugin/marketplace.json`
- **Modified** `CHANGELOG.md`
- **Modified** `README.md`

## Steps

1. **Create `scripts/session_usage.py`.** Stdlib-only Python modeled on `session_tool_scan.py`. Resolve the transcript: prefer `$CLAUDE_CODE_SESSION_ID` + cwd-encoded dir (`/`→`-`), fall back to newest-mtime `*.jsonl`; accept an explicit path arg override. Iterate lines (tolerate a malformed final line); for each `type=="assistant"`, sum `message.usage.{input,output,cache_creation,cache_read}_input_tokens`, collect `message.model` into a set, track first/last `timestamp`. Print JSON: `{total_tokens, input, output, cache_write, cache_read, cache_hit_rate, duration_minutes, first_timestamp_iso, models[], user_msgs, assistant_msgs, tool_calls, first_user_prompt, session_id}`.
   - *Why:* Token/usage data lives only in the JSONL; a small reusable parser keeps the SKILL.md prose thin and the logic testable.
   - *Verify:* `python3 kit/plugins/social-media-tools/scripts/session_usage.py` prints valid JSON with non-zero `total_tokens` for the current session; passing an explicit `.jsonl` path also works.

2. **Create `templates/session-card.html`.** Reuse the shared dark-mode palette (`--bg:#0d1117` … `--accent:#388bfd`) and `.card{width:720px}`. Layout, usage-first: a title row (`{{TITLE}}` + model badge `{{MODEL}}`), a prominent metric-tile grid (`{{TOTAL_TOKENS}}`, `{{INPUT_TOKENS}}`, `{{OUTPUT_TOKENS}}`, `{{CACHE_READ}}`, `{{CACHE_HIT_RATE}}`, `{{DURATION}}`, `{{FILES_CHANGED}}`, `{{COMMITS}}`), a one-line `{{SUMMARY}}` subtitle, and the shared `{{COPY_PANELS}}` block. HTML-escape all substituted values.
   - *Why:* "Usage front-and-center" needs a distinct metric-dashboard layout the existing feature/quote cards don't provide; reusing the palette keeps design-system consistency.
   - *Verify:* Open the file in a browser with placeholder values — metric tiles render legibly in dark mode and match the other cards' look; all `{{…}}` placeholders present.

3. **Create `skills/session-share/SKILL.md`.** Model on `selection-share`. Frontmatter: `name: session-share`, description ≤160 chars, `allowed-tools`. Workflow: (0) locate templates; (1) run `session_usage.py`, derive git stats + SUMMARY; (1c) reuse check; (2) mandatory `security-scrub`; (3) tokens-only platform-aware copy; (4) populate `session-card.html`; (4b) save; (5) screenshot; (6) deliver + `SOCIAL-SHARE: DONE`. Flags: `--background`, `--platform=`, `--tone=`, `--session=`.
   - *Why:* Mirroring an audited skill guarantees the scrub gate, background contract, and rendering pipeline behave identically.
   - *Verify:* `head -8 SKILL.md` shows valid frontmatter; skill runs and produces copy + PNG; background mode emits `SOCIAL-SHARE: DONE`.

4. **Create `commands/session-bg.md`.** Exit plan mode → dispatch `agent-social-share` with `TARGET_SKILL=session-share --background <extra>`; return one-line ack.
   - *Why:* Reusing `agent-social-share` delivers zero-interruption background without a new agent file.
   - *Verify:* `/code-share:session-bg` returns an immediate ack; background agent later reports `SOCIAL-SHARE: DONE skill=session-share`.

5. **Update `references/variables.md` and `skills/media-library/SKILL.md`.** Add `session-card` variable table; add `session` prefix to media-library type mapping.
   - *Why:* Both are shared registries every card type must appear in.
   - *Verify:* `variables.md` lists all `session-card` vars; `media-library` recognizes `session-…html` files.

6. **Register: bump version + docs.** Bump `code-share` `0.9.0` → `0.10.0` in `marketplace.json`, extend tags. Add `v0.10.0` to `CHANGELOG.md`, add `session-share` docs to `README.md`.
   - *Why:* MINOR bump for an added skill + command.
   - *Verify:* `marketplace.json` parses cleanly; version reads `0.10.0`; CHANGELOG and README mention `session-share`.

7. **Rename plan file and commit.** Rename `i-want-to-create-tidy-kahan.md` → `add-session-share-skill.md`; commit all changes together.
   - *Why:* Auto-generated slug is a plan defect under the rename rule.
   - *Verify:* `git status` clean after commit; plan committed under verb-target name.

## Acceptance Criteria

- [x] `Skill(skill: "code-share:session-share")` produces tokens-only social copy + a `session-card` PNG saved under `docs/media/social/`.
- [x] The card shows usage stats (total/input/output/cache tokens, cache hit rate, duration, model) front-and-center, with files/commits and a one-line summary.
- [x] No dollar/cost figure appears anywhere (tokens only).
- [x] `/code-share:session-bg` runs in the background, returns control immediately, and later emits `SOCIAL-SHARE: DONE skill=session-share …`.
- [x] Background mode asks **zero** `AskUserQuestion`s and `security-scrub` BLOCKED still hard-stops.
- [x] A new `templates/session-card.html` exists, documented in `references/variables.md`, and reuses the shared dark-mode palette.
- [x] `code-share` version is `0.10.0` in `marketplace.json`; CHANGELOG + README updated; `media-library` lists `session` cards.
- [x] Plan committed as `add-session-share-skill.md` in the same commit as the skill.

## Verification

End-to-end, from `~/devbox/agentics`:

1. **Parser:** `python3 kit/plugins/social-media-tools/scripts/session_usage.py` → valid JSON, non-zero `total_tokens`, current `session_id`.
2. **Foreground:** invoke `session-share` → copy block + PNG under `docs/media/social/session-*.png`; open the PNG and confirm metric tiles read correctly and no `$` appears.
3. **Background:** `/code-share:session-bg` → immediate ack; background agent later reports exactly one `SOCIAL-SHARE: DONE skill=session-share platform=… png=… html=…` line.
4. **Scrub gate:** confirm the skill calls `code-share:security-scrub` before rendering and treats BLOCKED as a stop.
5. **Registration:** confirm no `marketplace.json` validation-hook error and version reads `0.10.0`.

## Next Steps *(optional)*

- **Router integration** (deferred — background command chosen over router-integrated):
  ```text
  Wire session-share into the social-media-tools (code-share) social-share router at kit/plugins/social-media-tools/skills/social-share/SKILL.md. Add a high-priority Phase 1 classification row that matches phrases like "share my session", "session recap", "tokens this session", "usage today" and dispatches TARGET_SKILL=session-share with --background. Keep first-match ordering so it precedes the project-share rules (5/6). Update the router's rule table and bump the code-share version with a CHANGELOG entry.
  ```

- **Foreground convenience command:**
  ```text
  Add commands/session.md to the social-media-tools (code-share) plugin: a thin foreground command that invokes Skill(skill: "code-share:session-share") so users can run /code-share:session interactively to review copy before sharing. Mirror commands/digest.md. Update README and CHANGELOG.
  ```

- **Past-session sharing via usage-data rollups:**
  ```text
  Extend session-share to optionally share a PAST session using Claude Code's pre-aggregated rollups at ~/.claude/usage-data/session-meta/<id>.json and facets/<id>.json (richer: files_modified, lines_added, git_commits, brief_summary). Add a --session=<id> path that reads the rollup when present instead of parsing the live JSONL. Document that current-session rollups lag and live parse remains the default.
  ```

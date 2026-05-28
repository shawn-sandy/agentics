---
status: completed
type: feature
created: 2026-05-28
repo-name: agentics
---

# Plan: Build a social-share router skill + background agent

## Context

A developer mid-flow wants to describe what they're working on in plain language and get a
polished, platform-ready social post — without context-switching. The `social-media-tools`
plugin (manifest name `code-share`) already ships every building block for this: skills for
git changes (`code-share`), pasted/selected code (`selection-share`), GitHub URLs
(`github-code-share`), blogs (`blog-share`), videos (`video-share`), and project
announcements (`project-share`). What is missing is a **router** that classifies a
natural-language request, picks the right workflow, and runs it **in the background** so the
user keeps working.

Per the agent-vs-skill decision: the **router is a skill** (it must auto-activate on natural
language, read live session/git/selection state, and stay in-context), and it reuses an
**agent** for the background hand-off — exactly the plugin's own `scan-for-shares` (skill) →
`agent-digest` (agent) → `digest-bg` (command) trio. Confirmed design choices:

- **Architecture:** router skill + background agent.
- **Background mode:** smart defaults, zero questions — the router infers content type,
  platform, and tone and dispatches immediately.
- **Entry points:** auto-activating router skill + an explicit `/code-share:social-share-bg`
  command.

Because the run is fire-and-forget, the five interactive card skills must gain a
**non-interactive mode** (skip their `AskUserQuestion` and copy-approval pause). This is the
core enabling change and is required regardless of where defaults are decided.

## Objective

Add a `social-share` router skill, an `agent-social-share` background agent, and a
`social-share-bg` command to the `social-media-tools` plugin; teach the existing card skills a
shared non-interactive (`--background`) mode so the router can run any chosen workflow
unattended and deliver a finished post.

## Files to modify / create

Plugin root: `kit/plugins/social-media-tools/`. Skills are invoked as `code-share:<skill>`
(manifest `name` is `code-share`, not the directory name).

- **Create** `references/non-interactive-mode.md` — single source of truth for the `--background` contract.
- **Create** `skills/social-share/SKILL.md` — the router/classifier skill.
- **Create** `agents/agent-social-share.md` — background runner (mirrors `agents/agent-digest.md`).
- **Create** `commands/social-share-bg.md` — explicit background dispatch (mirrors `commands/digest-bg.md`).
- **Modify** 5 card skills (`code-share`, `blog-share`, `github-code-share`, `selection-share`, `video-share`) — add the non-interactive branch.
- **Modify** `skills/project-share/SKILL.md` — honor `--background` (skip its AskUserQuestion).
- **Modify** `CHANGELOG.md`, `README.md`, and `.claude-plugin/marketplace.json` (version 0.8.1 → 0.9.0).

## Steps

1. **Create `references/non-interactive-mode.md`** defining the uniform contract: flags
   `--background`, `--platform=<linkedin|twitter|bluesky|all>`, `--tone=<professional|casual|punchy|conversational>`,
   `--source=<url-or-path>`, `--objective=<text>`, `--code-file=<path>` (equals-form to survive
   URL/path tokenization); the skip rules (no `AskUserQuestion`, auto-proceed past the copy gate,
   scrub `BLOCKED`→STOP / `WARN`→proceed-and-flag, long-file→first 80 lines, video 4xx→empty
   fallback, reuse-check→fresh card); smart-default resolution (platform `all`; tone omitted for
   `all` so each variant uses its `references/platforms.md` per-platform default); and the final
   machine line `SOCIAL-SHARE: DONE skill=<n> platform=<v> png=<path> html=<path>`.
   - *Why:* DRY — the 5 card skills + `project-share` + the agent all reference one contract instead of restating it, matching the plugin's `references/` pattern.
   - *Verify:* File exists; lists every flag, every skip rule, and the exact `SOCIAL-SHARE: DONE` format.

2. **Modify the 5 card skills** (`code-share`, `blog-share`, `github-code-share`,
   `selection-share`, `video-share`) with the same minimal edit: add a `## Non-interactive mode`
   note near the top pointing to `$PLUGIN_DIR/references/non-interactive-mode.md` when
   `$ARGUMENTS` contains `--background`; and prefix the existing Phase-1 `AskUserQuestion` line
   and the Draft-phase "present copy / wait for approval" line with "(Interactive mode only — see
   Non-interactive mode when `--background` is set.)". No phase rewrites (~4–6 lines per skill).
   - *Why:* Lets each skill run unattended under the router while leaving its interactive behavior unchanged for direct use.
   - *Verify:* In each of the 5 SKILL.md files, the AskUserQuestion and copy-gate lines carry the guard, and the top note references the reference file.

3. **Modify `skills/project-share/SKILL.md`** to honor `--background`: it already parses
   `--topic/--platform/--path/--days`, so add the same `## Non-interactive mode` pointer and
   make Phase 1 skip its `AskUserQuestion` when `--background` is present (router always supplies
   a resolved `--topic`).
   - *Why:* Launch/progress routes (rules 5/6/8) target `project-share`; it must not block. `disable-model-invocation: true` does not prevent explicit `Skill` invocation (precedent: `agent-digest` invokes `scan-for-shares`).
   - *Verify:* `project-share` with `--background --topic=release --platform=all` reaches Draft without any AskUserQuestion call.

4. **Create `skills/social-share/SKILL.md`** (router skill). Body: a top-to-bottom,
   first-match-wins classification table — GitHub blob/raw URL → `github-code-share`;
   YouTube/Vimeo URL → `video-share`; other URL or `.md/.mdx` path → `blog-share`;
   pasted/selected/fenced code → `selection-share` (capture the code to
   `~/.claude/tmp/social-share-selection.txt`, pass `--code-file=` + inferred `--objective=`);
   "launch/release/shipped/announcing" → `project-share --topic=release`;
   "progress/update/working on" → `project-share --topic=features`; fallback A (git diff present)
   → `code-share`; fallback B (ambiguous) → `project-share --topic=changes`; if no git repo and
   no source → STOP with one-line error. Resolve smart defaults (`--platform=all`, tone per
   platform), then dispatch `agent-social-share` via the `Agent` tool with
   `run_in_background: true` and return a one-line ack. Frontmatter:
   `allowed-tools: Bash, Read, Glob, Grep, Agent, ToolSearch, ExitPlanMode`; three-part
   `description` so it auto-activates on "share what I'm working on".
   - *Why:* Classification needs live session/git/selection state and must capture the user's code before a cold subagent runs — so it lives in an in-context skill, not the agent.
   - *Verify:* Each table row maps to exactly one target; selection path writes a temp file; the skill calls the `Agent` tool with `run_in_background: true`; `head -6` shows valid frontmatter with `name`, `description`, `allowed-tools`.

5. **Create `agents/agent-social-share.md`** mirroring `agents/agent-digest.md`: frontmatter
   `tools: Skill, Bash, Read, Write, Glob, Grep, ToolSearch, SendUserFile`, `model: sonnet`,
   `maxTurns: 25`, `background: true`, and a "Mirrors the social-share skill but runs as a
   background subagent" description. Body: parse the dispatched target + flags from `$ARGUMENTS`,
   invoke `Skill(skill: "code-share:<target>", args: "<flags> --background")`, emit the
   `SOCIAL-SHARE: DONE …` line (or a one-line error), then a hard **STOP**.
   - *Why:* This is the fire-and-forget runner; `SendUserFile`/`ToolSearch` are added vs `agent-digest` because card skills attach a PNG and drive Playwright via ToolSearch.
   - *Verify:* `head` shows `background: true` + the tool list; body ends with an explicit STOP and never posts to any platform.

6. **Create `commands/social-share-bg.md`** as a thin wrapper mirroring `commands/digest-bg.md`:
   frontmatter `allowed-tools: Skill, ToolSearch, ExitPlanMode`; Step 0 ExitPlanMode bootstrap
   (`ToolSearch select:ExitPlanMode`); Step 1 `Skill(skill: "code-share:social-share", args: "$ARGUMENTS")`.
   - *Why:* Gives an explicit `/code-share:social-share-bg` trigger while keeping one source of truth — all classification/dispatch logic stays in the skill.
   - *Verify:* `/code-share:social-share-bg share my latest commit` dispatches the background agent and returns an ack without blocking.

7. **Bump version and update docs:** set the `code-share` entry in
   `.claude-plugin/marketplace.json` to `0.9.0`; add a `v0.9.0` entry to
   `kit/plugins/social-media-tools/CHANGELOG.md`; add the router skill + command + agent to
   `README.md`; update the `code-share` row in root `CLAUDE.md`'s plugin table.
   - *Why:* Adding a skill/agent/command is a MINOR bump per `marketplace.md`; version lives only in `marketplace.json` (never `plugin.json`).
   - *Verify:* `marketplace.json` shows `0.9.0`; CHANGELOG top entry is `v0.9.0`; `settings.json` JSON auto-validation passes.

## Acceptance Criteria

- [ ] Saying "share what I just built" (no flags) auto-activates `social-share`, classifies, and dispatches a background job with zero questions.
- [ ] The router picks the correct skill for: a GitHub URL, a YouTube URL, a blog URL/`.md`, pasted code, a "launch" announcement, a "progress update", and a bare git change.
- [ ] Selected/pasted code is captured to a temp file and passed via `--code-file=` so the cold subagent can render it.
- [ ] `/code-share:social-share-bg <text>` returns an immediate ack and runs without blocking.
- [ ] A background run completes end-to-end with no `AskUserQuestion`, produces a PNG in `docs/media/social/`, and the agent reports a `SOCIAL-SHARE: DONE …` line.
- [ ] Each of the 6 modified skills still behaves interactively when invoked directly (no `--background`).
- [ ] `marketplace.json` version is `0.9.0`, CHANGELOG and README updated; `plugin.json` has no `version`.
- [ ] No card is auto-posted to any platform — output is copy + image only.

## Verification

1. Load the plugin: `claude --plugin-dir ~/devbox/agentics/kit/plugins/social-media-tools`.
2. **Auto-skill, no flags:** "share the change I just made" → confirm it auto-activates
   `social-share`, classifies to `code-share` (git diff present), dispatches in background, and
   acks immediately. On completion, confirm a PNG was saved under `docs/media/social/` and the
   agent emitted `SOCIAL-SHARE: DONE skill=code-share …`.
3. **Each route:** issue one request per classification row (GitHub URL, YouTube URL, blog URL,
   pasted fenced code, "we just launched v2", "here's my progress this week") and confirm the
   correct target skill ran and produced a card with copy for all three platforms.
4. **Command path:** `/code-share:social-share-bg share my latest commit` → ack returns without
   blocking; background job finishes and reports the saved path.
5. **Interactive regression:** invoke `/code-share:code-share` and `code-share:blog-share`
   directly (no `--background`) and confirm they still ask platform/tone and wait for copy
   approval.
6. **Scrub guard:** route pasted code containing a fake secret and confirm `BLOCKED` hard-stops
   the background run with masked findings (nothing rendered).
7. Run `/skill-reviewer:reviewing-skills` on `skills/social-share/SKILL.md` and
   `/validate-plugin social-media-tools`; address any blocking findings.

## Next Steps *(optional)*

- Add an interactive foreground variant:
  ```text
  Add a /code-share:social-share command (no -bg) to the social-media-tools plugin that runs
  the same classification as the social-share skill but executes the chosen workflow inline in
  the foreground (interactive: ask platform/tone, wait for copy approval) instead of dispatching
  a background agent. Reuse the existing classification logic; do not duplicate it.
  ```

- Let the user pin a default platform:
  ```text
  Add a per-project setting to the social-media-tools plugin (a .claude/code-share.local.md
  file with YAML frontmatter) that lets the user pin a default platform and tone for the
  social-share router, overriding the built-in 'all'/per-platform smart defaults. Document it
  in the plugin README.
  ```

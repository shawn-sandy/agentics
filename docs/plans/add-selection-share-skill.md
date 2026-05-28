# Plan: New `selection-share` skill — share selected/pasted code with objective-driven posts

## Context

The `code-share` skill (plugin dir `kit/plugins/social-media-tools/`) sources post content
**only from git** (Phase 1 runs `git diff` / `git log` / `CHANGELOG.md`). It can't use code
the user selected/highlighted in their editor or pasted into chat, and it has no notion of a
post *objective* (what the user wants the post to accomplish/emphasize).

**Decision:** add this as a **new dedicated skill** (proposed name `selection-share`), not by
extending `code-share`. This mirrors the plugin's established one-skill-per-input-source
pattern — `github-code-share` is its own skill precisely because its input acquisition (fetch
a GitHub URL) differs from local git. Reading code from an IDE selection / pasted fence is
likewise a distinct acquisition mechanism, so it gets its own skill. The downstream pipeline
(draft → template → populate → save → screenshot → deliver) is shared via the plugin-root
`references/` folder, so the new skill is mostly a new Phase 1 + the snippet/diff auto-pick.

**Reuse (read each, one level deep):**
- IDE-selection phrasing — `plan-interview` SKILL.md:68 / `commands/plan-interview.md:50`
  (*"currently open or selected in the IDE (provided via context)"*).
- Snippet rendering, HTML-escape order, `security-scrub` call, snippet-card variable map —
  `skills/github-code-share/SKILL.md` Phases 3–5 and `references/variables.md`.
- `snippet-card.html` (snippet) and `diff-card.html` (diff) templates — used as-is.
- Shared pipeline — `references/{platforms,reuse-check,copy-panels,saving-and-delivery,rendering-pipeline,variables}.md`.

## Approach

### 1. New skill `skills/selection-share/SKILL.md`

Frontmatter:
- `name: selection-share`
- `allowed-tools: AskUserQuestion, Read, Write, Bash, ToolSearch, SendUserFile, Glob, Skill`
  (`Skill` is required for the `security-scrub` call, matching `github-code-share`).
- `description` — three-part, sentence 1 ≤80 chars, total ≤256. Make trigger words
  **distinct from `code-share`** to minimize activation overlap. Recommended:
  > "Drafts a social post and a dark-mode card from code you selected or pasted. Detects the
  > selection, scrubs for secrets, and tailors copy to your objective. Use when asked to
  > share, post, or tweet selected, highlighted, or pasted code."

Phases (modeled on `github-code-share`, swapping URL-fetch for selection capture):

- **Phase 0 — Locate plugin assets.** Copy the existing Phase 0 block verbatim from
  `github-code-share`/`code-share` (sets `TEMPLATES_DIR`, `PLUGIN_DIR`).
- **Phase 1 — Capture selection + objective.**
  - Detect content from (first match): (1) lines the user highlighted in their IDE (provided
    via context) — use exactly those lines, `LINE_RANGE` reflects the selection; (2) a
    selected/open **file** (path provided via context, no specific lines highlighted) — read
    the file and use its contents, deriving `FILENAME`/`LANGUAGE` from the real path/extension;
    (3) a fenced code block pasted in the user's message. Capture the code text plus any
    filename/path hint, fenced-block language tag, and line range.
  - **Selected-file guards:** if the file is non-code (binary, image, lockfile, minified
    bundle), decline with a clear message instead of rendering garbage. If the file exceeds the
    ~80-line snippet cap (see Phase 5), **ask the user which region** (line range, function, or
    section) to feature via `AskUserQuestion`, then use only that range — do not silently
    truncate or render the whole file.
  - If none of the above is present: ask the user to paste or select the code (this skill is
    selection-driven — do **not** silently fall back to git; that's `code-share`'s job).
  - **Objective:** infer from the user's prompt; if absent, ask a short free-text **objective**
    ("What should this post accomplish or emphasize?") together with platform + tone via
    `AskUserQuestion`. Store as `OBJECTIVE`.
- **Phase 1c — Reuse check.** Set `FILE_PREFIX` (`snippet` or `diff`), then follow
  `$PLUGIN_DIR/references/reuse-check.md`.
- **Phase 2 — Security scrub.** Untrusted, about-to-be-published code. Mirror
  `github-code-share` Phase 3 verbatim: write to `~/.claude/tmp/scrub-input.txt`, call
  `Skill(skill: "code-share:security-scrub", args: "Scan the file at ~/.claude/tmp/scrub-input.txt for secrets before sharing.")`,
  handle `BLOCKED` (stop) / `WARN` (confirm) / `PASS` (continue).
- **Phase 3 — Draft copy.** Per `$PLUGIN_DIR/references/platforms.md` limits/tone, **and** the
  copy must serve `OBJECTIVE`. Draft per-platform variants; present in fenced blocks.
- **Phase 4 — Pick template (auto-pick).** Diff-like content (lines starting with `+`/`-`,
  `@@` hunk headers, or a ```` ```diff ```` fence) → `diff-card`; otherwise → `snippet-card`.
- **Phase 5 — Populate template.**
  - snippet-card path: HTML-escape `{{CODE_LINES}}` (`&`→`<`→`>`→`"`); derive `{{LANGUAGE}}`
    (lowercase hljs alias) and `{{LANGUAGE_COLOR}}` from the file extension / fence tag via
    `$PLUGIN_DIR/references/language-map.md` (see §2); `{{FILENAME}}` from the path hint or
    `snippet.<ext>`; `{{LINE_RANGE}}` from the selection or `"selected lines"`; `{{REPO_SLUG}}`
    from `git remote get-url origin` parsed to `owner/repo` (fallback repo dir name, else
    empty); `{{GITHUB_URL}}` empty for local selections; `{{COPY_PANELS}}` per
    `references/copy-panels.md`.
  - diff-card path: reuse the diff-card variable mapping in `references/variables.md`.
- **Phase 5b / 6 / 7 — Save / Screenshot / Deliver.** One-line pointers to
  `references/saving-and-delivery.md` and `references/rendering-pipeline.md`, identical to the
  other card skills.

### 2. Promote `language-map.md` to shared references

The new skill needs the language→hljs-alias/color map, which today lives only at
`skills/github-code-share/references/language-map.md`. The v0.7.0 refactor removed cross-skill
`references/` pointers, so:
- Move it to `references/language-map.md` (plugin root).
- Repoint `skills/github-code-share/SKILL.md` (Phases 1 and 5 reference it) to
  `$PLUGIN_DIR/references/language-map.md`.
- Document it in `references/variables.md` (note `LANGUAGE_COLOR` is sourced only from this
  file).

### 3. Version + metadata (per `.claude/rules/marketplace.md`) — MINOR bump

- `.claude-plugin/marketplace.json` — bump `code-share` entry `version` `0.7.0` → `0.8.0`;
  refresh `description` to mention sharing selected/pasted code; add a tag like
  `code-selection`.
- `kit/plugins/social-media-tools/CHANGELOG.md` — add `## v0.8.0 — 2026-05-28` describing the
  new `selection-share` skill, objective-driven copy, snippet/diff auto-pick, the scrub step,
  and the `language-map.md` relocation.
- `kit/plugins/social-media-tools/README.md` — add a `selection-share` section.
- `.claude-plugin/plugin.json` — optionally extend `keywords` (`code-selection`); no `version`
  field (relative-path plugin).

## Activation note (residual risk)

Two "share code" skills (`code-share`, `selection-share`) can both look relevant when a user
says "share this code." We mitigate by keeping `selection-share`'s description tightly worded
around *selected/highlighted/pasted* code while `code-share` stays git/diff-oriented. The user
chose **not** to also narrow `code-share`'s description, so if real-world activation proves
ambiguous, tightening `code-share`'s wording is the follow-up lever.

## Out of scope

- The `/code-share:digest*` commands and `agent-digest`.
- The other card skills (`blog-share`, `video-share`, `project-share`) and `code-share` itself
  (untouched except the shared-references relocation pointer in `github-code-share`).
- Any new template; `snippet-card.html` / `diff-card.html` are reused as-is.

## Verification

1. **Load locally:** `claude --plugin-dir ./kit/plugins/social-media-tools`.
2. **Pasted snippet + objective:** paste a fenced code block and say "share this on Twitter,
   emphasize the perf win." Expect `selection-share` to fire, pick `snippet-card`, run
   `security-scrub`, draft copy that follows the objective, and produce the PNG card + copy
   panel.
3. **Selected file:** with a short code file open/selected → expect the file's contents used,
   filename + language taken from the path. A large file → expect a prompt to choose a region.
   A binary/lockfile → expect a polite decline.
4. **Diff auto-pick:** paste a block with `+`/`-` lines → expect `diff-card`.
5. **Objective prompt:** share a snippet with no stated goal → expect the objective question
   alongside platform + tone.
6. **Secret in selection:** paste code with a fake key → expect `BLOCKED`/`WARN` before any
   card is produced.
7. **No selection:** invoke with nothing selected/pasted → expect a prompt to paste/select
   code (no git fallback).
8. **Regression:** confirm `code-share` and `github-code-share` still work after the
   `language-map.md` relocation.
9. **Metadata:** `marketplace.json` auto-validates via the `.claude/settings.json` hook on
   save; optionally run `/skill-reviewer:reviewing-skills` on the new skill.

## Commit notes

- Branch `claude/code-share-selection-detect-WrfM7`; conventional commit
  `feat(kit/plugins/social-media-tools): add selection-share skill for selected/pasted code`.
- **Plan hygiene** (`.claude/rules/plan-hygiene.md`): this plan file has a random name — rename
  it to a verb-target slug (e.g. `add-selection-share-skill.md`) via `/plan-hygiene` before
  committing, and include the plan file in the commit.

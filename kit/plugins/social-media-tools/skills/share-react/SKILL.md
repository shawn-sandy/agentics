---
name: share-react
description: "Turns a React component into a social card with preview, code, and props table. Builds a static preview and screenshots react-card.html via Playwright. Use when asked to share a React component."
allowed-tools: AskUserQuestion, Read, Write, Bash, Glob, Grep, ToolSearch, ExitPlanMode, Skill, SendUserFile
---

# share-react

Turn a React component — a `.tsx`/`.jsx` file path, an IDE selection, or pasted code — into
platform-aware social media copy and a styled dark-mode card image showing a static preview,
the component source, and a props table (see `$PLUGIN_DIR/references/platforms.md` for
supported platforms).

This skill is **component-driven**: it shares one React component the user points at. The
preview is a hand-built static HTML/CSS approximation — no bundler, no React runtime, and
never any execution of user code. It does **not** scan git history — that is `share-code`'s
job.

## Quick Reference

| Phase | Action |
|-------|--------|
| 0 — Locate | Locate `templates/` and derive `PLUGIN_DIR` |
| 0b — Config | Load `SOCIAL.md` defaults (`DEFAULT_PLATFORM`, `DEFAULT_TONE`) |
| 1 — Capture | Component from file path, IDE selection, or pasted code |
| 1c — Reuse check | Scan `docs/media/social/` for existing react posts; offer reuse |
| 2 — Scrub | Run `security-scrub` on the component source |
| 3 — Props | Build `PROPS_ROWS` per `references/props-extraction.md` |
| 4 — Preview | Hand-build static `PREVIEW_MARKUP` (up to 3 states) |
| 5 — Draft | Platform-aware, takeaway-first copy |
| 6 — Populate | Fill `react-card.html` `{{VARIABLES}}` including `{{COPY_PANELS}}` |
| 6b — Save | Persistent save to `docs/media/social/` |
| 7 — Screenshot | Serve HTML locally, Playwright screenshot |
| 8 — Deliver | Present copy + attach PNG + show saved path |

## Exit plan mode

`ExitPlanMode` is a deferred tool. **Only call it if currently in plan mode** — skip this step entirely when not in plan mode. When calling: use `ToolSearch` with `select:ExitPlanMode` first, then call `ExitPlanMode` silently.

---

## Phase 0 — Locate Plugin Assets

Run silently:

```bash
[ -n "${CLAUDE_PLUGIN_ROOT}" ] && [ -d "${CLAUDE_PLUGIN_ROOT}/templates" ] && \
  echo "${CLAUDE_PLUGIN_ROOT}/templates"
find ~/.claude/plugins -path "*/social-media-tools/templates" -type d 2>/dev/null | head -1
find ~/.claude -path "*/social-media-tools/templates" -type d 2>/dev/null | head -1
```

Use the first non-empty result as `TEMPLATES_DIR`. Derive:

```bash
PLUGIN_DIR=$(dirname "$TEMPLATES_DIR")
```

If no directory is found: output "Templates not found. Install the plugin or load it with `--plugin-dir`." and **STOP**.

---

## Phase 0b — Load Project Sharing Config

Check for `SOCIAL.md` (see `$PLUGIN_DIR/references/social-config.md`):

```bash
SOCIAL_CONFIG=""
GIT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null)"
if [ -f "$PWD/SOCIAL.md" ]; then
  SOCIAL_CONFIG="$PWD/SOCIAL.md"
elif [ -n "$GIT_ROOT" ] && [ -f "$GIT_ROOT/SOCIAL.md" ]; then
  SOCIAL_CONFIG="$GIT_ROOT/SOCIAL.md"
fi
```

If `SOCIAL_CONFIG` is non-empty, `Read` it silently. Extract:

- `DEFAULT_PLATFORM` from `## Defaults` → `Platform:` line
- `DEFAULT_TONE` from `## Defaults` → `Tone:` line

---

## Phase 1 — Capture Component

### Source the component (path and selection on equal footing; first match wins)

1. **File path** — a `.tsx`/`.jsx` path supplied in `$ARGUMENTS` (bare, or via
   `--source=<path>`). `Read` the file and use its contents.
2. **IDE selection / open file** — if the user highlighted lines or has a `.tsx`/`.jsx` file
   selected or open in the IDE (provided via context), use exactly those contents (the whole
   file when no specific lines are highlighted).
3. **Pasted code** — if the user pasted a fenced code block (e.g. ```` ```tsx ```` or
   ```` ```jsx ````), use its contents.

Capture for later phases:

- `COMPONENT_RAW` — the component source text.
- `COMPONENT_NAME` — the PascalCase component identifier from the default or named export
  (e.g. `export default function Button`, `export const Card = …`); fallback: PascalCase of
  the file basename (`user-card.tsx` → `UserCard`). For pastes with no export, use the first
  PascalCase function/const that returns JSX; else `Component`.
- `SOURCE_PATH` — the repo-relative path of the captured file (relative to the git root when
  inside a repo, otherwise the path as given); empty string for pasted code.
- `FRAMEWORK_BADGE` — `"React · TSX"` for `.tsx`, `"React · JSX"` for `.jsx`. For pastes,
  derive from the fence tag (`tsx`/`jsx`); when ambiguous, use `"React · TSX"` if TypeScript
  syntax is present (type annotations, interfaces), else `"React · JSX"`.

### Guards

- **Not a standalone component** — if the captured source does not define a React component
  (no function/class component and no component export that returns JSX), or it is clearly a
  non-component React file by name or shape — a test (`*.test.*`/`*.spec.*`), a Storybook
  story (`*.stories.*`), a route module, a hooks-only or utility file, or an arbitrary JSX
  fragment — do **not** stop dead. Tell the user in one line what was captured, write
  `COMPONENT_RAW` to `~/.claude/tmp/social-share-selection.txt`, then hand off:
  `Skill(skill: "social-media-tools:share-selection", args: "--code-file=~/.claude/tmp/social-share-selection.txt --objective=demonstrate this code")`
  and **STOP this skill** once share-selection takes over (it produces the generic snippet
  card these files actually need).
- **Long source** — *(Interactive mode)* If the source exceeds 80 lines, use
  `AskUserQuestion` to ask which region to feature (a line range, a single component, or a
  section), then use only that region. Do **not** silently truncate. *(Background mode)* use
  the first 80 lines without asking.

### No component found

If none of the three sources yields code, ask the user to provide a component path or paste
the component. Do **not** fall back to git history.

### Platform and tone

Resolve `PLATFORM` and `TONE` in order: explicit flags (`--platform=<v>`, `--tone=<v>`) →
`DEFAULT_PLATFORM`/`DEFAULT_TONE` from Phase 0b → ask via `AskUserQuestion` (see **Platform
Options** in `$PLUGIN_DIR/references/platforms.md`).

---

## Phase 1c — Reuse Check

```bash
FILE_PREFIX=react
```

Read `$PLUGIN_DIR/references/reuse-check.md` and follow its procedure.

---

## Phase 2 — Security Scrub

Component source is untrusted and about to be published. Write it to a temp file:

```
Write to: ~/.claude/tmp/scrub-input.txt
Content: COMPONENT_RAW (plain text, no HTML escaping yet)
```

Then invoke:

```
Skill(skill: "social-media-tools:security-scrub", args: "Scan the file at ~/.claude/tmp/scrub-input.txt for secrets before sharing.")
```

Check the returned `GATE RESULT` line (the gate runs inside `security-scrub`):

- `GATE RESULT: BLOCKED` or `GATE RESULT: CANCELLED` → **STOP.** Do not proceed to Phase 3.
- `GATE RESULT: APPROVED` → proceed to Phase 3.
- Missing or unrecognized `GATE RESULT` → **STOP** and report an error (treat as gate failure).

---

## Phase 3 — Extract Props

Read `references/props-extraction.md` (bundled with this skill) and follow its rules to build
`PROPS_ROWS`:

- **Typed path first** — extract from the TypeScript props interface, type alias, or inline
  prop types on the component signature.
- **Inference fallback** — when no types exist (`.jsx`, untyped `.tsx`), infer from the
  destructured props in the function signature, default values, and usage in the body.

---

## Phase 4 — Build Static Preview

Hand-build `PREVIEW_MARKUP` — a static HTML/CSS approximation of what the component renders.

**Safe by construction**: `{{PREVIEW_MARKUP}}` is substituted RAW in Phase 6, so it must
contain only markup you author from your understanding of the component. **NEVER** copy user
code — `COMPONENT_RAW` or any user-supplied string — into it; write representative labels
and content yourself.

- **States** — render up to 3 states inferred from the props (e.g. default/primary,
  disabled, a size or loading variant). Render a single state when the props expose no
  meaningful variants.
- **Wrapper** — wrap each state:

  ```html
  <div class="preview-state">
    <span class="preview-state-label">default</span>
    <!-- skill-authored approximation of the rendered component -->
  </div>
  ```

- **Styling** — inline `style` attributes only, scoped to the preview pane; no external CSS.
- **Accessibility** — alt text on any `<img>`; `aria-label` on icon-only elements.
- **Non-visual components** (providers, hooks-only modules): render a single muted panel
  labeled "non-visual component" with a one-line usage hint.

---

## Phase 5 — Draft Copy

Read `$PLUGIN_DIR/references/platforms.md` for character limits, tone defaults, the
**Instructional Voice** doctrine, **Learn-More CTA** rule, **Default Per-Platform Copy
Formats**, and **Draft Copy — Standard Procedure**.

**Takeaway-first**: every post must surface a concrete, applicable takeaway — what the
reader can learn or apply from this component (a composition pattern, a prop API decision,
an accessibility technique). The component is evidence for the lesson, not the headline.

Draft copy for `PLATFORM` in the chosen `TONE`, following the **Default Per-Platform Copy
Formats** in `$PLUGIN_DIR/references/platforms.md`.

---

## Phase 6 — Populate Template

```bash
TEMPLATE_FILE=$TEMPLATES_DIR/react-card.html
TEMP_HTML=share-react-card.html
SLUG_INPUT=$COMPONENT_NAME
```

Read `TEMPLATE_FILE`. For `{{COPY_PANELS}}` markup and escaping, read
`$PLUGIN_DIR/references/copy-panels.md`.

### HTML-escape — MANDATORY

Apply to every escaped value below in this exact order:

1. `&` → `&amp;` ← first, to prevent double-escaping
2. `<` → `&lt;`
3. `>` → `&gt;`
4. `"` → `&quot;`

Store the escaped component source as `COMPONENT_CODE_ESCAPED`.

### react-card variables

| Template variable | Value |
|-------------------|-------|
| `{{COMPONENT_NAME}}` | `COMPONENT_NAME` (HTML-escaped) |
| `{{FRAMEWORK_BADGE}}` | `"React · TSX"` or `"React · JSX"` — hardcoded from the extension in Phase 1, never user-derived |
| `{{PREVIEW_MARKUP}}` | `PREVIEW_MARKUP` — RAW skill-authored markup from Phase 4; never user code |
| `{{COMPONENT_CODE}}` | `COMPONENT_CODE_ESCAPED` |
| `{{PROPS_ROWS}}` | Escaped rows built in Phase 3 |
| `{{REPO_SLUG}}` | From `git remote get-url origin` parsed to `owner/repo`; fallback the repo directory name; else empty string |
| `{{SOURCE_PATH}}` | `SOURCE_PATH` repo-relative path (HTML-escaped); empty string for pasted code |
| `{{COPY_PANELS}}` | Per `$PLUGIN_DIR/references/copy-panels.md` |

Write the populated HTML to `~/.claude/tmp/share-react-card.html`:

```bash
mkdir -p ~/.claude/tmp
```

---

## Phase 6b — Persistent Save

Variables already set: `FILE_PREFIX=react`, `SLUG_INPUT`, `TEMP_HTML`.

Read `$PLUGIN_DIR/references/saving-and-delivery.md` — **Persistent Save** section.

---

## Phase 7 — Screenshot

Read `$PLUGIN_DIR/references/rendering-pipeline.md` and follow the full pipeline.

---

## Phase 8 — Deliver

Read `$PLUGIN_DIR/references/saving-and-delivery.md` — **Deliver** section.

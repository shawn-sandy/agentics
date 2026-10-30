---
name: customize-design
description: "Rebrands a DESIGN.md project's tokens in every theme scope. Finds the token file, measures contrast, and keeps the spec and mirrors in step. Use when asked to change a site's colours or branding."
allowed-tools: AskUserQuestion, Read, Write, Edit, Bash, Glob, Grep, Skill, ToolSearch, ExitPlanMode
---

# customize-design

## Exit plan mode

**If in plan mode**, call `ExitPlanMode` first — this workflow mutates state.

## Overview

Changes how a project looks — its accent and neutral colours, its fonts, its corners — in
every theme scope, without breaking dark mode, contrast, or the tests that guard the design.
`DESIGN.md` is the written spec. The stylesheet is what ships, so change the stylesheet first
and make the spec match it. Nothing about the project is hardcoded here: Step 0 discovers the
token file, its scopes, the build command and the files that mirror the spec, and confirms
them once.

Two dependency-free scripts ship with this skill. `${CLAUDE_SKILL_DIR}` is replaced with this
skill's absolute folder when the skill loads.

```bash
node "${CLAUDE_SKILL_DIR}/scripts/contrast.mjs" --tokens <token file>     # the direction's eight pairs, both themes
node "${CLAUDE_SKILL_DIR}/scripts/contrast.mjs" '#185c53:#fcfcfd'         # any hex pair
node "${CLAUDE_SKILL_DIR}/scripts/scaffold.mjs" --accent '#185c53'        # a project with no tokens yet
```

The contrast script reads `--name: value` declarations and assigns each to light or dark by
its enclosing block: SCSS `direction-light` / `direction-dark` mixins, `:root`,
`@media (prefers-color-scheme: dark)`, `[data-theme="dark"]` or `.dark`. Other scope names go
through `--light-scope` and `--dark-scope`. `--design-md DESIGN.md` reads the frontmatter
`colors:` map instead. Ratios are floored to two decimals; it exits 1 under 4.5:1 and 2 when
a value cannot be measured (`hsl()`, `oklch()`, `var()`, translucent): measure those by hand,
never guess.

## Rules to keep

Keep these through any rebrand. Tests cover only part of them, so a green run is not proof.

- **The accent is only for things a visitor can operate.** `--island` paints links, buttons
  and focus rings. Never a heading, border, hairline or surface.
- **Every text pair is at least 4.5:1, in both themes.** The script measures eight pairs:
  ink and ink-soft on paper and on paper-sunk, island on paper, paper-sunk and island-bg,
  and ink on island-bg.
- **Headings, body and labels use three different font families.**
- **Dark is darker than light**, and body, header and cards repaint between themes.
- **The primary button label is `--paper`, never white.** The accent lightens in dark mode,
  and white text on it would fail contrast.
- **Edit every scope the discovery found.** A colour set only in `:root` stays stale under
  the OS preference and under the theme toggle. In a Sass project that means the mixins, not
  the blocks that include them.

## Step 0 — Discover, ask once, then check the build

Run every command from the repository root. Discover, in this order:

1. **The token file**: the stylesheet declaring `--` custom properties under `:root` or a
   direction mixin.

   ```bash
   grep -rlE --include='*.css' --include='*.scss' --exclude-dir=node_modules --exclude-dir=dist -e '^\s*--[a-z][a-z0-9-]*\s*:' . \
     | xargs grep -lE ':root|@mixin direction-light'
   ```

   Several matches: prefer the source over its compiled output (`index.css`), and the file
   that declares the colour tokens over a vendor or docs-theme sheet.

2. **The dark scopes** in that file, and whether it is Sass:

   ```bash
   grep -nE 'prefers-color-scheme:\s*dark|\[data-theme=.dark.\]|\.dark\b|@mixin direction-(light|dark)' <token file>
   ```

3. **The build command**, if the site loads compiled CSS rather than the token file itself:

   ```bash
   grep -nE '"(sass|sass:build|build:css|css:build|styles)"\s*:' package.json
   ```

4. **The mirrors**: every `.md` or `.mdx` file that repeats three or more of the token values.
   A file that merely names the tokens is not a mirror; one that repeats their values is.

   ```bash
   values=$(grep -ohE -- '--(ink|ink-soft|island|island-bg|paper|paper-sunk|rule)\s*:\s*#[0-9a-fA-F]{3,6}' <token file> | grep -oE '#[0-9a-fA-F]{3,6}' | sort -u | paste -sd'|' -)
   for f in $(grep -rlE --include='*.md' --include='*.mdx' --exclude-dir=node_modules -e "$values" .); do
     n=$(grep -oiE "$values" "$f" | sort -uf | wc -l); [ "$n" -ge 3 ] && echo "$n $f"
   done
   ```

   Match on the direction tokens' values, not every `--name: #hex` in the file: a legacy
   palette's forty hexes would pull in every document that mentions one. (A project with
   other token names: put those names in the first grep.) `DESIGN.md` lists itself;
   changelogs and plan files often qualify too. The user strikes those in the question below.

5. **`DESIGN.md`** at the root, and **the project's test command** (`"test"`, `"e2e"` in
   `package.json`).

> **Astro Kit example.** In `shawn-sandy/astro-basics` and its forks, discovery finds
> `src/styles/_design-tokens.scss` (the seven tokens in `@mixin direction-light` and
> `direction-dark`, compiled to `src/styles/index.css` by `npm run sass:build`), the Starlight
> accent variables in `src/styles/starlight-custom.scss` (`--sl-color-accent`, `-high`, `-low`,
> `--sl-color-text-accent`, measured against `--sl-color-bg` and `--sl-color-bg-sidebar`), and
> two mirrors: `src/content/docs/guide/design-direction.mdx` and
> `project-docs/03-features/design-direction.md`.

Then ask **once**, with `AskUserQuestion`, showing what was found and asking:

1. **Confirm the findings**: the token file, its scopes, the build command (or none), the
   mirrors to keep in step, and `DESIGN.md`. When no token file was found, offer the
   scaffold: "Write `src/styles/tokens.css` and a starter `DESIGN.md` from the brand colour?"
2. **Scope.** The whole site (Path A, the default), or a brand layer on a few sections only
   (Path B).
3. **Colour.** One brand colour is enough; derive the rest from it. A logo works too: read
   its fills.
4. **Fonts.** Keep the current faces, or name a display face they may self-host (Google
   Fonts' OFL fonts can be). Body and labels keep their faces unless they ask.
5. **Corners.** Keep the current radius, go sharper, or go rounder.
6. **Name.** What the design system is called in `DESIGN.md`.

**No token file, scaffold accepted:** run
`node "${CLAUDE_SKILL_DIR}/scripts/scaffold.mjs" --accent '<brand>' --name '<name>'` (add
`--out <dir>` if the stylesheets live elsewhere than `src/styles`). It writes the seven tokens
in three scopes plus the three font roles, and a starter `DESIGN.md` with the measured ratios
filled in. A brand colour too light for text is darkened in 2% steps until it clears 4.5:1,
and the original is kept for the wash. The script refuses to overwrite. Import the new
`tokens.css` from the site's base layout or global stylesheet, then continue into Path A on
the files it wrote, with the scaffold's values as the "before" table.

**Drift pre-flight.** Before editing anything:

```bash
git status --short <token file's directory>
```

Any output means style work is in progress: stop and ask them to commit it or set it aside.
With a build command, run it and check the compiled stylesheet is unchanged:

```bash
<build command> && git status --short <compiled stylesheet>
```

Output means the committed CSS had drifted from its source and a rebuild would ship unrelated
changes with the rebrand: show `git diff --stat`, and ask whether to commit the rebuilt CSS
first or to use Path B, which needs no build (restore the compiled file with `git restore`).
With no build command, skip this check.

Record the starting numbers:

```bash
node "${CLAUDE_SKILL_DIR}/scripts/contrast.mjs" --tokens <token file>
```

## Path A — Rebrand the whole site

### A1 — Pick the seven colours

| Token          | Role                                                | Light                                                        | Dark                           |
| -------------- | --------------------------------------------------- | ------------------------------------------------------------ | ------------------------------ |
| `--island`     | the accent                                          | the brand colour, dark enough for 4.5:1 on all three grounds | a lighter tint of the same hue |
| `--island-bg`  | accent wash: hover fills, `::selection`, active nav | a very light tint of the hue                                 | a very dark shade of the hue   |
| `--ink`        | text                                                | near-black, may lean toward the hue                          | near-white                     |
| `--ink-soft`   | secondary text                                      | mid-grey; its pair with `--paper-sunk` is the tightest       | mid-grey, lighter              |
| `--paper`      | page background                                     | near-white                                                   | near-black                     |
| `--paper-sunk` | header band, cards, code blocks                     | one step darker than paper                                   | one step lighter than paper    |
| `--rule`       | hairlines, never text                               | light grey                                                   | dark grey                      |

Try candidates before editing anything. Any `#fg:#bg` pair works:

```bash
node "${CLAUDE_SKILL_DIR}/scripts/contrast.mjs" '#185c53:#fcfcfd' '#185c53:#f1f3f5'
```

A brand colour too light for text (yellow, light orange, any pastel) is never refused: darken
it toward black in 2% steps until the pair measures, use that for `--island`, keep the bright
original for `--island-bg` or the logo, and tell the user. `scaffold.mjs --accent '<brand>'
--out <scratch dir>` prints that derivation for both themes without touching the project.
Hover and active states should mix from `--island` with `color-mix()`, so no hover tokens.

### A2 — Edit the tokens

Change the values in every scope the discovery found — the two mixins, or the `:root`, dark
and `[data-theme]` blocks. Keep the property names: components read `--island`, `--ink` and the
rest. Replace the ratios in the comment above the tokens with the script's output. Those
figures are a record, never an estimate. If the project has a docs theme with its own accent
variables, point them at the new hue and measure its text-accent against its own grounds with
the script's hex mode.

### A3 — Fonts (only if asked)

1. Put the font where the project keeps static files (`public/fonts/` or the equivalent) as
   one woff2, one weight, latin subset. Confirm its licence allows self-hosting.
2. In the token file, update the `@font-face` `font-family`, `font-weight` and `src`, and put
   the new family first in `--font-family-display`.
3. Find the preload: `grep -rn 'as="font"' src` — change its `href` to match the `src`
   exactly. A mismatch downloads the font twice.
4. If headings render at a fixed weight (`grep -rn 'font-weight' <base stylesheet>`), a file in
   another weight needs that line changed too, or the browser fakes the weight.

Each extra weight is another network request: make that choice with the user. The sans and
mono families must stay different from the display family and from each other.

### A4 — Corners (only if asked)

Change the `--radius-*` scale and the aliases follow. Then find the corners that bypass it:

```bash
grep -rnE 'border-radius:\s*[0-9.]+(px|rem)' src --include='*.css' --include='*.scss' --include='*.astro' --include='*.tsx' --include='*.vue' --include='*.svelte'
```

List them and tie each to a token only if the user wants that corner to change too. A
component library may read its own alias (`--radius`, `--btn-radius`): set those aliases to
`var(--radius-lg)` in the token file's `:root` block. Radius does not change between themes, so
`:root` is enough.

### A5 — Build and check

```bash
<build command, if any>
node "${CLAUDE_SKILL_DIR}/scripts/contrast.mjs" --tokens <token file>
<the project's test command, if any>
```

Prefer the narrow test commands the project documents over a bare `npm test` whose pre-scripts
rebuild or reformat files. If the e2e browsers are missing, say the e2e checks did not run
rather than calling the work verified. Then look at the site: the homepage and one of each
route type, in light and dark, using both the theme toggle and the OS setting, and at 320px
wide. Leave status colours (success, warning, error, info) alone; they signal state, not brand.

### A6 — Make DESIGN.md and its mirrors match

- **Frontmatter:** `name`, `description`, the seven `colors` (light values), each
  `typography.*.fontFamily`, `rounded`, and any component value that hardcodes a colour.
- **`## Colors`:** new names for the colours, how the accent is described, light and dark hex,
  and the script's ratios.
- **`## Typography`** if the display font changed, **`## Shapes`** if the corners did.
- **Every other hex, ratio and colour word.** Ratios also appear outside `## Colors`. List them
  all and decide each one, on `DESIGN.md` and then on every confirmed mirror:

  ```bash
  grep -nE '#[0-9a-fA-F]{6}\b|[0-9]+\.[0-9]+:1' DESIGN.md <mirror> ...
  grep -nwE '<old colour names>|<old font names>' DESIGN.md <mirror> ...
  ```

Keep the Named Rules. They describe the system, not the brand. Change one only if the user's
brand really breaks it, and tell them which. The script floors ratios, so 6.768 prints as
6.76; write the script's figures.

### A7 — Re-sync the published design system (optional)

If `README.md` or `DESIGN.md` links a claude.ai Design System artifact, offer to re-sync it:
run `/design-system-tools:from-design-md` with that URL so it merges into the existing system
instead of creating one. Never build an artifact by hand.

## Path B — A brand layer on some sections

Use this when only some sections should carry the brand while every other route keeps the
current palette, or when Step 0 found drifted compiled CSS, because it needs no build.

1. **Create `<styles dir>/<brand>-palette.css`**, plain CSS outside any build. Prefix every
   property with the brand name and scope it to `[data-<brand>]`, in three blocks:

   ```css
   [data-acme] {
     --acme-ground: #f5f8f6;
     --acme-ink: #12302b;
   }

   @media (prefers-color-scheme: dark) {
     :root:not([data-theme='light']) [data-acme] {
       --acme-ground: #0e1d1a;
       --acme-ink: #e4efeb;
     }
   }

   :root[data-theme='dark'] [data-acme] {
     --acme-ground: #0e1d1a;
     --acme-ink: #e4efeb;
   }
   ```

   The `:not([data-theme='light'])` guard lets the theme toggle beat a dark OS. The last block
   lets it beat a light one.

2. **Opt components in.** Each one sets `data-<brand>` on its root element and imports the
   sheet. The browser loads it once, however many components import it.
3. **Point the component's colours at the brand.** Components read the direction tokens
   through their own aliases (`--hero-ink: var(--ink, #101418)`); wrap each so the kit token
   and the literal fallback both survive: `--hero-ink: var(--acme-ink, var(--ink, #101418));`.
   A component with no aliases needs its painted properties pointed at the brand properties
   directly. Confirm in the browser that the section's computed colours are the brand values,
   in both themes.
4. **No brand colour may equal `--island`**, in either theme, or an accent audit will flag a
   static element as interactive. Choose a visibly different hue.
5. **Measure every brand pair** with the script's `#fg:#bg` mode in both themes, and record
   the ratios in a comment at the top of the sheet.
6. **Write it into `DESIGN.md`:** the brand's light values as `colors.<brand>-*` in the
   frontmatter, and a `### <Brand> Brand Layer` section under `## Colors` that names the
   components it paints. Then run A5 without the build, and A7 if wanted.

## Report back

Done means the stylesheet, the spec and the measurement agree, not that the edits were made.
Re-run the contrast script on the edited token file and paste its output. Tell the user:

- which files changed
- the contrast table, before and after
- which checks ran and passed, and which did not run (no build, no e2e browsers)
- what is left for them: logo, favicon, site title if those were not part of it

Commit nothing unless they ask.

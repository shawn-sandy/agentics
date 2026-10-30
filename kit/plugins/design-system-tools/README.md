# design-system-tools

Turning a repository's design rules into a design system other agents can build on, and
keeping the rules true.

A `DESIGN.md` describes a brand's tokens and rules, and the stylesheets implement them. This
plugin keeps the two in step and publishes both as a claude.ai Design System artifact: tokens
in every theme, a README brand book of usage rules that name those tokens, static component
previews and a cover. Nothing about the project is hardcoded: each skill discovers the token
file, its theme scopes, the build command and the files that mirror the spec by grep, and
confirms them once.

## Skills

| Skill | What it does |
|-------|--------------|
| `align-design-md` | Compares `DESIGN.md`'s frontmatter and prose with each component's style block, prints a drift table, and on confirmation rewrites the record and its mirrors. Never edits source. |
| `customize-design` | Rebrands the seven direction tokens in every theme scope, with contrast measured by a bundled script; scaffolds the tokens and a starter `DESIGN.md` for a project that has none. |
| `from-design-md` | Maps `DESIGN.md` and the stylesheets behind it into a new Design System artifact, or re-syncs an existing one. |

## Usage order

Align first, so the record is true; customize next, so the tokens are the brand's; publish
last, so the artifact carries both.

```text
/design-system-tools:align-design-md
/design-system-tools:customize-design
/design-system-tools:from-design-md https://claude.ai/artifact/<id>
```

Each skill also auto-activates on a matching request: "find where DESIGN.md drifted", "change
the site's accent to #185c53", "turn this repo's DESIGN.md into a design system". With no
system URL, `from-design-md` makes a new one named after the `DESIGN.md` `name`; with a URL, it
merges into that system and keeps anything added on the page.

## How it works

The Design System artifact type ships its own authoring instructions inside every system
(`SKILL.md` and `artifact-type/reference/*.md`). `from-design-md` reads those from the target
first and defers to them for every file shape, cap and publish call. What this plugin adds
is the DESIGN.md mapping and a few firm choices:

- **The stylesheet is truth; DESIGN.md is intent.** Where they disagree, the code's value and
  unit win, and the disagreement is reported. `align-design-md` is the skill that makes the
  record match again.
- **Contrast is measured, never estimated.** Both contrast scripts print the WCAG 2 ratio of
  each token pair in every theme, floored to two decimals so a near-miss never rounds up to a
  pass, and refuse `hsl()`, `oklch()` and translucent values rather than guess.
- **A too-light brand colour is darkened, not refused.** The scaffold steps it toward black
  in 2% increments until every pair clears 4.5:1 and keeps the original for the wash.
- **A control under a stated size floor is reported, never changed.** The user decides
  whether the record or the code moves.
- **Components are static.** Each preview is hand-written from the source rule it names, with
  interaction states shown through `data-state` attributes, and the static route always ships
  a one-line `components/bundle.js` namespace stub because the page renders no preview
  without it.
- **The publish is checked on the remote.** The file listing, the index, the ratios and both
  themes are read back before the system is reported as done.

## Install

```bash
/plugin marketplace add shawn-sandy/agentics
/plugin install design-system-tools@agentics-kit
```

Local testing:

```bash
claude --plugin-dir ./kit/plugins/design-system-tools
```

## Requirements

- Node.js 22 or newer, for the bundled scripts (they use only `node:` modules, so the target
  project needs no `node_modules`).
- An Artifact tool that can publish files (Claude Code or Cowork), for `from-design-md`.
- The built-in browser tools, for measuring heading sizes from the rendered page and checking
  the published system in both themes. Without them the skills record the stylesheet's own
  declaration and say what went unmeasured.
- A local checkout of the repository, or `owner/name` to clone.

## Scripts

Run from any directory; `${CLAUDE_SKILL_DIR}` is substituted when a skill loads.

```bash
node "${CLAUDE_SKILL_DIR}/scripts/contrast.mjs" --tokens src/styles/tokens.css          # customize-design: eight pairs, both themes
node "${CLAUDE_SKILL_DIR}/scripts/contrast.mjs" --design-md DESIGN.md --pairs ink:paper  # from the frontmatter colors map
node "${CLAUDE_SKILL_DIR}/scripts/contrast.mjs" '#185c53:#fcfcfd'                        # any hex pair
node "${CLAUDE_SKILL_DIR}/scripts/scaffold.mjs" --accent '#185c53' --name Acme            # tokens.css in three scopes + DESIGN.md
node "${CLAUDE_SKILL_DIR}/scripts/contrast.mjs" project/tokens.json ink:paper             # from-design-md: a published tokens.json
```

Tests:

```bash
node --test "kit/plugins/design-system-tools/skills/customize-design/scripts/*.test.mjs"
node --test "kit/plugins/design-system-tools/skills/from-design-md/scripts/*.test.mjs"
node --test tests/plugins/design-system-tools.test.mjs
```

## Plugin Structure

```
design-system-tools/
├── .claude-plugin/
│   └── plugin.json
├── README.md
├── CHANGELOG.md
└── skills/
    ├── align-design-md/
    │   ├── SKILL.md
    │   └── references/
    │       └── drift-checklist.md   # what counts as drift, and the report format
    ├── customize-design/
    │   ├── SKILL.md
    │   ├── scripts/
    │   │   ├── contrast.mjs         # SCSS mixins, plain CSS scopes, DESIGN.md colors, bare pairs
    │   │   ├── contrast.test.mjs
    │   │   ├── scaffold.mjs         # tokens.css in three scopes + a starter DESIGN.md
    │   │   └── scaffold.test.mjs
    │   ├── fixtures/
    │   │   ├── oncue/               # oncue-app's token file and DESIGN.md frontmatter at 2f0b5d2
    │   │   └── plain-css/           # the same seven tokens as plain CSS
    │   └── templates/
    │       ├── tokens.css
    │       └── DESIGN.md
    └── from-design-md/
        ├── SKILL.md
        └── scripts/
            ├── contrast.mjs         # WCAG 2 contrast per token pair, per theme of a tokens.json
            └── contrast.test.mjs
```

## Components

- **Skill:** `align-design-md` — auto-activates on requests to align or audit `DESIGN.md`
  against the code; also invocable as `/design-system-tools:align-design-md`.
- **Skill:** `customize-design` — auto-activates on requests to change a site's colours,
  fonts or branding; also invocable as `/design-system-tools:customize-design`.
- **Skill:** `from-design-md` — auto-activates on requests to turn a `DESIGN.md` into a design
  system; also invocable as `/design-system-tools:from-design-md`.

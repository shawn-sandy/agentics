# design-system-tools

Turning a repository's design rules into a design system other agents can build on.

A `DESIGN.md` describes a brand's tokens and rules, and the stylesheets implement them. This
plugin publishes both as a claude.ai Design System artifact: tokens in every theme, a README brand
book of usage rules that name those tokens, static component previews and a cover.

## Skills

| Skill | What it does |
|-------|--------------|
| `from-design-md` | Maps a `DESIGN.md` frontmatter and prose, plus the stylesheets behind it, into a new Design System artifact, or re-syncs an existing one |

## How it works

The Design System artifact type ships its own authoring instructions inside every system
(`SKILL.md` and `artifact-type/reference/*.md`). The skill reads those from the target first and
defers to them for every file shape, cap and publish call. What it adds is the DESIGN.md mapping
and a few firm choices:

- **The stylesheet is truth; DESIGN.md is intent.** Where they disagree, the code's value and unit
  win, and the disagreement is reported.
- **Contrast is measured, never estimated.** `design-system-contrast`, on the Bash tool's PATH
  through the plugin's `bin/`, prints the WCAG 2 ratio of each token pair in every theme, floored to
  two decimals so a near-miss never rounds up to a pass.
- **Components are static.** Each preview is hand-written from the source rule it names, with
  interaction states shown through `data-state` attributes. No component library is built or run.
- **The publish is checked on the remote.** The file listing, the index and the ratios are read
  back before the system is reported as done.

## Install

```bash
/plugin marketplace add shawn-sandy/agentics
/plugin install design-system-tools@agentics-kit
```

Local testing:

```bash
claude --plugin-dir ./kit/plugins/design-system-tools
```

## Usage

```text
/design-system-tools:from-design-md ~/repos/astro-basics
Turn this repo's DESIGN.md into a design system
Re-sync https://claude.ai/artifact/<id> from DESIGN.md
```

With no system URL, the skill makes a new one named after the `DESIGN.md` `name`. With a URL, it
merges into that system and keeps anything added on the page.

## Requirements

- An Artifact tool that can publish files (Claude Code or Cowork).
- A local checkout of the repository, or `owner/name` to clone.
- Node.js, for the contrast script.

## Plugin Structure

```
design-system-tools/
├── .claude-plugin/
│   └── plugin.json
├── README.md
├── CHANGELOG.md
├── bin/
│   └── design-system-contrast   # bare-name wrapper for scripts/contrast.mjs
└── skills/
    └── from-design-md/
        ├── SKILL.md
        └── scripts/
            └── contrast.mjs     # WCAG 2 contrast per token pair, per theme
```

## Components

- **Skill:** `from-design-md` — auto-activates on requests to turn a `DESIGN.md` into a design
  system; also invocable as `/design-system-tools:from-design-md`.

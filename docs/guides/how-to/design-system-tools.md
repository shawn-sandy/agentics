# How do I... design-system-tools

Keeps a repository's `DESIGN.md` honest and publishes it — find drift, rebrand the tokens, then publish as a claude.ai Design System artifact. The skills run in the order align, customize, publish.

Install: `/plugin marketplace add shawn-sandy/agentics`, then `/plugin install design-system-tools@agentics-kit`

## from-design-md

Turns a `DESIGN.md` (YAML frontmatter plus prose) into a Design System artifact that other agents read before building on the brand.

- **Command** — `/design-system-tools:from-design-md [repo path, owner/name, or an existing system URL]`
- **Say it instead** — "Turn this repo's DESIGN.md into a design system"
- **What happens** — Reads `DESIGN.md` and the stylesheets that declare its tokens, creates a Design System artifact (or reads the one you named), and reads that type's own authoring rules from it. It shows the inventory and asks which components to include. It then writes `tokens.json` in every theme, a README brand book of rules that name tokens, a static preview and README per component, and a cover. Every contrast ratio in a note comes from the bundled `contrast.mjs` checker. After one publish, it re-reads the remote file listing, the index and the ratios before reporting.
- **Watch out** — The stylesheet wins wherever it disagrees with `DESIGN.md`, and the disagreements are listed in the final report rather than in the system. Previews are static and hand-written: no component library is built or run. Passing a system URL re-syncs and merges into it; leaving it out always creates a new system.

## customize-design

Rebrands a `DESIGN.md` project's tokens in every theme scope, or lays a brand sheet over a few sections.

- **Command** — `/design-system-tools:customize-design`
- **Say it instead** — "Rebrand this site's colours to our new brand"
- **What happens** — Step 0 finds the token file, its dark scopes, the build command and the Markdown mirrors by grep and confirms them with you once. Path A rebrands every scope; Path B lays a brand sheet over some sections. The bundled `contrast.mjs` prints the eight contrast ratios, and `scaffold.mjs` writes the seven-token direction in three scopes plus a starter `DESIGN.md` for a project with no tokens, darkening a too-light brand colour until it measures. It hands off to `/design-system-tools:from-design-md` by name.
- **Watch out** — It edits token files and mirrors, so it exits plan mode first. Run `align-design-md` before it and `from-design-md` after it.

## align-design-md

Finds where `DESIGN.md` drifted from the component code.

- **Command** — `/design-system-tools:align-design-md`
- **Say it instead** — "Check whether DESIGN.md still matches the components"
- **What happens** — Inventories the record, locates each component's source, lists every literal in its style block, and prints a drift table fixed by `references/drift-checklist.md` so two runs agree. On your confirmation it rewrites the record and every mirror.
- **Watch out** — A control under a stated size floor is reported in the table and never changed. Nothing is rewritten until you confirm.

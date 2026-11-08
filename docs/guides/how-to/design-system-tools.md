# How do I... design-system-tools

Aligns, rebrands, and publishes a repository's `DESIGN.md` and the stylesheets behind it as a claude.ai Design System artifact. The three skills run in the order align, customize, publish.

Install: `/plugin marketplace add shawn-sandy/agentics`, then `/plugin install design-system-tools@agentics-kit`

## align-design-md

Finds where `DESIGN.md` has drifted from the component code and brings the record back in step.

- **Command** — `/design-system-tools:align-design-md`
- **Say it instead** — "Check whether DESIGN.md still matches the components"
- **What happens** — Compares `DESIGN.md`'s frontmatter and prose with each component's style block and prints a drift table, using the fixed rules in `references/drift-checklist.md` so two runs agree. On your confirmation it rewrites the record and every Markdown mirror.
- **Watch out** — A control under a stated size floor is reported in the table and never changed. Nothing is rewritten until you confirm.

## customize-design

Rebrands a `DESIGN.md` project's tokens in every theme scope.

- **Command** — `/design-system-tools:customize-design`
- **Say it instead** — "Change this site's brand colours to our new palette"
- **What happens** — Step 0 finds the token file, its dark scopes, the build command and the Markdown mirrors by search and confirms them once. Path A rebrands every scope; Path B lays a brand sheet over a few sections. It measures contrast with the bundled `scripts/contrast.mjs` (SCSS `direction-*` mixins, plain CSS `:root` and dark scopes, or a `DESIGN.md` `colors:` map). A project with no tokens gets the seven-token direction in three scopes plus a starter `DESIGN.md` from `scripts/scaffold.mjs`.
- **Watch out** — The scaffold darkens a brand colour that is too light until it measures. When done it hands off to `/design-system-tools:from-design-md` by name rather than publishing itself.

## from-design-md

Turns a `DESIGN.md` (YAML frontmatter plus prose) into a Design System artifact that other agents read before building on the brand.

- **Command** — `/design-system-tools:from-design-md [repo path, owner/name, or an existing system URL]`
- **Say it instead** — "Turn this repo's DESIGN.md into a design system"
- **What happens** — Reads `DESIGN.md` and the stylesheets that declare its tokens, creates a Design System artifact (or reads the one you named), and reads that type's own authoring rules from it. It shows the inventory and asks which components to include. It then writes `tokens.json` in every theme, a README brand book of rules that name tokens, a static preview and README per component, and a cover. Every contrast ratio in a note comes from the bundled `contrast.mjs` checker. After one publish, it re-reads the remote file listing, the index and the ratios before reporting. Checks both themes through colour-scheme emulation, and reads heading ceilings from the rendered page's computed `font-size`.
- **Watch out** — The stylesheet wins wherever it disagrees with `DESIGN.md`, and the disagreements are listed in the final report rather than in the system. Previews are static and hand-written: no component library is built or run. The static route always ships a one-line `components/bundle.js` stub, since the page renders no preview without it, and `type.families` values are capped at 200 characters. Passing a system URL re-syncs and merges into it; leaving it out always creates a new system.

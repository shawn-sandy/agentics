# How do I... design-system-tools

Keeps a repository's `DESIGN.md` true to its stylesheets and publishes both as a claude.ai Design System artifact. The three skills run in the order align, customize, publish.

Install: `/plugin marketplace add shawn-sandy/agentics`, then `/plugin install design-system-tools@agentics-kit`

## align-design-md

Finds where `DESIGN.md` has drifted from the component code and brings the record back in step.

- **Command** — `/design-system-tools:align-design-md`
- **Say it instead** — "Check whether DESIGN.md still matches the components"
- **What happens** — Inventories what the `DESIGN.md` frontmatter and prose claim, locates each component's style block, and prints a drift table using the fixed rules in `references/drift-checklist.md`, so two runs on the same tree agree. On your confirmation it rewrites `DESIGN.md` and every file that mirrors it.
- **Watch out** — It never edits a source file. When the code breaks a rule the record states (a control under a stated size floor, for example), the row is reported and you decide which side moves.

## customize-design

Rebrands a project's tokens — accent and neutral colours, fonts, corners — in every theme scope.

- **Command** — `/design-system-tools:customize-design`
- **Say it instead** — "Change this site's accent colour to #185c53"
- **What happens** — Step 0 discovers the token file, its dark scopes, the build command and the Markdown mirrors by grep and asks you to confirm them once. Path A rebrands every scope; Path B lays a brand sheet over a few sections. The bundled `contrast.mjs` measures eight text pairs in both themes, and `scaffold.mjs` writes a starter token file and `DESIGN.md` for a project with none, darkening a brand colour that is too light until it measures. It then hands off to `/design-system-tools:from-design-md` by name.
- **Watch out** — The stylesheet is changed first and the spec made to match it. Every text pair must reach 4.5:1 in both themes; a value the script cannot measure (`hsl()`, `oklch()`, `var()`, translucent) exits 2 and must be measured by hand, never guessed.

## from-design-md

Turns a `DESIGN.md` (YAML frontmatter plus prose) into a Design System artifact that other agents read before building on the brand.

- **Command** — `/design-system-tools:from-design-md [repo path, owner/name, or an existing system URL]`
- **Say it instead** — "Turn this repo's DESIGN.md into a design system"
- **What happens** — Reads `DESIGN.md` and the stylesheets that declare its tokens, creates a Design System artifact (or reads the one you named), and reads that type's own authoring rules from it. It shows the inventory and asks which components to include. It then writes `tokens.json` in every theme, a README brand book of rules that name tokens, a static preview and README per component, and a cover. Every contrast ratio in a note comes from the bundled `contrast.mjs` checker. After one publish, it re-reads the remote file listing, the index and the ratios before reporting.
- **Watch out** — The stylesheet wins wherever it disagrees with `DESIGN.md`, and the disagreements are listed in the final report rather than in the system. Previews are static and hand-written: no component library is built or run. The static route always ships a one-line `components/bundle.js` namespace stub (without it the page renders no preview), `type.families` values are capped at 200 characters, and the cover and previews are checked in both themes. Passing a system URL re-syncs and merges into it; leaving it out always creates a new system.

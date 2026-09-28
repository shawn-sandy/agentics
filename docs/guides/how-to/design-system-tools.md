# How do I... design-system-tools

Publishes a repository's `DESIGN.md` and the stylesheets behind it as a claude.ai Design System artifact.

Install: `/plugin marketplace add shawn-sandy/agentics`, then `/plugin install design-system-tools@agentics-kit`

## from-design-md

Turns a `DESIGN.md` (YAML frontmatter plus prose) into a Design System artifact that other agents read before building on the brand.

- **Command** — `/design-system-tools:from-design-md [repo path, owner/name, or an existing system URL]`
- **Say it instead** — "Turn this repo's DESIGN.md into a design system"
- **What happens** — Reads `DESIGN.md` and the stylesheets that declare its tokens, creates a Design System artifact (or reads the one you named), and reads that type's own authoring rules from it. It shows the inventory and asks which components to include. It then writes `tokens.json` in every theme, a README brand book of rules that name tokens, a static preview and README per component, and a cover. Every contrast ratio in a note comes from the bundled `design-system-contrast` command. After one publish, it re-reads the remote file listing, the index and the ratios before reporting.
- **Watch out** — The stylesheet wins wherever it disagrees with `DESIGN.md`, and the disagreements are listed in the final report rather than in the system. Previews are static and hand-written: no component library is built or run. Passing a system URL re-syncs and merges into it; leaving it out always creates a new system.

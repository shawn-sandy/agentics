# How do I... content-tools

Turns work products — HTML artifacts and Markdown files — into draft posts for a static site.

Install: `/plugin marketplace add shawn-sandy/agentics`, then `/plugin install content-tools@agentics-kit`

## artifact-to-post

Converts a local `.html` artifact, pasted HTML, or a `.md` file into a draft post for a static site generator, keeping interactive blocks alive instead of flattening them to screenshots.

- **Command** — `/content-tools:artifact-to-post [path to .html or .md]`
- **Say it instead** — "Turn this artifact into a blog post"
- **What happens** — Runs a blocking `security-scrub` on the source, loads every site-specific value from a project-root `CONTENT.md`, places each block on the fidelity ladder (native Markdown, scoped inline HTML, scoped HTML plus script, screenshot last), escapes prose for MDX, and writes the post into the configured `posts_dir` with the draft flag on its unpublished value.
- **Watch out** — claude.ai artifact URLs are refused: run `social-media-tools:save-artifact` first and point this skill at the `.html` it writes. Without `social-media-tools` installed the scrub cannot run, and the skill writes nothing.

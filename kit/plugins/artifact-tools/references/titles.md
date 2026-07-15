# Artifact titles

The title names the artifact in the browser tab and in the user's gallery, for as
long as the artifact exists. Read this before setting one.

Set it as the page's `<title>` for HTML sources, or as frontmatter `title:` for
Markdown sources.

## Rules

- **A bare subject.** A noun phrase naming what the artifact is *about*. No type
  prefix, no repo name, no branch name.
  Good: `Artifact title generation`. Bad: `Diff: agentics artifact title generation`.
- **Around 60 characters.** Never cut mid-word. Too long means write a shorter
  subject — not a truncated one.
- **Sentence case.** Title Case is not required and reads worse.
- **Derive it from the content, not from the request.** A verbatim slice of what
  the user typed is not a title.
  - diff — the changed files and the theme they share
  - plan — the plan's objective
  - session — the work that actually got done
  - prompt — what the prompt is *for*; its H1 usually already says so. The
    library page's subject is the collection, not any one prompt.
- **Stable across republishes.** The title is how the user finds their tab again.
  Change it only on a hard pivot in what the artifact covers.
- **Never a placeholder.** `Untitled`, `Session export`, `Artifact`, or an empty
  title are all failures. With no subject in reach, name the most specific
  concrete thing the content touches.
- **When another tool renders the title, these rules cover the part you control.**
  A prefix baked into a generator and unreachable from its source — plan HTML's
  `Plan: ` is the one live case — is out of scope. Check the subject after it.

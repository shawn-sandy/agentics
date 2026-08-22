# Re-render failure modes

Loaded when `plan-agent-render` exits non-zero. A clean exit needs nothing from
this file.

Two failures, and they call for opposite responses. Telling them apart is the
whole point of reading this.

## The spec broke the format

A non-zero exit naming a **missing or malformed section** means the spec edit
broke the format — a heading renamed, a required section emptied, frontmatter
truncated by an embedded newline or a bare `---`.

Fix the markdown and re-run. Never hand-edit the HTML to compensate: the HTML
is generated output, and the next re-render discards whatever was patched into
it, so a hand-fix reads as success and silently reverts.

## The environment broke

Any other failure — `MODULE_NOT_FOUND`, a missing renderer, a node crash — is
an environment problem, not a spec problem.

Report it and stop. Never rewrite a valid spec to satisfy a broken renderer:
the spec is the source of truth, and editing it here corrupts the one artifact
that survives the session.

## Why run it at all

The `render-plan-html.py` hook also re-renders on each spec write. Run the
command anyway, so a parse failure surfaces at the step that caused it rather
than silently inside a hook whose stderr nobody is reading.

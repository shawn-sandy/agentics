# Re-render: where the output goes, and failure modes

Loaded when `plan-agent-render` exits non-zero, or when the plan has no sibling
`<stem>.html`. A clean exit on a file-delivered plan needs nothing from here.

## Where the rendered HTML goes

`<stem>.html`'s existence beside the spec is the file-published signal, and it
decides the output path.

**Sibling exists** — the plan was delivered as a file. Overwrite it in place:

```bash
plan-agent-render "<stem>.md" -o "<stem>.html"
```

**No sibling** — the plan was published to a claude.ai artifact and its URL is
in the spec's `artifact-url:`. Render to the scratchpad, then call `Artifact`
with that path and `url: <the artifact-url>` so the shared page updates instead
of becoming a second copy:

```bash
plan-agent-render "<stem>.md" -o "$SCRATCHPAD/<stem>.html"
```

Never write `<stem>.html` in this case. Doing so resurrects the file the author
chose not to publish, and it flips the plan's gallery card off the artifact and
onto a local path — `build-index.sh` gives a sibling priority over the URL.

A spec with neither a sibling nor an `artifact-url:` has nowhere to publish.
Render to the scratchpad anyway so a format error still surfaces, mention it in
one line, and carry on — this is a plan delivered before artifact publishing
existed, or one whose publish failed.

## Failure modes

Two failures, and they call for opposite responses. Telling them apart is the
whole point of reading this section.

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

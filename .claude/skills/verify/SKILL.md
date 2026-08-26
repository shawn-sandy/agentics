---
name: verify
description: Runtime-verification recipe for this repo's plan-agent CLI surfaces — how to drive the renderer and hub bundler and observe their HTML output in a real browser.
---

# Verifying plan-agent CLI changes at runtime

The runtime surfaces here are the plugin bin CLIs and the HTML pages they
emit. Do not verify by running the test suite — that is CI's job.

## Handles

- Renderer: `kit/plugins/plan-agent/bin/plan-agent-render <spec>.md -o <out>.html`
- Hub bundler: `kit/plugins/plan-agent/bin/plan-agent-hub <spec>.md -o <hub>.html [--extra <p>]... [--skip <p>]... [--max-bytes <n>]`
- Invoke the bin wrappers by absolute path in a plain shell (bare names only
  resolve when the plugin is enabled in the session).

## Minimal fixture

A parseable spec needs `# Plan: <title>`, `## Objective`, `## Steps` with
numbered `N. action Why: ... Verify: ...` items, `## Acceptance Criteria`
bullets, and `## Verification`. Frontmatter `prototype: <path>` resolves
against the cwd first, then the spec's directory — so a fixture spec and
prototype in one temp dir work with `cwd` set to that dir.

## Observing the output

Playwright (plugin:playwright MCP) blocks `file:` URLs. Serve the output
dir instead:

```bash
python3 -m http.server <port> --bind 127.0.0.1 --directory <dir>
```

(background it; stop it when done). Then `browser_navigate` to
`http://127.0.0.1:<port>/<file>.html`. The server's missing `/favicon.ico`
is the one expected console 404 — not a page defect. Reach inside embedded
panels with `document.querySelector('#panel-N iframe').contentDocument`.
Test dark mode via `page.emulateMedia({ colorScheme: 'dark' })` in
`browser_run_code_unsafe`.

## Worth probing

Exit codes: 2 = misuse (usage on stderr), 1 = unreadable/unparseable input
or size-cap overflow (stderr names the offending file). `--max-bytes` tiny
values exercise the overflow + `--skip` retry path end to end.

# Building the prompt page

Loaded by `prompt-artifact` Step 5.

Load the `artifact-design` skill first to calibrate design investment, then
`Write` one self-contained `.html` file to the scratchpad.

## Contents

- [Both modes](#both-modes)
- [Single mode](#single-mode)
- [Library mode](#library-mode)
- [The copy button](#the-copy-button)

## Both modes

- **Self-contained** — a strict CSP blocks every external request. Inline all
  CSS and JS; no CDN links, no web fonts, no remote images, no fetch.
- **Theme-aware** — `@media (prefers-color-scheme: dark)` for the default
  signal, plus `:root[data-theme="dark"]` / `:root[data-theme="light"]`
  overrides so the viewer's theme toggle wins in both directions.
- **Escape every value read from the `.md`** — not just the prompt body. Prompts
  are full of XML tags (`<context>`, `<instructions>`), and so are the titles and
  intents describing them: a prompt titled `# Summarize <document>` breaks the
  page from the `<title>`, the card heading, or a `data-type` attribute just as
  surely as from the `<pre>`. Escape `&`, `<`, `>` in text, and additionally `"`
  and `'` in anything interpolated into an attribute:

  | Value | Lands in |
  |-------|----------|
  | H1 title | `<title>`, card heading |
  | `intent` | card body text |
  | `techniques`, `created`, `modified` | metadata row |
  | `type` | chip text **and** `data-type="…"` |
  | prompt body | `<pre>` |

  Escaping the body alone leaves the other five as injection points.
- **Set a `<title>` per `${CLAUDE_PLUGIN_ROOT}/references/titles.md`** — read it
  first. A prompt's H1 is usually already a bare subject and can stand as the
  title; the derived subject is the prompt's *goal*, not the text of the prompt
  itself. In library mode the subject is the collection (`Prompt library`), not
  any one prompt. Write the page content only (no `<!doctype>`/`<html>`/`<head>`
  /`<body>` — those are added at publish time).

## Single mode

Renders the H1 as the title, a metadata row (`type`, `techniques`, `created`),
and the prompt in one `<pre>` block with its copy button.

## Library mode

Renders one card per prompt — title, `type` chip, `intent`,
`created`, and `modified` when the frontmatter carries it (omit the field
entirely when absent, rather than rendering an empty slot). A `proposal` prompt
is a living document rewritten in place, so `created` alone makes an actively
deepening proposal look untouched since the day it was started. Each card
carries the full body expandable in place (`<details>` needs no JS) and its own
copy button. Filter chips by `type` (`task`, `system`,
`creative`, `analytical`, `proposal`) hide and show cards via inlined JS; carry
the value on `data-type` and follow `plans-library`'s card and filter idiom
rather than inventing a second one. A type with no saved prompts still gets its
chip — an absent chip reads as a broken filter, an empty one reads as an empty
category. Sort newest-first by `created` (`YYYY-MM-DD` strings compare
correctly), empty `created` last, ties broken by title ascending.

`proposal` bodies run several hundred lines — roughly 3x anything else in the
directory. The existing `<details>` collapse already keeps them out of the way
until opened; give the `<pre>` `overflow-x: auto` so a wide markdown table
scrolls inside its own card instead of widening the page. The page body must
never scroll horizontally at mobile width. No type-specific CSS beyond that.

## The copy button

Copy from the DOM, not from a duplicated copy of the text:

```html
<pre id="p1">{{ESCAPED_PROMPT}}</pre>
<button data-copy="p1">Copy</button>
<script>
document.querySelectorAll('[data-copy]').forEach(function (b) {
  b.addEventListener('click', function () {
    var pre = document.getElementById(b.dataset.copy);
    var ok = function () {
      b.textContent = 'Copied';
      setTimeout(function () { b.textContent = 'Copy'; }, 1500);
    };
    // Clipboard API missing or denied: select the text so Cmd/Ctrl-C still works.
    var manual = function () {
      var r = document.createRange();
      r.selectNodeContents(pre);
      var sel = getSelection();
      sel.removeAllRanges();
      sel.addRange(r);
      b.textContent = 'Selected — press Cmd/Ctrl-C';
    };
    if (!navigator.clipboard) { manual(); return; }
    navigator.clipboard.writeText(pre.textContent).then(ok, manual);
  });
});
</script>
```

`textContent` returns the entities already decoded, so the escaping above
round-trips back to the exact source text. Three things break that guarantee:

- **No newline after `<pre>`.** The HTML parser drops one immediately following
  the open tag, and the copied prompt loses its first line break.
- **No prettifying the `<pre>`.** Indenting it to match surrounding markup
  indents every copied line with it.
- **Never leave `writeText` unhandled.** It rejects on a denied permission, and
  is absent outside a secure context — which is exactly the Step 8 fallback page
  opened over `file://`. An unhandled rejection makes the button do nothing at
  all, silently, on the one path where the page is the only deliverable. Hence
  the rejection handler above: selecting the `<pre>` contents leaves the user one
  keystroke from the same result, and copies the same verbatim text.

# UI Previews

A `## Previews` item is one self-contained HTML document, written inline in the
spec, that the renderer turns into a live, isolated preview on the plan page —
the component change sitting next to the step that makes it, clickable before
anything is built. `/plan-agent:build` treats each preview as the structure
target for the steps it tags, so a preview is a contract, not an illustration.
Read this file when Step 2 says previews apply.

## When to author them

- **Only when the plan carries UI signals.** Apply the `ui_signals_present`
  rule in `skills/review-plan/SKILL.md`, "Step 3b — Detect UI signals", to the
  drafted spec. That file owns the keyword list; do not restate it here or in
  the spec.
- **Never under `--quick`.** It skips exploration, and a faithful preview needs
  the project's tokens, which exploration finds.
- **One preview per distinct component or surface that changes** — not one per
  step. A component two steps share is one preview tagging both steps. A step
  with nothing visible (a version bump, a test file, a parser change) gets no
  preview.
- **Not a whole flow and not an artboard.** A multi-screen flow belongs in
  `/plan-agent:prototype`; an editable design belongs on a
  `/plan-agent:design` canvas, whose `.dc.html` artboards load `./support.js`.
  A preview is one document with nothing outside it.

## Item syntax

The section mirrors `## Next Steps`. Each top-level `- ` bullet is one preview:

````markdown
## Previews

- <label> (step N)
  <description: what it shows, which tokens it copied from where, and the
  measured contrast>
  ```html
  <!doctype html>
  <html lang="en">
  …
  </html>
  ```
````

- **Bullet line** — the label, shown as the figure caption. An optional
  trailing `(step N)` or `(steps N, M)` tag names the steps that build it; each
  tagged step card gets a `preview` chip linking to the figure. An untagged
  preview still renders, with no chip.
- **Indented lines** — the description, rendered under the caption. Cite the
  stylesheet the tokens came from and record the contrast result here.
- **The fenced `html` block** — the preview document. Indent the fence and its
  body under the bullet; the common indent is stripped. One block per item.
- **Fence length** — if the document contains a run of three backticks (a code
  sample inside the preview), the outer fence must use more backticks than any
  run inside it, exactly as with Next Steps prompts.

The renderer fails the render, naming the item, on any of these:

- no html block, or more than one fenced block;
- no `<html` tag at the top, where only a doctype and comments may come before
  it (theme sync works by rewriting that tag, so a fragment would silently
  ignore the plan's toggle);
- an empty label;
- a step tag it cannot read: `(steps 2-4)` (list the steps instead), or a
  valid tag with text after it;
- a tag naming a step beyond the plan's step count.

Place the section after `## Verification` and before `## Next Steps`; the
rendered page puts it after Steps either way.

## How it renders

Each item becomes a `<figure class="plan-preview">` holding an `<iframe>`
that loads the document from a `data:` URL. Scripts run, and the frame has an
opaque origin, so it cannot touch the plan page. There is no `sandbox`
attribute on purpose: a sandboxed frame never paints inside the claude.ai
artifact viewer in the desktop app. Author for that:

- `parent.document`, `localStorage`, `sessionStorage`, and cookies are out of
  reach and throw. Keep state in memory.
- The frame is 320px tall and the reader can drag it taller. Lay the states out
  so the important ones show in the first 320px.
- Frames load eagerly, so Save as PDF prints every preview.
- An in-page link (`href="#id"`) is a jump inside the preview. Any relative URL
  other than a fragment resolves to nothing, which the no-external rule below
  already rules out.
- A native form submit reloads the preview and loses its state. Use
  `type="button"`, or handle `submit` and call `event.preventDefault()`.
- The plan's theme toggle reaches the preview by setting `data-theme` on the
  preview's `<html>`. Setting `color-scheme` on the iframe does not change
  `prefers-color-scheme` inside it, which is why the `:root[data-theme=…]`
  guards below are required rather than optional.

## The authoring contract

Every preview meets all of these before the plan is delivered:

- **A full document.** `<!doctype html>`, an `<html lang="…">` tag, `<head>`
  with `<meta charset="utf-8">`, `<body>`. Not a fragment.
- **Nothing external.** No `src`/`href` to another URL, no web fonts, no CDN
  scripts, no images from the network. Inline everything; use system fonts.
- **Tokens on `:root`, dark override twice.** Light values on `:root`; the dark
  values under both `:root:not([data-theme="light"])` inside
  `@media (prefers-color-scheme: dark)` (follows the reader's OS, but lets the
  toggle force light) and `:root[data-theme="dark"]` (lets the toggle force
  dark on a light OS). Missing either one breaks one direction of the toggle.
- **The project's real token values.** Copy them from the project's stylesheet
  (found in Step 0b) and cite the file and token names in the description. A
  project with no tokens gets the colours its components actually use, cited
  the same way. Never invent a palette.
- **Every state side by side.** Default, hover or focus, disabled, error, empty,
  and loading — whichever the component has — each labelled, all visible at
  once, so a reviewer compares them without clicking. A state CSS cannot hold
  statically (focus, hover) gets a class sharing the real selector:
  `.btn:focus-visible, .btn.is-focus { … }`.
- **Semantic, accessible markup.** Real `<button>`, `<label for>`, `<input>`;
  errors wired with `aria-invalid` and `aria-describedby`; a visible focus
  indicator on every interactive element.
- **Reduced motion honoured.** Any animation or transition stops under
  `@media (prefers-reduced-motion: reduce)`.
- **`<\/script>` inside scripts.** A literal closing script tag in a string or
  comment ends the element early; escape it as `<\/script>`, the same rule
  `/plan-agent:prototype` enforces.
- **No real data.** No real names, emails, or credentials (API keys, access
  tokens) — placeholders such as `Display name` and `user@example.com` only.
- **Compact.** Under about 4 KB per preview: every implementing agent reads the
  whole spec, previews included.

## Measure contrast — never estimate

Measure every text and UI-part colour pair with a tool, in both themes, and fix
any failure before delivery: **4.5:1** for body text, **3:1** for large text
(24px, or 18.66px bold) and UI parts (input borders, focus rings, icons).
Disabled controls are exempt under WCAG (the web accessibility guidelines)
1.4.3; measure them anyway and say they are exempt. A WCAG relative-luminance
script over the token values:

```bash
node -e '
const lum = (h) => { const c = [1, 3, 5].map((i) => parseInt(h.slice(i, i + 2), 16) / 255)
  .map((v) => (v <= 0.04045 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4));
  return 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2]; };
for (const pair of process.argv.slice(1)) {
  const [hi, lo] = pair.split(":").map(lum).sort((a, b) => b - a);
  console.log(pair, (Math.floor(((hi + 0.05) / (lo + 0.05)) * 100) / 100).toFixed(2) + ":1");
}' '#5c5c70:#ffffff' '#10142a:#8fb0ff'
```

It takes six-digit hex `foreground:background` pairs and floors to two
decimals, so 4.499 never prints as 4.50. Record the lowest text pair and the
lowest UI pair in the description; a number with no run behind it does not go
in the spec.

## Worked example

A plan whose steps 2 and 3 add a Save button and a required display-name field
to a settings form, in a project whose tokens live in `src/styles/tokens.css`.
The ratios below came from running the script above on these exact values.

````markdown
## Previews

- Save button and display-name field states (steps 2, 3)
  Tokens copied from src/styles/tokens.css (`--bg`, `--sunk`, `--fg`, `--muted`, `--border`, `--accent`, `--accent-fg`, `--danger`). Contrast measured with the WCAG relative-luminance script, 14 pairs across both themes: lowest text pair 5.74:1 (light disabled label, exempt), lowest UI pair 3.38:1 (light input border); every pair passes.
  ```html
  <!doctype html>
  <html lang="en">
  <head>
  <meta charset="utf-8">
  <title>Save button states</title>
  <style>
    :root { --bg:#ffffff; --sunk:#f0f0f5; --fg:#1a1a24; --muted:#5c5c70; --border:#8a8a9c; --accent:#2f5bd3; --accent-fg:#ffffff; --danger:#b42318; }
    @media (prefers-color-scheme: dark) {
      :root:not([data-theme="light"]) { --bg:#15151c; --sunk:#22222c; --fg:#ececf2; --muted:#a3a3b5; --border:#6e6e85; --accent:#8fb0ff; --accent-fg:#10142a; --danger:#ff8a80; }
    }
    :root[data-theme="dark"] { --bg:#15151c; --sunk:#22222c; --fg:#ececf2; --muted:#a3a3b5; --border:#6e6e85; --accent:#8fb0ff; --accent-fg:#10142a; --danger:#ff8a80; }
    body { margin:0; padding:16px; background:var(--bg); color:var(--fg); font:14px/1.45 system-ui, sans-serif; }
    .grid { display:grid; grid-template-columns:repeat(auto-fill, minmax(150px, 1fr)); gap:16px; }
    h2 { margin:0 0 6px; font-size:12px; color:var(--muted); text-transform:uppercase; letter-spacing:.06em; }
    label { display:block; margin-bottom:4px; }
    input { width:100%; box-sizing:border-box; font:inherit; padding:6px 8px; border:1px solid var(--border); border-radius:4px; background:var(--bg); color:var(--fg); }
    input[aria-invalid="true"] { border-color:var(--danger); }
    .err { margin:4px 0 0; color:var(--danger); }
    .btn { display:inline-flex; align-items:center; gap:8px; min-height:44px; padding:0 16px; border:0; border-radius:4px; font:inherit; font-weight:600; background:var(--accent); color:var(--accent-fg); cursor:pointer; }
    .btn:focus-visible, .btn.is-focus { outline:2px solid var(--accent); outline-offset:2px; }
    .btn:disabled { background:var(--sunk); color:var(--muted); cursor:not-allowed; }
    .spin { width:12px; height:12px; border:2px solid currentColor; border-right-color:transparent; border-radius:50%; animation:spin .8s linear infinite; }
    @keyframes spin { to { transform:rotate(360deg); } }
    @media (prefers-reduced-motion: reduce) { .spin { animation:none; } }
  </style>
  </head>
  <body>
  <div class="grid">
    <section><h2>Default</h2><button class="btn" type="button" id="save">Save changes</button></section>
    <section><h2>Focus</h2><button class="btn is-focus" type="button">Save changes</button></section>
    <section><h2>Disabled</h2><button class="btn" type="button" disabled>Save changes</button></section>
    <section><h2>Loading</h2><button class="btn" type="button" aria-disabled="true"><span class="spin" aria-hidden="true"></span>Saving…</button></section>
    <section><h2>Error</h2>
      <label for="name">Display name</label>
      <input id="name" value="" aria-invalid="true" aria-describedby="name-err">
      <p class="err" id="name-err">Enter a display name.</p>
    </section>
  </div>
  <script>
    // The default button walks through the loading state and back, in memory only.
    var save = document.getElementById('save');
    save.addEventListener('click', function () {
      save.textContent = 'Saving…';
      setTimeout(function () { save.textContent = 'Save changes'; }, 1200);
    });
  </script>
  </body>
  </html>
  ```
````

What it demonstrates: both dark guards, the states laid out side by side with
focus held by `.is-focus`, the spinner stopped under reduced motion, the error
wired to its field, placeholder copy only, and 3,018 bytes of document.

## Before delivering

1. Render the spec (Step 5d). A non-zero exit names the item that hit one of
   the rejections under Item syntax — fix the spec and re-render.
2. Re-run the contrast script on any token you changed since the last run, and
   update the description's numbers from that output.
3. When a browser tool is available, open the rendered plan, click inside each
   preview, and flip the plan's theme toggle: the preview must respond and
   follow the theme in both directions.

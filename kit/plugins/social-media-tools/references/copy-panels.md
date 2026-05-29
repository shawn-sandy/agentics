# Copy Panels Reference

Used by all card-generating skills. Supplies the `{{COPY_PANELS}}` markup in the
saved HTML. Each template defines one shared `copyPost(id, btn)` function; every copy
button calls it with its own textarea `id`.

Platform names and panel IDs below must match the **Platform Options** in
`platforms.md`. When adding a platform, add a new `<div class="copy-panel">` block
following the same pattern.

| Field | Value |
|-------|-------|
| Variable | `{{COPY_PANELS}}` |
| Type | HTML — one or more `<div class="copy-panel">` blocks |
| Source | The drafted post copy from the Draft phase |
| Escaping | **Textarea-safe**, applied per variant in this order: `&` → `&amp;`, `<` → `&lt;`, `>` → `&gt;` (do **not** escape `"`) |

---

## Single site — one panel (default)

Textarea content is all platform variants joined with `\n---\n`, then escaped:

```html
<div class="copy-panel">
  <p class="copy-label">Social media post</p>
  <textarea readonly class="post-copy-text" id="post-copy">ESCAPED_COPY</textarea>
  <button class="copy-btn" onclick="copyPost('post-copy', this)">Copy post</button>
</div>
```

---

## All sites — four per-site panels

One panel per platform, each holding only that platform's escaped copy under a unique `id`:

```html
<div class="copy-panel">
  <p class="copy-label">LinkedIn</p>
  <textarea readonly class="post-copy-text" id="post-copy-linkedin">ESCAPED_LINKEDIN</textarea>
  <button class="copy-btn" onclick="copyPost('post-copy-linkedin', this)">Copy LinkedIn post</button>
</div>
<div class="copy-panel">
  <p class="copy-label">Twitter/X</p>
  <textarea readonly class="post-copy-text" id="post-copy-twitter">ESCAPED_TWITTER</textarea>
  <button class="copy-btn" onclick="copyPost('post-copy-twitter', this)">Copy Twitter/X post</button>
</div>
<div class="copy-panel">
  <p class="copy-label">Bluesky</p>
  <textarea readonly class="post-copy-text" id="post-copy-bluesky">ESCAPED_BLUESKY</textarea>
  <button class="copy-btn" onclick="copyPost('post-copy-bluesky', this)">Copy Bluesky post</button>
</div>
<div class="copy-panel">
  <p class="copy-label">Substack</p>
  <textarea readonly class="post-copy-text" id="post-copy-substack">ESCAPED_SUBSTACK</textarea>
  <button class="copy-btn" onclick="copyPost('post-copy-substack', this)">Copy Substack post</button>
</div>
```

---

## Notes

- Every panel keeps `class="post-copy-text"`, so reuse/extraction (`media-library` and each
  skill's reuse check) matches **by class** — one textarea for a single site, four for all
  sites — and labels each by its preceding `copy-label`.
- Content inside `<textarea>` is parsed as HTML character data: the browser decodes entities
  and shows raw text. Apply `&amp;` → `&lt;` → `&gt;`; do **not** escape `"`.

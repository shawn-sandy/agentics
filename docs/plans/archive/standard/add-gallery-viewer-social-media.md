# Plan: Social Media Gallery Viewer Page

## Context

The social-media-tools plugin saves generated social cards (HTML + PNG pairs) to `docs/media/social/` with filenames like `diff-add-copy-button-2026-05-27.html`. Currently, users can only browse saved cards via the CLI-based `media-library` skill, which outputs a markdown table. There's no way to visually browse all cards in a browser. The user wants a simple HTML page in that same folder so they can open it and view all their saved social cards whenever they choose — generated on-demand, not on every card save.

## Approach

Create a gallery HTML template and a dedicated on-demand skill. When the user invokes the `media-library` skill (e.g., "view my shares"), it scans `docs/media/social/`, populates the gallery template, writes `index.html`, and opens or presents the path. No changes to the card-saving workflow (`saving-and-delivery.md`).

## Changes

### 1. Create gallery template: `kit/plugins/social-media-tools/templates/gallery.html`

A self-contained HTML page matching the existing dark-mode design language (same CSS custom properties used by all card templates: `--bg: #0d1117`, `--surface: #161b22`, `--border: #30363d`, `--text: #e6edf3`, `--muted: #8b949e`, `--accent: #388bfd`).

**Layout:**
- Page title/header: "Social Media Gallery"
- Responsive CSS grid of card entries (auto-fill, ~280px min column width)
- Each entry is a clickable card showing:
  - PNG thumbnail via `<img>` (with a styled fallback if image fails to load)
  - Type badge (color-coded by card type)
  - Topic (humanized from slug — hyphens to spaces, title case)
  - Date
  - Link to open the full HTML card
- Footer with total card count and generation timestamp

**Template variable:** `{{GALLERY_ENTRIES}}` — replaced with the generated `<a>` card blocks when populating. `{{CARD_COUNT}}` and `{{GENERATED_AT}}` for the footer.

**Design details:**
- Card grid items: surface background, border-radius 8px, border, hover glow effect
- Thumbnails: `object-fit: cover`, fixed aspect ratio container
- Type badges: small colored pills, color-coded per card type
- No JavaScript dependencies — pure CSS grid, works on `file://` protocol
- `<img>` tags use `onerror` to show a CSS fallback placeholder with the card type text

### 2. Enhance media-library skill: `kit/plugins/social-media-tools/skills/media-library/SKILL.md`

Add a **"View gallery"** option to the Step 3 interactive actions. When selected, Claude:

1. Lists all `.html` files in `docs/media/social/` (excluding `index.html`)
2. Parses each filename into type, slug (humanized), and date
3. Sorts by date descending (newest first)
4. Reads the gallery template from `$PLUGIN_DIR/templates/gallery.html`
5. Builds the `{{GALLERY_ENTRIES}}` markup — one card `<a>` block per file, with `href` pointing to the HTML file and `<img src>` pointing to the matching PNG
6. Substitutes `{{CARD_COUNT}}` and `{{GENERATED_AT}}`
7. Writes the populated HTML to `docs/media/social/index.html`
8. Reports the path and opens in browser (via `open` / `xdg-open`)

Also update the skill description to mention gallery viewing as a capability.

### 3. Version bump and changelog

- **`.claude-plugin/marketplace.json`**: Bump `social-media-tools` version (MINOR bump — new feature)
- **`kit/plugins/social-media-tools/CHANGELOG.md`**: Add entry for the gallery viewer

## Files to modify

| File | Action |
|------|--------|
| `kit/plugins/social-media-tools/templates/gallery.html` | **Create** — gallery template |
| `kit/plugins/social-media-tools/skills/media-library/SKILL.md` | **Edit** — add "View gallery" option with generation logic |
| `.claude-plugin/marketplace.json` | **Edit** — version bump |
| `kit/plugins/social-media-tools/CHANGELOG.md` | **Edit** — add changelog entry |

## Verification

1. Confirm the gallery template renders correctly by opening it in a browser (with sample entries populated)
2. Verify the media-library skill's new option is consistent with the existing interactive pattern
3. Run `/validate-plugin social-media-tools` to check plugin structure
4. Confirm marketplace.json is valid JSON after version bump

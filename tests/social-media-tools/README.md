# social-media-tools Tests

Smoke and registration tests for the `share-react` skill and its `react-card.html` template, plus instructions for a manual end-to-end run of the full skill.

## Automated Tests

Run from the repository root (or any directory — the scripts resolve paths relative to themselves):

```bash
bash tests/social-media-tools/test-react-card-smoke.sh
bash tests/social-media-tools/test-share-react-registration.sh
```

Both scripts print per-check `PASS`/`FAIL` lines and exit `0` when everything passes, `1` otherwise.

### test-react-card-smoke.sh

Objective smoke test for `kit/plugins/social-media-tools/templates/react-card.html`:

1. Populates all eight `{{...}}` template variables with a sample `Button.tsx` component (HTML-escaped code, three props rows, a two-state preview pane).
2. Serves the populated card from a temp directory with `python3 -m http.server` on a free port (chosen by `scripts/find_free_port.py`).
3. Fetches the page with `curl` and asserts the rendered output contains the preview pane, the `language-tsx` code block, at least three props rows, an accessible props table (`th scope="col"`), the `--card-width` token in `:root`, and zero leftover `{{` placeholders.

The HTTP server is killed by a `trap` on `EXIT`, so no process is left running even when an assertion fails.

### test-share-react-registration.sh

Wiring test asserting the skill is fully registered:

1. `marketplace.json` lists `social-media-tools` at version `2.11.0`.
2. The `social-share` router's Phase 1 table contains a `share-react` rule, ordered before the `share-selection` rule (so `.tsx`/`.jsx` input routes to the React skill, not the generic selection skill).
3. `skills/share-react/SKILL.md` frontmatter declares `name: share-react`, a `description:` (value 200 characters or fewer), and an `allowed-tools:` line.
4. The plugin `README.md` mentions `share-react` and `react-card.html`.
5. `references/variables.md` documents a `react-card.html` section.

## Manual End-to-End Run

The automated tests do not exercise the live skill (Playwright screenshot, scrub gate, file saves). To verify the full pipeline by hand:

1. Load the plugin from the repository root:

   ```bash
   claude --plugin-dir ./kit/plugins/social-media-tools
   ```

2. Inside the session, invoke `share-react` on a sample component path, for example:

   ```text
   Share src/components/Button.tsx as a React component card for LinkedIn.
   ```

   Any `.tsx`/`.jsx` path works; pasting a fenced `tsx` code block also routes to `share-react` via the `social-share` router.

3. Expected outcome:

   - The `security-scrub` gate fires on the component source before any copy is drafted; the run stops if secrets are detected.
   - A card HTML file and screenshot are saved to `docs/media/social/` as `react-<slug>-<date>.html` and `react-<slug>-<date>.png`.
   - The card shows a static preview pane, the syntax-highlighted component source, and a typed props table; the post copy is delivered in the same turn.
   - No dangling `python3 -m http.server` process remains after the run — verify with:

     ```bash
     pgrep -fl "http.server" || echo "no dangling server"
     ```

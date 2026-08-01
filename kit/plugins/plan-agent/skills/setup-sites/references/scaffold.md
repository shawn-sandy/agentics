# Scaffolding the four artifacts

Loaded before Step 4. Covers Step 4 and its hub placeholder and card-pruning rules.

## Step 4 — Scaffold the four artifacts (idempotent)

Write each target only if it does not already exist. If it exists, **do not clobber** — report `exists, skipped` and move on, so re-running the skill is safe. Track what was created vs. skipped for the Step 7 summary.

**4a. The deploy workflow** → `.github/workflows/deploy-pages.yml` (verbatim, SHA-pinned):

```bash
mkdir -p .github/workflows
if [ -e .github/workflows/deploy-pages.yml ]; then
  echo "deploy-pages.yml: exists, skipped"
else
  cp "$TEMPLATES_DIR/deploy-pages.yml" .github/workflows/deploy-pages.yml
  echo "deploy-pages.yml: created"
fi
```

**4b. The no-Jekyll marker** → `docs/.nojekyll` (0-byte; without it Jekyll mangles underscore filenames and the build job fails its assertion):

```bash
if [ -e docs/.nojekyll ]; then echo ".nojekyll: exists, skipped"; else touch docs/.nojekyll; echo ".nojekyll: created"; fi
```

**4c. The local preview script** → `scripts/serve-docs.sh` (executable):

```bash
mkdir -p scripts
if [ -e scripts/serve-docs.sh ]; then
  echo "serve-docs.sh: exists, skipped"
else
  cp "$TEMPLATES_DIR/serve-docs.sh" scripts/serve-docs.sh && chmod +x scripts/serve-docs.sh
  echo "serve-docs.sh: created"
fi
```

**4d. The landing hub** → `docs/index.html`. Skip entirely if a `docs/index.html` already exists. Otherwise read `$TEMPLATES_DIR/hub.html`, substitute the three placeholders, and prune cards for galleries the repo does not use:

- `{{SITE_TITLE}}` → the repo name title-cased, or a name the user supplies.
- `{{SITE_TAGLINE}}` → a one-line description (ask the user, or default to "Browse generated plans and social cards.").
- `{{SITE_FOOTER}}` → the site title.
- **Card pruning** — each card is wrapped in `<!-- CARD:plans -->…<!-- /CARD:plans -->` and `<!-- CARD:social -->…<!-- /CARD:social -->`. Remove the `plans` card block if neither `docs/plans/` exists nor `plan-agent` is in use; remove the `social` card block if neither `docs/media/social/` exists nor `social-media-tools` is in use. If pruning would remove **both** (a fresh repo), keep both as scaffolding and tell the user to delete whichever they don't need.

Use Read to load the template and Write to emit `docs/index.html` with substitutions applied. **Never** introduce absolute-root links (`href="/..."`) — the project site is served under a path prefix, so they break. Keep the relative `plans/index.html` and `media/social/index.html` hrefs.

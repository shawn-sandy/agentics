# Enabling Pages, verifying, and delivering

Loaded before Step 5. Covers Steps 5, 6, and 7.

## Step 5 — Enable the one-time GitHub Pages source (Settings → Pages → Source = GitHub Actions)

Without this repo setting there is no Pages environment to deploy into, and the workflow has nowhere to land. This is an **outward-facing** change (it makes the repo publicly published), so confirm before doing it automatically.

Check whether `gh` is authenticated:

```bash
gh auth status >/dev/null 2>&1 && echo "GH_READY=yes" || echo "GH_READY=no"
```

- **If `GH_READY=yes`:** use `AskUserQuestion` to offer "Enable Pages now via gh" vs. "I'll do it manually". Only if the user picks the automatic path, run (idempotent — create, else update):

  ```bash
  gh api -X POST "repos/{owner}/{repo}/pages" -f build_type=workflow 2>/dev/null \
    || gh api -X PUT "repos/{owner}/{repo}/pages" -f build_type=workflow
  ```

  Substitute the real `owner`/`repo` from Step 1.

- **If `GH_READY=no`, or the user declines:** print the manual steps —
  > Open the repo on GitHub → **Settings → Pages → Build and deployment → Source → GitHub Actions**. (One-time; nothing publishes until this is set.)

---

## Step 6 — Verify the scaffold

Run fast structural checks and report a pass/fail line for each:

```bash
echo "--- verification ---"
test -f docs/.nojekyll && echo "PASS .nojekyll present" || echo "FAIL .nojekyll missing"
grep -q "upload-pages-artifact" .github/workflows/deploy-pages.yml && echo "PASS workflow installed" || echo "FAIL workflow missing"
! grep -Eq 'uses:[^#]*@v[0-9]' .github/workflows/deploy-pages.yml && echo "PASS actions SHA-pinned" || echo "FAIL an action is tag-pinned, not SHA-pinned"
if [ -f docs/index.html ]; then
  grep -q 'href="/' docs/index.html && echo "FAIL hub has absolute-root link(s)" || echo "PASS hub uses relative links"
fi
```

Any `FAIL` must be fixed before the user commits.

---

## Step 7 — Deliver and stop

Report concisely:

1. **What was created vs. skipped** (the Step 4 tally).
2. **The live URL** from Step 1 (or note it's pending a GitHub remote).
3. **Whether the Pages source is set** (done via gh, or the manual reminder).
4. **The exact next commands** the user runs to publish:

   ```bash
   git add docs .github/workflows/deploy-pages.yml scripts/serve-docs.sh
   git commit -m "chore: set up GitHub Pages publishing for docs/"
   git push origin main        # or open a PR and merge to main
   ```

   Only a push to `main` touching `docs/**` triggers a deploy; feature branches never publish.
5. **Preview locally first:** `bash scripts/serve-docs.sh` → open the printed `http://localhost:<port>/`.
6. **Gallery refresh asymmetry:** the *Plans* gallery index rebuilds automatically (the `rebuild-plans-index` hook). The *Social* gallery has no hook — run the `media-library` skill before committing a new card, or Pages deploys a stale index.

**STOP.** Do not commit, push, or invoke other skills automatically — the user commits when ready.

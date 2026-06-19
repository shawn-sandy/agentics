---
name: setup-sites
description: "Scaffolds GitHub Pages publishing into any repo. Adds the deploy workflow, .nojekyll, hub, and preview script so docs/ HTML reaches a public URL. Use when asked to set up or publish GitHub Pages."
allowed-tools: Bash, Read, Write, AskUserQuestion, ToolSearch, ExitPlanMode
---

# setup-sites

Scaffold the GitHub Pages deployment pipeline into the **current repository** so anything generated under `docs/` (plan galleries from `plan-agent`, social cards from `social-media-tools`, or any static HTML) publishes to a public URL. This drops four artifacts and guides the one-time GitHub setting — it does **not** generate plans or cards (the owning plugins do that) and does **not** commit (you commit when ready).

The pipeline it installs: a push to `main` touching `docs/**` fires a path-filtered Actions workflow that uploads `docs/` and deploys it to Pages. See the companion guide `docs/guides/publish-docs-to-github-pages.md` in the agentics repo for the full reference.

---

## Exit plan mode

`ExitPlanMode` is a deferred tool. **Only call it if currently in plan mode** — skip this step entirely when not in plan mode. When calling: use `ToolSearch` with `select:ExitPlanMode` first, then call `ExitPlanMode` silently. This skill performs filesystem writes, so it runs directly rather than producing a plan document.

---

## Step 1 — Preflight: confirm a git repo and resolve the live URL

Confirm the cwd is a git work tree, then derive the published URL from the `origin` remote. A project repo publishes under a path prefix (`https://<owner>.github.io/<repo>/`); a user/org root repo named `<owner>.github.io` publishes at the apex (`https://<owner>.github.io/`).

```bash
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  echo "Not inside a git repository. cd into your project first."; exit 1; }

python3 - <<'EOF'
import re, subprocess
try:
    url = subprocess.check_output(["git", "remote", "get-url", "origin"],
                                  text=True, stderr=subprocess.DEVNULL).strip()
except Exception:
    url = ""
owner = repo = ""
m = re.search(r'github\.com[:/]+([^/]+)/(.+?)(?:\.git)?/?$', url)
if m:
    owner, repo = m.group(1), m.group(2)
if not owner:
    print("REMOTE=none")
    print("Note: no GitHub origin remote found — using placeholders for the hub.")
elif repo.lower() == f"{owner.lower()}.github.io":
    print(f"REMOTE={owner}/{repo}")
    print(f"LIVE_URL=https://{owner}.github.io/")
    print("SITE_KIND=root  (served at the apex, no path prefix)")
else:
    print(f"REMOTE={owner}/{repo}")
    print(f"LIVE_URL=https://{owner}.github.io/{repo}/")
    print("SITE_KIND=project  (served under /%s/ — links MUST stay relative)" % repo)
EOF
```

Keep `owner`, `repo`, and the computed `LIVE_URL` for Steps 4, 5, and 7. If there is no remote, continue anyway with placeholder values and warn the user that the live URL is unknown until a GitHub remote exists.

---

## Step 2 — Resolve the docs directory and sanity-check `plansDirectory`

The deploy workflow uploads `docs/` and nothing else, so generated HTML must live under `docs/`. Two failure modes to close here:

1. **`plansDirectory` set but outside `docs/`** — plans would generate where Pages never looks. Warn and ask before proceeding.
2. **`plansDirectory` unset and `docs/plans/` missing** — `implementation-plan` resolves its output dir as `--dir` → `plansDirectory` → **`docs/plans/` only if it already exists** → otherwise the Claude *user* plans folder (outside the repo). So the very first plan after scaffolding would land outside `docs/` and never deploy. Seed `docs/plans/` now (with a committed `.gitkeep`) so that resolution rule lands inside `docs/`.

```bash
mkdir -p docs
python3 - <<'EOF'
import json, os
def read(p):
    try: return json.load(open(p)).get("plansDirectory", "").strip()
    except Exception: return ""
val = read(os.path.join(".claude", "settings.json")) or \
      read(os.path.join(os.path.expanduser("~"), ".claude", "settings.json"))
if val:
    norm = val[2:] if val.startswith("./") else val
    inside = (not os.path.isabs(norm)) and (norm.rstrip("/") + "/").startswith("docs/")
    print(f"plansDirectory = {val}")
    if not inside:
        print("WARNING: plansDirectory is OUTSIDE docs/ — Pages only serves docs/.")
        print("         Move plans under docs/ (e.g. docs/plans) or edit the")
        print("         workflow's upload `path:` to match, or plans won't publish.")
else:
    # Unset: implementation-plan resolves docs/plans/ only if it EXISTS, else the
    # Claude user plans folder (outside the repo). Seed it so the first plan deploys.
    os.makedirs(os.path.join("docs", "plans"), exist_ok=True)
    open(os.path.join("docs", "plans", ".gitkeep"), "a").close()
    print("plansDirectory unset — seeded docs/plans/ (with .gitkeep) so generated")
    print("plans land inside docs/ and deploy, not in the Claude user plans folder.")
EOF
```

If the warning fires, surface it to the user and ask whether to proceed before scaffolding.

---

## Step 3 — Locate the plugin templates directory

The four artifacts ship as templates inside this plugin. The plugin may be a versioned cached copy or loaded directly — try every layout:

```bash
TEMPLATES_DIR=$( { \
  find ~/.claude/plugins -path "*/plan-agent/*/templates/pages" -type d 2>/dev/null | sort -rV; \
  find ~/.claude/plugins -path "*/plan-agent/templates/pages"   -type d 2>/dev/null; \
  find "$PWD"            -path "*/plan-agent/templates/pages"   -type d 2>/dev/null; \
} | head -1 )
[ -n "$TEMPLATES_DIR" ] || { echo "Templates not found. Install plan-agent or load it with --plugin-dir."; exit 1; }
echo "TEMPLATES_DIR=$TEMPLATES_DIR"
```

If empty, output that message and **STOP**.

---

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

---

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

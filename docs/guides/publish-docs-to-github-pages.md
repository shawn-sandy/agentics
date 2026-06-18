# Publishing Plans and Social Cards to GitHub Pages
A developer guide to the `docs/` → GitHub Pages pipeline: how generated plan and social-card HTML reaches a public URL, what deploys it, and how to preview before shipping.

> **Origin.** Written 2026-06-18 after a session question — *"Did we not write a way for developers to publish the plans and social media artifacts to GitHub Pages?"* The answer was yes: the pipeline shipped 2026-06-07 across three commits — `ecb231e` (the Pages deploy workflow), `8926e64` (serve-docs tooling, #276), and `45de119` (the landing hub, #280). This guide consolidates the moving parts into one reference.

---

## Table of contents

1. [The pipeline in one sentence](#1-the-pipeline-in-one-sentence)
2. [What it is — the files and the workflow](#2-what-it-is--the-files-and-the-workflow)
3. [Why it exists](#3-why-it-exists)
4. [How it works structurally](#4-how-it-works-structurally)
5. [How it fires — and what stops it](#5-how-it-fires--and-what-stops-it)
6. [Decision criteria — Pages vs. dist, preview vs. publish](#6-decision-criteria--pages-vs-dist-preview-vs-publish)
7. [Operational script — what to actually do](#7-operational-script--what-to-actually-do)
8. [Boundaries — what this pipeline does NOT do](#8-boundaries--what-this-pipeline-does-not-do)
9. [Interactions with related systems](#9-interactions-with-related-systems)
10. [Project-specific context](#10-project-specific-context)
11. [Maintenance and audit](#11-maintenance-and-audit)
12. [Verification protocol](#12-verification-protocol)

---

## 1. The pipeline in one sentence

**Anything committed under `docs/` on `main` is published to GitHub Pages automatically; the plugins generate the HTML into `docs/`, and a path-filtered Actions workflow deploys the whole tree as a static site.**

Everything below unpacks that sentence.

---

## 2. What it is — the files and the workflow

Five artifacts, all in this repo, make up the pipeline.

**The deploy workflow** — [`.github/workflows/deploy-pages.yml`](../../.github/workflows/deploy-pages.yml). Two jobs: a `build` job that packages `docs/`, and a `deploy` job that publishes it. The trigger and permission blocks, verbatim:

```yaml
on:
  push:
    branches: [main]
    paths:
      - 'docs/**'
      - '.github/workflows/deploy-pages.yml'
  workflow_dispatch:

permissions:
  pages: write
  id-token: write
  contents: read

concurrency:
  group: pages
  cancel-in-progress: false
```

The `build` job asserts the no-Jekyll marker before uploading, then uploads the whole `docs/` folder as the Pages artifact:

```yaml
- name: Assert .nojekyll exists
  run: test -f docs/.nojekyll || { echo "::error::docs/.nojekyll is missing — Jekyll will mangle the site"; exit 1; }
- name: Upload Pages artifact
  uses: actions/upload-pages-artifact@fc324d3547104276b827a68afc52ff2a11cc49c9  # v5.0.0
  with:
    path: docs
```

**The no-Jekyll marker** — [`docs/.nojekyll`](../../docs/.nojekyll) (a 0-byte file). Its presence tells GitHub Pages to serve the raw tree instead of running it through Jekyll.

**The landing hub** — [`docs/index.html`](../../docs/index.html). A two-card page that links to the two galleries with *relative* hrefs:

```html
<a class="gallery-card" href="plans/index.html">…Plans…</a>
<a class="gallery-card" href="media/social/index.html">…Social Media…</a>
```

**The two galleries** — [`docs/plans/index.html`](../../docs/plans/index.html) (filterable plan gallery) and [`docs/media/social/index.html`](../../docs/media/social/index.html) (social-card gallery). These are *generated*, not hand-written (see §4).

**The local preview script** — [`scripts/serve-docs.sh`](../../scripts/serve-docs.sh). Serves `docs/` over `python3 -m http.server`, bound to `127.0.0.1`, on an auto-selected free port (or a port you pass as `$1`).

The live site is **<https://shawn-sandy.github.io/agentics/>** (verified live, 2026-06-18 — title "Agentics - Claude Code Plugin Marketplace", both gallery links resolve).

---

## 3. Why it exists

The objective, quoted verbatim from the implementation plan ([`docs/plans/publish-plans-to-github-pages.html`](../../docs/plans/publish-plans-to-github-pages.html)):

> Ship a GitHub Actions pipeline that publishes the entire docs/ tree to GitHub Pages, so every developer can browse all 32 HTML plans from one public URL — landing straight on the filterable plans gallery — instead of cloning the repo and opening files by hand.

The gap was **reach, not generation**. The repo already produced rich, self-contained HTML plans into `docs/plans/` (32 of them when the plan was written), and a PostToolUse hook already kept the gallery index current. But those files lived only on disk — reading one meant cloning the repo and opening a local browser. Pages closed that gap: the artifacts were already there; the pipeline just gave them a URL.

---

## 4. How it works structurally

Two phases: **generation** (plugins write into `docs/`) and **deployment** (Actions ships `docs/`). They are decoupled — the plugins never touch Pages, and the workflow never generates content.

```text
GENERATION (local, on demand)
  plan-agent  ──────────────►  docs/plans/<verb-target>.html
       └─ PostToolUse hook (rebuild-plans-index.py) ──► regenerates docs/plans/index.html
  social-media-tools ───────►  docs/media/social/<card>.html  + <card>.png
       └─ (NO hook) run media-library skill MANUALLY ─► regenerates docs/media/social/index.html

  Result on disk:
     docs/
      ├─ index.html              (landing hub — relative links)
      ├─ .nojekyll               (serve raw, no Jekyll)
      ├─ plans/index.html        (filterable gallery)
      └─ media/social/index.html (filterable gallery)

──────────────────────────────────────────────────────────────────
DEPLOYMENT (CI, automatic)

  git commit + push to main  (changes touch docs/**)
            │
            ▼
  .github/workflows/deploy-pages.yml
      build  ─ assert .nojekyll ─ configure-pages ─ upload-pages-artifact(path: docs)
            │
      deploy ─ deploy-pages ─ environment: github-pages
            │
            ▼
  https://shawn-sandy.github.io/agentics/   (live)
```

**The two galleries refresh differently — this asymmetry matters.** The *Plans* gallery (`docs/plans/index.html`) regenerates **automatically** via a `plan-agent` PostToolUse hook on every plan write (§9). The *Social Media* gallery (`docs/media/social/index.html`) has **no hook** — the card save flow stops after writing the card and delivering it ([`saving-and-delivery.md`](../../kit/plugins/social-media-tools/references/saving-and-delivery.md): "STOP. Do not run further git commands..."). To refresh the social gallery you must run the `media-library` skill yourself before committing, or Pages deploys a stale gallery that does not link the new card.

The whole `build` → `deploy` chain uses GitHub's official, SHA-pinned actions:

| Action | Pinned version | Role |
|--------|----------------|------|
| `actions/checkout` | `v4.2.2` | Clone the repo |
| `actions/configure-pages` | `v6.0.0` | Resolve Pages settings |
| `actions/upload-pages-artifact` | `v5.0.0` | Package `docs/` as the artifact |
| `actions/deploy-pages` | `v5.0.0` | Publish the artifact to Pages |

---

## 5. How it fires — and what stops it

**What activates a deploy:**

- A push to `main` whose diff touches `docs/**` *or* `.github/workflows/deploy-pages.yml`.
- A manual `workflow_dispatch` run (Actions tab → "Deploy to GitHub Pages" → Run workflow).

**What prevents a deploy from happening — or from succeeding:**

- A push to any branch other than `main` — the trigger is `branches: [main]` only. Feature-branch pushes never deploy.
- A push to `main` that changes *only* non-`docs/` files (e.g. a plugin edit) — the `paths:` filter skips it.
- A missing `docs/.nojekyll` — the `build` job's assertion step fails fast with `::error::docs/.nojekyll is missing` before anything uploads.
- The one-time repo setting **Settings → Pages → Source** not set to **GitHub Actions** — without it, there is no Pages environment to deploy into. (See [`docs/GITHUB_SETUP.md`](../../docs/GITHUB_SETUP.md) for the repo's CI configuration notes.)

`concurrency: group: pages, cancel-in-progress: false` means overlapping pushes **queue** rather than cancel each other — GitHub Pages has a single live deployment slot, so deploys serialize.

---

## 6. Decision criteria — Pages vs. dist, preview vs. publish

> *Is this artifact for teammates to read, or for users to install — and am I checking it or shipping it?*

Two independent axes resolve almost every "where does this go?" question.

### Axis 1 — Pages (`docs/`) vs. distribution (`agentics-kit`)

| You have… | Goes to… | Via… |
|-----------|----------|------|
| Browsable HTML for humans (plans, social cards, the hub) | GitHub Pages | `deploy-pages.yml`, on push to `main` |
| Installable plugin files for users | `shawn-sandy/agentics-kit` repo | `publish-dist.yml`, daily cron (see §8) |

These are different targets with different purposes. Pages is **reading**; the dist repo is **installing**. A change to a plugin's SKILL.md ships through `publish-dist.yml`; a new plan HTML ships through `deploy-pages.yml`.

### Axis 2 — preview (local) vs. publish (live)

| You want to… | Use… |
|--------------|------|
| Check a gallery before the world sees it | `bash scripts/serve-docs.sh` (local, `127.0.0.1`) |
| Make it public | Commit under `docs/`, merge to `main` |

Local preview never publishes; merging to `main` always (eventually) does. There is no "publish to Pages without committing" path — `main` is the source of truth.

---

## 7. Operational script — what to actually do

**To publish a new plan or social card:**

1. Generate it with the owning plugin — `plan-agent` for plans, `social-media-tools` for cards. The artifact lands in `docs/plans/` or `docs/media/social/`.
2. **Refresh the gallery index.** For a **plan**, this happens automatically (the `rebuild-plans-index.py` hook fires on the write). For a **social card**, there is no hook — **run the `media-library` skill** so `docs/media/social/index.html` links the new card. Skip this and the deployed Social Media gallery will be stale.
3. Preview locally: `bash scripts/serve-docs.sh` → open the printed `http://localhost:<port>/plans/` (or `/media/social/`).
4. Commit the `docs/` changes on a feature branch, open a PR, merge to `main`.
5. The push to `main` fires `deploy-pages.yml`; the artifact is live at `https://shawn-sandy.github.io/agentics/` within a minute or two.

**What NOT to do:**

- **Do NOT delete `docs/.nojekyll`.** Jekyll will mangle filenames with underscores and skip files it considers "special" — the build job fails on purpose if the marker is gone.
- **Do NOT hand-edit `docs/plans/index.html`.** The `rebuild-plans-index.py` hook regenerates it on the next plan write and will overwrite your edits. Change the generator, not the output.
- **Do NOT commit a new social card without running `media-library`.** Unlike plans, the social gallery has no rebuild hook — commit the card alone and Pages publishes a `docs/media/social/index.html` that omits it. Run the skill, confirm the card appears, then commit both.
- **Do NOT add absolute-root links (`href="/..."`) to the hub or galleries.** The site is served under the `/agentics/` path prefix, so `/` resolves to the wrong place. Use relative hrefs — `test-docs-hub.sh` fails if it finds an absolute-root link.
- **Do NOT expect a feature branch to deploy.** Only `main` triggers Pages. Preview locally instead.
- **Do NOT unpin an action to a tag.** `test-workflow-config.sh` asserts every `uses:` is pinned to a 40-char SHA.

---

## 8. Boundaries — what this pipeline does NOT do

1. **It does not package or publish plugins.** Installable plugin distribution is a separate pipeline — [`.github/workflows/publish-dist.yml`](../../.github/workflows/publish-dist.yml) runs `node scripts/build-dist.mjs --publish` on a daily `cron: '0 6 * * *'` and pushes a clean, plugin-only tree to the `shawn-sandy/agentics-kit` repo. Different trigger, different target, different artifact.
2. **It does not deploy from non-`main` branches.** The trigger is `branches: [main]`. There is no preview-deployment-per-PR mechanism here.
3. **It does not build or transform.** No bundler, no Jekyll, no templating at deploy time — `docs/` is uploaded as-is. The HTML is self-contained by the time it lands in `docs/`.
4. **It does not generate the artifacts.** The plugins do (§4). Pages only ships what already exists in `docs/`.
5. **It does not gate the deploy on tests.** The smoke tests in §12 are run manually or in a separate CI job — they are not a precondition inside `deploy-pages.yml`. A broken gallery committed to `main` will deploy.

---

## 9. Interactions with related systems

- **`plan-agent` rebuild hook** — [`kit/plugins/plan-agent/hooks/rebuild-plans-index.py`](../../kit/plugins/plan-agent/hooks/rebuild-plans-index.py), registered as a `PostToolUse` hook on `Write|Edit|MultiEdit` in [`kit/plugins/plan-agent/hooks.json`](../../kit/plugins/plan-agent/hooks.json). It regenerates `docs/plans/index.html` after any plan HTML write (2-second debounce; always exits 0 so an index-rebuild failure never blocks the write). This is what keeps the *Plans* gallery current without manual steps.
- **`social-media-tools` media library** — the `media-library` skill builds and refreshes `docs/media/social/index.html` from the cards in that folder. Unlike the plan gallery, this is **manual**: `social-media-tools` ships no hook, and the card save flow stops after delivery without rebuilding the index ([`saving-and-delivery.md`](../../kit/plugins/social-media-tools/references/saving-and-delivery.md)). You must run `media-library` yourself to keep the *Social Media* gallery current.
- **Local preview tooling** — `scripts/serve-docs.sh` plus the fixed-port VS Code configs in `.claude/launch.json`: `plans-gallery` (`:8901`), `media-library` (`:8902`), `docs-all` (`:8900`). Documented in the repo `README.md` under "Browsing Docs Locally".
- **Sibling publish pipeline** — `publish-dist.yml` (§8). Easy to confuse with Pages because both are "publish"; they are unrelated.
- **One-time repo config** — `docs/GITHUB_SETUP.md` documents workflow-permission expectations for this repo's CI.

---

## 10. Project-specific context

These facts are local to **this repo** — they are not universal GitHub Pages behavior.

- **Served under a path prefix.** The project site lives at `…/agentics/`, so every link in the hub and galleries is *relative*. `test-docs-hub.sh` enforces this by failing on any `href="/"` (absolute-root) link and confirming the relative hrefs `plans/index.html` and `media/social/index.html` are present.
- **`.nojekyll` is mandatory, not optional.** Plan HTML filenames and inline content trip Jekyll's defaults; the marker is asserted in CI rather than assumed.
- **Actions are SHA-pinned with a version comment.** e.g. `actions/deploy-pages@cd2ce8fcbc39b97be8ca5fce6e763baed58fa128  # v5.0.0`. This is a repo security convention; `test-workflow-config.sh` check #10 rejects any unpinned `uses:`.
- **The trigger is path-filtered.** Plugin/test edits do not rebuild the site — only `docs/**` (or the workflow file) changes do. This keeps the Pages environment quiet and deploys meaningful.

The general fact that **transfers to any repo**: a custom Actions workflow with `pages: write` + `id-token: write` permissions, an `upload-pages-artifact` build job, and a `deploy-pages` deploy job is GitHub's standard "deploy from a workflow" pattern. See the canonical docs in Cross-references.

---

## 11. Maintenance and audit

- **Adding a third gallery?** Generate its `index.html` under `docs/<name>/`, then add a relative-href card to `docs/index.html`. Add a `test-docs-hub.sh` assertion for the new link so a future edit can't silently drop it.
- **Bumping an action?** Keep it SHA-pinned and update the trailing `# vX.Y.Z` comment to match. Re-run `test-workflow-config.sh` (check #10) afterward.
- **Never remove `docs/.nojekyll`.** If a deploy starts 404-ing on underscore-named files, the missing marker is the first suspect.
- **One-time setup, if Pages ever stops deploying:** confirm **Settings → Pages → Source = GitHub Actions** and that workflow permissions allow the `pages`/`id-token` scopes. `docs/GITHUB_SETUP.md` has the repo's notes.
- **Stale-doc check:** if any path, action version, or live-URL claim in this guide stops matching reality, this guide is the defect — re-run the verification protocol below and update it.

---

## 12. Verification protocol

All commands run from the repo root. These are the executable checks that confirm the pipeline is intact.

**Workflow config (11 checks)** — asserts the trigger, permissions, artifact path, `.nojekyll` assertion, and SHA-pinning:

```bash
bash tests/pages/test-workflow-config.sh
# Expect: "ALL PASSED"
```

**Landing hub (7 checks)** — asserts `docs/index.html` exists, has no meta-refresh redirect, links both galleries via relative hrefs, and uses no absolute-root links:

```bash
bash tests/pages/test-docs-hub.sh
# Expect: "ALL PASSED"
```

**Additional pages smoke tests** bundled in the same folder:

```bash
bash tests/pages/test-pages-smoke.sh
bash tests/pages/test-root-redirect.sh
```

**Live-site check (manual):** open <https://shawn-sandy.github.io/agentics/> and confirm the two cards resolve to the Plans and Social Media galleries.

**Local-preview check (manual):**

```bash
bash scripts/serve-docs.sh
# then open the printed http://localhost:<port>/plans/  and  /media/social/
```

---

## Quick reference

```text
PUBLISH A PLAN OR CARD TO PAGES
  1. Generate ── plan-agent → docs/plans/      | social-media-tools → docs/media/social/
  2. Index    ── plan: auto (rebuild hook)     | card: run media-library skill MANUALLY
  3. Preview  ── bash scripts/serve-docs.sh    → http://localhost:<port>/plans/
  4. Commit   ── docs/** changes on a branch → PR → merge to main
  5. Deploy   ── push to main fires deploy-pages.yml  (automatic)
  6. Live     ── https://shawn-sandy.github.io/agentics/

DEPLOY FIRES WHEN…            DEPLOY DOES NOT FIRE WHEN…
  • push to main, docs/**       • push to a feature branch
  • workflow_dispatch           • push to main, no docs/** change
                                • docs/.nojekyll missing (build FAILS)

DON'T
  • delete docs/.nojekyll          • hand-edit docs/plans/index.html (hook overwrites)
  • use href="/" absolute links    • unpin a `uses:` from its SHA

NOT THIS PIPELINE
  • plugin install files → publish-dist.yml → agentics-kit (daily cron)

VERIFY
  bash tests/pages/test-workflow-config.sh   # 11 checks
  bash tests/pages/test-docs-hub.sh          # 7 checks
```

---

## Cross-references

**External (verified live 2026-06-18):**

- [Using custom workflows with GitHub Pages](https://docs.github.com/en/pages/getting-started-with-github-pages/using-custom-workflows-with-github-pages) — GitHub's canonical "deploy Pages from Actions" docs.
- [`actions/deploy-pages`](https://github.com/actions/deploy-pages) — the official deploy action (v5.0.0).
- [shawn-sandy.github.io/agentics](https://shawn-sandy.github.io/agentics/) — the live published site.

**Sibling internal docs and configs:**

- [`.github/workflows/deploy-pages.yml`](../../.github/workflows/deploy-pages.yml) — the deploy workflow.
- [`.github/workflows/publish-dist.yml`](../../.github/workflows/publish-dist.yml) — the *other* publish pipeline (dist → agentics-kit), not Pages.
- [`docs/index.html`](../../docs/index.html) — the landing hub.
- [`scripts/serve-docs.sh`](../../scripts/serve-docs.sh) — local preview server.
- [`docs/GITHUB_SETUP.md`](../../docs/GITHUB_SETUP.md) — one-time CI/repo configuration notes.
- [`kit/plugins/plan-agent/hooks/rebuild-plans-index.py`](../../kit/plugins/plan-agent/hooks/rebuild-plans-index.py) — the gallery-rebuild hook.
- `tests/pages/` — the verification suite (`test-workflow-config.sh`, `test-docs-hub.sh`, `test-pages-smoke.sh`, `test-root-redirect.sh`).

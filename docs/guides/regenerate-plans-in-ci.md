# Regenerating the Plans Gallery in CI

A setup guide for making CI rebuild `docs/plans/index.html` on push, instead of relying on the local `plan-agent` hook to have run before you committed. Companion to [Publishing Plans and Social Cards to GitHub Pages](publish-docs-to-github-pages.md) — that guide *deploys* `docs/`; this one *regenerates* the plans gallery so what gets deployed is never stale.

> **When you need this.** By default `plan-agent` rebuilds `docs/plans/index.html` via a local `PostToolUse` hook ([`rebuild-plans-index.py`](../../kit/plugins/plan-agent/hooks/rebuild-plans-index.py)) that fires in your editing session — so the committed index is current *if the hook ran*. It won't have run when a plan HTML is added by hand, edited on the GitHub web UI, merged from a branch that skipped the hook, or committed from a machine without the plugin installed. This workflow closes that gap by regenerating the gallery on the runner.

---

## The setup in one sentence

**Vendor the gallery builder into `scripts/`, add a path-filtered workflow that runs it on plan-HTML pushes, and commit the result only when real card content changed — not when the build clock moved.**

---

## 1. Vendor the builder

The builder is a self-contained `bash` + `python3` script — no plugin runtime, no node. Copy it out of your installed plugin into the repo so CI can reach it:

```bash
mkdir -p scripts
# find the builder inside the installed plugin (path includes a version dir)
src="$(find ~/.claude/plugins -path '*plan-agent*/hooks/build-index.sh' | sort | tail -1)"
cp "$src" scripts/build-plans-index.sh
git add scripts/build-plans-index.sh
git commit -m "chore: vendor plans-index builder for CI"
```

The copy is byte-for-byte identical to the plugin hook. That's deliberate: on a plugin upgrade you refresh it with the same `cp`, with no local edits to reconcile. (In *this* repo the source is [`kit/plugins/plan-agent/hooks/build-index.sh`](../../kit/plugins/plan-agent/hooks/build-index.sh) and the vendored copy is [`scripts/build-plans-index.sh`](../../scripts/build-plans-index.sh).)

The optional `templates/` directory the builder looks for degrades gracefully — if it's absent, cards render with a plain fallback. Copy it too only if the fallback looks too bare:

```bash
# optional: fully-styled cards
find ~/.claude/plugins -path '*plan-agent*/templates' -type d | sort | tail -1 \
  | xargs -I{} cp -r {} scripts/plan-agent-templates
```

## 2. Add the workflow

Drop in [`.github/workflows/regen-plans.yml`](../../.github/workflows/regen-plans.yml):

```yaml
name: Regenerate plans gallery

on:
  push:
    branches: [main]
    paths:
      - 'docs/plans/**.html'
      - '!docs/plans/index.html'   # the file we generate — never let it re-trigger us
  workflow_dispatch:

permissions:
  contents: write

jobs:
  regen:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Regenerate the gallery index
        run: bash scripts/build-plans-index.sh "$GITHUB_WORKSPACE"
      - name: Commit only if real card content changed
        run: |
          git config user.name  "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git add docs/plans/index.html
          if git diff --cached --quiet -I'>Generated [0-9]'; then
            echo "No card changes (timestamp-only or identical) — skipping commit."
            git reset -q docs/plans/index.html
          else
            git commit -m "chore: regenerate plans gallery [skip ci]"
            git push
          fi
```

Two lines are load-bearing:

- **`'!docs/plans/index.html'`** — excludes the generated file from the trigger, so the workflow's own commit can't re-fire it. No loop.
- **`git diff --cached --quiet -I'>Generated [0-9]'`** — the builder stamps a `Generated <date> <time>` line into the index, so a rebuild *always* differs from the committed copy even when no plan changed. The `-I` flag makes `git diff` ignore any hunk whose changed lines all match that pattern, so a timestamp-only rebuild is treated as no change and skipped. Without it, every run would push a noise commit.

## 3. Verify

**Locally, before you trust it on `main`** — this exercises the builder and the guard with no runner:

```bash
T=$(mktemp -d); mkdir -p "$T/docs/plans"
cp docs/plans/*.html "$T/docs/plans/"; rm -f "$T/docs/plans/index.html"
git -C "$T" init -q

# build + commit a baseline index
bash scripts/build-plans-index.sh "$T"
git -C "$T" add -A && git -C "$T" -c user.email=t@t -c user.name=t commit -qm baseline

# rebuild with no plan change → guard must SKIP (only the clock moved)
bash scripts/build-plans-index.sh "$T"
git -C "$T" add docs/plans/index.html
git -C "$T" diff --cached --quiet -I'>Generated [0-9]' \
  && echo "SKIP: timestamp-only churn ignored (correct)" \
  || echo "COMMIT: timestamp noise (wrong)"
```

Expect `SKIP`. Add a throwaway plan (`echo '<title>x</title>' > "$T/docs/plans/zz.html"`), rebuild, and the same `git diff` line should now report the change instead — proving the guard catches real content.

**On the runner** — the trigger and `contents: write` permission can only be confirmed with a real push. The workflow ships with `workflow_dispatch:`, so after committing both files:

```bash
gh workflow run regen-plans.yml --ref main
gh run watch
```

---

## Boundaries — what this does NOT do

1. **It does not deploy.** Publishing `docs/` to a public URL is the separate Pages pipeline — see [Publishing Plans and Social Cards to GitHub Pages](publish-docs-to-github-pages.md). This workflow only keeps the *index* honest; the deploy workflow ships it. Run both and the chain is: push a plan → regenerate index → deploy.
2. **It does not replace the local hook.** The `plan-agent` `PostToolUse` hook still rebuilds the gallery in your session — that's faster feedback. CI regeneration is the backstop for commits the hook never saw.
3. **It does not regenerate the social-media gallery.** `docs/media/social/index.html` is built by the `media-library` skill and has no CI equivalent here.
4. **It does not stay in sync automatically.** The vendored script drifts from the plugin on upgrades — re-run the `cp` from step 1 to refresh. If you'd rather never vendor, install the marketplace in a CI step and call the builder from the plugin path instead (more moving parts, always current).

---

## Cross-references

- [Publishing Plans and Social Cards to GitHub Pages](publish-docs-to-github-pages.md) — the deploy pipeline this pairs with.
- [`kit/plugins/plan-agent/hooks/build-index.sh`](../../kit/plugins/plan-agent/hooks/build-index.sh) — the source of the vendored builder.
- [`kit/plugins/plan-agent/hooks/rebuild-plans-index.py`](../../kit/plugins/plan-agent/hooks/rebuild-plans-index.py) — the local `PostToolUse` hook this backstops.
- [`git diff --ignore-matching-lines`](https://git-scm.com/docs/git-diff#Documentation/git-diff.txt---ignore-matching-linesltregexgt) — the `-I` flag behind the commit guard.

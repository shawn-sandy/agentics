---
name: setup-sites
description: "Scaffolds GitHub Pages publishing into any repo. Adds the deploy workflow, .nojekyll, hub, and preview script so docs/ HTML reaches a public URL. Use when asked to set up or publish GitHub Pages."
allowed-tools: Bash, Read, Write, AskUserQuestion, ToolSearch, ExitPlanMode
---

# setup-sites

Scaffold the GitHub Pages deployment pipeline into the **current repository** so anything generated under `docs/` (plan galleries from `plan-agent`, social cards from `social-media-tools`, or any static HTML) publishes to a public URL. This drops four artifacts and guides the one-time GitHub setting — it does **not** generate plans or cards (the owning plugins do that) and does **not** commit (you commit when ready).

The pipeline it installs: a push to `main` touching `docs/**` fires a path-filtered Actions workflow that uploads `docs/` and deploys it to Pages. See the companion guide `docs/guides/publish-docs-to-github-pages.md` in the agentics repo for the full reference.

## References

- `references/preflight.md` — Steps 1–3: the git and remote preflight, the `plansDirectory` sanity check, the templates lookup
- `references/scaffold.md` — Step 4: the four artifact writes, the hub placeholders, the card-pruning rules
- `references/enable-and-verify.md` — Steps 5–7: the one-time Pages source setting, the verification checks, the delivery summary

---

## Exit plan mode

**If in plan mode**, call `ExitPlanMode` first — this workflow mutates state.

Produce no plan document — execute the workflow directly.

---

## Step 1 — Preflight: confirm a git repo and resolve the live URL

Run the work-tree check and the `origin`-remote parser in `references/preflight.md`.
Keep `owner`, `repo`, and the computed `LIVE_URL` for Steps 4, 5, and 7.

## Step 2 — Resolve the docs directory and sanity-check `plansDirectory`

Follow `references/preflight.md`: resolve `plansDirectory`, warn (and ask before
scaffolding) if it sits outside `docs/`, and seed `docs/plans/` when it is unset.

## Step 3 — Locate the plugin templates directory

Resolve `TEMPLATES_DIR` with the three-layout lookup in `references/preflight.md`.
If it comes back empty, print that step's message and **STOP**.

## Step 4 — Scaffold the four artifacts (idempotent)

Write the workflow, `.nojekyll`, `serve-docs.sh`, and the hub exactly as
`references/scaffold.md` specifies — never clobber an existing target, and track
created vs. skipped for the Step 7 tally.

## Step 5 — Enable the one-time GitHub Pages source (Settings → Pages → Source = GitHub Actions)

Check whether `gh` is authenticated, then follow `references/enable-and-verify.md`:
ask before enabling Pages automatically, otherwise print the manual steps.

## Step 6 — Verify the scaffold

Run the structural checks in `references/enable-and-verify.md` and report a
pass/fail line for each. Any `FAIL` must be fixed before the user commits.

## Step 7 — Deliver and stop

Report the created/skipped tally, the live URL, the Pages-source state, and the
publish commands from `references/enable-and-verify.md`. **STOP.** Do not commit,
push, or invoke other skills automatically — the user commits when ready.

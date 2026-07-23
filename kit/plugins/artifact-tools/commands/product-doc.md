---
description: Publish a recap of this session or a pull request for the product team and stakeholders — features, fixes, decisions, and plan details
allowed-tools:
  - Skill
  - Bash
---

# Product Doc

Write an artifact documenting this session — or a pull request — for the product
team and stakeholders to review.

Run the `artifact-tools:session-artifact` skill with these framing overrides:

- **Source.** Pick the first mode the argument matches. Both modes produce the
  same document from the same downstream pipeline; only the raw material differs.

  | Mode | Trigger | Raw material |
  |------|---------|--------------|
  | **Session** (default) | no argument, a session ID, or a `.jsonl` path | the session transcript, per the skill |
  | **PR** | `#453`, a PR URL, or `--pr <n>` | the pull request, gathered below |

  In **PR mode**, skip the skill's transcript-location and extraction steps.
  Gather the PR into one brief in the scratchpad and hand that to the skill as
  the source:

  Preflight first — run this alone and read its output. PR mode needs both `gh`
  and a GitHub remote, and an unguarded `gh` call emits shell errors instead of
  degrading:

  ```bash
  if gh auth status >/dev/null 2>&1 &&
     git remote get-url origin 2>/dev/null | grep -qi 'github\.com'; then
    echo "PR_MODE_OK"
  else
    echo "PR_MODE_UNAVAILABLE"
  fi
  ```

  On `PR_MODE_UNAVAILABLE`, say which piece is missing and continue in session
  mode — do not run the block below. On `PR_MODE_OK`, gather the PR into one
  brief in the scratchpad and hand that to the skill as the source:

  ```bash
  PR=<number-or-url>
  BASE=$(gh pr view "$PR" --json baseRefName --jq .baseRefName)
  HEAD=$(gh pr view "$PR" --json headRefName --jq .headRefName)
  git fetch -q origin "$BASE" "$HEAD" 2>/dev/null

  gh pr view "$PR" --json number,title,body,url,author,state,mergedAt,labels
  gh pr diff "$PR" --name-only                              # no --stat flag exists
  git log --format='%s%n%b%n---' "origin/$BASE".."origin/$HEAD"
  gh pr view "$PR" --json comments,reviews \
    --jq '{comments: [.comments[].body], reviews: [.reviews[] | {state, body}]}'
  ```

  If the PR number itself is bad, `gh pr view` fails on the first line and
  `$BASE` is empty — report that and stop rather than gathering a partial brief.

  Read the sections below out of that material: **Features** and **Bug fixes**
  from the commit subjects and the changed-file list, **Decisions** from the PR
  body and review discussion, **Known gaps** from unresolved review threads and
  anything the PR body defers. Prefer the commit bodies over the diff — they say
  *why*, which is the thing a stakeholder needs and a diff never carries.

  Bot review comments arrive as HTML-commented boilerplate; take the finding and
  drop the scaffolding. A resolved finding belongs in Decisions (what was
  changed and why), not in Known gaps.

  Falling back is deliberate, not a failure path — a recap of the work in hand
  still beats no recap.

- **Audience:** the product team and any non-engineering stakeholder — PM,
  design, support, sales, leadership. Explain *what changed and why it matters*;
  keep code to what a reader outside the codebase needs to follow the decision.
  Spell out internal names and acronyms the first time they appear.
- **Sections**, in this order. Omit any section the session produced nothing for
  rather than printing an empty heading:
  - **Summary** — what this session was for and where it landed.
  - **Features** — what a user can now do that they could not before, or what
    behaves differently. One entry per feature: the capability, who it is for,
    and how to reach it (command, flag, URL, menu path).
  - **Bug fixes** — one entry per fix: the symptom someone would have hit, the
    cause in plain language, and what now happens instead. Note anything that
    was reported but *not* fixed, and why.
  - **Decisions** — with the reasoning behind each, including options weighed
    and rejected. Flag any decision still open or awaiting product input.
  - **Logic and behavior changes** — rules, defaults, limits, or edge-case
    handling that changed but that no feature or fix line already covers.
  - **Implementation plan details** — link or inline any plan file touched by
    the session or the PR, with its current status, which steps closed, and what
    remains.
  - **Known gaps and follow-ups** — anything deferred, stubbed, or left
    unverified, so the product team is not surprised later.
  - **Files touched** — grouped by area, with a short note on why each changed.
- **Destination:** file the rendered HTML where every other saved artifact
  lives — the `.claude/artifacts/` inbox, published into the committed
  `docs/artifacts/` gallery. After the skill renders its HTML, hand that file to
  `social-media-tools:save-artifact`, which owns the dated filename, the
  collision suffix, and the gallery index rebuild:

  ```
  Skill(skill: "social-media-tools:save-artifact", args: "<path to the rendered HTML>")
  ```

  If that skill is not installed, copy the HTML into the inbox yourself, picking
  a free name the way `save-artifact` does — a same-day second recap must not
  overwrite the first:

  ```bash
  mkdir -p .claude/artifacts
  stem="product-doc"          # PR mode: "pr-<number>-doc"
  target=".claude/artifacts/${stem}-$(date +%F).html"
  n=2
  while [ -e "$target" ]; do
    target=".claude/artifacts/${stem}-$(date +%F)-${n}.html"
    n=$((n + 1))
  done
  cp "<rendered HTML>" "$target" && echo "Saved → $target (not published to the gallery)"
  ```

  Either way, report the gallery path alongside the artifact URL.

Everything else follows the skill unchanged: the blocking `security-scrub` gate,
the HTML render, publishing, and the post-publish marker check.

## Republish key

Each recap needs a record that survives the session, because that record is what
holds the published URL — without it, a second run mints a new link and the one
you shared goes stale. Both modes keep theirs under `{plansDirectory}/sessions/`:

| Mode | Record | Key |
|------|--------|-----|
| Session | the skill's `<date>-<slug>-<session-id[:8]>.md` | `product-artifact-url:` |
| PR | `pr-<number>.md` | `product-artifact-url:` |

**Never write `artifact-url:`.** In session mode that key already belongs to the
reviewer-first recap `session-artifact` publishes from the same record — the
filename is deterministic per session, so reusing the key would republish this
product recap over that page. Read `product-artifact-url:` before publishing,
write it back after, and leave any `artifact-url:` untouched.

PR mode gets its own record keyed on the PR number, so re-running against the
same PR updates the same page as the PR evolves — which is the point: the link
you send a stakeholder on day one still shows the merged state on day five.

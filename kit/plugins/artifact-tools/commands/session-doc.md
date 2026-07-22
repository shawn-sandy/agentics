---
description: Publish a session recap written for the product team and stakeholders — features, fixes, decisions, and plan details
allowed-tools:
  - Skill
  - Bash
---

# Session Doc

Write an artifact documenting this session for the product team and stakeholders
to review.

Run the `artifact-tools:session-artifact` skill with these framing overrides:

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
  - **Implementation plan details** — link or inline any plan file touched this
    session, with its current status, which steps closed, and what remains.
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
  target=".claude/artifacts/session-doc-$(date +%F).html"
  n=2
  while [ -e "$target" ]; do
    target=".claude/artifacts/session-doc-$(date +%F)-${n}.html"
    n=$((n + 1))
  done
  cp "<rendered HTML>" "$target" && echo "Saved → $target (not published to the gallery)"
  ```

  Either way, report the gallery path alongside the artifact URL.
- **Extra input:** `$ARGUMENTS` — a session ID or `.jsonl` path if given,
  otherwise use the newest transcript for this project.

Everything else follows the skill unchanged: transcript extraction, the blocking
`security-scrub` gate, the HTML render, publishing, and the post-publish marker
check.

**Use `product-artifact-url:`, not `artifact-url:`, as this recap's republish
key.** Both commands share one record under `{plansDirectory}/sessions/` —
`export_session.py` names it `<date>-<slug>-<session-id[:8]>.md`, deterministic
per session — so reusing `artifact-url:` would republish the product recap over
a reviewer recap already published from the same transcript, silently mutating
that page. Read `product-artifact-url:` before publishing and write it back
after; leave any `artifact-url:` in the file untouched. The two audiences get
two stable URLs from one record.

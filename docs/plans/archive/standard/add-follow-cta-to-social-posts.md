# Add a contextual "follow for more" CTA to social posts

## Context

The `code-share` plugin (directory `kit/plugins/social-media-tools`, marketplace
version `0.8.1`) drafts LinkedIn / Twitter-X / Bluesky copy across several share
skills. The goal of these posts is reach, but they currently end with at most a
content CTA (drive to a URL) — there is **no follow CTA**, so they don't actively
grow the author's audience.

We want every generated post to invite readers to **follow for more on the post's
topic**, to convert reach into followers. Two constraints from the user:

1. **Don't repeat the same stock line.** Never a bare "Follow me." The wording and
   structure should vary post-to-post.
2. **Match the keywords.** The "more on X" must name the post's actual subject —
   the same themes already reflected in the post's hashtags (language, technique,
   feature area, topic).

Confirmed decisions: apply to **all three platforms** (kept concise, and only when
character budget allows on Twitter/Bluesky); apply across **all share skills**; keep
the CTA **generic with no @handle** (the post publishes from the author's own
account, so nothing needs to be configured or asked each run).

## Approach

There is one canonical file every share skill reads during its "Draft Copy" phase:
`kit/plugins/social-media-tools/references/platforms.md` ("For character limits and
tone defaults, read `$PLUGIN_DIR/references/platforms.md`"). That is the single
source of truth for the new rule, so it propagates everywhere. Two skills
(`blog-share`, `video-share`) additionally carry their own concrete format
templates/examples whose closing lines currently model the *old* behavior — concrete
examples override abstract rules, so those must also be updated for consistency.

### 1. Authoritative rule — `references/platforms.md` (PRIMARY)

Add a new **`## Follow CTA`** section under the existing "Universal Copy Rules". It
must state:

- **Purpose**: close each post with a short invitation to follow for more on the
  post's topic (audience growth).
- **Topic-matched**: derive "more on X" from the post's primary subject — the same
  keywords reflected in the post's hashtags (language, technique, feature area,
  topic). Never a bare "Follow me."
- **Vary every time**: rotate phrasing/structure across posts; do not reuse a stock
  line. Include a small *pattern bank to adapt, not copy verbatim*, e.g.:
  - "Follow for more <topic> breakdowns like this."
  - "I share <language> patterns like this regularly — follow along."
  - "More <topic> deep-dives coming; follow to catch them."
  - "If <topic> is your thing, follow for the next one."
- **Generic, no handle** (post comes from the author's own account).
- **Placement & budget**:
  - LinkedIn: one short closing line, after any content/read CTA and before the
    hashtags.
  - Twitter/X & Bluesky: only if it fits the limit after the core message and URL
    (URL counts as 23 chars on Twitter/X). Keep it to a brief clause; if it would
    crowd the message, **drop it — content wins**.

### 2. Update concrete examples in the two skills that template their own copy

- `skills/blog-share/references/platforms.md` — its LinkedIn/Twitter/Bluesky format
  blocks end with "Worth a read if … : [URL]". Add a topic-matched follow line to the
  LinkedIn template (before hashtags) and to the example post; add a brief follow
  clause to the Twitter/Bluesky examples where budget allows.
- `skills/video-share/references/platforms.md` — same treatment around the
  "Watch here ▶ [URL]" CTA; weave a varied follow line into the templates/examples.

### 3. Light reinforcement where "CTA" is mentioned abstractly

These already read the canonical `platforms.md`; add a one-line clarification so the
existing "CTA" explicitly includes the topic-matched follow CTA:

- `skills/code-share/SKILL.md` — Phase 2 line "story arc (hook → insight → CTA)".
- `skills/selection-share/SKILL.md` — Phase 3 "Draft Copy" CTA mention.
- `skills/github-code-share/SKILL.md` — Phase 4 "Draft Copy" CTA mention.
- `skills/project-share/references/topics.md` — the per-topic tone-guide table's
  "CTA" cells; note that the closing CTA is a topic-matched follow line.

### 4. Version + changelog (per `.claude/rules/marketplace.md`)

- Bump `code-share` in `.claude-plugin/marketplace.json` from `0.8.1` → **`0.9.0`**
  (new user-visible behavior across all share skills; MINOR).
- Add a `0.9.0` entry to `kit/plugins/social-media-tools/CHANGELOG.md`.
- Conventional commit: `feat(kit/plugins/social-media-tools): bump version to 0.9.0`.

### Out of scope

The `{{CTA}}` template variable in `references/variables.md` drives a visual element
on the rendered **card image** (video-card), not the post text. This change is about
post copy only, so that variable is left unchanged.

## Files to modify

- `kit/plugins/social-media-tools/references/platforms.md` — new `## Follow CTA` rule
- `kit/plugins/social-media-tools/skills/blog-share/references/platforms.md`
- `kit/plugins/social-media-tools/skills/video-share/references/platforms.md`
- `kit/plugins/social-media-tools/skills/code-share/SKILL.md`
- `kit/plugins/social-media-tools/skills/selection-share/SKILL.md`
- `kit/plugins/social-media-tools/skills/github-code-share/SKILL.md`
- `kit/plugins/social-media-tools/skills/project-share/references/topics.md`
- `.claude-plugin/marketplace.json` — version `0.8.1` → `0.9.0`
- `kit/plugins/social-media-tools/CHANGELOG.md` — `0.9.0` entry

## Verification

1. **Structure/JSON**: editing `marketplace.json` auto-runs the JSON validation hook;
   confirm no errors. Optionally run `/validate-plugin social-media-tools`.
2. **Behavior (golden path)**: load the plugin locally —
   `claude --plugin-dir ./kit/plugins/social-media-tools` — then invoke `code-share`
   for "All sites" on a recent commit. Confirm each of the three variants ends with a
   follow CTA that (a) names the post's actual topic/keywords, (b) carries no @handle,
   and (c) fits its character limit.
3. **Variation**: run `code-share` (or `blog-share`) twice on different subjects and
   confirm the follow line differs in wording/structure — no repeated stock phrase.
4. **Budget edge case**: confirm that on a long Twitter/X post the follow clause is
   dropped rather than overflowing 280 chars (content wins).
5. **Cross-skill spot check**: invoke `blog-share` and `video-share` and confirm their
   templated examples now include the follow CTA consistently with the universal rule.

# Platform Reference

Canonical character limits, platform options, and universal copy rules for all
card-generating skills. Per-skill copy format templates and examples live in each
skill's own `references/platforms.md` (share-blog, share-video).

When adding a new platform, update this file only — all skills read it at runtime.

---

## Supported Platforms

| Platform | Max chars | Tone default |
|----------|-----------|--------------|
| LinkedIn | 1,500 | Professional |
| Twitter/X | 280 | Punchy |
| Bluesky | 300 | Conversational |
| Substack | 500 | Thoughtful |

### Platform Options for `AskUserQuestion`

When asking the user to choose a platform, **always offer all five options**:

> LinkedIn, Twitter/X, Bluesky, Substack, All sites

Never filter, omit, or selectively hide platforms based on content type, context,
card type, or any other heuristic. Every share skill must present all five options
in every `AskUserQuestion` call. "All sites" drafts one variant per platform and
renders a separate copy panel for each (see `$PLUGIN_DIR/references/copy-panels.md`).

---

## Universal Copy Rules

- **URL length**: every URL counts as **23 characters** on Twitter/X (t.co shortener);
  plan character budget accordingly.
- **Lead with insight**: open with the most surprising or useful observation — not
  "Great post by…", "I just watched…", or "Check out this…"
- **Attribution on Bluesky**: name the creator or author — Bluesky culture values attribution;
  do not echo the Twitter copy verbatim.
- **Hashtags**: LinkedIn supports 2–4 hashtags at end; Twitter/X 1–2 max (they eat budget
  fast); Bluesky hashtags are optional; Substack Notes do not use hashtags.
- **Substack Notes tone**: write in a newsletter voice — more personal and reflective than
  LinkedIn, more substantive than Twitter. Add a sentence of context or opinion that wouldn't
  fit in 280 chars. Do not echo the LinkedIn or Twitter copy verbatim.
- **All-sites drafting**: when platform is "All sites", draft all four variants and respect
  each platform's length and tone independently — find a different angle per platform.

---

## Follow CTA

Close each post with a short invitation to follow for **more on the post's topic** —
this is what turns reach into followers. It is the closing CTA referenced in the
per-skill story arcs (hook → insight → CTA).

- **Topic-matched, never generic**: name what the reader gets more of — the same
  keywords reflected in the post's hashtags (the language, technique, feature area, or
  subject). Never a bare "Follow me" or "Follow for more" with no topic.
- **Vary it every time**: rotate the wording and structure across posts; do not reuse
  a stock line. The patterns below are starting points to **adapt, not copy verbatim**:
  - "Follow for more `<topic>` breakdowns like this."
  - "I share `<language>` patterns like this regularly — follow along."
  - "More `<topic>` deep-dives coming; follow to catch them."
  - "If `<topic>` is your thing, follow for the next one."
  - "Posting more on `<topic>` soon — follow if it's useful."
- **Generic, no handle**: the post publishes from the author's own account, so do not
  invent or insert an `@handle`.
- **Placement & budget**:
  - **LinkedIn** (1,500): one short closing line, after any content/read CTA and
    before the hashtags.
  - **Twitter/X** (280) & **Bluesky** (300): add a brief follow clause **only if it
    fits** after the core message and URL (a URL is 23 chars on Twitter/X). If it
    would crowd the message, **drop it — content wins**.
  - **Substack** (500): one closing line inviting the reader to subscribe or follow
    for more on the topic — natural newsletter voice, not a hard sell.

---

## Copy Variant Storage

How to store drafted copy for downstream template population:

- **Single site:** store all variants joined with `\n---\n` as `POST_COPY_TEXT_RAW`
- **All sites:** keep each variant in a separate variable:
  `LINKEDIN_COPY`, `TWITTER_COPY`, `BLUESKY_COPY`, `SUBSTACK_COPY`

---

## Draft Copy — Standard Procedure

Every card-generating skill follows this procedure after drafting:

1. Present the drafted copy in a fenced code block labelled with the platform name
2. Wait for user approval before proceeding to template population
3. Store variants per the **Copy Variant Storage** convention above

---

## Default Per-Platform Copy Formats

Universal copy structure guidance. Skills with content-specific needs add to these
defaults in their own Draft Copy phase.

- **LinkedIn**: Narrative paragraphs; story arc (hook → insight → CTA); 2–4 hashtags
  at end
- **Twitter/X**: One punchy sentence or tight two-liner; 1–2 hashtags max; lead with
  the insight, not "Great post by…"
- **Bluesky**: Conversational, similar brevity to Twitter; name the creator; no
  hashtags required
- **Substack**: Newsletter voice — more reflective than LinkedIn, more substantive
  than Twitter; add a sentence of context or opinion; no hashtags

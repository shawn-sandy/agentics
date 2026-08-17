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
in every `AskUserQuestion` call **that asks the user to choose a platform**. Non-platform
questions (reuse checks, URL collection, tone, etc.) are unaffected by this rule.
"All sites" drafts one variant per platform and renders a separate copy panel
for each (see `$PLUGIN_DIR/references/copy-panels.md`).

---

## Universal Copy Rules

- **URL length**: every URL counts as **23 characters** on Twitter/X (t.co shortener);
  plan character budget accordingly.
- **Lead with takeaway**: open with a concrete, teachable principle or technique the
  reader can apply — not "Great post by…", "I just watched…", or "Check out this…"
  (see the **Instructional Voice** doctrine below)
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

## Instructional Voice

Every post this plugin generates must lead with a **concrete, teachable takeaway** —
a principle, technique, or pattern the reader can learn from and apply. This is the
**unconditional default** for every card-generating skill; the SOCIAL.md tone setting
only adjusts the *register* (professional, conversational, technical) and can never
disable the takeaway.

**Post arc:** hook → takeaway/lesson → learn-more (not hook → insight → CTA).

- **Takeaway first**: the body of the post names a specific principle, pattern, or
  technique and explains it concisely enough that a reader learns something without
  clicking through.
- **Teach, don't just promote**: frame every post as a learning resource. "Here's a
  technique you can apply" beats "Here's what I shipped." Accomplishments and
  features are evidence for the lesson, not the headline.
- **Applicable**: the reader should be able to act on the takeaway — try a pattern,
  avoid a pitfall, adopt a workflow. Abstract praise ("great article") doesn't count.

---

## Learn-More CTA

Close each post with a short **learn-more invitation** — secondary to the takeaway,
never a hard sell. This replaces the old follow-for-reach pattern.

- **Topic-matched, never generic**: name what the reader gets more of — the same
  keywords reflected in the post's hashtags (the language, technique, feature area, or
  subject). Never a bare "Follow me" or "Follow for more" with no topic.
- **Framed as continued learning**: the line invites the reader to keep exploring a
  topic, not to grow someone's audience. The patterns below are starting points to
  **adapt, not copy verbatim**:
  - "More `<topic>` breakdowns like this on my feed."
  - "I break down `<language>` patterns like this regularly — follow along to learn more."
  - "More `<topic>` deep-dives coming — follow to keep learning."
  - "If you're learning `<topic>`, I post more breakdowns like this."
  - "I post more `<topic>` walkthroughs — follow if they're useful."
- **Secondary to the takeaway, never a hard sell**: if the post already delivers
  the lesson, the learn-more line is a bonus, not the purpose of the post. It should
  read naturally if removed.
- **Generic, no handle**: the post publishes from the author's own account, so do not
  invent or insert an `@handle`.
- **Placement & budget**:
  - **LinkedIn** (1,500): one short closing line, after any content/read CTA and
    before the hashtags.
  - **Twitter/X** (280) & **Bluesky** (300): the **takeaway wins and the learn-more
    line is dropped** when character budget is tight. Only include it if there is
    clear room after the core message and URL (a URL is 23 chars on Twitter/X).
  - **Substack** (500): one closing line inviting the reader to subscribe for more
    on the topic — natural newsletter voice, framed as continued learning.

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

- **LinkedIn**: Narrative paragraphs; story arc (hook → takeaway/lesson → learn-more);
  lead with a concrete principle or technique the reader can apply; 2–4 hashtags at end
- **Twitter/X**: One punchy takeaway or tight two-liner; 1–2 hashtags max; lead with
  the lesson, not "Great post by…"; drop the learn-more line if budget is tight
- **Bluesky**: Conversational; lead with the takeaway; name the creator; no hashtags
  required; drop the learn-more line if budget is tight
- **Substack**: Newsletter voice — more reflective than LinkedIn, more substantive
  than Twitter; lead with a teachable principle; add a sentence of context or opinion;
  no hashtags

### Worked Examples

One representative code change — replacing a hand-rolled debounce timer on a
search input with an AbortController fetch-cancellation pattern — rendered once
per platform. These show the structure and instructional voice to aim for;
adapt the angle to the actual content, never copy verbatim. Skills with
content-specific templates (share-blog, share-video) follow their own
skill-local references instead.

**LinkedIn:**

```
Debouncing a search input delays requests — it doesn't cancel the ones already
in flight. A slow early response can still land last and overwrite fresh results.

I replaced a hand-rolled debounce timer with an AbortController: each keystroke
aborts the previous fetch before starting the next, so the network can never
race the UI.

The pattern:

1. Keep one controller per input; call controller.abort() before every new request.
2. Pass controller.signal into fetch — the browser drops the stale request for you.
3. Catch AbortError and do nothing; it's the expected path, not a failure.

If your "flickering search results" bug survives a debounce, this is why — you
throttled the requests, but never cancelled them.

More async JavaScript patterns like this on my feed — follow along to keep learning.

#JavaScript #WebDev #AsyncPatterns
```

**Twitter/X:**

```
Debounce delays requests — it doesn't cancel them. A slow early response can
still overwrite fresh results. One AbortController per input, abort before each
new fetch, and the last keystroke always wins. #JavaScript
```

**Bluesky:**

```
A debounce timer doesn't stop the race — it only spaces requests out. Swapped
our hand-rolled search debounce for an AbortController: abort the in-flight
fetch on every keystroke, catch the AbortError, done. The stale-results flicker
is gone.
```

**Substack:**

```
I spent an afternoon on a search box that flickered stale results — with a
debounce already in place.

The lesson: debouncing spaces requests out, but the requests that do fire can
still finish out of order. Cancellation, not timing, is the real fix. An
AbortController per input — abort before each new fetch, treat AbortError as
the expected path — and the last keystroke always wins.

I write about async patterns like this — subscribe to keep learning.
```

# Video Share — Platform Copy Formats & API Reference

Read in Phase 2 (API endpoints) and Phase 3 (copy format + examples).
For canonical character limits and universal copy rules — including the **Follow CTA**
rule that closes each post — see `$PLUGIN_DIR/references/platforms.md`.

---

## oEmbed API Endpoints

| Platform | Endpoint | Notes |
|----------|----------|-------|
| YouTube | `https://www.youtube.com/oembed?url={URL}&format=json` | Returns `title`, `author_name`, `thumbnail_url`. Does NOT include `description` — requires a second WebFetch on the video page URL to get `og:description`. |
| Vimeo | `https://vimeo.com/api/oembed.json?url={URL}` | Returns `title`, `author_name`, `thumbnail_url`, `description`. Single call is sufficient. |

**4xx responses** (private, deleted, age-restricted, or unavailable): ask the user for
`title` and `channel` via `AskUserQuestion`. Proceed without a thumbnail
(set `THUMBNAIL_ZONE = ""`).

---

## Copy Format — LinkedIn

**Structure:** Why-watch narrative → key insight → watch CTA → follow CTA → hashtags

```
[Hook that names the video and the channel — one sentence.]

[Two to three sentences on who made it, what problem it covers, and why it's worth
watching right now.]

Key insight: [The most concrete or surprising thing you learned — one to two sentences.]

Watch here ▶ [URL]

[Topic-matched follow CTA — one varied line on the video's subject; see the
Follow CTA rule in $PLUGIN_DIR/references/platforms.md]

#[Hashtag1] #[Hashtag2] #[Hashtag3]
```

**Example:**

```
Cassidy Williams just dropped a 20-minute breakdown of how she structures Claude
projects — and it's the most practical take I've seen.

She walks through her actual CLAUDE.md files, how she layers context for different
project types, and why she stopped putting documentation in the prompt.

Key insight: treating CLAUDE.md as a living document — edited after each session
based on what Claude got wrong — is a fundamentally different mindset than "write
it once and forget it."

Watch here ▶ https://youtu.be/example

I share Claude workflow breakdowns like this regularly — follow if you want more.

#ClaudeCode #AIEngineering #DeveloperProductivity
```

---

## Copy Format — Twitter/X

**Structure:** Hook + "Watch ▶ [URL]"

```
[One punchy sentence naming the video or its key insight.] Watch ▶ [URL]
```

**Rules:**
- Lead with the insight or the creator, not "Great video by…"
- The ▶ symbol is 1 character
- Hashtags optional; if used, 1 max
- Add a short, topic-matched follow tag only if it fits the 280-char budget after the
  URL (the URL counts as 23 chars); drop it if the message would overflow

**Example:**

```
Cassidy Williams shows her actual CLAUDE.md workflow — treating it as a living
doc you edit after each session. This changed how I think about context. Watch ▶ https://youtu.be/example — follow for more Claude workflow tips.
```

---

## Copy Format — Bluesky

**Structure:** Quick take + link

```
[Two sentences max: name the video + one concrete observation.] [URL]
```

**Rules:**
- Name the creator — Bluesky culture values attribution
- More casual than LinkedIn; no hashtags required
- Don't echo the Twitter copy; find a different angle
- Close with a brief, varied follow line on the topic when it fits the 300-char budget

**Example:**

```
Cassidy Williams on structuring Claude projects — the part about updating
CLAUDE.md after each session based on what Claude got wrong is genuinely useful.
https://youtu.be/example
Following more Claude project tips here — follow along if that's useful.
```

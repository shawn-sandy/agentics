# Video Share — Platform Copy Formats & API Reference

Read in Phase 2 (API endpoints) and Phase 3 (copy format + examples).
For canonical character limits and universal copy rules — including the **Instructional
Voice** doctrine and **Learn-More CTA** rule — see `$PLUGIN_DIR/references/platforms.md`.

**Takeaway-first**: every video-share post leads with a concrete, applicable lesson
from the video — a technique, principle, or workflow the reader can learn and apply.
The video link is supporting evidence, not the point of the post.

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

**Structure:** Lesson hook → teachable takeaway → watch CTA → learn-more CTA → hashtags

```
[Hook naming the key technique or principle from the video — one sentence.]

[Two to three sentences on who made it and the most applicable technique or
principle it teaches.]

Key lesson: [The most concrete, applicable thing you can take from this — one to
two sentences framing it as something the reader can try.]

Watch here ▶ [URL]

[Topic-matched learn-more CTA — one varied line on the video's subject; see the
Learn-More CTA rule in $PLUGIN_DIR/references/platforms.md]

#[Hashtag1] #[Hashtag2] #[Hashtag3]
```

**Example:**

```
A technique for structuring AI project context that changes how you think about
prompt management.

Cassidy Williams walks through her actual CLAUDE.md files, how she layers context
for different project types, and why she stopped putting documentation in the prompt.

Key lesson: treating CLAUDE.md as a living document — edited after each session
based on what Claude got wrong — turns static config into an iterative feedback
loop you can apply to any AI-assisted workflow.

Watch here ▶ https://youtu.be/example

More agentic-dev breakdowns like this on my feed — follow along to keep learning.

#ClaudeCode #AIEngineering #DeveloperProductivity
```

---

## Copy Format — Twitter/X

**Structure:** Teachable principle + "Watch ▶ [URL]"

```
[One punchy sentence naming the key technique or principle you can learn.] Watch ▶ [URL]
```

**Rules:**
- Lead with the lesson, not "Great video by…"
- The ▶ symbol is 1 character
- Hashtags optional; if used, 1 max
- The **takeaway wins** — drop the learn-more line if the 280-char budget is tight
  (URL counts as 23 chars)

**Example:**

```
Treat CLAUDE.md as a living doc you edit after each session — it turns static
config into an iterative feedback loop. Watch ▶ https://youtu.be/example #ClaudeCode
```

---

## Copy Format — Bluesky

**Structure:** Teachable observation + link

```
[Two sentences max: name the technique or lesson + how the reader can apply it.] [URL]
```

**Rules:**
- Lead with the takeaway
- Name the creator — Bluesky culture values attribution
- More casual than LinkedIn; no hashtags required
- Don't echo the Twitter copy; find a different angle
- The **takeaway wins** — drop the learn-more line if the 300-char budget is tight

**Example:**

```
Cassidy Williams on structuring Claude projects — the technique of updating
CLAUDE.md after each session based on what Claude got wrong turns static config
into iterative learning. Try it on your next project. https://youtu.be/example
```

---

## Copy Format — Substack

**Structure:** Learning context + teachable takeaway + what to apply + link

```
[One sentence on what you were trying to learn or what question you had.]

[CHANNEL]'s [TITLE] covers [topic] — [one or two concrete techniques or principles
you learned, written as applicable lessons rather than summary.]

[A sentence on what you'll apply differently — the actionable shift.] [URL]

[Topic-matched subscribe/learn-more CTA — newsletter voice; see the Learn-More
CTA rule in $PLUGIN_DIR/references/platforms.md]
```

**Rules:**
- Newsletter voice: more reflective than LinkedIn, more substantive than Twitter
- Name the creator — attribution matters
- No hashtags (Substack Notes don't use them)
- Lead with the learning, not just a reaction
- Keep under 500 chars

**Example:**

```
I've been trying to figure out how to structure context for Claude effectively —
this video laid out the technique clearly.

Cassidy Williams' breakdown teaches a specific workflow: treat CLAUDE.md as a
living document you edit after each session based on what Claude got wrong, not a
set-it-and-forget-it config file.

That technique alone changed how I approach project setup — I'm applying it to
every new project now. https://youtu.be/example

I write about agentic dev techniques — subscribe to keep learning.
```

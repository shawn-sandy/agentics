# Blog Share — Platform Copy Formats

Read in Phase 3 to draft platform-aware copy. For canonical character limits and
universal copy rules — including the **Instructional Voice** doctrine and **Learn-More
CTA** rule — see `$PLUGIN_DIR/references/platforms.md`.
Follow the format for the selected platform exactly — character limits are hard
constraints, not suggestions.

**Takeaway-first**: every blog-share post leads with a concrete, applicable lesson
from the article — a principle, technique, or pattern the reader can learn and apply.
The article link is supporting evidence, not the point of the post.

---

## LinkedIn

**Structure:** Lesson hook → 3 numbered takeaways → what the reader can apply → read CTA → learn-more CTA → hashtags

```
[One-sentence hook naming the key principle or technique from the article.]

[Article title] by [Author] covers [topic] — here are three things you can apply:

1. [First teachable takeaway — one to two sentences]
2. [Second teachable takeaway — one to two sentences]
3. [Third teachable takeaway — one to two sentences]

[One or two sentences on how to apply these: what to try, what to change in your
own work, or the mindset shift worth making.]

Worth a read if [specific audience / condition]: [URL]

[Topic-matched learn-more CTA — one varied line on the article's subject; see the
Learn-More CTA rule in $PLUGIN_DIR/references/platforms.md]

#[Hashtag1] #[Hashtag2] #[Hashtag3]
```

**Example:**

```
Three principles for building agent pipelines that don't silently corrupt state.

"Designing Reliable Agent Pipelines" by Sarah Chen tackles the hard problem of
keeping orchestrators and subagents in sync — here are three things you can apply:

1. Idempotency at every boundary: agents that retry must produce the same result,
   or your pipeline silently corrupts state.
2. Structured output contracts: prose responses break tool parsers; JSON schemas
   with strict validation prevent silent drift.
3. Backpressure over retry loops: when a downstream agent is slow, pause the
   upstream queue instead of hammering retries.

If you're building multi-agent systems, start with idempotency — it's the
foundation the other two patterns rely on.

Deep-dive worth your time: https://example.com/article

More agentic-dev breakdowns like this on my feed — follow along to keep learning.

#AIEngineering #MultiAgentSystems #SoftwareArchitecture
```

---

## Twitter/X

**Structure:** Teachable principle + URL + 1–2 hashtags

```
[One punchy sentence naming the single most applicable principle or technique.] [URL] #[Tag]
```

**Rules:**
- Lead with the lesson, not "Great article by…"
- 1–2 hashtags max; they eat character budget fast
- If the article teaches a memorable principle, lead with it
- The **takeaway wins** — drop the learn-more line if it would crowd the 280-char budget
  (URL counts as 23 chars)

**Example:**

```
Idempotency at agent boundaries isn't optional — it's the only way retry logic
doesn't silently corrupt state. Solid deep-dive: https://example.com/article #AIEngineering
```

---

## Bluesky

**Structure:** Lesson framing + one teachable observation + relevance qualifier

```
[Key lesson from the article] — from [TITLE] by [AUTHOR].
Worth your time if you [relevant condition]. [URL]
```

**Rules:**
- Lead with the takeaway, not "Just read…"
- More casual than LinkedIn, less compressed than Twitter
- Name the author — Bluesky culture values attribution
- End with a qualification: "if you work with…", "if you've ever hit…"
- No hashtags required
- The **takeaway wins** — drop the learn-more line if the 300-char budget is tight

**Example:**

```
Backpressure beats retry loops when a downstream agent is slow — pause the
upstream queue instead of hammering. From "Designing Reliable Agent Pipelines" by
Sarah Chen. Worth your time if you've debugged a stuck orchestrator.
https://example.com/article
```

---

## Substack

**Structure:** Learning context + teachable takeaways + what to apply + link

```
[One sentence framing what question you had or what problem you were learning about.]

[TITLE] by [AUTHOR] gets into [topic] — and [one or two concrete principles you
learned or reconsidered].

[A sentence on what you'll apply differently — the actionable shift.]

[URL]

[Topic-matched learn-more/subscribe CTA — one varied line in newsletter voice; see
the Learn-More CTA rule in $PLUGIN_DIR/references/platforms.md]
```

**Rules:**
- Newsletter voice: more personal and reflective than LinkedIn, more substantive than Twitter
- No hashtags — Substack Notes don't use them
- Name the author — attribution matters
- Lead with the learning, not just a reaction
- Keep under 500 chars for optimal engagement in Notes

**Example:**

```
I've been trying to figure out why retry logic quietly corrupts state in agent
pipelines — this article laid out the principle clearly.

"Designing Reliable Agent Pipelines" by Sarah Chen nails the
idempotency-at-every-boundary argument and makes a strong case for backpressure
over retry loops.

The shift from "just retry" to "pause the upstream queue" is a technique I'm
applying to my own orchestrators this week. https://example.com/article

I write about agent architecture patterns — subscribe to keep learning.
```

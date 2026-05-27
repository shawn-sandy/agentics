# Blog Share — Platform Copy Formats

Read in Phase 3 to draft platform-aware copy. For canonical character limits and
universal copy rules, see `$PLUGIN_DIR/references/platforms.md`.
Follow the format for the selected platform exactly — character limits are hard
constraints, not suggestions.

---

## LinkedIn

**Structure:** Hook → 3 numbered takeaways → commentary → CTA → hashtags

```
[One-sentence hook that names the article and its core claim.]

[Article title] by [Author] covers [topic] and here's what stood out:

1. [First key takeaway — one to two sentences]
2. [Second key takeaway — one to two sentences]
3. [Third key takeaway — one to two sentences]

[One or two sentences of personal commentary: why this matters, what surprised you,
or how you plan to apply it.]

Worth a read if [specific audience / condition]: [URL]

#[Hashtag1] #[Hashtag2] #[Hashtag3]
```

**Example:**

```
If you're building multi-agent systems, this article will save you hours.

"Designing Reliable Agent Pipelines" by Sarah Chen tackles the hard problem of
keeping orchestrators and subagents in sync — and here's what stood out:

1. Idempotency at every boundary: agents that retry must produce the same result,
   or your pipeline silently corrupts state.
2. Structured output contracts: prose responses break tool parsers; JSON schemas
   with strict validation prevent silent drift.
3. Backpressure over retry loops: when a downstream agent is slow, pause the
   upstream queue instead of hammering retries.

I've hit each of these in production. The section on backpressure alone is worth
the read.

Essential for anyone working on AI pipelines or workflow orchestration: https://example.com/article

#AIEngineering #MultiAgentSystems #SoftwareArchitecture
```

---

## Twitter/X

**Structure:** Hook (names key insight) + URL + 1–2 hashtags

```
[One punchy sentence that names the single most surprising or useful insight.] [URL] #[Tag]
```

**Rules:**
- No "Great article by…" opener — lead with the insight
- 1–2 hashtags max; they eat character budget fast
- If the article has a memorable quote, lead with it (no surrounding quotation marks)

**Example:**

```
Idempotency at agent boundaries isn't optional — it's the only way retry logic
doesn't silently corrupt state. Solid deep-dive: https://example.com/article #AIEngineering #Agents
```

---

## Bluesky

**Structure:** "Just read…" framing + one observation + relevance qualifier

```
Just read [TITLE] by [AUTHOR] — [one concrete observation from the article].
Worth your time if you [relevant condition]. [URL]
```

**Rules:**
- More casual than LinkedIn, less compressed than Twitter
- Name the author — Bluesky culture values attribution
- End with a qualification: "if you work with…", "if you've ever hit…"
- No hashtags required

**Example:**

```
Just read "Designing Reliable Agent Pipelines" by Sarah Chen — the section on
backpressure instead of retry loops clicked immediately. Worth your time if
you've ever debugged a stuck orchestrator. https://example.com/article
```

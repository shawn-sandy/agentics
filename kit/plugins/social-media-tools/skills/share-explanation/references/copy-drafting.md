# Copy Drafting Reference

Platform/tone resolution and the takeaway-first content rules for the social copy.
Phase 5 of `share-explanation`. Character limits, the **Instructional Voice** doctrine, the
**Learn-More CTA** rule, and the **Default Per-Platform Copy Formats** live in
`$PLUGIN_DIR/references/platforms.md`, which the core reads first.

## Resolve PLATFORM and TONE

Resolve both concretely before prompting:

```bash
# PLATFORM and TONE were parsed from $ARGUMENTS in Phase 1
[ -z "$PLATFORM" ] && [ -n "$DEFAULT_PLATFORM" ] && PLATFORM="$DEFAULT_PLATFORM"
[ -z "$TONE" ]     && [ -n "$DEFAULT_TONE" ]     && TONE="$DEFAULT_TONE"
```

Only if either variable is still empty after applying the above, ask for both in a single
`AskUserQuestion`.

## Takeaway-first

**Takeaway-first**: every post must surface a concrete, applicable takeaway — what the
reader can learn or apply from how this component works (a pattern, technique, or design
principle). The explanation is evidence for the lesson, not the headline.

## Content guidance per platform

- **LinkedIn**: hook on the key takeaway → 2–3 teachable patterns the reader can apply →
  one-line invocation example → learn-more CTA
- **Twitter/X**: one sharp teachable principle in ≤280 chars; invocation if space allows
- **Bluesky**: conversational, takeaway-first, same brevity as Twitter/X
- **Substack**: reflect on the teachable design principle and what the reader can apply;
  patterns as supporting detail

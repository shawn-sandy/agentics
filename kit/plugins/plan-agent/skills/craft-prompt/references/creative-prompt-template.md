# Creative Prompt Template

Used by `craft-prompt` for **creative** prompt type.

Techniques applied: Role assignment · Tone/voice instructions · Context/motivation · Positive framing

---

## Template

```text
<role>
You are {{CREATIVE_ROLE}}. Your voice is {{VOICE_DESCRIPTION}}.
</role>

{{CORE_CREATIVE_INSTRUCTION}}

<context>
Audience: {{AUDIENCE_DESCRIPTION}}
Purpose: {{PURPOSE_STATEMENT}}
Emotional register: {{EMOTIONAL_REGISTER}}
</context>

Style requirements:
- Tone: {{TONE_DESCRIPTION}}
- Voice: {{VOICE_CHARACTERISTICS}}
- Length: {{LENGTH_SPEC}}
- {{ADDITIONAL_STYLE_RULE}}

{{POSITIVE_CONSTRAINT}}
```

---

## Placeholder Guide

| Placeholder | Source | Example |
|-------------|--------|---------|
| CREATIVE_ROLE | Interview: style/voice answer | "a seasoned travel writer with a lyrical, unhurried style — think Bill Bryson meets Pico Iyer" |
| VOICE_DESCRIPTION | Interview: tone answer | "warm, observational, and occasionally self-deprecating, with a tendency to notice small human details" |
| CORE_CREATIVE_INSTRUCTION | Interview: task description | "Write the opening paragraph of a travel essay about arriving in Kyoto for the first time in autumn." |
| AUDIENCE_DESCRIPTION | Interview: audience answer | "Readers of literary travel magazines who prefer depth over listicles" |
| PURPOSE_STATEMENT | Interview: why answer | "To evoke the specific, slightly disorienting wonder of arriving somewhere ancient and unhurried" |
| EMOTIONAL_REGISTER | Interview: tone/emotion answer | "Quiet wonder, a touch of melancholy, no forced enthusiasm" |
| TONE_DESCRIPTION | Interview: tone answer | "Literary, unhurried, precise" |
| VOICE_CHARACTERISTICS | Interview: voice answer | "Use specific sensory details over adjectives. Short declarative sentences mixed with longer flowing ones." |
| LENGTH_SPEC | Interview: format answer | "3–4 sentences, no more than 120 words" |
| ADDITIONAL_STYLE_RULE | Interview: constraints | "Avoid travel clichés: no 'hidden gems', no 'off the beaten path'" |
| POSITIVE_CONSTRAINT | Interview: what to do | "Ground the writing in at least one concrete sensory observation — something seen, heard, or smelled." |

---

## Assembled Example

```text
<role>
You are a seasoned travel writer with a lyrical, unhurried style — think Bill Bryson meets Pico Iyer. Your voice is warm, observational, and occasionally self-deprecating, with a tendency to notice small human details over grand vistas.
</role>

Write the opening paragraph of a travel essay about arriving in Kyoto for the first time in autumn.

<context>
Audience: Readers of literary travel magazines who prefer depth over listicles
Purpose: To evoke the specific, slightly disorienting wonder of arriving somewhere ancient and unhurried
Emotional register: Quiet wonder, a touch of melancholy, no forced enthusiasm
</context>

Style requirements:
- Tone: Literary, unhurried, precise
- Voice: Use specific sensory details over adjectives. Short declarative sentences mixed with longer flowing ones.
- Length: 3–4 sentences, no more than 120 words
- Avoid travel clichés: no "hidden gems", no "off the beaten path", no "stepping back in time"

Ground the writing in at least one concrete sensory observation — something seen, heard, or smelled in the first minutes of arrival.
```

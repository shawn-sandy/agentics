# Analytical Prompt Template

Used by `prompt` for **analytical** prompt type.

Techniques applied: Long-context patterns (document grounding) · Thinking/CoT · Self-check · Output format

---

## Template

```text
<document>
<content>
{{DOCUMENT_CONTENT}}
</content>
</document>

<thinking>
Before answering, work through this analysis step by step:
1. {{ANALYSIS_STEP_1}}
2. {{ANALYSIS_STEP_2}}
3. {{ANALYSIS_STEP_3}}
</thinking>

{{CORE_ANALYSIS_INSTRUCTION}}

Quote the most relevant passage from the document before drawing each conclusion.

Self-check before responding:
- Is every claim directly supported by a passage I quoted?
- Have I addressed the specific question asked, not a related one?
- {{ADDITIONAL_SELF_CHECK}}

Output requirements:
- Format: {{OUTPUT_FORMAT}}
- Length: {{OUTPUT_LENGTH}}
- Cite passages as: "The document states: '...'"
```

---

## Placeholder Guide

| Placeholder | Source | Example |
|-------------|--------|---------|
| DOCUMENT_CONTENT | User-provided at runtime | "[Insert the full text of the research paper here]" |
| ANALYSIS_STEP_1 | Derived from analysis goal | "Identify the central claim or thesis of the document" |
| ANALYSIS_STEP_2 | Derived from analysis goal | "Find the key evidence the author uses to support that claim" |
| ANALYSIS_STEP_3 | Derived from analysis goal | "Identify any assumptions the argument relies on that are not supported by evidence" |
| CORE_ANALYSIS_INSTRUCTION | Interview: task description | "Analyze this research paper and identify its central claim, the three strongest pieces of supporting evidence, and one significant assumption the argument relies on." |
| ADDITIONAL_SELF_CHECK | Interview: failure mode | "Am I attributing conclusions to the document that are my own inference, not the author's stated position?" |
| OUTPUT_FORMAT | Interview: format answer | "Three sections: Claim, Evidence (numbered list), Assumptions" |
| OUTPUT_LENGTH | Interview: length answer | "300–400 words total" |

---

## Assembled Example

```text
<document>
<content>
[Insert the full text of the research paper, article, or report here before sending this prompt]
</content>
</document>

<thinking>
Before answering, work through this analysis step by step:
1. Identify the central claim or thesis of the document — what is the author arguing or asserting?
2. Find the three strongest pieces of evidence the author uses to support that claim, noting where each appears
3. Identify any significant assumptions the argument relies on that are not explicitly proven in the document
</thinking>

Analyze this research paper and identify: (1) its central claim, (2) the three strongest pieces of supporting evidence, and (3) one significant assumption the argument relies on.

Quote the most relevant passage from the document before drawing each conclusion.

Self-check before responding:
- Is every claim directly supported by a passage I quoted from the document?
- Have I addressed the specific question (claim, evidence, assumption), not a general summary?
- Am I attributing conclusions to the document that are my own inference, not the author's stated position?

Output requirements:
- Format: Three labeled sections — "Central Claim", "Supporting Evidence" (numbered list of 3), "Key Assumption"
- Length: 300–400 words total
- Cite passages as: "The document states: '...'"
```

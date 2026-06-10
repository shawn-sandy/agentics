# Anthropic Claude Prompting Best Practices — Distilled Reference

This file is consumed by the `refine-prompt` skill to apply the correct technique subset for each prompt type. Each technique maps to a specific phase of the skill's pipeline.

---

## 1. Clarity and Directness

**Principle:** Be clear, direct, and specific. Treat Claude as a capable colleague — give precise instructions without softening hedges.

**Implementation:**
- Lead with the most important instruction
- Use specific, actionable verbs ("Summarize", "Extract", "Rewrite")
- State the desired output format explicitly upfront
- Avoid double negatives and vague qualifiers ("somewhat", "fairly")

**Applied in:** task and analytical prompts — Phase 4 Draft

---

## 2. Context and Motivation (Add Context to Improve Performance)

**Principle:** Providing the *why* behind instructions helps Claude deliver more targeted responses. Context transforms a generic instruction into a calibrated one.

**Implementation:**
- Include the audience, purpose, and use case
- Explain what a bad output would look like
- State the downstream action that the output supports
- Add relevant constraints or domain knowledge

**Applied in:** all prompt types — Phase 2 Interview (the "why" question)

---

## 3. XML Tags for Structure

**Principle:** Use XML tags to create clear boundaries between prompt components. Tags prevent ambiguity and make prompts easier to maintain.

**Key tags:**
- `<instructions>...</instructions>` — the core task instructions
- `<context>...</context>` — background information or document content
- `<example>...</example>` — input/output demonstrations
- `<constraints>...</constraints>` — rules and guardrails
- `<role>...</role>` — persona or identity assignment
- `<document>...</document>` — long-context document grounding
- `<thinking>...</thinking>` — internal reasoning scaffold

**Applied in:** system and task prompts — Phase 3 Structure

---

## 4. Role Assignment (Give Claude a Role)

**Principle:** Assigning a role or persona activates domain knowledge and sets response style. Works best when paired with specific context about the role's constraints.

**Implementation:**
- State the role in the opening line: "You are an expert [role] with deep experience in [domain]."
- Include what makes this role distinct from a generic assistant
- Pair with constraints for chatbot/agent system prompts
- Use for creative prompts to set tone and voice

**Applied in:** system and creative prompts — Phase 3 Structure

---

## 5. Few-Shot Examples

**Principle:** Demonstrating input/output pairs calibrates style, format, and scope more precisely than description alone.

**Implementation:**
- Include 1–3 `<example><input>...</input><output>...</output></example>` pairs
- Choose examples that cover edge cases and the target style
- Place examples before the actual instruction
- Use consistent format in examples that mirrors the desired output format

**Applied in:** task prompts — Phase 3 Structure

---

## 6. Thinking / Chain-of-Thought Scaffolding

**Principle:** Prompting Claude to reason before answering improves accuracy on complex tasks. Extended thinking externalizes the reasoning process.

**Implementation:**
- Add a `<thinking>` block before the main instruction for complex tasks
- Instruct: "Before answering, work through the problem step by step in `<thinking>` tags."
- For multi-step tasks, enumerate the reasoning steps explicitly
- Use "think carefully" only when you want visible step-by-step work

**Applied in:** task and analytical prompts — Phase 3 Structure

---

## 7. Output Formatting

**Principle:** Specify format, length, and structure explicitly. Claude adjusts output to match stated requirements, but needs specific instructions to do so optimally.

**Implementation:**
- State the format: markdown, JSON, plain text, numbered list, table
- State the length: "in 3 bullet points", "under 200 words", "a full paragraph"
- Specify tone: "formal", "concise", "conversational"
- Add output constraints: "do not include preamble", "end with a summary"
- Use positive framing: "Respond with X" not "Don't include Y"

**Applied in:** all prompt types — Phase 4 Draft

---

## 8. Long-Context Patterns (Document Grounding)

**Principle:** For prompts that process documents, use explicit document wrappers and quote-extraction instructions to prevent hallucination and improve precision.

**Implementation:**
- Wrap source documents in `<document><content>...</content></document>` tags
- Add a quote-extraction instruction: "Quote the relevant passage before answering."
- Include a self-check: "Before responding, verify your answer is supported by the document."
- Place documents before instructions in the prompt (Claude attends to beginning and end)

**Applied in:** analytical prompts — Phase 3 Structure

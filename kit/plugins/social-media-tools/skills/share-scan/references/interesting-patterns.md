# Interesting Patterns Reference

Scoring tables for `share-scan`. Re-read on every run so users can tune weights without editing the skill.

**Primary criterion: teaching value.** Score each candidate by how well it
illustrates a principle, technique, or pattern a reader can learn from and apply.
A change that teaches something (an agentic-dev lesson, a design pattern, a
technique) outscores a change that is merely impressive or novel.

---

## History Mode — Commit Scoring

| Pattern | Score | Notes |
|---------|-------|-------|
| `feat:` or `feature:` prefix | +3 | New capability — teaches a technique |
| New skill/agent/command file added | +3 | Plugin authoring — teaches agentic patterns |
| New public API surface | +3 | New function/class exported — teaches API design |
| `refactor:` with >50 lines changed | +2 | Architecture lesson — teaches design decisions |
| `perf:` prefix | +2 | Performance technique worth teaching |
| Algorithm or data structure change | +2 | Teaches computational thinking |
| `fix:` prefix for a non-trivial bug | +1 | Teaches root-cause analysis |
| `fix:` prefix for a trivial typo/lint | -3 | No teachable content |
| `chore:` or `ci:` or `build:` prefix | -5 | Rarely teaches something applicable |
| `docs:` prefix | -3 | Usually not visual enough for a card |
| `test:` or `spec:` only changes | -3 | Test-only changes rarely teach well |
| Merge commit (`Merge branch`) | -10 | Never share merge commits |
| Revert commit (`Revert "`) | -10 | Never share reverts |
| Single file changed, <5 lines | -2 | Low teaching signal |

**Inclusion threshold:** score ≥ 2. If fewer than 3 candidates meet this, include score ≥ 1 as fill-ups up to 3 total.

---

## Codebase Mode — File/Function Scoring

| Pattern | Score | Notes |
|---------|-------|-------|
| Public exported function/class with JSDoc or docstring | +3 | Teaches API design — well-documented |
| Algorithm with explicit complexity comment (`O(n)`) | +3 | Teaches computational thinking |
| Custom hook, decorator, or higher-order function | +3 | Teaches an advanced pattern readers can apply |
| Utility function with clear single responsibility | +2 | Teaches clean design |
| State machine or FSM implementation | +2 | Teaches architectural thinking |
| Functional composition chain (>3 transforms) | +2 | Teaches functional patterns |
| Configuration-driven design (data over code) | +2 | Teaches a design principle |
| Test file with property-based or generative tests | +2 | Teaches advanced testing techniques |
| File >500 lines (likely a god class) | -3 | Too large to teach cleanly |
| File with >5 TODO / FIXME / HACK comments | -3 | Work in progress |
| Generated file (auto-generated header comment) | -10 | Never share generated code |
| Minified/bundled file | -10 | Never share minified output |
| Migration file (db schema migration) | -5 | Database internals |
| Lock file (`package-lock.json`, `yarn.lock`) | -10 | Never share lock files |

**Inclusion threshold:** same as history mode — score ≥ 2, fill-up to ≥ 1.

---

## Card-Type Decision Tree

Use this to pick the card template for each candidate:

```
Is it a diff / line-by-line change showing before/after?
  YES → diff-card

Is it a new feature, release, version bump, or capability announcement?
  YES → feature-card

Is it a code insight, teachable pattern, technique, or design lesson?
  YES → quote-card

Default → feature-card
```

---

## Platform Heuristics

| Content type | Best platform | Format hint |
|-------------|--------------|-------------|
| New feature / release | LinkedIn | Story arc: problem → solution → outcome |
| Elegant algorithm | Twitter/X | One punchy line + code snippet |
| Developer insight / opinion | Bluesky | Conversational, 2-3 sentences |
| Architecture decision | LinkedIn | Narrative with context |
| Quick tip / trick | Twitter/X or Bluesky | Punchy + hashtag |
| Open-source contribution | LinkedIn | Context + impact |

---

## Share-Code Prompt Template

Each digest entry should include a ready-to-paste prompt:

```
/social-media-tools:share-code <card-type> for <platform>: <one-sentence description of what to share>
```

Example:
```
/social-media-tools:share-code feature-card for LinkedIn: the new share-scan skill that finds shareable commits from git history
```

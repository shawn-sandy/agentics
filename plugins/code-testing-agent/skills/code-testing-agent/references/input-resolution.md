# Input Resolution

Detailed heuristics for Step 1 — resolving the target code to analyze.

## Table of Contents

- [Detecting a File Path](#detecting-a-file-path)
- [Detecting a Function or Method Name](#detecting-a-function-or-method-name)
- [Error Handling](#error-handling)
- [Reporting](#reporting)
- [Multi-file Handling](#multi-file-handling)

---

## Detecting a File Path

A file path may appear in the invocation message in any of these forms:

- **Backticks** — `` `src/auth.ts` ``
- **Quotes** — `"src/auth.ts"` or `'src/auth.ts'`
- **Bare token** — `src/auth.ts` or `./lib/utils.js`
- **After keywords** — "for", "in", "analyze", "review", "of" (e.g., "suggest tests for `src/auth.ts`")
- **Known extension** — any token ending in `.ts`, `.js`, `.tsx`, `.jsx`, `.py`, `.go`, `.rs`, `.rb`, `.java`, `.cs`

If a file path is found, resolve it relative to the current working directory and confirm it exists. **If it does not exist, stop and report the error to the user — do not fall through to lower-priority sources.**

---

## Detecting a Function or Method Name

Look for a function or method name alongside a file path. Indicators:

- After "function", "method", "the", "called" — e.g., "test the `validateToken` function", "the `render` method in `Button.tsx`"
- A backtick-wrapped identifier that is **not** a file path (no `/` or known code extension)

If a function/method name is found:
- Note it.
- Once the file is resolved (from any priority level), scope the Step 3 analysis to that function/method only.
- Tell the user: "Scoping analysis to `[name]` function only."

If a function name is given **without** a file path, still require a file path from priority levels 3–6 before scoping. Do not attempt to guess which file contains the function.

---

## Error Handling

| Situation | Action |
|-----------|--------|
| File path found but does not exist | Stop. Report error. Do not fall through. |
| Function name given, no file path | Continue to lower-priority sources to find the file. |
| More than 5 files specified | Ask the user to narrow scope or confirm they want a broad analysis before proceeding. |
| No source found after all 6 levels | Ask: "Which code would you like me to suggest tests for? Please provide a file path or paste the code." |

---

## Reporting

Once the target is resolved, report clearly:

- File(s) to be analyzed
- Function/method scope, if any (e.g., "Scoping analysis to `validateToken` function only.")
- Whether the analysis is full-file or function-scoped

Then read each target file in full before proceeding to Step 2.

---

## Multi-file Handling

If multiple files are specified, process them together as a unit — they may interact. In Step 5, group test suggestions by file.

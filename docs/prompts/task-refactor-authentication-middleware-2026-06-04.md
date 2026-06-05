---
type: task
intent: Refactor the authentication middleware to use JWT tokens instead of session cookies
techniques: Clarity, XML structure, CoT scaffolding, Output format
created: 2026-06-04
---

# Task: Refactor Authentication Middleware

```text
<context>
You are refactoring an Express.js authentication middleware layer.
The current implementation uses session cookies; the target is JWT tokens.
</context>

<thinking>
Step 1 — identify all session cookie read/write points in the middleware.
Step 2 — map each to the JWT equivalent (sign on login, verify on request).
Step 3 — update error responses to match the new token expiry semantics.
</thinking>

Refactor the authentication middleware from session cookies to JWT tokens.
Preserve all existing route protection behavior. Return only the modified
middleware file with inline comments explaining each change.

Output format: a single code block containing the updated middleware file.
```

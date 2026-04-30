# Example Analysis

A complete sample analysis demonstrating the expected output format.

````markdown
### Summary

This module manages user session lifecycle including creation, validation,
renewal, and cleanup. The core logic works but has accumulated structural
debt — duplicated validation, a god function, and primitive obsession around
session tokens.

### Smell Severity Rating

**Needs Refactoring** — One critical smell (god function at 120 lines) and
several moderate smells (duplicated validation, primitive obsession) indicate
targeted refactoring will meaningfully improve maintainability.

### Critical Smells

**1. God Function — `handleSession` (session-manager.ts:45, 120 lines)**

```typescript
export function handleSession(req: Request, res: Response) {
  // 120 lines handling creation, validation, renewal, cleanup,
  // error recovery, logging, and metrics — all in one function
  if (req.method === 'POST') {
    // 30 lines for creation
  } else if (req.headers['x-session-renew']) {
    // 25 lines for renewal
  } else if (isExpired(req.session)) {
    // 20 lines for cleanup
  }
  // ... continues
}
```

This function handles four distinct responsibilities. Each branch is a separate
concern that should be its own function.

**Suggested refactoring:**

```typescript
export function handleSession(req: Request, res: Response) {
  if (req.method === 'POST') return createSession(req, res);
  if (req.headers['x-session-renew']) return renewSession(req, res);
  if (isExpired(req.session)) return cleanupSession(req, res);
  return validateSession(req, res);
}
```

### Moderate Smells

**1. Duplicated Validation (session-manager.ts:78, session-manager.ts:142)**

The same token format check appears in both `renewSession` and
`validateSession`:

```typescript
if (!token || token.length !== 64 || !/^[a-f0-9]+$/.test(token)) {
  throw new InvalidTokenError();
}
```

Extract into a shared `assertValidToken(token: string)` function.

**2. Primitive Obsession — Session Token (multiple locations)**

Session tokens are passed as bare `string` throughout the module. A `SessionToken`
branded type would prevent accidental misuse (e.g., passing a user ID where a
token is expected).

```typescript
type SessionToken = string & { readonly __brand: 'SessionToken' };

function createToken(): SessionToken {
  return crypto.randomBytes(32).toString('hex') as SessionToken;
}
```

**3. Magic Number (session-manager.ts:23)**

```typescript
const isExpired = Date.now() - session.createdAt > 86400000;
```

Replace with a named constant: `const SESSION_TTL_MS = 24 * 60 * 60 * 1000;`

### Refactoring Plan

Created at `docs/plans/simplify-session-manager.md` with 4 prioritized steps:

1. Extract `handleSession` into four single-responsibility functions (high impact)
2. Extract duplicated token validation into `assertValidToken` (moderate impact)
3. Introduce `SessionToken` branded type (moderate impact)
4. Replace magic numbers with named constants (low impact)

### Positive Observations

- Clear module boundary — session logic is self-contained, not scattered
- Good error class hierarchy (`InvalidTokenError`, `SessionExpiredError`)
- Consistent use of early returns in validation paths
````

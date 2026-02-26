# Plan: Remove Unsupported Fields from marketplace.json Plugin Entries

## Context

The `.claude-plugin/marketplace.json` plugin entries contain fields that the schema (documented in `CHANGELOG.md` lines 124–134) explicitly reserves for `plugin.json` only — specifically `author`, `license`, and additional undocumented fields (`keywords`, `homepage`, `repository`). These fields cause marketplace manifest validation to fail during registration, blocking users from loading the marketplace.

Per the schema table:

| Field       | `plugin.json` | `marketplace.json` plugin entry |
|-------------|:---:|:---:|
| `author`    | allowed | **not allowed** |
| `license`   | allowed | **not allowed** |
| `keywords`  | (not in table) | **not allowed** |
| `homepage`  | (not in table) | **not allowed** |
| `repository`| (not in table) | **not allowed** |
| `category`  | not allowed | allowed |
| `tags`      | not allowed | allowed |

## File to Modify

- `.claude-plugin/marketplace.json` — all 5 plugin entries

## Steps

1. Remove the following fields from **every** plugin entry (`hello-world`, `dev-tools`, `claude-md-optimizer`, `code-review`, `plan-interview`):
   - `author`
   - `license`
   - `keywords` (duplicate of `tags`; not in schema)
   - `homepage`
   - `repository`

2. Retain only the schema-valid fields per plugin entry:
   - `name` (required)
   - `source` (required)
   - `version` (required)
   - `description` (required)
   - `category` (allowed)
   - `tags` (allowed)

3. Verify result: each plugin entry should have exactly 6 fields.

## Verification

- Confirm no `author`, `license`, `keywords`, `homepage`, or `repository` keys remain in any plugin entry
- Confirm `tags` is still present (not removed alongside `keywords`)
- Run: `claude --plugin-dir ~/devbox/agentics/plugins/hello-world` to confirm no parse errors
- Optionally: `/plugin marketplace add ~/devbox/agentics` to confirm registration succeeds

## Unresolved Questions

None — the schema violation is clearly documented in CHANGELOG.md.

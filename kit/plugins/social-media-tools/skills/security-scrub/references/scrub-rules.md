# Scrub Rules Reference

## Pattern Table

| Severity | Pattern | Examples | Action |
|----------|---------|---------|--------|
| HIGH | `sk-[A-Za-z0-9]{20,}` | OpenAI/Anthropic API keys | BLOCK |
| HIGH | `ghp_[A-Za-z0-9]{36}` | GitHub personal access tokens | BLOCK |
| HIGH | `ghs_[A-Za-z0-9]{36}` | GitHub server tokens | BLOCK |
| HIGH | `AKIA[A-Z0-9]{16}` | AWS access key IDs | BLOCK |
| HIGH | `xoxb-[0-9]{11}-[0-9]{11}-[A-Za-z0-9]{24}` | Slack bot tokens | BLOCK |
| HIGH | `xoxp-[A-Za-z0-9-]{72,}` | Slack user tokens | BLOCK |
| HIGH | `-----BEGIN (RSA|EC|OPENSSH|PGP) PRIVATE KEY` | Private keys | BLOCK |
| HIGH | `[A-Z_]{3,}=[[:alnum:]_\-]{32,}` | Generic long env var values | BLOCK |
| HIGH | `eyJ[A-Za-z0-9_\-]{20,}\.eyJ` | JWT tokens | BLOCK |
| HIGH | `mongodb(\+srv)?://[^/\s]+:[^@\s]+@` | MongoDB connection strings with credentials | BLOCK |
| HIGH | `postgres://[^/\s]+:[^@\s]+@` | PostgreSQL connection strings with credentials | BLOCK |
| MEDIUM | `password\s*[=:]\s*\S{4,}` | Inline password assignments | WARN |
| MEDIUM | `secret\s*[=:]\s*\S{4,}` | Inline secret assignments | WARN |
| MEDIUM | `token\s*[=:]\s*\S{8,}` | Inline token assignments | WARN |
| MEDIUM | `api_key\s*[=:]\s*\S{8,}` | API key assignments | WARN |
| MEDIUM | `private_key\s*[=:]\s*\S{8,}` | Private key assignments | WARN |
| LOW | `10\.[0-9]+\.[0-9]+\.[0-9]+` | Internal IP (10.x.x.x) | NOTE |
| LOW | `192\.168\.[0-9]+\.[0-9]+` | Internal IP (192.168.x.x) | NOTE |
| LOW | `172\.(1[6-9]|2[0-9]|3[01])\.[0-9]+\.[0-9]+` | Internal IP (172.16-31.x.x) | NOTE |
| LOW | `\.internal\b` | Internal service hostnames | NOTE |
| LOW | `localhost:[0-9]{4,5}` | Localhost port references | NOTE |

## File-Path Block List

Content from these file paths must never be shared regardless of content:

- `.env`, `.env.*`, `*.env`
- `credentials.json`, `credentials.yaml`, `credentials.yml`
- `secrets.json`, `secrets.yaml`, `secrets.yml`
- `id_rsa`, `id_ed25519`, `id_ecdsa`, `*.pem`, `*.p12`, `*.pfx`, `*.key`
- `~/.ssh/*`, `~/.aws/credentials`, `~/.config/gcloud/*`
- `*.keystore`, `*.jks`
- Any file under `.git/` (git object store, config with credentials)

## Never-Share Rules (no exceptions)

These must always result in BLOCKED regardless of context or framing:

1. **Private key material** — any `-----BEGIN ... PRIVATE KEY-----` block
2. **JWT tokens** — `eyJ...` base64url payloads containing signatures
3. **Database connection strings with credentials** — `protocol://user:pass@host`
4. **SSH key content** — file content from `~/.ssh/`
5. **Cloud provider credentials** — AWS keys, GCP service account JSON, Azure certificates
6. **`.env` file content** — even "example" `.env` files may contain real values

## Masking Format

When reporting a matched value, show:
- First 4 characters + `***` + last 4 characters
- Example: `sk-abcd***wxyz`
- For patterns with no visible value (e.g. file path), report the path only

## Structured Report Format

```
SCRUB RESULT: [PASS | BLOCKED | WARN]
---
Findings:
  - [HIGH|MEDIUM|LOW] <pattern-name>: <masked-value> (line N)
  - ...
ALLOWLIST verdict: [PASS | BLOCKED]
Reason: <one sentence>
```

`ALLOWLIST verdict: BLOCKED` overrides `SCRUB RESULT: PASS` — callers must check both.

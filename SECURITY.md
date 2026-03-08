# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in this project, please report it responsibly.

**Do not open a public issue for security vulnerabilities.**

Instead, email **shawnsandy04@gmail.com** with:

- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

You should receive a response within 72 hours. We will work with you to understand the issue and coordinate a fix before any public disclosure.

## Scope

This policy covers:

- Plugin manifest files and marketplace configuration
- Plugin commands, skills, agents, and hooks
- Repository infrastructure and CI/CD

## Supported Versions

| Version | Supported |
|---------|-----------|
| Latest on `main` | Yes |
| Older commits | No |

## Best Practices for Plugin Authors

- Never include secrets, API keys, or credentials in plugin files
- Validate and sanitize all user inputs in commands
- Use relative paths in marketplace configuration — avoid hardcoded absolute paths
- Follow the principle of least privilege in agent and hook implementations

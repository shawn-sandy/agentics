---
description: Greet the user with a friendly message
---

# Greet Command

Greet the user warmly and introduce yourself as an example plugin. Explain that you're part of the agentics marketplace testing suite.

If the user provides a name in $ARGUMENTS, greet them by name. Otherwise, use a general greeting.

## Examples

**With name:**

```
User: 
Response: Hello, Alice! I'm the hello-world plugin, a minimal example from the agentics marketplace testing suite. I'm here to demonstrate basic plugin structure and functionality.
```

**Without name:**

```
User: /hello-world:greet
Response: Hello! I'm the hello-world plugin, a minimal example from the agentics marketplace testing suite. I demonstrate the basic structure of a Claude Code plugin with a simple command.
```

## Implementation Notes

- Keep the greeting friendly and informative
- Mention your role as a test/example plugin
- If arguments are provided, incorporate them naturally
- Optionally explain what the hello-world plugin demonstrates

# hello-world Commands

Slash commands provided by the `hello-world` plugin.

## Available Commands

### `/hello-world:greet`

Greet the user with a friendly message.

**Invocation:**

```
/hello-world:greet
/hello-world:greet [name]
```

**Arguments:**

| Argument | Required | Description |
|----------|----------|-------------|
| `name`   | No       | Name to include in the greeting |

**Examples:**

```
/hello-world:greet
# → Hello! I'm the hello-world plugin...

/hello-world:greet Alice
# → Hello, Alice! I'm the hello-world plugin...
```

**Behavior:**

- If a name is provided via `$ARGUMENTS`, greets the user by name
- If no argument is given, uses a general greeting
- Always identifies itself as a minimal example plugin from the agentics marketplace testing suite

## Command Files

| File | Command | Description |
|------|---------|-------------|
| `greet.md` | `/hello-world:greet` | Friendly greeting with optional name |

## Notes

This plugin contains a single command and exists as a minimal reference implementation. See the [plugin README](../README.md) for installation and usage details.

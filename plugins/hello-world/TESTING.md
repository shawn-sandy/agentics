# Testing Guide: hello-world Plugin

This guide provides comprehensive instructions for testing the `hello-world` plugin locally.

## Prerequisites

- **Claude Code CLI** must be installed and accessible in your PATH
- Working directory should be the project root (the cloned `agentics` directory)
- Terminal with bash/zsh support

## Understanding Commands vs Skills

**Important Distinction:**
- **Commands** require explicit invocation via `/plugin-name:command-name` syntax
- **Skills** activate automatically based on user intent
- The `greet` component is a **command**, not a skill
- If you see "Unknown skill: hello-world:greet", it means the plugin isn't loaded or the syntax is incorrect

## Loading Methods

### Method 1: Direct Plugin Directory Loading (Recommended for Testing)

This method bypasses marketplace infrastructure and loads the plugin directly:

```bash
# From project root
claude --plugin-dir ./plugins/hello-world
```

**Expected Output:**
- Claude Code session starts
- No error messages during plugin loading
- Plugin should be silently loaded and available

**Verification:**
Once in the Claude session, type `/help` or check available commands to confirm the plugin loaded.

### Method 2: Multiple Plugin Loading

Load several plugins simultaneously for integration testing:

```bash
claude --plugin-dir ./plugins/hello-world --plugin-dir ./plugins/dev-tools
```

This tests that plugins don't conflict with each other.

### Method 3: Marketplace-Based Loading

*Note: This method requires marketplace API implementation (planned future feature)*

```bash
# Future functionality
claude --marketplace ./marketplace-data
```

## Test Cases

### TC1: Load Plugin Without Errors

**Objective:** Verify the plugin loads successfully

**Steps:**
1. Navigate to project root
2. Run: `claude --plugin-dir ./plugins/hello-world`
3. Observe console output

**Expected Result:**
- Claude Code session starts
- No error messages
- Prompt appears ready for input

**Failure Indicators:**
- Error: "Invalid plugin manifest"
- Error: "Plugin not found"
- Session fails to start

### TC2: Verify Plugin Appears in Available Commands

**Objective:** Confirm the plugin is registered and discoverable

**Steps:**
1. Load plugin using Method 1
2. In Claude session, type: `/help` (or check available commands)
3. Look for `hello-world` in the plugin list

**Expected Result:**
- `hello-world` plugin appears in loaded plugins
- `greet` command is listed under hello-world
- Description: "Simple greeting command"

**Failure Indicators:**
- Plugin not listed
- Command not visible
- Wrong description shown

### TC3: Invoke Command Without Arguments

**Objective:** Test basic command execution

**Steps:**
1. Load plugin using Method 1
2. In Claude session, type: `/hello-world:greet`
3. Observe the response

**Expected Result:**
- Claude generates a friendly greeting
- Greeting mentions "agentics marketplace"
- No error messages

**Example Output:**
```
Hello! Welcome to the agentics marketplace plugin system.
I'm here to help you explore the marketplace and discover amazing plugins.
```

**Failure Indicators:**
- Error: "Unknown skill: hello-world:greet"
- Error: "Command not found"
- No response
- Generic response not mentioning the marketplace

### TC4: Invoke Command With Name Argument

**Objective:** Test command argument handling

**Steps:**
1. Load plugin using Method 1
2. In Claude session, type: `/hello-world:greet Alice`
3. Observe the response

**Expected Result:**
- Claude generates a personalized greeting
- Greeting includes the name "Alice"
- Greeting mentions "agentics marketplace"

**Example Output:**
```
Hello, Alice! Welcome to the agentics marketplace plugin system.
I'm here to help you explore the marketplace and discover amazing plugins.
```

**Failure Indicators:**
- Name not incorporated
- Generic greeting without personalization
- Argument parsing errors

### TC5: Verify Error Handling

**Objective:** Test plugin behavior with invalid invocations

**Steps:**
1. Load plugin using Method 1
2. Try: `/hello-world:nonexistent`
3. Try: `/wrong-plugin:greet`

**Expected Result:**
- Clear error message: "Command not found"
- Suggestion to check available commands
- Session remains stable (no crash)

**Failure Indicators:**
- Unclear error messages
- Session crashes
- Plugin unloads unexpectedly

## Troubleshooting

### Plugin Not Loading

**Symptom:** Error when running `claude --plugin-dir ./plugins/hello-world`

**Possible Causes:**
1. **Incorrect path** - Verify you're in the project root directory
   ```bash
   pwd  # Should show your agentics project root
   ls plugins/hello-world  # Should list plugin contents
   ```

2. **Invalid plugin structure** - Check plugin.json exists:
   ```bash
   cat plugins/hello-world/.claude-plugin/plugin.json
   ```

3. **File permissions** - Ensure files are readable:
   ```bash
   ls -la plugins/hello-world/.claude-plugin/
   ```

**Solution:**
- Verify directory structure matches Claude Code plugin standards
- Check that `plugin.json` contains required fields: name, version, description
- Ensure all files have read permissions

### Command Not Found

**Symptom:** "Unknown skill: hello-world:greet" or "Command not found"

**Possible Causes:**
1. **Plugin not loaded** - Plugin must be loaded before commands are available
2. **Wrong syntax** - Commands use `/plugin-name:command-name` format
3. **Typo** - Check spelling of plugin name and command name

**Solution:**
- Reload the plugin using `claude --plugin-dir ./plugins/hello-world`
- Verify syntax: `/hello-world:greet` (not `/hello world greet`)
- Run `/help` to see available commands
- Check that command file exists: `plugins/hello-world/commands/greet.md`

### "Unknown Skill" Error Confusion

**Symptom:** Error message says "Unknown skill" but you're trying to invoke a command

**Explanation:**
- This is a misleading error message from Claude Code
- `greet` is a **command**, not a skill
- The error indicates the plugin isn't loaded or command isn't found

**Solution:**
- Ensure plugin is loaded first
- Use correct command syntax: `/hello-world:greet`
- Skills activate automatically; commands require explicit invocation

### Permission Issues

**Symptom:** "Permission denied" errors

**Solution:**
```bash
# Make test script executable
chmod +x plugins/hello-world/test.sh

# Verify file permissions
ls -la plugins/hello-world/
```

### Claude Code Version Compatibility

**Symptom:** Plugin works locally but not in production

**Possible Cause:**
- Claude Code CLI version mismatch
- Plugin uses features not available in older versions

**Solution:**
- Check Claude Code version: `claude --version`
- Verify plugin manifest uses stable features
- Test with multiple Claude Code versions if possible

### Argument Not Being Used

**Symptom:** Command ignores the name argument

**Possible Cause:**
- Command file doesn't reference `$ARGUMENTS` variable
- Argument parsing issue in Claude Code

**Solution:**
- Check `commands/greet.md` contains `$ARGUMENTS` reference
- Verify YAML frontmatter is correctly formatted
- Test with simple arguments first (single word, no special characters)

## Verification Checklist

Use this checklist to confirm successful testing:

- [ ] Plugin loads without errors using `claude --plugin-dir ./plugins/hello-world`
- [ ] Command appears in `/help` or command list
- [ ] `/hello-world:greet` executes and produces greeting
- [ ] Greeting mentions "agentics marketplace"
- [ ] `/hello-world:greet TestUser` incorporates "TestUser" in greeting
- [ ] No console errors during execution
- [ ] Plugin works alongside other plugins (multi-plugin test)
- [ ] Invalid commands produce clear error messages
- [ ] Session remains stable after multiple invocations

## Quick Test Workflow

For rapid testing during development:

```bash
# 1. Navigate to project root
cd /path/to/agentics

# 2. Run the test helper script
./plugins/hello-world/test.sh

# 3. Follow the on-screen instructions

# 4. Load the plugin
claude --plugin-dir ./plugins/hello-world

# 5. In Claude session, test commands
# /hello-world:greet
# /hello-world:greet YourName
```

## Advanced Testing

### Testing with Modified Commands

If you modify `commands/greet.md`:

1. Exit the Claude Code session
2. Reload the plugin: `claude --plugin-dir ./plugins/hello-world`
3. Re-run test cases to verify changes

Changes to command files require session restart to take effect.

### Testing Marketplace Registration

To verify marketplace registration is correct:

```bash
# Check marketplace.json references the plugin
cat marketplace-data/.claude-plugin/marketplace.json | grep "hello-world"

# Verify version consistency
# Plugin version:
grep version plugins/hello-world/.claude-plugin/plugin.json

# Marketplace version:
grep -A 5 '"name": "hello-world"' marketplace-data/.claude-plugin/marketplace.json
```

Versions should match exactly.

### Integration Testing

Test the plugin alongside other marketplace plugins:

```bash
# Load multiple plugins
claude --plugin-dir ./plugins/hello-world --plugin-dir ./plugins/dev-tools

# In session, verify both work:
# /hello-world:greet
# /dev-tools:format
```

Plugins should not interfere with each other.

## Expected Behavior Summary

**Successful Plugin Load:**
- No error messages
- Plugin silently loads
- Commands become available

**Successful Command Execution:**
- Greeting appears
- Mentions "agentics marketplace"
- Incorporates name if provided
- Natural language response (not just echoing)

**Proper Error Handling:**
- Unknown commands: Clear "not found" message
- Invalid syntax: Helpful correction suggestion
- Missing plugin: Instructions to load plugin first

## Known Issues

1. **Misleading Error Message**: "Unknown skill" appears when command isn't found (command vs skill terminology issue in Claude Code)
2. **Session Restart Required**: Changes to command files require exiting and reloading Claude Code
3. **Path Sensitivity**: Plugin loading is sensitive to working directory; always run from project root

## Additional Resources

- **Plugin Structure**: See `README.md` for component overview
- **Claude Code Documentation**: Check official docs for CLI options
- **Marketplace Registration**: See `marketplace-data/.claude-plugin/marketplace.json`
- **Command Reference**: Read `commands/greet.md` for implementation details

## Reporting Issues

If testing reveals bugs:

1. Document the exact steps to reproduce
2. Capture error messages and console output
3. Note your Claude Code CLI version
4. Check if issue exists in `tests/fixtures/valid-plugin/` (minimal test case)
5. Report in project issue tracker with "hello-world plugin" label

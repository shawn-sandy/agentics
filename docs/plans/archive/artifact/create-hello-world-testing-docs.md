---
status: completed
type: artifact
created: 2026-01-19
modified: 2026-02-26
---

# Plan: Test hello-world Plugin

## Problem Analysis

The user attempted to test the `hello-world` plugin and encountered an "Unknown skill: hello-world:greet" error. Investigation reveals:

**Plugin Structure Status: ✓ Valid**
- Plugin manifest (`plugin.json`) contains all required fields
- Command file (`commands/greet.md`) has proper YAML frontmatter
- Directory structure follows Claude Code plugin standards
- Marketplace registration is correct with matching versions

**Root Cause:**
The error message "Unknown skill" is a misnomer—`greet` is a **command**, not a skill. The issue suggests the plugin either:
1. Wasn't loaded into the Claude Code session
2. Has a loading/discovery issue
3. Command syntax is being misinterpreted

## Testing Approach

### Phase 1: Verify Plugin Structure (Already Complete)
Files verified:
- `plugins/hello-world/.claude-plugin/plugin.json` - Valid manifest ✓
- `plugins/hello-world/commands/greet.md` - Valid command definition ✓
- `marketplace-data/.claude-plugin/marketplace.json` - Valid registration ✓

### Phase 2: Document Proper Testing Procedure

Create a comprehensive testing guide that includes:

1. **Direct Plugin Loading**
   - Use `claude --plugin-dir ./plugins/hello-world` to load the plugin
   - This bypasses marketplace infrastructure and tests the plugin directly
   - Document expected output and verification steps

2. **Command Invocation**
   - Correct syntax: `/hello-world:greet` (not a skill invocation)
   - With arguments: `/hello-world:greet [name]`
   - Verify command appears in available commands list

3. **Expected Behavior Documentation**
   - What output should appear when command executes successfully
   - How to verify the plugin is loaded
   - How to list available commands

### Phase 3: Create Testing Documentation

Create `plugins/hello-world/TESTING.md` with:

**Section 1: Prerequisites**
- Claude Code CLI must be installed
- Working directory should be project root

**Section 2: Loading Methods**
- Method 1: Direct plugin directory loading
- Method 2: Multiple plugin loading
- Method 3: Marketplace-based loading (future)

**Section 3: Test Cases**
- TC1: Load plugin without errors
- TC2: Verify plugin appears in loaded plugins list
- TC3: Invoke command without arguments
- TC4: Invoke command with name argument
- TC5: Verify error handling

**Section 4: Troubleshooting**
- Plugin not loading: Check directory path
- Command not found: Verify plugin is loaded first
- "Unknown skill" error: Clarify command vs skill distinction
- Permission issues: Check file permissions

**Section 5: Verification Checklist**
- [ ] Plugin loads without errors
- [ ] Command appears in `/help` or command list
- [ ] Command executes with correct greeting
- [ ] Arguments are properly incorporated
- [ ] No console errors during execution

### Phase 4: Create Quick Test Script

Create `plugins/hello-world/test.sh` with:
```bash
#!/bin/bash
# Quick test script for hello-world plugin

echo "Testing hello-world plugin..."
echo ""
echo "To test this plugin:"
echo "1. Run: claude --plugin-dir ./plugins/hello-world"
echo "2. In Claude session, run: /hello-world:greet"
echo "3. Test with argument: /hello-world:greet YourName"
echo ""
echo "Expected output:"
echo "- Friendly greeting mentioning agentics marketplace"
echo "- If name provided, personalized greeting with that name"
```

### Phase 5: Update README with Troubleshooting

Add a "Troubleshooting" section to `plugins/hello-world/README.md`:
- Common error messages and solutions
- How to verify plugin is loaded
- How to check Claude Code version compatibility
- Known issues and workarounds

## Critical Files

- **Create:** `plugins/hello-world/TESTING.md` (new testing guide)
- **Create:** `plugins/hello-world/test.sh` (quick test helper script)
- **Modify:** `plugins/hello-world/README.md` (add troubleshooting section)

## Verification Steps

After implementation, the user should:

1. **Test Direct Loading:**
   ```bash
   cd /Users/shawnsandy/devbox/agentics
   claude --plugin-dir ./plugins/hello-world
   ```

2. **In Claude Session:**
   ```
   /hello-world:greet
   /hello-world:greet TestUser
   ```

3. **Verify Output:**
   - Greeting appears with mention of "agentics marketplace"
   - Name argument (if provided) is incorporated
   - No errors in console

4. **Alternative: Check Plugin Status**
   - Run `/help` or equivalent to list loaded plugins
   - Verify `hello-world` appears in the list
   - Verify `greet` command is listed

## Success Criteria

- [ ] Testing documentation clearly explains loading and invocation
- [ ] Test script provides quick reference for testing
- [ ] Troubleshooting section addresses common errors
- [ ] User can successfully load and test the plugin
- [ ] "Unknown skill" confusion is clarified

## Notes

- The plugin structure is already correct; no code changes needed
- Focus is on documentation and testing guidance
- The "Unknown skill" error suggests misunderstanding of command vs skill distinction
- Testing should work with Claude Code CLI (not this AI session)

#!/bin/bash
# Quick test script for hello-world plugin
# This script provides instructions for testing the plugin

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the script's directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         hello-world Plugin - Quick Test Guide                 ║${NC}"
echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo ""

# Check if we're in the right directory
if [ ! -f "$PROJECT_ROOT/plugins/hello-world/.claude-plugin/plugin.json" ]; then
    echo -e "${YELLOW}⚠️  Warning: Plugin manifest not found at expected location${NC}"
    echo "   Expected: $PROJECT_ROOT/plugins/hello-world/.claude-plugin/plugin.json"
    echo ""
fi

echo -e "${GREEN}Step 1: Verify Your Location${NC}"
echo "   Current directory: $(pwd)"
echo "   Project root: $PROJECT_ROOT"
echo ""

echo -e "${GREEN}Step 2: Load the Plugin${NC}"
echo "   Run the following command to start Claude Code with the plugin:"
echo ""
echo -e "   ${BLUE}claude --plugin-dir ./plugins/hello-world${NC}"
echo ""
echo "   Note: Make sure you're in the project root directory first:"
echo "   cd $PROJECT_ROOT"
echo ""

echo -e "${GREEN}Step 3: Test Basic Command${NC}"
echo "   Once Claude Code starts, test the greet command:"
echo ""
echo -e "   ${BLUE}/hello-world:greet${NC}"
echo ""
echo "   Expected output:"
echo "   - Friendly greeting message"
echo "   - Mention of 'agentics marketplace'"
echo "   - No errors"
echo ""

echo -e "${GREEN}Step 4: Test Command with Argument${NC}"
echo "   Test with a name argument:"
echo ""
echo -e "   ${BLUE}/hello-world:greet YourName${NC}"
echo ""
echo "   Expected output:"
echo "   - Personalized greeting with 'YourName'"
echo "   - Mention of 'agentics marketplace'"
echo "   - No errors"
echo ""

echo -e "${GREEN}Step 5: Verify Plugin Status${NC}"
echo "   Check that the plugin is loaded:"
echo ""
echo -e "   ${BLUE}/help${NC}"
echo ""
echo "   Look for:"
echo "   - 'hello-world' in the plugin list"
echo "   - 'greet' command under hello-world"
echo "   - Description: 'Simple greeting command'"
echo ""

echo -e "${YELLOW}Troubleshooting:${NC}"
echo ""
echo "   If you see: 'Unknown skill: hello-world:greet'"
echo "   → The plugin isn't loaded or syntax is wrong"
echo "   → Reload: claude --plugin-dir ./plugins/hello-world"
echo "   → Correct syntax: /hello-world:greet (with colon)"
echo ""
echo "   If you see: 'Plugin not found'"
echo "   → Check your working directory (should be project root)"
echo "   → Verify path: ls -la plugins/hello-world/"
echo ""
echo "   If you see: 'Invalid plugin manifest'"
echo "   → Check plugin.json: cat plugins/hello-world/.claude-plugin/plugin.json"
echo "   → Verify required fields: name, version, description"
echo ""

echo -e "${BLUE}Quick Verification Checklist:${NC}"
echo "   [ ] Plugin loads without errors"
echo "   [ ] /hello-world:greet produces greeting"
echo "   [ ] Greeting mentions 'agentics marketplace'"
echo "   [ ] /hello-world:greet TestUser includes 'TestUser'"
echo "   [ ] No console errors"
echo ""

echo -e "${GREEN}For detailed testing instructions, see:${NC}"
echo "   $SCRIPT_DIR/TESTING.md"
echo ""

echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"

#!/usr/bin/env sh
# Measure the description: frontmatter length in a SKILL.md file.
# Called by the PostToolUse hook and the /skill-reviewer:check-description command.
#
# Usage: measure-description.sh <path-to-SKILL.md>
# Exit 0 in all measurable cases; non-zero only for unreadable file.
# Output (stdout, one line):
#   OK: SKILL.md description is N chars (<=160) in <path>
#   WARNING: SKILL.md description is N chars (>160) in <path> — run /skill-reviewer:optimizing-descriptions to trim
#   WARNING: multi-line description detected in <path> — measurement may be approximate; run /skill-reviewer:optimizing-descriptions
#   ERROR: SKILL.md has no description: frontmatter in <path> — required by Claude Code

file="$1"

if [ -z "$file" ] || [ ! -r "$file" ]; then
  printf 'ERROR: cannot read file: %s\n' "${file:-(none)}" >&2
  exit 1
fi

# Use only the first match — frontmatter always appears before the body,
# so body lines that also contain "description:" are safely ignored.
line=$(grep "^description:" "$file" | head -1)

if [ -z "$line" ]; then
  printf 'ERROR: SKILL.md has no description: frontmatter in %s — required by Claude Code\n' "$file"
  exit 0
fi

# Strip the "description:" prefix (with optional single trailing space)
val="${line#description:}"
val="${val# }"

# Detect YAML multi-line / block scalar indicators (| or >)
case "$val" in
  "|"*|">"*)
    printf 'WARNING: multi-line description detected in %s — measurement may be approximate; run /skill-reviewer:optimizing-descriptions\n' "$file"
    exit 0
    ;;
esac

# Strip surrounding double then single quotes
val="${val%\"}"
val="${val#\"}"
val="${val%\'}"
val="${val#\'}"

# Empty after stripping means the description key has no value
if [ -z "$val" ]; then
  printf 'ERROR: SKILL.md has no description: frontmatter in %s — required by Claude Code\n' "$file"
  exit 0
fi

len="${#val}"

if [ "$len" -gt 160 ]; then
  printf 'WARNING: SKILL.md description is %d chars (>160) in %s — run /skill-reviewer:optimizing-descriptions to trim\n' "$len" "$file"
else
  printf 'OK: SKILL.md description is %d chars (<=160) in %s\n' "$len" "$file"
fi

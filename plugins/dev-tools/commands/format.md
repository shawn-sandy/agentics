---
description: Format code in the current file or directory
---

# Format Command

Format the code in the current file or the path specified in $ARGUMENTS. This command identifies the language/file type and applies appropriate formatting tools.

## Supported Languages

- **JavaScript/TypeScript**: Prettier
- **Python**: Black or autopep8
- **JSON**: Built-in JSON formatter
- **Markdown**: Prettier
- **CSS/SCSS**: Prettier
- **HTML**: Prettier

## Usage

### Format Current File

If no arguments are provided, format the file in the current context:

```
/dev-tools:format
```

### Format Specific File

Provide a file path as an argument:

```
/dev-tools:format src/index.ts
/dev-tools:format components/Button.tsx
```

### Format Directory

Provide a directory path to format all supported files:

```
/dev-tools:format src/
/dev-tools:format .
```

## Implementation Steps

1. **Identify Target**
   - If $ARGUMENTS is provided, use it as the path
   - Otherwise, use the current file or directory context

2. **Detect Language**
   - Check file extension (.js, .ts, .py, .json, etc.)
   - Read file content if needed to detect language

3. **Select Formatter**
   - JavaScript/TypeScript/JSON/CSS/HTML → Prettier
   - Python → Black (prefer) or autopep8
   - Unknown types → Notify user, skip formatting

4. **Apply Formatting**
   - Use appropriate command-line tool
   - For Prettier: `prettier --write <path>`
   - For Black: `black <path>`
   - For autopep8: `autopep8 --in-place <path>`

5. **Report Results**
   - Show which files were formatted
   - Report any files that were skipped
   - Display any errors encountered

## Examples

**Format a TypeScript file:**
```
User: /dev-tools:format src/utils/helpers.ts
Assistant: I'll format src/utils/helpers.ts using Prettier.
[Runs: prettier --write src/utils/helpers.ts]
✓ Formatted src/utils/helpers.ts
```

**Format a directory:**
```
User: /dev-tools:format src/components
Assistant: I'll format all supported files in src/components.
[Runs: prettier --write "src/components/**/*.{ts,tsx,js,jsx}"]
✓ Formatted 12 files:
  - Button.tsx
  - Card.tsx
  - Header.tsx
  ...
```

**Unsupported file type:**
```
User: /dev-tools:format image.png
Assistant: image.png is not a supported file type for formatting. Supported types include JavaScript, TypeScript, Python, JSON, CSS, HTML, and Markdown files.
```

## Error Handling

- **Missing formatter tool**: Notify user to install the required tool (Prettier, Black, etc.)
- **Invalid path**: Report that the file or directory doesn't exist
- **Permission errors**: Explain the permission issue and suggest solutions
- **Syntax errors**: Report formatting failures and show error details

## Notes

- Always preview changes if the user seems unsure
- Respect existing configuration files (.prettierrc, pyproject.toml, etc.)
- Don't format files in node_modules, .git, or other ignored directories
- Provide clear feedback on what was changed

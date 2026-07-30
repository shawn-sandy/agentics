# Synthesis Structure Reference

How to read the located files and build `EXPLANATION_RAW`. Phase 3 of `share-explanation`.

## Reading rules

Read `PRIMARY_FILE` (or each file in `SOURCE_FILES` for multi-file targets). For skill targets,
also read any reference files explicitly named in the SKILL.md body — do not bulk-read any
directory. For code targets (file, function, concept), read only the matched files; do not
speculatively read adjacent files.

## Section structures per target type

Adapt the synthesis structure to `TARGET_TYPE`:

**For `skill` or `command` targets** — six sections:

1. **Core Purpose** — 1–2 sentences: what this component does and why it exists
2. **Activation Conditions** *(skills only)* — what user intent or trigger fires it; the
   frontmatter `description` field is the source of truth
3. **Workflow Phases** — numbered list, one line per phase: phase name + what it does
4. **Key Patterns** — bullet list of non-obvious conventions used
5. **Important Files** — `path/to/file — purpose` for each file the component reads or writes
6. **Invocation** — exact syntax with a brief usage example

**For `file`, `function`, or `concept` targets** — five sections:

1. **Core Purpose** — what this code does and the problem it solves
2. **How It Works** — numbered steps describing the logic flow or algorithm
3. **Key Patterns** — non-obvious conventions, assumptions, or design choices
4. **Dependencies / Callers** — what calls this and what it depends on (from the source)
5. **Usage Example** — minimal concrete call or invocation

Write concretely — real file names, real function signatures, real variable names. No filler.

## Handoff

`SUMMARY_RAW` = full `EXPLANATION_RAW` text (passed to security scrub in Phase 4).

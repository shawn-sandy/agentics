# Template Variable Reference

Per-template variable maps have moved to the plugin root:

- **All six card templates:** `$PLUGIN_DIR/references/variables.md`
- **`{{COPY_PANELS}}` markup and escaping:** `$PLUGIN_DIR/references/copy-panels.md`

`$PLUGIN_DIR` is derived in Phase 0 of every card-generating skill as
`$(dirname "$TEMPLATES_DIR")`.

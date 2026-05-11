---
name: fixture-desc-multiline
description: |
  This is a multi-line description using YAML block scalar syntax.
  It spans multiple lines and cannot be accurately measured by head -1.
---

# Fixture: multi-line description

This fixture uses a folded YAML block scalar (description: |) which should produce a WARNING about approximate measurement.

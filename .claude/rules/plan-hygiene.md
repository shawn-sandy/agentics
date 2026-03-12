---
description: Run plan file hygiene before committing changes
paths:
  - "**/plans/**"
  - "**/planning/**"
---

# Pre-Commit Plan Hygiene

Before creating any git commit, check if there are plan files with random
non-descriptive names (e.g., `precious-knitting-tulip.md`) in the planning
directories.

If random-named plan files exist, run `/plan-hygiene` first and complete the
rename workflow before proceeding with the commit.

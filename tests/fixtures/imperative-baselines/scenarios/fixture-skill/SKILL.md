---
name: fixture-demo
description: This skill renames files across a project directory tree according to a naming convention supplied by the caller, walking every subdirectory, computing the new name for each file it encounters, applying the rename on disk, and then writing a summary report of everything it changed.
allowed-tools: Read, Edit
---

# Fixture Demo

## Overview

This skill performs a bulk rename pass over a project directory. It walks the
tree, computes a new name for every file that does not already match the caller's
naming convention, and applies each rename on disk. Because the renames mutate
the working tree and are not reversible without git, the skill is meant to be run
deliberately by a person rather than picked up automatically mid-conversation.

## Steps

1. Walk the target directory and list every file whose name does not match the convention.
2. Rename each listed file to its computed new name and print a summary of the changes.

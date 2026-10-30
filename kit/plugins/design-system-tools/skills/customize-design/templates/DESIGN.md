---
name: {{name}}
description: "Ink on paper with a single {{brand}} signal, where the accent colour marks what a visitor can operate."
colors:
  ink: '{{ink-light}}'
  ink-soft: '{{ink-soft-light}}'
  paper: '{{paper-light}}'
  paper-sunk: '{{paper-sunk-light}}'
  island: '{{island-light}}'
  island-bg: '{{island-bg-light}}'
  rule: '{{rule-light}}'
typography:
  display:
    fontFamily: 'Georgia, Cambria, "Times New Roman", Times, serif'
    fontSize: 'clamp(3rem, 6.6vw, 4.5rem)'
    fontWeight: 400
    lineHeight: 1.02
    letterSpacing: '-0.035em'
  body:
    fontFamily: 'ui-sans-serif, system-ui, -apple-system, sans-serif'
    fontSize: '1rem'
    fontWeight: 400
    lineHeight: 1.5
  label:
    fontFamily: 'ui-monospace, SFMono-Regular, Menlo, Consolas, monospace'
    fontSize: '0.75rem'
    fontWeight: 400
    letterSpacing: '0.12em'
  button:
    fontFamily: 'ui-sans-serif, system-ui, -apple-system, sans-serif'
    fontSize: '0.9375rem'
    fontWeight: 600
rounded:
  none: '0'
  base: '4px'
  lg: '8px'
  2xl: '16px'
  full: '9999px'
spacing:
  1: '4px'
  2: '8px'
  3: '12px'
  4: '16px'
  6: '24px'
  8: '32px'
  11: '44px'
  12: '48px'
  16: '64px'
components:
  button-primary:
    backgroundColor: '{colors.island}'
    textColor: '{colors.paper}'
    rounded: '{rounded.lg}'
    padding: '11px 20px'
    typography: '{typography.button}'
    height: '44px'
  button-ghost:
    backgroundColor: 'transparent'
    textColor: '{colors.island}'
    rounded: '{rounded.lg}'
    padding: '11px 20px'
    typography: '{typography.button}'
    height: '44px'
  button-ghost-hover:
    backgroundColor: '{colors.island-bg}'
    textColor: '{colors.island}'
  card:
    backgroundColor: '{colors.paper-sunk}'
    textColor: '{colors.ink}'
    rounded: '{rounded.lg}'
    padding: '24px'
  code-block:
    backgroundColor: '{colors.paper-sunk}'
    textColor: '{colors.ink-soft}'
    rounded: '{rounded.none}'
    padding: '16px 20px'
  input:
    backgroundColor: '{colors.paper}'
    textColor: '{colors.ink}'
    rounded: '{rounded.base}'
    padding: '8px 12px'
  eyebrow:
    textColor: '{colors.ink-soft}'
    typography: '{typography.label}'
---

# Design System: {{name}}

Scaffolded by design-system-tools on {{date}}. The tokens live in `{{tokens-path}}`; this file is
the written record of them. The stylesheet is what ships, so change the stylesheet first and make
this file match it. Every ratio below was measured by `contrast.mjs`, never estimated.

## Overview

_One paragraph on the north star: what the product looks like, and why. Replace this._

**Key Characteristics:**

- One lit indicator: the accent is a signal, never decoration
- Ink-on-paper neutrals with tonal layering instead of shadow
- Three type roles and no fourth
- Measured, not estimated: contrast ratios are recorded and asserted

## Colors

A colourless ink-on-paper ground carrying exactly one chromatic voice, derived from the brand
colour `{{brand}}`.

### Primary

- **Accent** (`--island`): `{{island-light}}` light, `{{island-dark}}` dark. Links, buttons, focus
  rings and nothing static.
- **Accent Wash** (`--island-bg`): `{{island-bg-light}}` light, `{{island-bg-dark}}` dark. Hover
  fills and `::selection`; the brand colour at 8% over paper.

### Neutrals

- **Ink** (`--ink`): `{{ink-light}}` / `{{ink-dark}}`. Text.
- **Soft Ink** (`--ink-soft`): `{{ink-soft-light}}` / `{{ink-soft-dark}}`. Secondary text.
- **Paper** (`--paper`): `{{paper-light}}` / `{{paper-dark}}`. The page.
- **Sunk Paper** (`--paper-sunk`): `{{paper-sunk-light}}` / `{{paper-sunk-dark}}`. Header band,
  cards, code blocks.
- **Rule** (`--rule`): `{{rule-light}}` / `{{rule-dark}}`. Hairlines, never text.

### Measured contrast

| Pair | Light | Dark | Where |
| --- | --- | --- | --- |
{{ratio-table}}

### Named Rules

**The Accent Rule.** `--island` paints only what a visitor can operate. A heading, a border or a
surface in the accent is a defect.

**The Floor Rule.** Every text pair is at least 4.5:1 in both themes. Re-measure when a token moves.

## Typography

_Name the display, body and label faces and where each is used. Replace this._

## Layout

_State the measure, the gutter and the 44px minimum target. Replace this._

## Shapes

Softly rounded (8px, `--radius-lg`) on buttons and cards; 4px on form fields; squared on a code
block that runs edge to edge. Borders are 1px in Rule. The focus ring is a 2px accent outline.

## Components

### Buttons

- **Primary:** Accent fill, label in Paper, 8px corners, 44px minimum height.
- **Ghost:** Transparent fill, label in Accent, border in Rule. Hover paints the Accent Wash.

### Cards

Sunk Paper, 1px Rule border, 8px corners, 24px padding.

### Code blocks

Sunk Paper, Soft Ink mono, squared corners.

## Do's and Don'ts

### Do:

- **Do** keep the accent for links, buttons and focus rings.
- **Do** flip every token in all three scopes of `{{tokens-path}}`.
- **Do** re-measure contrast when repointing a token.

### Don't:

- **Don't** put the accent on a heading, a hairline or a surface.
- **Don't** put white text on the accent in dark mode; use Paper.
- **Don't** add a second typeface or a shadow to a resting surface.

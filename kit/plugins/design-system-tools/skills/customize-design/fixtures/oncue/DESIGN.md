---
name: OnCue
description: Black ink on white paper with a single rust signal — an editorial serif over a plain sans, where the accent colour is a machine-checked signal, not decoration.
colors:
  ink: '#000000'
  ink-soft: '#606060'
  paper: '#ffffff'
  paper-sunk: '#f0f0f0'
  island: '#c7342b'
  island-bg: '#fcebe9'
  rule: '#dedede'
  success: '#22c55e'
  warning: '#f59e0b'
  error: '#ef4444'
  info: '#3b82f6'
typography:
  display:
    fontFamily: 'Georgia, Cambria, "Times New Roman", Times, serif'
    fontSize: 'clamp(3rem, 6.6vw, 4.5rem)'
    fontWeight: 400
    lineHeight: 1.02
    letterSpacing: '-0.035em'
  headline:
    fontFamily: 'Georgia, Cambria, "Times New Roman", Times, serif'
    fontWeight: 400
    letterSpacing: '-0.02em'
  title:
    fontFamily: 'Georgia, Cambria, "Times New Roman", Times, serif'
    fontWeight: 400
    letterSpacing: '-0.015em'
  section-title:
    fontFamily: 'Georgia, Cambria, "Times New Roman", Times, serif'
    fontSize: 'clamp(2rem, 2.6vw + 1rem, 2.75rem)'
    fontWeight: 400
    lineHeight: 1.08
    letterSpacing: '-0.015em'
  card-title:
    fontFamily: 'Georgia, Cambria, "Times New Roman", Times, serif'
    fontSize: '1.375rem'
    fontWeight: 400
    lineHeight: 1.2
    letterSpacing: '-0.015em'
  deck:
    fontFamily: 'DM Sans, ui-sans-serif, system-ui, -apple-system, sans-serif'
    fontSize: 'clamp(1.125rem, 0.9vw + 0.9rem, 1.5rem)'
    fontWeight: 400
    lineHeight: 1.5
  body:
    fontFamily: 'DM Sans, ui-sans-serif, system-ui, -apple-system, sans-serif'
    fontSize: '1rem'
    fontWeight: 400
    lineHeight: 1.5
  label:
    fontFamily: 'DM Mono, ui-monospace, SFMono-Regular, Menlo, Consolas, monospace'
    fontSize: '0.75rem'
    fontWeight: 400
    letterSpacing: '0.12em'
  button:
    fontFamily: 'DM Sans, ui-sans-serif, system-ui, -apple-system, sans-serif'
    fontSize: '0.9375rem'
    fontWeight: 600
rounded:
  none: '0'
  base: '4px'
  lg: '8px'
  xl: '12px'
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
  button-primary-hover:
    backgroundColor: '#a82a23'
    textColor: '{colors.paper}'
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
  nav-toggle:
    backgroundColor: 'transparent'
    textColor: '{colors.ink}'
    rounded: '{rounded.lg}'
    height: '44px'
    width: '44px'
  eyebrow:
    textColor: '{colors.ink-soft}'
    typography: '{typography.label}'
  command-block:
    backgroundColor: '{colors.paper-sunk}'
    textColor: '{colors.ink-soft}'
    rounded: '{rounded.lg}'
    padding: '8px 8px 8px 20px'
  copy-button:
    backgroundColor: 'transparent'
    textColor: '{colors.ink-soft}'
    rounded: '{rounded.lg}'
    height: '40px'
    width: '40px'
  copy-button-hover:
    backgroundColor: '{colors.island-bg}'
    textColor: '{colors.island}'
  nav-logo:
    height: '56px'
    width: '56px'
  feature-card:
    backgroundColor: '{colors.paper-sunk}'
    textColor: '{colors.ink}'
    rounded: '{rounded.lg}'
    padding: '24px'
  feature-panel:
    backgroundColor: 'transparent'
    textColor: '{colors.ink}'
    rounded: '{rounded.lg}'
    padding: '24px'
  chip:
    backgroundColor: 'transparent'
    textColor: '{colors.ink}'
    rounded: '{rounded.lg}'
    padding: '8px 12px'
  feature-frame:
    backgroundColor: '#111111'
    textColor: '#f2f2f2'
    rounded: '{rounded.xl}'
---

# Design System: OnCue

Fixture: the frontmatter of oncue-app's `DESIGN.md` at `2f0b5d2`, plus the component tokens added to
its working tree on 2026-10-30. The prose is left out on purpose; `contrast.mjs --design-md` reads only
the `colors:` map above.

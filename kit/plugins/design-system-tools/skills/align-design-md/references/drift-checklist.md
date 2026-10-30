# Drift checklist

What `align-design-md` reports and what it leaves alone. Two runs on the same tree must agree,
so the line is drawn here, not in the moment. Read it before step 4 of the skill.

## Drift: report it

1. **A frontmatter value the code contradicts.** `components.code-block.padding: '16px 20px'`
   while the source rule says `padding: 0.5rem 0.5rem 0.5rem 1.25rem`. Same for
   `typography`, `rounded` and `spacing` scale values the stylesheet declares differently.
2. **A component in the code with no frontmatter entry.** A class family in a component's
   style block that paints colour, radius or padding (`.command-block`, `.chip`,
   `[data-nav-brand] img`) and has no `components:` key.
3. **A frontmatter entry with no source.** A key whose words match no file under the
   component folders: the component was renamed or removed.
4. **A selector, attribute, class or file the prose names that no longer exists.** "the
   `.command-block__bar`", "`data-opens-dialog`", "a `pre > code`" — grep the source; a miss
   is drift.
5. **A layout claim the code contradicts.** "a two-column header" over a `flex-direction:
   column`; "the deck beside the title" when the deck is under it.
6. **A rule the code breaks.** A control under a stated size floor: the 40px copy button
   under "interactive controls hold a 44px minimum target". Reported with its file and line
   and marked `under floor`. The skill never changes the control; the user decides whether
   the record or the code moves.

## Not drift: leave it

1. **A vendor default the project never overrides.** A library's `0.375rem` button radius is
   not the project's value until a project rule sets it.
2. **The literal inside `var(--x, fallback)`.** `var(--radius, 0.5rem)` reads the token; the
   `0.5rem` applies only when the token is missing. Compare the token's value, not the
   fallback.
3. **A unit difference where rem and px agree at 16px.** `0.5rem` is `8px`; `2.5rem` is `40px`;
   `1.25rem` is `20px`. Report only a different length.
4. **A derived state colour.** A hover mixed with `color-mix()` from a token, or a `::selection`
   that reads `--island-bg`, has no literal to compare.
5. **Status colours and legacy ramps.** `success`, `warning`, `error`, `info` and any
   `--color-primary-*` / `--color-neutral-*` family the direction leaves alone.
6. **Spacing the record never claims.** A `gap` or `margin` inside a component with no
   frontmatter property and no prose sentence about it.

## The one-line report format

```text
<Component>.<property>: spec <value> (<where in the record>) · code <value> · <file>:<line>[ · under floor]
```

```text
CommandBlock.padding: spec 16px 20px (components.code-block) · code 0.5rem 0.5rem 0.5rem 1.25rem · src/components/astro/CommandBlock.astro:149
CommandBlock.copy-button.height: spec 44px minimum target (Layout) · code min-height: 2.5rem · src/components/astro/CommandBlock.astro:210 · under floor
Navigation.logo: spec (no entry; prose names a 44px toggle only) · code width="56" height="56" · src/components/astro/Navigation.astro:129
FeatureSection.feature-card: spec (no entry) · code .feature-card { background: var(--paper-sunk); border-radius: var(--radius, 0.5rem); padding: 1.5rem } · src/components/astro/FeatureSection.astro:131
```

A run that finds nothing prints one line: `No drift: <N> components, <M> prose claims checked
against <K> source files.`

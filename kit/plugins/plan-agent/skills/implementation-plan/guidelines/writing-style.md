# Writing Style

Direct, imperative, developer-friendly — real names (file paths, function
names, CLI flags), lists over prose, one idea per item, explicitly scoped.
Plan only what was requested; unsolicited ideas go to Next Steps, blue-sky
ideas to a wish-list label there.

**Tone.** Write like an enthusiastic senior engineer briefing the team —
concrete, direct, zero filler. The objective is a rallying statement, not a
ticket summary (*"Ship a dark-mode toggle that persists across all three
themes"*, not *"Add dark mode"*). Step actions lead with a strong imperative
verb phrase (*"Wire up the ThemeContext provider"*, not *"ThemeContext
setup"*). No emoji in authored text — section icons are the renderer's job.

**Plain language.** Write every reader-facing sentence for someone who
wasn't in the planning session — assume no memory of the conversation that
produced the plan. Expand jargon, acronyms, and project shorthand on first
use (*"the scroll-spy (the sidebar highlighting that tracks your scroll
position)"*, *"WCAG (the web accessibility guidelines)"*); after the first
expansion the short form is fine. This applies to the objective, the glance,
step actions and whys, acceptance criteria, and verification text alike.
Precision stays — real file paths, function names, and CLI flags are never
dumbed down; it is the connective prose around them that must read as plain
English.

**Objective vs. glance.** They must never restate each other: the objective
is the one-line *what*; the glance explains *why it matters* and *how we'll
know it worked*. If the glance repeats the objective sentence, rewrite it.

**No markup concerns.** Author plain markdown text. HTML escaping, styling,
icons, copy buttons, and section intros are all owned by the renderer —
never write HTML into the spec.

---
status: todo
type: feature
created: 2026-07-20
glance: Artifacts and Markdown files die in the session that made them. This plan creates a content-tools plugin whose first skill converts either into a draft MDX post for an Astro site — keeping interactive blocks interactive by scoping their CSS instead of flattening everything to screenshots.
---

# Plan: Create the content-tools plugin with an artifact-to-post skill

## Objective

Create a new content-tools plugin at version 1.0.0 whose first skill,
artifact-to-post, turns an HTML artifact or a Markdown file into a draft MDX
post for a static site generator (Astro first) — preserving interactivity
through a per-block fidelity ladder and guarding the output against MDX's JSX
parsing rules.

## Context

An upstream plan (`build-artifact-to-post-pipeline`, written for the 513 Astro
site) proposed a standalone pipeline: a `convert.mjs` HTML-to-Markdown script, a
`screenshot.mjs` Playwright script, a `node-html-parser` dependency, and a
site-local skill. That plan flattened **every** visual block to a screenshot,
because embedding artifact HTML collided with the site's design tokens.

Three decisions reshape it for this repo.

**Scoping replaces screenshotting.** Token collision is fixed by wrapping a
block in a container and scoping the artifact's CSS to it — which keeps
`<details>`, `<dialog>`, and range inputs working. Screenshots become rung 4, a
last resort, not the default.

**The converter script is dropped.** The upstream plan rewrote the parser's
output by hand in the very next step, so the parser earned nothing. Claude reads
the HTML and writes the MDX directly — no `convert.mjs`, no `screenshot.mjs`, no
`node-html-parser`.

**This is content management, not social media.** The obvious home was
`social-media-tools`, but the config proves otherwise: this skill needs a posts
directory, an output extension, frontmatter keys, a draft flag, and a build
command, while `SOCIAL.md` holds platforms, tone, and hashtags. Nothing overlaps.
`content-tools` is named for the domain — turning work products into publishable
site content — so it can grow without a rename (renaming a plugin later is a
MAJOR bump and a reinstall for every user). `social-media-tools:write-guide` is
a candidate to migrate here eventually; that move is a separate breaking change
and is explicitly **not** in this plan.

Two constraints drive the risk. First, MDX parses Markdown as JSX: bare `{`/`}`
and `<word…>` in unfenced prose compile fine as `.md` and hard-fail an MDX build
— and the hazard is introduced by the *prose rewrite*, so the safety pass must
run after it. Second, this repo has no Astro install, so the smoke test cannot
validate a real MDX build; the authoritative gate is a manual run against a real
site.

**Out of scope for v1:** published claude.ai artifact URLs. `WebFetch` fails on
authenticated/private URLs, so the upstream plan's "WebFetch with session login"
path cannot work from a skill. Sources are local `.html`/`.md` paths or pasted
HTML — which is exactly what `social-media-tools:save-artifact` already produces.

## Files

- kit/plugins/content-tools/.claude-plugin/plugin.json (new) — manifest, `name` only; version lives in marketplace.json
- kit/plugins/content-tools/skills/artifact-to-post/SKILL.md (new) — the skill: source branch, ladder, MDX-safety pass, verify, publish gate
- kit/plugins/content-tools/references/mdx-safety.md (new) — the fidelity ladder and the MDX/JSX escaping rules, loaded on demand
- kit/plugins/content-tools/references/content-config.md (new) — the CONTENT.md config schema and prerequisite checks
- kit/plugins/content-tools/README.md (new) — plugin overview
- kit/plugins/content-tools/CHANGELOG.md (new) — v1.0.0 entry
- .claude-plugin/marketplace.json (modified) — register content-tools at 1.0.0
- tests/fixtures/artifact-to-post/sample-artifact.html (new) — fixture carrying every ladder rung and every MDX hazard
- tests/plugins/test-artifact-to-post.sh (new) — smoke test pinning the skill contract and the escaping rules
- CLAUDE.md (modified) — add the content-tools row to the plugin table

## Steps

1. Scaffold the plugin: `kit/plugins/content-tools/.claude-plugin/plugin.json` containing `name: content-tools` and a description — **no `version` key**, since a relative-path plugin's version lives only in `marketplace.json` and a `plugin.json` version silently overrides it. Add `README.md` stating the plugin's charter (turning work products into publishable site content) and `CHANGELOG.md` with a v1.0.0 entry. Register the plugin in `.claude-plugin/marketplace.json` with `version: "1.0.0"`, a relative `source` path, `category: "documentation"`, and specific tags (`mdx`, `astro`, `static-site`, `content-publishing` — never generic terms like "tool"). Why: an unregistered plugin directory fails `tests/plugins/test-no-orphan-plugin-dirs.sh`, and registration is what makes it installable. Verify: `python3 -m json.tool .claude-plugin/marketplace.json` succeeds, `bash tests/plugins/test-no-orphan-plugin-dirs.sh` exits 0, and `plugin.json` contains no `version` key.

2. Write `kit/plugins/content-tools/references/mdx-safety.md` — the technical core, kept out of `SKILL.md` so the skill body stays scannable (the `social-media-tools/references/platforms.md` precedent). Two sections. **(a) The fidelity ladder**, applied per content block, highest rung that holds: rung 1 native Markdown (headings, prose, lists, tables, fenced code) — the majority of any document; rung 2 scoped inline HTML for interactivity needing no JS (`<details>`/`<summary>`, `<dialog>`, `<input type="range">`, native tables), wrapped in a single container with the artifact's CSS prefixed to that container's selector — this is the design-token fix, and it is what preserves the interaction; rung 3 scoped HTML plus the artifact's own inline `<script>` (charts, calculators); rung 4 screenshot into the configured images directory plus a link to the live artifact — last resort only, for blocks that genuinely cannot be ported. Record that rung 3 is version-sensitive: whether `<script>` inside MDX is bundled depends on the target site's Astro/MDX version, so the site build is the authority, never an assumption. **(b) The MDX-safety rules**: in unfenced prose, escape bare `{` and `}` and neutralize `<word…>` sequences — `Array<string>`, `{ id }`, `<T>`, and autolinks like `<https://…>` are the canonical failure cases; fenced blocks and inline code spans are safe and must be left untouched. For HTML emitted at rungs 2–3, which lands in a JSX parser: `class` → `className`, `for` → `htmlFor`, all void tags self-closed, `style` as an object rather than a string, and comments converted from `<!-- -->`. Why: these rules are the difference between a post that builds and one that fails, and they are too detailed to inline without burying the workflow. Verify: the file exists, documents all four rungs in order, and names `Array<string>`, `{ id }`, and `class`→`className` explicitly.

3. Write `kit/plugins/content-tools/references/content-config.md` defining a `CONTENT.md` project config, mirroring the `SOCIAL.md` convention from `social-media-tools:share-init` but with its own schema — nothing site-specific may be hardcoded, since the skill ships to arbitrary repos. Fields: posts output directory, output extension (`.md` or `.mdx`), frontmatter field names (title, description, date, author), the draft/publish flag name and its unpublished value, images output directory, dev preview URL pattern, build/verify command, and `interactivity_ceiling` (caps the ladder — a site that forbids inline scripts caps at rung 2). Specify that when no config exists the skill asks once and offers to write one. Document the two prerequisite checks the skill performs against the target repo and **never** auto-installs: `@astrojs/mdx` present in `package.json`, and the content-collection glob including `.mdx`; on a missing prerequisite the skill reports the exact fix and stops. Why: a hardcoded `src/content/posts/` or `publish:` key makes the skill work on one site and silently corrupt every other. Verify: the reference documents all nine fields plus both prerequisite checks.

4. Write `kit/plugins/content-tools/skills/artifact-to-post/SKILL.md` with frontmatter matching repo conventions — `name: artifact-to-post`, a three-part description ≤200 chars (short label + capability + trigger phrase), and `allowed-tools: AskUserQuestion, Read, Write, Edit, Bash, Glob, Grep, Skill, ToolSearch, ExitPlanMode, SendUserFile`. Include the Step 0 ExitPlanMode self-bootstrap used by sibling skills across the repo. Phases: **0** locate plugin assets; **1** resolve the source and branch on type — a `.md` source skips extraction entirely and goes straight to frontmatter synthesis plus the safety pass, while `.html` or pasted HTML takes the full extraction path, and a claude.ai URL is refused with a one-line pointer to `social-media-tools:save-artifact`; **2** invoke the `social-media-tools:security-scrub` skill as a blocking gate before anything is written, degrading to an explicit warning-and-stop if that plugin is not installed rather than silently skipping the scan; **3** read `CONTENT.md` and run the prerequisite checks; **4** extract to Markdown, classifying each block against the ladder in `references/mdx-safety.md` and capping at the configured interactivity ceiling; **5** human prose rewrite; **6** the MDX-safety pass — explicitly ordered *after* the rewrite, with a one-line note saying why, so a later editor does not "tidy" it earlier; **7** capture rung-4 screenshots by reusing the serve-locally-then-Playwright pattern documented in `social-media-tools/skills/share-code/SKILL.md` (no new script); **8** write the post with synthesized frontmatter and the draft flag set to unpublished, plus a footer link to the source artifact; **9** verification (step 7 below); **10** the publish gate — offer publish, display slug and URL, default to no, preserve the unpublished flag when declined. Why: this skill is the whole deliverable; everything else in this plan scaffolds, documents, or verifies it. Verify: frontmatter parses, `python3 tests/plugins/measure_description_budget.py` reports ≤200 chars, and the body orders the rewrite before the safety pass.

5. Add `tests/fixtures/artifact-to-post/sample-artifact.html` — a small artifact exercising every rung and every hazard: a heading and prose (rung 1), a `<details>` block with its own scoped-candidate CSS (rung 2), a block with an inline `<script>` (rung 3), a canvas-style block that cannot be ported (rung 4), and prose containing `Array<string>`, `{ id }`, `<T>`, and a bare autolink — plus a fenced code block containing the same constructs, which must survive untouched. Why: the fixture is the contract; without the hostile cases the escaping rules can rot without any test noticing. Verify: the file exists and `grep` finds each hazard construct and all four rung markers.

6. Add `tests/plugins/test-artifact-to-post.sh` following existing `tests/plugins/test-*.sh` conventions. Assert: the plugin manifest exists with no `version` key and is registered in `marketplace.json`; the skill file exists with valid frontmatter and a ≤200-char description; the body orders the prose rewrite before the MDX-safety pass; the body reads config values rather than hardcoding `src/content/posts`, `publish:`, or `astro build`; the body refuses claude.ai URLs and points at `save-artifact`; the security scrub runs before any write and fails loudly when unavailable; the reference documents all four rungs and the `class`→`className` rule; and the fixture carries every hazard. Include a runnable guard that scans the fixture's prose regions for unescaped `{`, `}`, and `<word…>` and confirms the fenced region is excluded from that scan — the smallest check that fails if the escaping contract drifts. State plainly in a comment that this repo has no Astro install, so the authoritative MDX build check is step 7's manual validation, not this test. Why: honest scope — a smoke test that claimed to validate an MDX build here would be lying about what it ran. Verify: `bash tests/plugins/test-artifact-to-post.sh` exits 0, and it fails when the `class`→`className` rule is deleted from the reference.

7. Validate end-to-end against a real Astro site (the 513 site is the proving case): load the plugin with `claude --plugin-dir ./kit/plugins/content-tools`, run the skill on a real artifact, and confirm the draft post builds. The site's own build command is the authoritative gate — an MDX escaping bug is invisible to `type-check` and fatal to the build. Confirm: the build passes; the post loads at the configured dev preview URL; rung-2 and rung-3 blocks are still interactive in the browser; no style or script leaks outside the scoped container; images resolve; the draft is absent from paginated lists but reachable by direct URL; and declining the publish offer leaves the unpublished flag intact. Then convert a plain Markdown file and confirm it produces the same valid draft without touching the extraction path. Record the observed rung-3 behavior for the target Astro version back into `references/mdx-safety.md`. Why: every other step is inference until a real build agrees. Verify: the site build exits 0 and the interactive blocks respond to input in the browser.

8. Document the new plugin: add a `content-tools` row to the plugin table in `CLAUDE.md` describing the plugin and its single skill, and update the plugin count in the surrounding prose. Why: `CLAUDE.md` is the map every future session reads first; an unlisted plugin is an invisible one. Verify: `BASE_REF=main node scripts/check-plugin-versions.mjs` passes, and `CLAUDE.md` lists content-tools with an accurate plugin count.

## Tests

Tier 1 — This plan creates files under `kit/plugins/`, which are the shipped product of this repo
- Objective: an artifact converts to a draft MDX post whose interactive blocks survive and whose prose cannot break an MDX build. File: tests/plugins/test-artifact-to-post.sh; Type: smoke; Asserts: plugin registered with no plugin.json version, skill frontmatter valid and ≤200 chars, rewrite ordered before the safety pass, config-driven paths with no hardcoded site literals, security-scrub gate present and loud on failure, claude.ai URLs refused, all four ladder rungs and the JSX attribute rules documented, and the fixture's prose regions carry no unescaped `{`/`}`/`<word…>` while the fenced region is left untouched; Run: bash tests/plugins/test-artifact-to-post.sh
- Integration: plugin registration and version consistency. File: tests/plugins/test-no-orphan-plugin-dirs.sh; Targets: .claude-plugin/marketplace.json, kit/plugins/content-tools/; Key cases: content-tools present at 1.0.0, no orphan directory, no version key in plugin.json
- E2E: real Astro build (manual, step 7 — this repo has no Astro install). Targets: the 513 site; Key cases: site build exits 0, rung-2/rung-3 blocks interactive in-browser, no style leakage past the scoped container, draft absent from lists but reachable by direct URL, Markdown source produces the same valid draft

## Acceptance Criteria

- [ ] `kit/plugins/content-tools/` exists with a `plugin.json` carrying no `version` key, a README, and a CHANGELOG
- [ ] `content-tools` is registered in `marketplace.json` at `1.0.0` with a documentation category and specific tags
- [ ] `skills/artifact-to-post/SKILL.md` exists with valid frontmatter, a three-part description ≤200 chars, and declared `allowed-tools`
- [ ] The skill accepts both `.html` and `.md` sources, and a Markdown source skips extraction entirely
- [ ] A claude.ai artifact URL is refused with a pointer to `save-artifact` — no `WebFetch` attempt on an authenticated URL
- [ ] The security scrub runs as a blocking gate before anything is written, and stops loudly rather than silently skipping when `social-media-tools` is absent
- [ ] `references/mdx-safety.md` documents all four ladder rungs in order and the JSX rules including `class`→`className`
- [ ] The skill escapes `{`, `}`, and `<word…>` in prose while leaving fenced and inline code untouched, and the pass runs after the prose rewrite
- [ ] Every site-specific value — posts directory, extension, frontmatter keys, draft flag, images directory, preview URL, build command, interactivity ceiling — comes from `CONTENT.md`, never a literal
- [ ] Missing `@astrojs/mdx` or an `.mdx`-less collection glob is reported with the exact fix and never auto-installed
- [ ] Output defaults to unpublished; the publish gate shows slug and URL, defaults to no, and preserves the unpublished flag when declined
- [ ] `bash tests/plugins/test-artifact-to-post.sh` and `bash tests/plugins/test-no-orphan-plugin-dirs.sh` both exit 0
- [ ] A real artifact converts and the target site's build command exits 0, with rung-2/rung-3 blocks still interactive and no style leakage
- [ ] `BASE_REF=main node scripts/check-plugin-versions.mjs` passes and `CLAUDE.md` lists content-tools

## Verification

Run `bash tests/plugins/test-artifact-to-post.sh`,
`bash tests/plugins/test-no-orphan-plugin-dirs.sh`, and
`BASE_REF=main node scripts/check-plugin-versions.mjs` — all exit 0. Then load
the plugin locally (`claude --plugin-dir ./kit/plugins/content-tools`) and
convert a real artifact against the 513 Astro site: the site's build command
must exit 0 (this is the authoritative MDX gate — `type-check` cannot see an
escaping bug), the post must load at the configured preview URL with its
`<details>` and script-backed blocks still responding to input, no artifact CSS
may affect anything outside the scoped container, the draft must be absent from
paginated lists yet reachable by direct URL, and declining the publish offer
must leave the post unpublished. Finally, install the plugin from the
marketplace (`/plugin install content-tools@agentics-kit`) and confirm the skill
activates on a natural request like "turn this artifact into a blog post".

## Next Steps

- Migrate write-guide from social-media-tools into content-tools
  ```text
  In ~/devbox/agentics, move the write-guide skill from kit/plugins/social-media-tools into the content-tools plugin, where it fits the charter (turning work products into publishable site content). This is a breaking change: MAJOR bump on social-media-tools with a removal notice in its CHANGELOG and README, MINOR bump on content-tools, plus a redirect note so existing users find the new location. Update the CLAUDE.md plugin table rows for both plugins.
  ```
- Support published claude.ai artifact URLs once an authenticated fetch path exists
  ```text
  In ~/devbox/agentics, extend the content-tools artifact-to-post skill to accept published claude.ai artifact URLs. WebFetch fails on authenticated/private URLs, so investigate a viable authenticated retrieval path first and report what is actually possible before implementing. Keep local .html/.md sources working unchanged. Bump content-tools MINOR in marketplace.json and add a CHANGELOG entry.
  ```
- Add a dark-theme capture pass for rung-4 screenshots
  ```text
  In ~/devbox/agentics, add an optional dark-theme capture pass to the rung-4 screenshot path of the content-tools artifact-to-post skill, emitting light and dark variants and referencing them via a picture element or prefers-color-scheme. Gate it behind a CONTENT.md flag that defaults to off, since light-only sites must not pay for it. Bump content-tools MINOR and add a CHANGELOG entry.
  ```

## Resources

- https://shawn-sandy.github.io/513/planning/build-artifact-to-post-pipeline.html — the upstream site-local plan this one supersedes; source of the screenshot-everything approach and the design-token collision constraint
- kit/plugins/social-media-tools/references/social-config.md — the SOCIAL.md schema that CONTENT.md is modelled on
- kit/plugins/social-media-tools/skills/share-code/SKILL.md — the serve-locally-then-Playwright screenshot pattern reused at rung 4
- .claude/rules/marketplace.md — categories, tagging, and the version-lives-in-marketplace.json rule

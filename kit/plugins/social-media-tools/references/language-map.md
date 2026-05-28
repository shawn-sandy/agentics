# Language Map

Shared by the snippet-card skills (`share-github`, `share-selection`). Use this table
to derive `LANGUAGE` (display name) and `LANGUAGE_COLOR` (hex badge colour) from a file
extension — taken from the GitHub `FILE_PATH`, a selected file's path, or a pasted fenced
block's language tag.

Match on the longest suffix first (e.g. `.tsx` before `.ts`).

| Extension(s) | LANGUAGE | LANGUAGE_COLOR |
|---|---|---|
| `.ts`, `.tsx` | TypeScript | `#3178c6` |
| `.js`, `.jsx`, `.mjs`, `.cjs` | JavaScript | `#f1e05a` |
| `.py`, `.pyw` | Python | `#3572A5` |
| `.go` | Go | `#00ADD8` |
| `.rs` | Rust | `#dea584` |
| `.rb`, `.rake` | Ruby | `#701516` |
| `.java` | Java | `#b07219` |
| `.cs` | C# | `#178600` |
| `.cpp`, `.cc`, `.cxx`, `.c++` | C++ | `#f34b7d` |
| `.c` | C | `#555555` |
| `.swift` | Swift | `#F05138` |
| `.kt`, `.kts` | Kotlin | `#A97BFF` |
| `.sh`, `.bash`, `.zsh` | Shell | `#89e051` |
| `.md`, `.mdx`, `.markdown` | Markdown | `#083fa1` |
| `.json`, `.jsonc` | JSON | `#292929` |
| `.yaml`, `.yml` | YAML | `#cb171e` |
| `.toml` | TOML | `#9c4221` |
| `.html`, `.htm` | HTML | `#e34c26` |
| `.css`, `.scss`, `.sass` | CSS | `#563d7c` |
| `.sql` | SQL | `#e38c00` |
| `.r`, `.R` | R | `#198CE7` |
| `.lua` | Lua | `#000080` |
| `.ex`, `.exs` | Elixir | `#6e4a7e` |
| `.hs`, `.lhs` | Haskell | `#5e5086` |
| `.clj`, `.cljs` | Clojure | `#db5855` |
| `.dart` | Dart | `#00B4AB` |
| `.vue` | Vue | `#41b883` |
| `.svelte` | Svelte | `#ff3e00` |
| *(no match)* | Code | `#8b949e` |

## Notes

- The `LANGUAGE` value is also passed as the `language-{{LANGUAGE}}` CSS class on
  the `<code>` element in `snippet-card.html` for highlight.js detection.
  highlight.js class format uses lowercase: `language-typescript`, `language-python`, etc.
  The skill should lowercase `LANGUAGE` before using it as the CSS class name.

- `LANGUAGE_COLOR` is always sourced from this table — never from fetched content
  or user input. This prevents CSS injection via crafted file extensions.

- For the highlight.js class, map display names to hljs aliases:
  - "C#" → `csharp`
  - "C++" → `cpp`
  - "Shell" → `bash`
  - All others: lowercase the display name, e.g. "TypeScript" → `typescript`

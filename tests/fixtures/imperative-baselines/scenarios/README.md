# Behavioral Baseline Scenarios

Fixed inputs for `tests/plugins/test-skill-behavior-baselines.sh`. Each file is copied into a throwaway sandbox and fed to one skill run headless via `claude -p`.

| File | Consumed by | What it is |
|---|---|---|
| `build-plan.md` | `plan-agent:build` | A minimal `status: todo` plan spec with one step: create `hello.txt` containing `hi` |
| `implementation-plan-objective.txt` | `plan-agent:implementation-plan` | A one-line objective string the skill turns into an HTML plan |
| `dirty-tree.sh` | `git-agent:branch-agent`, `git-agent:ship-autonomous` | Builds a throwaway git repo with a checkout-conflicting dirty tree; prints `SANDBOX READY` |
| `fixture-skill/SKILL.md` | `skill-reviewer:optimizing-skill-frontmatter` | A skill with an over-length description and no `disable-model-invocation`, so the reviewer has real work to do |

## These inputs are FIXED

The recorded `.expected` manifests in the parent directory are only meaningful against these exact bytes. Changing any scenario file — even the wording of a step or the length of a description — invalidates every manifest that consumed it, so any edit here must be followed by a re-record (`bash tests/plugins/test-skill-behavior-baselines.sh --record`) and the regenerated manifests committed in the same commit. Do not "fix" the deliberately bad description in `fixture-skill/SKILL.md`; its defects are the test input.

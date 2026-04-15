# tests/demo

Intentionally-broken fixture used by `tdd-fix` skill demos.

`calculator.sh` contains a deliberate one-character bug: the `add()` function
uses `-` (subtraction) instead of `+` (addition). `calculator.test.sh`
asserts the correct behavior and currently fails because of this bug. `run.sh`
is the test runner the skill invokes.

Do not delete or "fix" these files without updating the `tdd-fix` SKILL.md
reference documentation in
`kit/plugins/code-testing-agent/skills/tdd-fix/SKILL.md`.

## Running manually

```bash
bash tests/demo/run.sh        # exits non-zero (before tdd-fix)
bash tests/demo/run.sh        # exits 0 (after tdd-fix patches calculator.sh)
```

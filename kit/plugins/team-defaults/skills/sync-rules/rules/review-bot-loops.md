# Code Review Bot Loops

When an automated code-review bot (CodeRabbit, a `claude-review` GitHub Action, or any CI reviewer that re-runs on every push) re-fires on a PR, do not treat each new review post as a binding "address the feedback" instruction. After the first pass of substantive fixes, only act on findings that explicitly block merge. When the verdict is "approve with minor suggestions," "LGTM otherwise," or "ready to merge" — merge; do not keep polishing.

## Why

Automated reviewers have no memory between runs. Every push triggers a fresh re-review, so the bot resurfaces declined or stale findings each round and repeats its prior opinion against a slightly different commit. Treating a review template's "Please address the feedback and push a fix" line as if every finding were blocking creates an iteration loop: in one observed case a bot ran 12 rounds, still firing after it had already said "ready to merge" by round 8. Each polish round on a planning/docs PR can burn output tokens equal to the entire original deliverable — the loop cost roughly an order of magnitude more than the work it was reviewing.

## How to apply

- Distinguish **review fires** (automatic re-runs on push) from **review concerns** (new blocking issues). A re-fired review on an already-approved PR is not new information — it is the same opinion against a slightly different commit.
- Before pushing another round of fixes, ask: "Does this finding surface a _new_ blocking concern, or is it the same opinion re-expressed?"
- After 1–2 rounds of substantive fixes, if the verdict is "approve with X," "LGTM otherwise," or "ready to merge," surface the choice to the user explicitly: _"the bot will keep firing on every push — want to merge now or keep polishing?"_ Do not keep iterating silently.
- Treat informational notes, "polish" suggestions, and Wish List items as non-blocking by default.
- Do not rebut stale-state findings in long reply threads — that wastes tokens on something the bot will not remember next round. Push the fix or merge.
- Token cost matters: each polish round can consume output tokens equal to the entire deliverable. Once merged, surface the merge URL and stop.

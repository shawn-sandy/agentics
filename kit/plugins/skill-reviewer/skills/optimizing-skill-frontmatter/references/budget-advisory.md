# Skill listing budget advisory

Loaded at the end of Step 6, after verification.

## Why the format targets are what they are

Claude Code loads all skill descriptions into the context window each turn. The default `skillListingBudgetFraction` allocates 1% of the model’s context window — roughly 8,000 characters on a 200K-token model. The three-part format is designed around this budget:

- **Short description ≤80 chars**: survives at ~100 skills installed (8,000 ÷ 100 = 80 chars/skill). Always the first sentence so truncation still leaves a meaningful label.
- **Total ≤200 chars**: fits the full three-part description for ~40 skills (8,000 ÷ 200 = 40). Users with the agentics-kit alone (~16 skills) have headroom to spare.
- **Legacy ≤160 target**: still safe for ~50 skills installed; remains the recommendation in the table below.

The platform hard limit is 1,024 chars per description and 1,536 chars per skill listing entry; 200 is a practical target for surviving the default budget, not a platform constraint.

## The advisory

Count the total number of installed skills:

```bash
find . -name "SKILL.md" | wc -l
```

Then output this advisory to the user, substituting the actual count:

> **Skill listing budget check**
> You have N skills installed. Claude Code’s default `skillListingBudgetFraction` allocates 1% of the context window (~8,000 chars on a 200K-token model) for all skill descriptions combined.
>
> | Installed skills | Safe avg description length | Format target |
> |---|---|---|
> | ≤40 | ~200 chars | Full three-part (short + capability + trigger) |
> | ~50 | ~160 chars | Two-part (capability + trigger) |
> | ~100 | ~80 chars | Short description only |
>
> The three-part format is designed so the short description (≤80 chars, always Sentence 1) survives even at ~100 skills — truncation never removes the label entirely.
>
> Run `/doctor` to see whether any descriptions are currently being truncated or dropped.
>
> If `/doctor` shows overflow, add this to your `.claude/settings.json`:
> ```json
> {
>   "skillListingBudgetFraction": 0.02
> }
> ```
> This doubles the budget to ~16,000 chars at a cost of ~2,000 tokens of context per turn.

Skip the advisory if the count is ≤40 and all descriptions are already ≤200 chars — no action is needed in that case.

## Further reading

- Skill authoring best practices — https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices
- Claude Code settings (`skillListingBudgetFraction`, `maxSkillDescriptionChars`) — https://code.claude.com/docs/en/settings
- Skill description budgets and `/doctor` command — https://code.claude.com/docs/en/skills

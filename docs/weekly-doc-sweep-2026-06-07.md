# Weekly Documentation Sweep — 2026-06-07

Automated scan of `docs/plans/` for completed plans lacking `docs/guides/<slug>.md` documentation.

## Summary

| Metric                         | Count |
| ------------------------------ | ----: |
| Plans scanned (all statuses)   |    26 |
| Completed plans found          |    86 |
| Already documented (skipped)   |    59 |
| Not yet eligible (< 30 days)   |    27 |
| **Newly documented**           | **0** |
| Failures                       |     0 |

## Already Documented (59 skipped)

Docs exist in `docs/guides/` for 59 completed plans. No action taken.

## Not Yet Eligible — Pending Next Sweep (27)

All 27 undocumented completed plans were created within the last 30 days.
The `documenting-plans` skill requires plans to be 30+ days old before
documentation is generated (to let follow-up changes settle).

| Plan slug | Created | Eligible from |
| --------- | ------- | ------------- |
| `add-a-copy-button-purrfect-fern` | 2026-05-29 | 2026-06-28 |
| `add-built-in-interview-step` | 2026-05-30 | 2026-06-29 |
| `add-content-summary-to-share-session` | 2026-05-29 | 2026-06-28 |
| `add-discovery-and-security-scrub-to-social-media-tools` | 2026-05-26 | 2026-06-25 |
| `add-html-output-to-plan-review-agents` | 2026-05-17 | 2026-06-16 |
| `add-issue-agent-plugin` | 2026-05-28 | 2026-06-27 |
| `add-pr-event-watch-to-ship-autonomous` | 2026-05-28 | 2026-06-27 |
| `add-rejection-remediation-prompt` | 2026-05-18 | 2026-06-17 |
| `add-selection-share-skill` | 2026-05-28 | 2026-06-27 |
| `add-settings-sync-plugin` | 2026-05-18 | 2026-06-17 |
| `add-social-config-to-share-plugin` | 2026-06-04 | 2026-07-04 |
| `add-social-share-router-agent` | 2026-05-28 | 2026-06-27 |
| `consolidate-plan-review-skills` | 2026-05-20 | 2026-06-19 |
| `convert-plan-mode-to-plan-agent-skill` | 2026-05-27 | 2026-06-26 |
| `extract-shared-references-social-media-tools` | 2026-05-27 | 2026-06-26 |
| `fix-branch-agent-checkout-conflict` | 2026-05-28 | 2026-06-27 |
| `i-need-optimizing-skill-fluttering-emerson` | 2026-05-26 | 2026-06-25 |
| `let-s-review-the-code-share-peppy-hartmanis` | 2026-05-26 | 2026-06-25 |
| `optimize-agentic-memory-doctor-principle` | 2026-05-20 | 2026-06-19 |
| `optimize-all-skill-descriptions-linear-sundae` | 2026-05-26 | 2026-06-25 |
| `port-share-session-onto-main` | 2026-05-29 | 2026-06-28 |
| `redesign-plan-agent-html-output` | 2026-05-29 | 2026-06-28 |
| `refactor-skill-description-target-to-200` | 2026-05-28 | 2026-06-27 |
| `remove-background-social-media-tools` | 2026-05-29 | 2026-06-28 |
| `rename-plan-to-html-to-markdown-to-html` | 2026-05-18 | 2026-06-17 |
| `social-media-all-sites-copy-snippets` | 2026-05-27 | 2026-06-26 |
| `verify-panel-review-html-output-integration` | 2026-05-17 | 2026-06-16 |

The first wave becomes eligible on **2026-06-16** (2 plans). The next sweep on or after that date should pick up all 27 plans progressively.

## Notes

- Documentation checked against `docs/guides/<slug>.md` (current convention).
- The `plan-interview:documenting-plans` skill was not loaded in this session; age-check logic was applied directly from the skill's documented Step 2 rules.
- Plans in `docs/plans/archive/` were included in the scan per task instructions.

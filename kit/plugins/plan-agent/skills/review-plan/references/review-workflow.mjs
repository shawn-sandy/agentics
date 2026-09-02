// Plan review engine — the Workflow script behind /plan-agent:review-plan.
//
// The skill Reads this file and passes its contents as the Workflow tool's
// inline `script` input. It is never launched by path: the Bash tool rejects
// any command carrying shell expansion, so a ${CLAUDE_PLUGIN_ROOT}-anchored
// invocation is unrunnable at every permission level. The .mjs extension is
// what lets `node --check` validate this file in tests/.
//
// Expected `args`:
//   planPath   string   absolute path to the plan the reviewers read
//   reviewers  array    [{key, agentType}] — 7 core, or 10 when UI signals fired
//   deep       boolean  verify every finding instead of high/critical only
//
// Returns { findings, stats }. Findings carry the reviewer that raised them
// and, for the verified ones, the refutation verdict.

export const meta = {
  name: 'plan-review-team',
  description: 'Review an implementation plan across parallel lenses, then adversarially verify each high-severity finding',
  phases: [
    { title: 'Review', detail: 'one agent per reviewer lens, findings returned as typed data' },
    { title: 'Verify', detail: 'one skeptic per high-severity finding, prompted to refute it' },
  ],
}

// One row per proposed plan edit. `target` and `action` are what Step 7 maps
// onto a spec section, so they are required — a finding the skill cannot place
// is a finding it has to drop.
const FINDINGS = {
  type: 'object',
  required: ['findings'],
  properties: {
    assessment: { type: 'string', description: 'One sentence on the plan from this lens.' },
    findings: {
      type: 'array',
      items: {
        type: 'object',
        required: ['target', 'action', 'content', 'rationale', 'severity'],
        properties: {
          target: {
            type: 'string',
            description: 'Which part of the plan to change: objective, criteria, step N, verification, or tests.',
          },
          action: { type: 'string', enum: ['edit', 'append', 'insert'] },
          content: { type: 'string', description: 'The replacement or added text, as markdown.' },
          rationale: { type: 'string', description: 'Why this change is needed, in one sentence.' },
          severity: { type: 'string', enum: ['critical', 'high', 'medium', 'low'] },
        },
      },
    },
  },
}

const VERDICT = {
  type: 'object',
  required: ['refuted', 'reason'],
  properties: {
    refuted: { type: 'boolean', description: 'True when the finding does not hold up.' },
    reason: { type: 'string', description: 'One sentence justifying the verdict.' },
  },
}

const planPath = args?.planPath
const reviewers = args?.reviewers ?? []
const deep = args?.deep === true

if (!planPath) throw new Error('review-workflow: args.planPath is required')
if (!reviewers.length) throw new Error('review-workflow: args.reviewers is empty')

/** Findings at or above this severity earn an adversarial verifier. */
const MUST_VERIFY = ['critical', 'high']

/**
 * Stands in for a verdict when the skeptic itself failed. Distinct from
 * `verdict: null`, which means the finding was never sent for verification.
 * `refuted: false` keeps the finding alive — a crashed verifier is not
 * evidence against a finding.
 */
const VERIFIER_FAILED = { refuted: false, reason: 'The verifier failed to return a verdict.', failed: true }

/**
 * Whether a finding gets its own skeptic. `--deep` lifts the severity filter
 * so every finding is refuted; the default keeps the agent count near 18
 * instead of ~50 by trusting low and medium findings to the human triage gate.
 *
 * @param {{severity: string}} finding - One row from a reviewer's findings.
 * @returns {boolean} True when this finding should be verified.
 */
function shouldVerify(finding) {
  return deep || MUST_VERIFY.includes(finding.severity)
}

const reviewPrompt = (r) => `Review the implementation plan at ${planPath} through your assigned lens.

Read the plan with the Read tool. Its authored content — objective, context,
files, steps with why/verify, tests, acceptance criteria, and verification —
is what you review. Status and progress markers are out of scope.

Return every concern as a finding that names the part of the plan to change
and the exact markdown to put there, so it can be applied without further
interpretation. Set severity honestly: 'critical' or 'high' means the plan
ships broken or misleading work without this change. A finding you would not
defend under challenge should be 'low', or left out.`

const refutePrompt = (f, key) => `Try to REFUTE this finding raised by the ${key} reviewer about the plan at ${planPath}.

Target: ${f.target}
Severity claimed: ${f.severity}
Proposed change: ${f.content}
Their rationale: ${f.rationale}

Read the plan, and the codebase where it matters. Your job is to find the
reason this finding is wrong, already handled elsewhere in the plan, or not
worth the change. Default to refuted=true when you are uncertain — a plausible
but unproven finding must not become a plan edit.`

const reviewed = await pipeline(
  reviewers,

  // Stage 1 — one agent per lens. agentType points at the plan-reviewer-*
  // definitions this plugin already ships, so the lens comes from the agent's
  // own system prompt rather than a re-authored brief.
  (r) => agent(reviewPrompt(r), {
    label: `review:${r.key}`,
    phase: 'Review',
    agentType: r.agentType,
    schema: FINDINGS,
  }),

  // Stage 2 — refute this reviewer's high-severity findings as soon as IT
  // finishes, without waiting for the other reviewers. No barrier: a slow
  // lens never holds up verification of a fast one's findings.
  // A dead lens returns null here, NOT an empty array. `parallel([])` resolves
  // to `[]`, which is truthy — so coalescing a dead reviewer to no-findings
  // would make it indistinguishable from a lens that ran clean and found
  // nothing, and `lensesLost` below could never be non-zero.
  (result, r) => {
    if (!result) return null
    const findings = (result.findings ?? []).map((f) => ({ ...f, reviewer: r.key }))
    return parallel(
      findings.map((f, i) => () => {
        if (!shouldVerify(f)) return Promise.resolve({ ...f, verdict: null })
        return agent(refutePrompt(f, r.key), {
          label: `verify:${r.key}:${i + 1}`,
          phase: 'Verify',
          schema: VERDICT,
        })
          // A skeptic that dies resolves to null (or throws). Either way the
          // finding is kept with an honest verdict: dropping it would let an
          // infrastructure failure silently delete a critical finding, and
          // leaving `verdict: null` would report it as "below threshold".
          .then((v) => ({ ...f, verdict: v ?? VERIFIER_FAILED }))
          .catch(() => ({ ...f, verdict: VERIFIER_FAILED }))
      }),
    )
  },
)

// A dead lens is `null` (stage 2 returns it deliberately); a live one is an
// array. This is the count that replaces the old respawn-once-then-mark-
// unavailable bookkeeping, so it has to distinguish the two.
const liveLenses = reviewed.filter(Boolean)
const lensesLost = reviewers.length - liveLenses.length

// The trailing filter is not redundant: `parallel()` yields null for a thunk
// that rejected, so a verify thunk that failed outside its own catch lands here.
const all = liveLenses.flat().filter(Boolean)

// A finding survives unless a skeptic actually refuted it. An unverified
// finding is kept, not silently dropped — the human triage gate decides it.
const surviving = all.filter((f) => !f.verdict?.refuted)
const refuted = all.length - surviving.length

// Three distinct states, deliberately not collapsed: never sent (below the
// severity filter), sent but the verifier broke, and genuinely survived a
// challenge. Reporting the middle one as "below threshold" would tell the user
// to re-run with --deep, which cannot fix a crashed verifier.
const unverifiedCount = surviving.filter((f) => f.verdict === null).length
const verifierFailedCount = surviving.filter((f) => f.verdict?.failed === true).length
const verifiedCount = surviving.length - unverifiedCount - verifierFailedCount

if (lensesLost > 0) log(`${lensesLost} reviewer(s) failed and returned nothing — their lens is missing from this review.`)

log(`${surviving.length} findings stand: ${verifiedCount} survived refutation, ${unverifiedCount} unverified (below high severity; re-run with --deep to check them). ${refuted} refuted and dropped.`)
if (verifierFailedCount > 0) log(`${verifierFailedCount} finding(s) were sent for verification but their verifier failed — treat them as unchallenged. --deep will not help; re-run the review.`)

return {
  findings: surviving,
  stats: {
    reviewersRun: liveLenses.length,
    reviewersRequested: reviewers.length,
    lensesLost,
    total: all.length,
    surviving: surviving.length,
    verified: verifiedCount,
    unverified: unverifiedCount,
    verifierFailed: verifierFailedCount,
    refuted,
    deep,
  },
}

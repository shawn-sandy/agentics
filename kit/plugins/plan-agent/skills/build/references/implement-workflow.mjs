// Lane-implementation engine — the Workflow script behind the `build` skill's
// escalation path for laned plans.
//
// The skill Reads this file and passes its contents as the Workflow tool's
// inline `script` input. It is never launched by path: the Bash tool rejects
// any command carrying shell expansion, so a ${CLAUDE_PLUGIN_ROOT}-anchored
// invocation is unrunnable at every permission level. The .mjs extension is
// what lets `node --check`-style tooling and tests/ validate this file.
//
// Selection is narrow. This script is chosen only on a plan with 2 or more
// lanes, and only when the plan says `workflow: always`, the caller passed
// `--workflow`, or the plan carries 6 or more lanes. A plan with fewer than
// 2 lanes never reaches this script at all — `build` runs it sequentially
// in the calling session, and the only trace of the Workflow engine is the
// /workflows prompt it emits. Before invoking this script, the skill probes
// that the Workflow tool is callable in the current session; it never
// asserts a minimum Claude Code version, because a probe answers the only
// question that matters ("is it here right now") and a version check does
// not.
//
// Expected `args`:
//   planPath     string  absolute path to the plan being implemented
//   planBranch   string  the branch every lane forks from and merges back to
//   workerModel  string  model alias for each lane worker (default 'sonnet')
//   lanes        array   [{name, owns, after, brief}] — one entry per worker
//                         lane; `after` is the array of lane names this lane
//                         waits on; `brief` is the fully substituted worker
//                         brief text. `lead` is never included here — the
//                         lead lane always runs in the calling session,
//                         after every worker lane in this script has merged.
//
// Returns { reports, mergeOrder }. `reports` is one entry per worker lane,
// in `args.lanes` order, carrying that lane's structured LANE_REPORT (or
// null if the worker died). `mergeOrder` is the worker lane names
// topologically sorted by `after:`, so the lead can merge dependency-first
// with the same section-6 audit the Agent dispatcher uses — one merge
// procedure, not two. This script never runs git itself; merging is the
// lead's job.

export const meta = {
  name: 'plan-implement-lanes',
  description: 'Implement a plan\'s worker lanes in dependency-ordered waves, one worktree-isolated agent per lane',
  phases: [
    { title: 'Implement', detail: 'one worktree-isolated agent per lane, waiting only on its own after: edges' },
    { title: 'Report', detail: 'tally reported vs dead lanes and derive the merge order' },
  ],
}

// The structured return every lane worker is forced to produce, mirroring
// the "LANE REPORT" block dispatch-lanes.md has workers end with. `lane` and
// `branch` name the worker and where its commits live; `steps_done` and
// `files_changed` are arrays so the lead can diff them against the spec and
// `owns:` without re-parsing prose; `verify` and `blocked` stay free-text
// because a per-step pass/fail line and a blocker explanation don't fit a
// fixed schema without over-constraining the worker's report.
const LANE_REPORT = {
  type: 'object',
  required: ['lane', 'branch', 'steps_done', 'verify', 'files_changed', 'blocked'],
  properties: {
    lane: { type: 'string', description: 'The lane name this report is for.' },
    branch: { type: 'string', description: 'The branch the lane committed its work to.' },
    steps_done: { type: 'array', items: { type: 'string' }, description: 'Step numbers completed, in order.' },
    verify: { type: 'string', description: 'One pass/fail line per step, e.g. "1: pass, 2: fail".' },
    files_changed: { type: 'array', items: { type: 'string' }, description: 'Paths touched by this lane.' },
    blocked: { type: 'string', description: '"none", or what blocked the lane and why.' },
  },
}

const planPath = args?.planPath
const planBranch = args?.planBranch
const workerModel = args?.workerModel ?? 'sonnet'
const lanes = args?.lanes ?? []

if (!planPath) throw new Error('implement-workflow: args.planPath is required')
if (!planBranch) throw new Error('implement-workflow: args.planBranch is required')
if (!lanes.length) throw new Error('implement-workflow: args.lanes is required and must not be empty')

// The lead runs in the calling session, never as a worker — dispatching it
// here would race its shared-file writes against every other lane.
const workerLanes = lanes.filter((lane) => lane.name !== 'lead')
const laneByName = new Map(workerLanes.map((lane) => [lane.name, lane]))

/**
 * A brief that names a lane not present in this run (a typo, or a lane the
 * spec already merged and dropped from `args.lanes`) has nothing to wait on
 * — treat it as no dependency rather than hanging forever on a promise that
 * will never resolve.
 *
 * @param {{after?: string[]}} lane - One entry from `args.lanes`.
 * @returns {Array<{name: string}>} The dependency lanes actually in this run.
 */
function dependenciesOf(lane) {
  return (lane.after ?? []).map((name) => laneByName.get(name)).filter(Boolean)
}

// Wave ordering: a Map from lane name to a promise. Each lane's promise
// first awaits every lane its `after:` names, then dispatches its worker.
// There is no explicit barrier between waves — a lane with no dependencies
// starts immediately, and a downstream lane's `await` on its dependencies'
// promises is what turns `after:` edges into pipeline stages.
const waves = new Map()

/**
 * Look up (and lazily build) the promise for one lane, recursing into its
 * dependencies first. Memoized in `waves` so a lane with multiple
 * dependents is only ever dispatched once.
 *
 * @param {{name: string, after?: string[], brief: string}} lane - The lane to wave.
 * @returns {Promise<object|null>} The lane's LANE_REPORT, or null if it died.
 */
function waveFor(lane) {
  if (waves.has(lane.name)) return waves.get(lane.name)

  const ready = Promise.all(dependenciesOf(lane).map((dep) => waveFor(dep)))

  const dispatched = ready.then(() =>
    agent(lane.brief, {
      label: 'lane:' + lane.name,
      phase: 'Implement',
      isolation: 'worktree',
      agentType: 'general-purpose',
      model: workerModel,
      schema: LANE_REPORT,
    })
      // A worker that dies (a terminal API error, or a permission skip)
      // resolves to null here rather than rejecting — one dead lane must
      // never take down the rest of the wave, and the lead needs to see it
      // as a distinct, reportable failure rather than a thrown exception.
      .catch(() => null),
  )

  waves.set(lane.name, dispatched)
  return dispatched
}

for (const lane of workerLanes) waveFor(lane)

const results = await Promise.all(workerLanes.map((lane) => waves.get(lane.name)))

const reported = results.filter(Boolean).length
const dead = results.length - reported

log(`${reported} of ${workerLanes.length} lane(s) reported; ${dead} dead.`)

const reports = workerLanes.map((lane, i) => ({
  name: lane.name,
  after: lane.after ?? [],
  report: results[i],
}))

/**
 * Topologically sort the worker lanes by `after:` so the lead can merge
 * dependency-first — a post-order depth-first walk visits every dependency
 * before the lane that named it, which is exactly a valid merge order.
 *
 * @param {Array<{name: string, after?: string[]}>} allLanes - The worker lanes.
 * @returns {string[]} Lane names, dependencies before dependents.
 */
function topoSort(allLanes) {
  const byName = new Map(allLanes.map((lane) => [lane.name, lane]))
  const visited = new Set()
  const order = []

  function visit(name) {
    if (visited.has(name)) return
    visited.add(name)
    const lane = byName.get(name)
    for (const dep of lane?.after ?? []) {
      if (byName.has(dep)) visit(dep)
    }
    order.push(name)
  }

  for (const lane of allLanes) visit(lane.name)
  return order
}

const mergeOrder = topoSort(workerLanes)

return { reports, mergeOrder }

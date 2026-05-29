
export const meta = {
  name: 'organize-completed-plans',
  description: 'Move completed plans into docs/plans/archive/<type>/ subdirectories',
  phases: [
    { title: 'Scan', detail: 'Read frontmatter from every plan file' },
    { title: 'Archive', detail: 'Move completed plans into archive subdirectories' },
    { title: 'Report', detail: 'Summarize what was moved' },
  ],
}

const PLANS_DIR = '/Users/shawnsandy/devbox/agentics/docs/plans'
const ARCHIVE_DIR = `${PLANS_DIR}/archive`

const FRONTMATTER_SCHEMA = {
  type: 'object',
  properties: {
    filename: { type: 'string' },
    status: { type: 'string' },
    planType: { type: 'string' },
  },
  required: ['filename', 'status', 'planType'],
}

// Phase 1: list files and read frontmatter in parallel batches
phase('Scan')

const fileList = await agent(
  `List every .md file in ${PLANS_DIR} (not recursively — only the top-level directory). Return each filename (basename only, with extension) as a JSON array of strings. Do NOT descend into subdirectories. Use Bash: ls ${PLANS_DIR}/*.md | xargs -n1 basename`,
  {
    label: 'list-plan-files',
    schema: {
      type: 'object',
      properties: {
        files: { type: 'array', items: { type: 'string' } },
      },
      required: ['files'],
    },
  }
)

const files = fileList.files.filter(Boolean)
log(`Found ${files.length} plan files — reading frontmatter in parallel`)

// Batch into groups of 20 for parallel reading
const BATCH = 20
const batches = []
for (let i = 0; i < files.length; i += BATCH) {
  batches.push(files.slice(i, i + BATCH))
}

const batchResults = await parallel(
  batches.map((batch, batchIdx) => () =>
    agent(
      `Read the YAML frontmatter from these plan files in ${PLANS_DIR}/. For each file, extract the "status" and "type" fields. If frontmatter is missing or the field is absent, use "unknown" for that field. Return a JSON array where each element has: filename (string), status (string), planType (string — the "type" frontmatter field).

Files to read (batch ${batchIdx + 1}):
${batch.map(f => `- ${PLANS_DIR}/${f}`).join('\n')}

Read each file and parse the YAML frontmatter block (between --- delimiters at the top). Return only the array, no extra commentary.`,
      {
        label: `scan-batch-${batchIdx + 1}`,
        phase: 'Scan',
        schema: {
          type: 'object',
          properties: {
            plans: {
              type: 'array',
              items: {
                type: 'object',
                properties: {
                  filename: { type: 'string' },
                  status: { type: 'string' },
                  planType: { type: 'string' },
                },
                required: ['filename', 'status', 'planType'],
              },
            },
          },
          required: ['plans'],
        },
      }
    )
  )
)

const allPlans = batchResults.filter(Boolean).flatMap(r => r.plans)
const completed = allPlans.filter(p => p.status === 'completed')
log(`${completed.length} completed plans found out of ${allPlans.length} scanned`)

// Phase 2: Create archive directories and move files
phase('Archive')

// Gather unique types
const types = [...new Set(completed.map(p => p.planType || 'unknown'))]
log(`Plan types to create: ${types.join(', ')}`)

// Create all needed directories in one shot
const mkdirResult = await agent(
  `Create these directories (use mkdir -p for each):
${types.map(t => `${ARCHIVE_DIR}/${t}`).join('\n')}

Run: mkdir -p ${types.map(t => `"${ARCHIVE_DIR}/${t}"`).join(' ')}

Then verify with: ls ${ARCHIVE_DIR}/

Return a JSON object with: { created: string[] (list of directories created), output: string }`,
  {
    label: 'create-archive-dirs',
    schema: {
      type: 'object',
      properties: {
        created: { type: 'array', items: { type: 'string' } },
        output: { type: 'string' },
      },
      required: ['created', 'output'],
    },
  }
)

log(`Archive directories created: ${mkdirResult.created.join(', ')}`)

// Move completed plans in batches
const MOVE_BATCH = 30
const moveBatches = []
for (let i = 0; i < completed.length; i += MOVE_BATCH) {
  moveBatches.push(completed.slice(i, i + MOVE_BATCH))
}

const moveResults = await parallel(
  moveBatches.map((batch, idx) => () =>
    agent(
      `Move these plan files to their archive subdirectories. Use git mv so the moves are tracked by git.

${batch.map(p => `git mv "${PLANS_DIR}/${p.filename}" "${ARCHIVE_DIR}/${p.planType || 'unknown'}/${p.filename}"`).join('\n')}

Run each git mv command. If a file doesn't exist, skip it and note it. Return a JSON object with: { moved: string[] (filenames successfully moved), skipped: string[] (filenames that didn't exist), errors: string[] }`,
      {
        label: `move-batch-${idx + 1}`,
        phase: 'Archive',
        schema: {
          type: 'object',
          properties: {
            moved: { type: 'array', items: { type: 'string' } },
            skipped: { type: 'array', items: { type: 'string' } },
            errors: { type: 'array', items: { type: 'string' } },
          },
          required: ['moved', 'skipped', 'errors'],
        },
      }
    )
  )
)

const allMoved = moveResults.filter(Boolean).flatMap(r => r.moved)
const allSkipped = moveResults.filter(Boolean).flatMap(r => r.skipped)
const allErrors = moveResults.filter(Boolean).flatMap(r => r.errors)

// Phase 3: Report
phase('Report')

const report = await agent(
  `Generate a concise summary report of the plan archiving operation.

Stats:
- Total plans scanned: ${allPlans.length}
- Completed plans found: ${completed.length}
- Files successfully moved: ${allMoved.length}
- Files skipped (not found): ${allSkipped.length}
- Errors: ${allErrors.length}

Completed plans by type:
${types.map(t => {
  const count = completed.filter(p => (p.planType || 'unknown') === t).length
  return `- ${t}: ${count} plans`
}).join('\n')}

${allErrors.length > 0 ? `Errors:\n${allErrors.map(e => `- ${e}`).join('\n')}` : ''}

List the archive directory structure with: ls ${ARCHIVE_DIR}/

Return a markdown-formatted summary with: a stats table, per-type breakdown, and the directory listing. Plain markdown, no JSON schema needed.`,
  { label: 'generate-report' }
)

return {
  scanned: allPlans.length,
  completed: completed.length,
  moved: allMoved.length,
  skipped: allSkipped.length,
  errors: allErrors,
  types,
  report,
}

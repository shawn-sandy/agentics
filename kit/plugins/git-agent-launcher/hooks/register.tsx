import type { CommandInfo, EngineInterface, Register } from 'claude-code'

const PANE = 'git-agent-launcher'
const PREFIX = 'git-agent:'
const INSTALL = 'git-agent is not installed. Run /plugin install git-agent@agentics-kit'

// A `claude -p` run has no surface, yet `ui.open` still answers isPlaced there,
// so the text listing keys on whether any drawing surface has been seen.
let canDraw = false

/** git-agent's skills and commands, in the order the typeahead lists them. */
async function gitAgentEntries($: EngineInterface): Promise<CommandInfo[]> {
  return (await $.command.list()).filter(c => c.plugin === 'git-agent')
}

/** The text answer for surfaces that draw no pane: one `/name — description` per line. */
function listing(entries: CommandInfo[]): string {
  return entries.length === 0 ? INSTALL : entries.map(c => `/${c.name} — ${c.description}`).join('\n')
}

/**
 * Stages `/<name> ` in the prompt, never runs it: commit-agent and pr-agent
 * push, so a misclick must stay harmless and Enter is what runs it. A command
 * a previous press staged is replaced rather than stacked; what follows it is
 * kept as arguments.
 */
async function stage($: EngineInterface, name: string): Promise<void> {
  const { text: draft } = await $.prompt.read()
  const command = `/${name}`
  const args = draft.replace(/^\/git-agent:\S*\s*/, '')
  const { isFilled } = await $.prompt.fill({ text: `${command} ${args}`, mode: 'replace' })
  if (!isFilled) $.ui.toast(`Type ${command} in the prompt`)
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    canDraw ||= e.surface !== null
    await $.command.register({ name: 'git-agent-launcher', description: 'Open a pane of git-agent skills and commands' })
    return next(e)
  })

  on('session.attach', ($, e, next) => {
    canDraw = true
    return next(e)
  })

  on('command.run', { command: 'git-agent-launcher' }, async $ => {
    const opened = await $.ui.open({ id: PANE, title: 'git-agent', focus: true, closeOnEscape: true })
    if (opened.isPlaced && canDraw) return {}
    return { text: listing(await gitAgentEntries($)) }
  })

  on('ui.render', { component: 'Pane', requestId: PANE }, async ($, e) => {
    const { Box, Text, Button } = $.ui.resolve(e)
    const entries = await gitAgentEntries($)
    if (entries.length === 0) return <Text>{INSTALL}</Text>

    return (
      <Box flexDirection="column" width={e.props.bodyColumns}>
        <Text dimColor>Press an entry to stage it in the prompt · Esc closes</Text>
        {entries.map((c, i) => {
          const label = c.name.slice(PREFIX.length)
          const hotkey = i < 9 ? { hotkey: String(i + 1) } : {}
          return (
            <Box flexDirection="column">
              <Button key={label} label={label} plain {...hotkey} onPress={() => stage($, c.name)} />
              <Text dimColor>{c.description}</Text>
            </Box>
          )
        })}
      </Box>
    )
  })
}

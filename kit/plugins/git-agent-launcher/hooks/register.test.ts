import { expect, test } from 'claude-code/testing'
import type { CommandInfo, On, PromptFillInput, RenderPropsOf } from 'claude-code'

const PLUGIN = 'git-agent-launcher'
const SURFACES = ['terminal', 'desktop'] as const

// git-agent 4.23.0's 13 entries in the order Phase 0 observed, with two
// entries from elsewhere mixed in that the pane must never draw.
const GIT_AGENT = [
  'commit-bg', 'merge-bg', 'pr-bg', 'ship-bg', 'ship-ci-bg', 'branch-agent', 'commit-agent',
  'create-issue', 'merge', 'post-merge-cleanup', 'pr-agent', 'ship', 'ship-autonomous',
]
const LIST: CommandInfo[] = [
  { name: 'help', description: 'Show help', source: 'builtin' },
  ...GIT_AGENT.map(n => ({ name: `git-agent:${n}`, description: `Runs ${n}.`, source: 'plugin' as const, plugin: 'git-agent' })),
  { name: 'plan-agent:build', description: 'Implements a plan file.', source: 'plugin', plugin: 'plan-agent' },
]

const PANE: RenderPropsOf['Pane'] = {
  title: 'git-agent',
  isFocused: true,
  bodyColumns: 60,
  placement: 'dock',
  scroll: { offset: 0, bodyRows: 30 },
  view: {},
}

/** Answers, beneath the plugin, every engine call the launcher makes. */
function engine(on: On, list: CommandInfo[], draft: string, isFilled = true) {
  const fills: PromptFillInput[] = []
  const toasts: string[] = []
  const registered: string[] = []
  on('session.start', (_$, e) => ({ cwd: e.cwd }))
  on('session.attach', (_$, e) => ({ clientId: e.clientId }))
  on('command.register', (_$, e) => {
    registered.push(e.name)
    return { value: { command: e.name } }
  })
  on('command.list', () => ({ value: list }))
  on('prompt.read', () => ({ value: { text: draft, cursor: draft.length } }))
  on('prompt.fill', (_$, e) => {
    fills.push(e)
    return { isFilled }
  })
  on('ui.toast', (_$, e) => {
    toasts.push(e.text)
    return { value: undefined }
  })
  return { fills, toasts, registered }
}

const RUN = {
  command: PLUGIN,
  args: '',
  origin: { kind: 'composer' },
  presentation: { isFullscreen: true, columns: 120 },
} as const

test('draws only git-agent entries, in list order, with hotkeys 1-9', async ($, on) => {
  engine(on, LIST, '')
  for (const surface of SURFACES) {
    const ui = await $.ui.mount({ plugin: PLUGIN, surface, component: 'Pane', requestId: PLUGIN, props: PANE })
    const buttons = await ui.findAll({ type: 'Button' })
    expect(buttons.map(b => b.key)).toEqual(GIT_AGENT)
    expect(buttons.map(b => b.props.hotkey)).toEqual(['1', '2', '3', '4', '5', '6', '7', '8', '9', undefined, undefined, undefined, undefined])
    expect(await ui.find({ text: /plan-agent|Implements a plan|Show help/ })).toBeUndefined()
    await ui.unmount()
  }
})

test('a press over an empty draft fills exactly /git-agent:commit-agent ', async ($, on) => {
  const { fills, toasts } = engine(on, LIST, '')
  for (const surface of SURFACES) {
    const ui = await $.ui.mount({ plugin: PLUGIN, surface, component: 'Pane', requestId: PLUGIN, props: PANE })
    await ui.press({ key: 'commit-agent' })
    expect(fills.at(-1)?.text).toBe('/git-agent:commit-agent ')
    expect(fills.at(-1)?.mode).toBe('replace')
    await ui.unmount()
  }
  expect(fills).toHaveLength(2)
  expect(toasts).toHaveLength(0)
})

test('a press keeps the typed draft as arguments', async ($, on) => {
  const { fills } = engine(on, LIST, 'fix typo in readme')
  for (const surface of SURFACES) {
    const ui = await $.ui.mount({ plugin: PLUGIN, surface, component: 'Pane', requestId: PLUGIN, props: PANE })
    await ui.press({ key: 'commit-bg' })
    expect(fills.at(-1)?.text).toBe('/git-agent:commit-bg fix typo in readme')
    await ui.unmount()
  }
})

for (const draft of ['/git-agent:commit-agent fix typo', '/git-agent:\nfix typo', '/git-agent:commit-agent\nfix typo']) {
  test(`a second press replaces the staged command instead of stacking it: ${JSON.stringify(draft)}`, async ($, on) => {
    const { fills } = engine(on, LIST, draft)
    for (const surface of SURFACES) {
      const ui = await $.ui.mount({ plugin: PLUGIN, surface, component: 'Pane', requestId: PLUGIN, props: PANE })
      await ui.press({ key: 'commit-bg' })
      expect(fills.at(-1)?.text).toBe('/git-agent:commit-bg fix typo')
      await ui.unmount()
    }
  })
}

test('a refused fill raises a toast naming the command', async ($, on) => {
  const { toasts } = engine(on, LIST, '', false)
  for (const surface of SURFACES) {
    const ui = await $.ui.mount({ plugin: PLUGIN, surface, component: 'Pane', requestId: PLUGIN, props: PANE })
    await ui.press({ key: 'pr-agent' })
    expect(toasts.at(-1)).toBe('Type /git-agent:pr-agent in the prompt')
    await ui.unmount()
  }
  expect(toasts).toHaveLength(2)
})

test('with no git-agent entries the pane names the install command', async ($, on) => {
  engine(on, LIST.filter(c => c.plugin !== 'git-agent'), '')
  for (const surface of SURFACES) {
    const ui = await $.ui.mount({ plugin: PLUGIN, surface, component: 'Pane', requestId: PLUGIN, props: PANE })
    expect(await ui.find({ text: '/plugin install git-agent@agentics-kit' })).toBeDefined()
    expect(await ui.findAll({ type: 'Button' })).toHaveLength(0)
    await ui.unmount()
  }
})

for (const surface of SURFACES) {
  test(`session start registers the command, and ${surface} gets the pane and no text`, async ($, on) => {
    const { registered } = engine(on, LIST, '')
    on('ui.open', () => ({ value: { isPlaced: true } }))
    await $.session.start({ cwd: '/repo', surface, isInteractive: surface === 'terminal' })
    expect(registered).toEqual([PLUGIN])
    expect((await $.command.run(RUN)).text).toBeUndefined()
  })

  test(`${surface} gets the text listing when the pane is not placed`, async ($, on) => {
    engine(on, LIST, '')
    on('ui.open', () => ({ value: { isPlaced: false, reason: 'the attached surfaces place no panes' } }))
    await $.session.start({ cwd: '/repo', surface, isInteractive: surface === 'terminal' })
    const { text } = await $.command.run(RUN)
    for (const name of GIT_AGENT) expect(text).toContain(`/git-agent:${name} — Runs ${name}.`)
    expect(text).not.toContain('plan-agent')
  })
}

test('a headless run gets the text listing although ui.open says placed', async ($, on) => {
  engine(on, LIST, '')
  on('ui.open', () => ({ value: { isPlaced: true } }))
  await $.session.start({ cwd: '/repo', surface: null, isInteractive: false })
  const { text } = await $.command.run({ ...RUN, origin: { kind: 'sdk' } })
  expect(text?.split('\n')).toHaveLength(GIT_AGENT.length)
  expect(text).toContain('/git-agent:commit-agent — Runs commit-agent.')
})

test('a surface that attaches after start counts as drawing', async ($, on) => {
  engine(on, LIST, '')
  on('ui.open', () => ({ value: { isPlaced: true } }))
  await $.session.start({ cwd: '/repo', surface: null, isInteractive: false })
  await $.session.attach({ surface: 'desktop', clientId: 'desktop:default' })
  expect((await $.command.run({ ...RUN, origin: { kind: 'sdk' } })).text).toBeUndefined()
})

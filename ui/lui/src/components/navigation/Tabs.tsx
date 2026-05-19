import { useState } from 'react'
import type { LuiNode } from '../../schemas/node'
import { nodeClassName, nodePartClassName, nodePartStyle, nodeStyle } from '../shared/nodeProps'

type TabsProps = {
  node: LuiNode
}

type TabItem = {
  content: string
  label: string
  value: string
}

function normalizeTabs(value: unknown): TabItem[] {
  if (!Array.isArray(value)) {
    return []
  }

  return value.map((item, index) => {
    const record = typeof item === 'object' && item !== null ? (item as Record<string, unknown>) : {}
    const value = String(record.value ?? record.id ?? `tab-${index + 1}`)
    return {
      content: String(record.content ?? record.description ?? ''),
      label: String(record.label ?? record.title ?? value),
      value,
    }
  })
}

export function Tabs({ node }: TabsProps) {
  const tabs = normalizeTabs(node.props.tabs ?? node.props.items)
  const [active, setActive] = useState(String(node.props.defaultValue ?? tabs[0]?.value ?? ''))

  return (
    <div className={nodeClassName(node.props, 'w-full')} style={nodeStyle(node.props)}>
      <div className={nodePartClassName(node.props, 'listClassName', 'inline-flex h-10 items-center justify-center rounded-lg border border-lui-line bg-lui-panel-soft p-1 text-lui-muted shadow-sm')} style={nodePartStyle(node.props, 'listClassName')}>
        {tabs.map((tab) => (
          <button
            key={tab.value}
            className={nodePartClassName(
              node.props,
              active === tab.value ? ['triggerClassName', 'activeTriggerClassName'] : ['triggerClassName', 'inactiveTriggerClassName'],
              `inline-flex h-8 items-center justify-center whitespace-nowrap rounded-md border px-3 py-1 text-sm font-medium transition-colors ${
                active === tab.value ? 'border-lui-line bg-lui-panel text-lui-ink shadow-sm' : 'border-transparent hover:bg-lui-panel hover:text-lui-ink'
              }`,
            )}
            style={nodePartStyle(node.props, active === tab.value ? ['triggerClassName', 'activeTriggerClassName'] : ['triggerClassName', 'inactiveTriggerClassName'])}
            type="button"
            onClick={() => setActive(tab.value)}
          >
            <span className={nodePartClassName(node.props, active === tab.value ? ['labelClassName', 'activeLabelClassName'] : ['labelClassName', 'inactiveLabelClassName'], '')} style={nodePartStyle(node.props, active === tab.value ? ['labelClassName', 'activeLabelClassName'] : ['labelClassName', 'inactiveLabelClassName'])}>
              {tab.label}
            </span>
          </button>
        ))}
      </div>
      {tabs.map((tab) => (
        <div key={tab.value} className={nodePartClassName(node.props, 'contentClassName', `mt-2 text-sm text-lui-ink ${active === tab.value ? 'block' : 'hidden'}`)} style={nodePartStyle(node.props, 'contentClassName')}>
          {tab.content}
        </div>
      ))}
    </div>
  )
}

import { useState } from 'react'
import type { LuiNode } from '../../schemas/node'
import { iconProp, IconSlot } from '../shared/IconSlot'
import { nodeClassName, nodePartClassName, nodePartStyle, nodeStyle } from '../shared/nodeProps'

type AccordionProps = {
  node: LuiNode
}

type AccordionItem = {
  content: string
  disabled: boolean
  title: string
  value: string
}

function normalizeItems(value: unknown): AccordionItem[] {
  if (!Array.isArray(value)) {
    return []
  }

  return value.map((item, index) => {
    const record = typeof item === 'object' && item !== null ? (item as Record<string, unknown>) : {}
    const value = String(record.value ?? record.id ?? `item-${index + 1}`)
    return {
      content: String(record.content ?? record.description ?? ''),
      disabled: record.disabled === true,
      title: String(record.title ?? record.label ?? value),
      value,
    }
  })
}

export function Accordion({ node }: AccordionProps) {
  const type = String(node.props.type ?? 'single')
  const collapsible = node.props.collapsible !== false
  const items = normalizeItems(node.props.items)
  const defaultValue = node.props.defaultValue ?? items[0]?.value
  const [openValues, setOpenValues] = useState<Set<string>>(() => new Set(defaultValue ? [String(defaultValue)] : []))

  const toggle = (value: string) => {
    setOpenValues((current) => {
      const next = new Set(type === 'multiple' ? current : [])
      if (current.has(value)) {
        if (collapsible) {
          next.delete(value)
        } else {
          next.add(value)
        }
      } else {
        next.add(value)
      }

      return next
    })
  }

  return (
    <div className={nodeClassName(node.props, 'w-full divide-y divide-lui-line')} style={nodeStyle(node.props)}>
      {items.map((item) => {
        const open = openValues.has(item.value)
        const icon = open
          ? (iconProp(node.props, ['openIcon', 'openIconComponent', 'activeIcon', 'activeIconComponent', 'icon', 'iconComponent']) ?? '⌄')
          : (iconProp(node.props, ['closedIcon', 'closedIconComponent', 'icon', 'iconComponent']) ?? '⌄')
        return (
          <div key={item.value} className={nodePartClassName(node.props, 'itemClassName', '')} style={nodePartStyle(node.props, 'itemClassName')}>
            <button
              className={nodePartClassName(
                node.props,
                open ? ['triggerClassName', 'activeTriggerClassName', 'openTriggerClassName'] : 'triggerClassName',
                'flex w-full items-center justify-between py-4 text-left text-sm font-medium text-lui-ink transition-colors hover:underline disabled:pointer-events-none disabled:opacity-50',
              )}
              disabled={item.disabled}
              style={nodePartStyle(node.props, open ? ['triggerClassName', 'activeTriggerClassName', 'openTriggerClassName'] : 'triggerClassName')}
              type="button"
              onClick={() => toggle(item.value)}
            >
              <span className={nodePartClassName(node.props, 'titleClassName', '')} style={nodePartStyle(node.props, 'titleClassName')}>
                {item.title}
              </span>
              <IconSlot className={`text-lui-muted transition-transform ${open ? 'rotate-180' : ''}`} props={node.props} value={icon} />
            </button>
            {open && (
              <div className={nodePartClassName(node.props, 'contentClassName', 'pb-4 pt-0 text-sm text-lui-muted')} style={nodePartStyle(node.props, 'contentClassName')}>
                {item.content}
              </div>
            )}
          </div>
        )
      })}
    </div>
  )
}

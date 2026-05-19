import type React from 'react'
import type { LuiNode } from '../../schemas/node'
import { nodeClassName, nodePartClassName, nodePartStyle, nodeStyle } from '../shared/nodeProps'

type TooltipProps = {
  node: LuiNode
  children: React.ReactNode
}

export function Tooltip({ node, children }: TooltipProps) {
  const content = String(node.props.content ?? node.props.label ?? '')
  const trigger = node.props.trigger === undefined ? undefined : String(node.props.trigger)

  return (
    <span className={nodeClassName(node.props, 'group relative inline-flex')} style={nodeStyle(node.props)}>
      {children || (
        <span className={nodePartClassName(node.props, 'triggerClassName', 'cursor-default')} style={nodePartStyle(node.props, 'triggerClassName')}>
          {trigger}
        </span>
      )}
      <span
        className={nodePartClassName(
          node.props,
          ['tooltipClassName', 'contentClassName'],
          'pointer-events-none absolute bottom-full left-1/2 z-50 mb-2 -translate-x-1/2 rounded-md border border-lui-line bg-lui-ink px-3 py-1.5 text-xs text-lui-panel opacity-0 shadow-md transition-opacity group-hover:opacity-100',
        )}
        style={nodePartStyle(node.props, ['tooltipClassName', 'contentClassName'])}
      >
        {content}
      </span>
    </span>
  )
}

import type React from 'react'
import type { LuiNode } from '../../schemas/node'
import { nodeClassName, nodeStyle } from '../shared/nodeProps'

type RowProps = {
  node: LuiNode
  children: React.ReactNode
}

export function Row({ node, children }: RowProps) {
  const align = String(node.props.align ?? 'center')
  const alignClass = align === 'start' ? 'items-start' : align === 'end' ? 'items-end' : 'items-center'

  return (
    <div className={nodeClassName(node.props, `flex flex-wrap gap-3 ${alignClass}`)} style={nodeStyle(node.props)}>
      {children}
    </div>
  )
}

import type React from 'react'
import type { LuiNode } from '../../schemas/node'
import { nodeClassName, nodeStyle } from '../shared/nodeProps'

type PanelProps = {
  node: LuiNode
  children: React.ReactNode
}

export function Panel({ node, children }: PanelProps) {
  const width = String(node.props.width ?? 'md')
  const widthClass = width === 'sm' ? 'max-w-sm' : width === 'lg' ? 'max-w-2xl' : 'max-w-lg'
  const className = nodeClassName(
    node.props,
    `m-8 rounded-lg border border-lui-line bg-lui-panel p-5 shadow-lui ${widthClass}`,
  )

  return (
    <div className={className} style={nodeStyle(node.props)}>
      {children}
    </div>
  )
}

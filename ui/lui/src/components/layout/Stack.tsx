import type React from 'react'
import type { LuiNode } from '../../schemas/node'
import { nodeClassName, nodeStyle } from '../shared/nodeProps'

type StackProps = {
  node: LuiNode
  children: React.ReactNode
}

const gapClass: Record<string, string> = {
  sm: 'gap-2',
  md: 'gap-3',
  lg: 'gap-5',
}

export function Stack({ node, children }: StackProps) {
  const gap = String(node.props.gap ?? 'md')

  return (
    <div className={nodeClassName(node.props, `flex flex-col ${gapClass[gap] ?? gapClass.md}`)} style={nodeStyle(node.props)}>
      {children}
    </div>
  )
}

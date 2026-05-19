import type { LuiNode } from '../../schemas/node'
import { nodeClassName, nodeStyle } from '../shared/nodeProps'

type TextProps = {
  node: LuiNode
}

export function Text({ node }: TextProps) {
  const tone = String(node.props.tone ?? 'default')
  const className =
    tone === 'muted'
      ? 'text-sm leading-6 text-lui-muted'
      : 'text-sm leading-6 text-lui-ink'

  return (
    <p className={nodeClassName(node.props, className)} style={nodeStyle(node.props)}>
      {String(node.props.value ?? '')}
    </p>
  )
}

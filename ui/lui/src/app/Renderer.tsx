import { renderElement } from '../registry/elements'
import type { LuiNode } from '../schemas/node'

type RendererProps = {
  node: LuiNode
}

export function Renderer({ node }: RendererProps) {
  return renderElement(node)
}

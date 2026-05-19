import type React from 'react'
import type { LuiNode } from '../../schemas/node'
import { nodeClassName, nodeStyle } from '../shared/nodeProps'

type TypographyProps = {
  node: LuiNode
  children: React.ReactNode
}

const variants: Record<string, { className: string; tag: React.ElementType }> = {
  blockquote: { className: 'mt-6 border-l-2 border-lui-line pl-6 italic text-lui-ink', tag: 'blockquote' },
  code: { className: 'relative rounded bg-lui-panel-soft px-[0.3rem] py-[0.2rem] font-mono text-sm font-semibold', tag: 'code' },
  h1: { className: 'scroll-m-20 text-4xl font-extrabold tracking-tight text-lui-ink', tag: 'h1' },
  h2: { className: 'scroll-m-20 border-b border-lui-line pb-2 text-3xl font-semibold tracking-tight text-lui-ink', tag: 'h2' },
  h3: { className: 'scroll-m-20 text-2xl font-semibold tracking-tight text-lui-ink', tag: 'h3' },
  h4: { className: 'scroll-m-20 text-xl font-semibold tracking-tight text-lui-ink', tag: 'h4' },
  large: { className: 'text-lg font-semibold text-lui-ink', tag: 'div' },
  lead: { className: 'text-xl text-lui-muted', tag: 'p' },
  muted: { className: 'text-sm text-lui-muted', tag: 'p' },
  p: { className: 'leading-7 text-lui-ink', tag: 'p' },
  small: { className: 'text-sm font-medium leading-none text-lui-ink', tag: 'small' },
}

export function Typography({ node, children }: TypographyProps) {
  const variant = variants[String(node.props.variant ?? node.props.as ?? 'p')] ?? variants.p
  const Component = variant.tag
  const value = node.props.value === undefined ? undefined : String(node.props.value)
  const hasChildren = Array.isArray(children) ? children.length > 0 : Boolean(children)

  return (
    <Component className={nodeClassName(node.props, variant.className)} style={nodeStyle(node.props)}>
      {hasChildren ? children : value}
    </Component>
  )
}

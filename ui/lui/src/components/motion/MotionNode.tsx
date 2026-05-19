import { motion, type MotionProps } from 'framer-motion'
import type React from 'react'
import { sendLuiEvent } from '../../bridge/nui'
import type { LuiNode } from '../../schemas/node'
import { hasIcon, iconProp, IconSlot } from '../shared/IconSlot'
import { nodeClassName, nodePartClassName, nodePartStyle, nodeStyle } from '../shared/nodeProps'

type MotionNodeProps = {
  node: LuiNode
  children: React.ReactNode
}

const motionComponents = {
  article: motion.article,
  button: motion.button,
  div: motion.div,
  li: motion.li,
  p: motion.p,
  section: motion.section,
  span: motion.span,
  ul: motion.ul,
} as const

const motionPropNames = [
  'animate',
  'custom',
  'drag',
  'dragConstraints',
  'dragElastic',
  'dragMomentum',
  'exit',
  'initial',
  'layout',
  'layoutDependency',
  'layoutId',
  'transition',
  'variants',
  'whileDrag',
  'whileFocus',
  'whileHover',
  'whileInView',
  'whileTap',
] as const

type MotionElementName = keyof typeof motionComponents

function getMotionComponent(value: unknown): React.ElementType {
  const tag = String(value ?? 'div')
  if (tag in motionComponents) {
    return motionComponents[tag as MotionElementName]
  }

  return motionComponents.div
}

function motionPropsFrom(props: Record<string, unknown>): MotionProps {
  const motionProps: Record<string, unknown> = {}

  for (const propName of motionPropNames) {
    if (props[propName] !== undefined) {
      motionProps[propName] = props[propName]
    }
  }

  return motionProps as MotionProps
}

export function MotionNode({ node, children }: MotionNodeProps) {
  const Component = getMotionComponent(node.props.as)
  const actionId = typeof node.props.actionId === 'string' ? node.props.actionId : ''
  const label = node.props.label === undefined ? undefined : String(node.props.label)
  const hasChildren = node.children.length > 0
  const startIcon = iconProp(node.props, ['startIcon', 'startIconComponent', 'icon', 'iconComponent'])
  const endIcon = iconProp(node.props, ['endIcon', 'endIconComponent'])
  const iconPosition = String(node.props.iconPosition ?? 'start')

  return (
    <Component
      {...motionPropsFrom(node.props)}
      className={nodeClassName(node.props, String(node.props.classBase ?? ''))}
      style={nodeStyle(node.props)}
      type={node.props.as === 'button' ? 'button' : undefined}
      onClick={actionId.length > 0 ? () => void sendLuiEvent({ actionId }) : undefined}
    >
      {hasChildren ? (
        children
      ) : (
        <>
          {hasIcon(startIcon) && iconPosition !== 'end' && <IconSlot className="mr-2 inline-flex" partClassName={['iconClassName', 'startIconClassName']} props={node.props} value={startIcon} />}
          <span className={nodePartClassName(node.props, 'labelClassName', '')} style={nodePartStyle(node.props, 'labelClassName')}>
            {label}
          </span>
          {(hasIcon(endIcon) || (hasIcon(startIcon) && iconPosition === 'end')) && <IconSlot className="ml-2 inline-flex" partClassName={['iconClassName', 'endIconClassName']} props={node.props} value={endIcon || startIcon} />}
        </>
      )}
    </Component>
  )
}

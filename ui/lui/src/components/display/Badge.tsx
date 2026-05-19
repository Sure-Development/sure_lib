import type { LuiNode } from '../../schemas/node'
import { hasIcon, iconProp, IconSlot } from '../shared/IconSlot'
import { nodeClassName, nodePartClassName, nodePartStyle, nodeStyle } from '../shared/nodeProps'

type BadgeProps = {
  node: LuiNode
}

const variants: Record<string, string> = {
  default: 'border-transparent bg-lui-accent text-lui-accentForeground',
  destructive: 'border-transparent bg-red-500 text-white',
  outline: 'border-lui-line text-lui-ink',
  secondary: 'border-transparent bg-lui-panel-soft text-lui-ink',
}

export function Badge({ node }: BadgeProps) {
  const variant = String(node.props.variant ?? 'default')
  const label = String(node.props.label ?? node.props.value ?? '')
  const startIcon = iconProp(node.props, ['startIcon', 'startIconComponent', 'icon', 'iconComponent'])
  const endIcon = iconProp(node.props, ['endIcon', 'endIconComponent'])
  const iconPosition = String(node.props.iconPosition ?? 'start')

  return (
    <span
      className={nodeClassName(
        node.props,
        `inline-flex items-center rounded-md border px-2.5 py-0.5 text-xs font-semibold transition-colors ${variants[variant] ?? variants.default}`,
      )}
      style={nodeStyle(node.props)}
    >
      {hasIcon(startIcon) && iconPosition !== 'end' && <IconSlot className="mr-1 inline-flex" partClassName={['iconClassName', 'startIconClassName']} props={node.props} value={startIcon} />}
      <span className={nodePartClassName(node.props, 'labelClassName', '')} style={nodePartStyle(node.props, 'labelClassName')}>
        {label}
      </span>
      {(hasIcon(endIcon) || (hasIcon(startIcon) && iconPosition === 'end')) && <IconSlot className="ml-1 inline-flex" partClassName={['iconClassName', 'endIconClassName']} props={node.props} value={endIcon || startIcon} />}
    </span>
  )
}

import { sendLuiEvent } from '../../bridge/nui'
import type { LuiNode } from '../../schemas/node'
import { hasIcon, iconProp, IconSlot } from '../shared/IconSlot'
import { nodeClassName, nodePartClassName, nodePartStyle, nodeStyle } from '../shared/nodeProps'

type ButtonProps = {
  node: LuiNode
}

export function Button({ node }: ButtonProps) {
  const actionId = String(node.props.actionId ?? '')
  const label = String(node.props.label ?? '')
  const startIcon = iconProp(node.props, ['startIcon', 'startIconComponent', 'icon', 'iconComponent'])
  const endIcon = iconProp(node.props, ['endIcon', 'endIconComponent'])
  const iconPosition = String(node.props.iconPosition ?? 'start')
  const variant = String(node.props.variant ?? 'primary')
  const className =
    variant === 'ghost'
      ? 'rounded-md border border-lui-line px-3 py-2 text-sm font-medium text-lui-ink transition-colors hover:bg-black/5'
      : 'rounded-md bg-lui-accent px-3 py-2 text-sm font-semibold text-lui-accentForeground shadow-sm transition-colors hover:brightness-110'

  return (
    <button className={nodeClassName(node.props, className)} style={nodeStyle(node.props)} type="button" onClick={() => void sendLuiEvent({ actionId })}>
      {hasIcon(startIcon) && iconPosition !== 'end' && <IconSlot className="mr-2 inline-flex" partClassName={['iconClassName', 'startIconClassName']} props={node.props} value={startIcon} />}
      <span className={nodePartClassName(node.props, 'labelClassName', '')} style={nodePartStyle(node.props, 'labelClassName')}>
        {label}
      </span>
      {(hasIcon(endIcon) || (hasIcon(startIcon) && iconPosition === 'end')) && <IconSlot className="ml-2 inline-flex" partClassName={['iconClassName', 'endIconClassName']} props={node.props} value={endIcon || startIcon} />}
    </button>
  )
}

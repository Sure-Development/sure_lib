import type React from 'react'
import type { LuiNode } from '../../schemas/node'
import { hasIcon, iconProp, IconSlot } from '../shared/IconSlot'
import { nodeClassName, nodePartClassName, nodePartStyle, nodeStyle } from '../shared/nodeProps'

type AlertProps = {
  node: LuiNode
  children: React.ReactNode
}

export function Alert({ node, children }: AlertProps) {
  const title = node.props.title === undefined ? undefined : String(node.props.title)
  const description = node.props.description === undefined ? undefined : String(node.props.description)
  const icon = iconProp(node.props, ['icon', 'iconComponent'])
  const variant = String(node.props.variant ?? 'default')
  const variantClass = variant === 'destructive' ? 'border-red-500/50 text-red-600' : 'border-lui-line text-lui-ink'

  return (
    <div
      className={nodeClassName(node.props, `relative w-full rounded-lg border bg-lui-panel px-4 py-3 text-sm ${variantClass}`)}
      role="alert"
      style={nodeStyle(node.props)}
    >
      <div className={nodePartClassName(node.props, 'innerClassName', hasIcon(icon) ? 'flex gap-3' : '')} style={nodePartStyle(node.props, 'innerClassName')}>
        {hasIcon(icon) && <IconSlot className="mt-0.5 inline-flex" props={node.props} value={icon} />}
        <div className={nodePartClassName(node.props, ['bodyClassName', 'contentClassName'], 'min-w-0 flex-1')} style={nodePartStyle(node.props, ['bodyClassName', 'contentClassName'])}>
          {title && (
            <h5 className={nodePartClassName(node.props, 'titleClassName', 'mb-1 font-medium leading-none tracking-tight')} style={nodePartStyle(node.props, 'titleClassName')}>
              {title}
            </h5>
          )}
          {description && (
            <div className={nodePartClassName(node.props, 'descriptionClassName', 'text-sm text-lui-muted')} style={nodePartStyle(node.props, 'descriptionClassName')}>
              {description}
            </div>
          )}
          {children}
        </div>
      </div>
    </div>
  )
}

import { sendLuiEvent } from '../../bridge/nui'
import type { LuiNode } from '../../schemas/node'
import { hasIcon, iconProp, IconSlot } from '../shared/IconSlot'
import { nodeClassName, nodePartClassName, nodePartStyle, nodeStyle } from '../shared/nodeProps'

type InputProps = {
  node: LuiNode
}

export function Input({ node }: InputProps) {
  const actionId = String(node.props.actionId ?? '')
  const placeholder = String(node.props.placeholder ?? '')
  const value = String(node.props.value ?? '')
  const prefix = iconProp(node.props, ['prefix', 'prefixIcon', 'prefixIconComponent', 'startIcon', 'startIconComponent', 'icon', 'iconComponent'])
  const suffix = iconProp(node.props, ['suffix', 'suffixIcon', 'suffixIconComponent', 'endIcon', 'endIconComponent'])

  return (
    <label className={nodePartClassName(node.props, 'wrapperClassName', 'relative inline-flex min-w-48 items-center')} style={nodePartStyle(node.props, 'wrapperClassName')}>
      {hasIcon(prefix) && <IconSlot className="pointer-events-none absolute left-3 text-sm text-lui-muted" partClassName={['prefixClassName', 'startIconClassName', 'iconClassName']} props={node.props} value={prefix} />}
      <input
        className={nodeClassName(node.props, nodePartClassName(node.props, 'inputClassName', `min-w-48 rounded-md border border-lui-line bg-lui-panel-soft px-3 py-2 text-sm text-lui-ink outline-none transition-colors placeholder:text-lui-muted focus:border-lui-accent ${hasIcon(prefix) ? 'pl-8' : ''} ${hasIcon(suffix) ? 'pr-8' : ''}`))}
        defaultValue={value}
        placeholder={placeholder}
        style={{ ...nodePartStyle(node.props, 'inputClassName'), ...nodeStyle(node.props) }}
        onChange={(event) => void sendLuiEvent({ actionId, payload: { value: event.currentTarget.value } })}
      />
      {hasIcon(suffix) && <IconSlot className="pointer-events-none absolute right-3 text-sm text-lui-muted" partClassName={['suffixClassName', 'endIconClassName']} props={node.props} value={suffix} />}
    </label>
  )
}

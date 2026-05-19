import { sendLuiEvent } from '../../bridge/nui'
import type { LuiNode } from '../../schemas/node'
import { nodeClassName, nodePartClassName, nodePartStyle, nodeStyle } from '../shared/nodeProps'

type TextareaProps = {
  node: LuiNode
}

export function Textarea({ node }: TextareaProps) {
  const actionId = String(node.props.actionId ?? '')
  const placeholder = String(node.props.placeholder ?? '')
  const value = String(node.props.value ?? '')

  return (
    <textarea
      className={nodeClassName(
        node.props,
        nodePartClassName(
          node.props,
          ['textareaClassName', 'inputClassName'],
          'min-h-20 w-full rounded-md border border-lui-line bg-lui-panel px-3 py-2 text-sm text-lui-ink shadow-sm outline-none transition-colors placeholder:text-lui-muted focus:border-lui-accent disabled:cursor-not-allowed disabled:opacity-50',
        ),
      )}
      defaultValue={value}
      placeholder={placeholder}
      style={{ ...nodePartStyle(node.props, ['textareaClassName', 'inputClassName']), ...nodeStyle(node.props) }}
      onChange={(event) => void sendLuiEvent({ actionId, payload: { value: event.currentTarget.value } })}
    />
  )
}

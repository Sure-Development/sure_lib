import { useEffect, useMemo, useState } from 'react'
import { sendLuiEvent } from '../../bridge/nui'
import type { LuiNode } from '../../schemas/node'
import { iconProp, IconSlot } from '../shared/IconSlot'
import { nodeClassName, nodePartClassName, nodePartStyle, nodeStyle } from '../shared/nodeProps'

type SelectOption = {
  label: string
  value: string
}

type SelectProps = {
  node: LuiNode
}

function normalizeOptions(value: unknown): SelectOption[] {
  if (!Array.isArray(value)) {
    return []
  }

  return value.map((option) => {
    if (typeof option === 'object' && option !== null && 'value' in option) {
      const record = option as Record<string, unknown>
      return {
        label: String(record.label ?? record.value),
        value: String(record.value),
      }
    }

    return {
      label: String(option),
      value: String(option),
    }
  })
}

export function Select({ node }: SelectProps) {
  const actionId = String(node.props.actionId ?? '')
  const value = String(node.props.value ?? '')
  const options = normalizeOptions(node.props.options)
  const [open, setOpen] = useState(false)
  const [localValue, setLocalValue] = useState(value)
  const selectedValue = localValue || value
  const selected = useMemo(() => options.find((option) => option.value === selectedValue) ?? options[0], [options, selectedValue])
  const icon = open
    ? (iconProp(node.props, ['openIcon', 'openIconComponent', 'activeIcon', 'activeIconComponent', 'icon', 'iconComponent']) ?? '⌄')
    : (iconProp(node.props, ['closedIcon', 'closedIconComponent', 'icon', 'iconComponent']) ?? '⌄')

  useEffect(() => {
    setLocalValue(value)
  }, [value])

  const choose = (option: SelectOption) => {
    setLocalValue(option.value)
    setOpen(false)
    void sendLuiEvent({ actionId, payload: { value: option.value } })
  }

  return (
    <div className={nodeClassName(node.props, 'relative inline-flex min-w-48 items-center')} style={nodeStyle(node.props)}>
      <button
        className={nodePartClassName(
          node.props,
          'triggerClassName',
          'flex h-10 w-full items-center justify-between rounded-md border border-lui-line bg-lui-panel px-3 py-2 text-sm text-lui-ink shadow-sm outline-none transition-colors hover:bg-lui-panel-soft focus:border-lui-accent',
        )}
        style={nodePartStyle(node.props, 'triggerClassName')}
        type="button"
        onClick={() => setOpen((current) => !current)}
      >
        <span className={nodePartClassName(node.props, ['valueClassName', 'labelClassName'], '')} style={nodePartStyle(node.props, ['valueClassName', 'labelClassName'])}>
          {selected?.label ?? ''}
        </span>
        <IconSlot className={`text-xs text-lui-muted transition-transform ${open ? 'rotate-180' : ''}`} props={node.props} value={icon} />
      </button>
      {open && (
        <div
          className={nodePartClassName(
            node.props,
            ['menuClassName', 'contentClassName'],
            'absolute left-0 top-[calc(100%+0.25rem)] z-50 max-h-60 w-full overflow-auto rounded-md border border-lui-line bg-lui-panel p-1 text-lui-ink shadow-lui',
          )}
          style={nodePartStyle(node.props, ['menuClassName', 'contentClassName'])}
        >
          {options.map((option) => (
            <button
              key={option.value}
              className={nodePartClassName(
                node.props,
                option.value === selectedValue ? ['optionClassName', 'optionActiveClassName', 'optionSelectedClassName'] : 'optionClassName',
                `flex w-full items-center rounded-sm px-2 py-1.5 text-left text-sm outline-none transition-colors ${
                  option.value === selectedValue ? 'bg-lui-panel-soft font-medium' : 'hover:bg-lui-panel-soft'
                }`,
              )}
              style={nodePartStyle(node.props, option.value === selectedValue ? ['optionClassName', 'optionActiveClassName', 'optionSelectedClassName'] : 'optionClassName')}
              type="button"
              onClick={() => choose(option)}
            >
              <span className={nodePartClassName(node.props, option.value === selectedValue ? ['optionLabelClassName', 'optionActiveLabelClassName'] : 'optionLabelClassName', '')} style={nodePartStyle(node.props, option.value === selectedValue ? ['optionLabelClassName', 'optionActiveLabelClassName'] : 'optionLabelClassName')}>
                {option.label}
              </span>
            </button>
          ))}
        </div>
      )}
    </div>
  )
}

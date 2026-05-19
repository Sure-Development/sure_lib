import { useEffect, useState } from 'react'
import { sendLuiEvent } from '../../bridge/nui'
import type { LuiNode } from '../../schemas/node'
import { hasIcon, iconProp, IconSlot } from '../shared/IconSlot'
import { nodeClassName, nodePartClassName, nodePartStyle, nodeStyle } from '../shared/nodeProps'

type SliderProps = {
  node: LuiNode
}

function readNumber(value: unknown, fallback: number): number {
  const numeric = Number(value)
  return Number.isFinite(numeric) ? numeric : fallback
}

export function Slider({ node }: SliderProps) {
  const actionId = String(node.props.actionId ?? '')
  const min = readNumber(node.props.min, 0)
  const max = readNumber(node.props.max, 100)
  const step = readNumber(node.props.step, 1)
  const value = readNumber(node.props.value, min)
  const [localValue, setLocalValue] = useState(value)
  const progress = max === min ? 0 : ((localValue - min) / (max - min)) * 100
  const thumbIcon = iconProp(node.props, ['thumbIcon', 'thumbIconComponent', 'icon', 'iconComponent'])
  const rangeIcon = iconProp(node.props, ['rangeIcon', 'rangeIconComponent', 'fillIcon', 'fillIconComponent'])

  useEffect(() => {
    setLocalValue(value)
  }, [value])

  const changeValue = (nextValue: number) => {
    setLocalValue(nextValue)
    void sendLuiEvent({ actionId, payload: { value: nextValue } })
  }

  return (
    <div className={nodeClassName(node.props, 'relative flex h-5 w-full items-center')} style={nodeStyle(node.props)}>
      <div className={nodePartClassName(node.props, 'trackClassName', 'relative h-2 w-full overflow-hidden rounded-full bg-lui-panel-soft')} style={nodePartStyle(node.props, 'trackClassName')}>
        <div
          className={nodePartClassName(node.props, ['rangeClassName', 'fillClassName'], 'flex h-full items-center justify-end rounded-full bg-lui-accent')}
          style={{ ...nodePartStyle(node.props, ['rangeClassName', 'fillClassName']), width: `${progress}%` }}
        >
          {hasIcon(rangeIcon) && <IconSlot className="mr-1 text-[10px] text-lui-accentForeground" partClassName={['rangeIconClassName', 'fillIconClassName']} props={node.props} value={rangeIcon} />}
        </div>
      </div>
      <div
        className={nodePartClassName(node.props, 'thumbClassName', 'pointer-events-none absolute inline-flex size-5 -translate-x-1/2 items-center justify-center rounded-full border-2 border-lui-accent bg-lui-panel text-[10px] shadow-sm')}
        style={{ ...nodePartStyle(node.props, 'thumbClassName'), left: `${progress}%` }}
      >
        <IconSlot props={node.props} value={thumbIcon} />
      </div>
      <input
        className={nodePartClassName(node.props, 'inputClassName', 'absolute inset-0 h-5 w-full cursor-pointer opacity-0 disabled:cursor-not-allowed')}
        style={nodePartStyle(node.props, 'inputClassName')}
        max={max}
        min={min}
        step={step}
        type="range"
        value={localValue}
        onChange={(event) => changeValue(Number(event.currentTarget.value))}
      />
    </div>
  )
}

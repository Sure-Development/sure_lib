import { AnimatePresence } from 'framer-motion'
import type React from 'react'
import type { LuiNode } from '../../schemas/node'

type PresenceProps = {
  node: LuiNode
  children: React.ReactNode
}

const modes = new Set(['sync', 'wait', 'popLayout'])

function readMode(value: unknown): 'sync' | 'wait' | 'popLayout' | undefined {
  if (typeof value === 'string' && modes.has(value)) {
    return value as 'sync' | 'wait' | 'popLayout'
  }

  return undefined
}

export function Presence({ node, children }: PresenceProps) {
  return (
    <AnimatePresence
      custom={node.props.custom}
      initial={typeof node.props.initial === 'boolean' ? node.props.initial : undefined}
      mode={readMode(node.props.mode)}
      presenceAffectsLayout={
        typeof node.props.presenceAffectsLayout === 'boolean' ? node.props.presenceAffectsLayout : undefined
      }
      propagate={typeof node.props.propagate === 'boolean' ? node.props.propagate : undefined}
    >
      {children}
    </AnimatePresence>
  )
}

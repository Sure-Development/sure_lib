import type { NuiEventPayload, NuiEventResult } from './protocol'
import { luiDebug } from '../debug/luiDebug'

declare global {
  interface Window {
    GetParentResourceName?: () => string
  }
}

const resourceName = window.GetParentResourceName?.() ?? 'sure_lib'
const isNuiRuntime = typeof window.GetParentResourceName === 'function'

async function sendNuiCallback<TPayload, TResult>(name: string, payload: TPayload): Promise<TResult> {
  if (!isNuiRuntime) {
    luiDebug('info', 'bridge', 'skipped NUI callback outside FiveM runtime', { name, payload })
    return { ok: true } as TResult
  }

  luiDebug('info', 'bridge', 'posting NUI callback', { name, payload })
  const response = await fetch(`https://${resourceName}/${name}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: JSON.stringify(payload),
  })

  if (!response.ok) {
    luiDebug('warn', 'bridge', 'NUI callback returned HTTP error', {
      name,
      status: response.status,
      statusText: response.statusText,
    })
  }

  const result = await response.json()
  luiDebug('info', 'bridge', 'NUI callback completed', { name, result })
  return result
}

export async function notifyLuiReady(): Promise<NuiEventResult> {
  return sendNuiCallback('lui:ready', {})
}

export async function sendLuiEvent(payload: NuiEventPayload): Promise<NuiEventResult> {
  return sendNuiCallback('lui:event', payload)
}

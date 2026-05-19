export type LuiDebugLevel = 'info' | 'warn' | 'error'

export type LuiDebugEvent = {
  id: number
  at: string
  level: LuiDebugLevel
  area: string
  message: string
  data?: unknown
}

type DebugListener = (events: LuiDebugEvent[]) => void

declare global {
  interface Window {
    __SURE_LUI_DEBUG__?: boolean
    sureLuiDebug?: {
      enable: () => void
      disable: () => void
      events: () => LuiDebugEvent[]
      clear: () => void
    }
  }
}

const debugStorageKey = 'sure:lui:debug'
const maxEvents = 100
const events: LuiDebugEvent[] = []
const listeners = new Set<DebugListener>()

let nextEventId = 0
let enabled = readInitialEnabled()

function readInitialEnabled() {
  const query = new URLSearchParams(window.location.search)
  const queryValue = query.get('luiDebug')

  if (queryValue != null) {
    return queryValue === '1' || queryValue === 'true'
  }

  return window.__SURE_LUI_DEBUG__ === true || window.localStorage.getItem(debugStorageKey) === '1'
}

function notifyListeners() {
  const snapshot = getLuiDebugEvents()
  for (const listener of listeners) {
    listener(snapshot)
  }
}

export function isLuiDebugEnabled() {
  return enabled
}

export function setLuiDebugEnabled(value: boolean) {
  enabled = value

  if (value) {
    window.localStorage.setItem(debugStorageKey, '1')
  } else {
    window.localStorage.removeItem(debugStorageKey)
  }

  notifyListeners()
}

export function getLuiDebugEvents() {
  return [...events]
}

export function clearLuiDebugEvents() {
  events.length = 0
  notifyListeners()
}

export function subscribeLuiDebug(listener: DebugListener) {
  listeners.add(listener)
  listener(getLuiDebugEvents())

  return () => {
    listeners.delete(listener)
  }
}

export function luiDebug(level: LuiDebugLevel, area: string, message: string, data?: unknown) {
  const event: LuiDebugEvent = {
    id: ++nextEventId,
    at: new Date().toISOString(),
    level,
    area,
    message,
    data,
  }

  events.push(event)
  if (events.length > maxEvents) {
    events.shift()
  }

  if (!enabled) {
    return
  }

  notifyListeners()

  const method = level === 'error' ? console.error : level === 'warn' ? console.warn : console.debug
  method('[sure_lui]', `${area}: ${message}`, data ?? '')
}

window.sureLuiDebug = {
  enable: () => setLuiDebugEnabled(true),
  disable: () => setLuiDebugEnabled(false),
  events: getLuiDebugEvents,
  clear: clearLuiDebugEvents,
}

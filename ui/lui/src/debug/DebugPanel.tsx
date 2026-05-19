import { useEffect, useState } from 'react'
import {
  getLuiDebugEvents,
  isLuiDebugEnabled,
  setLuiDebugEnabled,
  subscribeLuiDebug,
  type LuiDebugEvent,
} from './luiDebug'
import { useLuiStore } from '../store/useLuiStore'

function formatData(data: unknown) {
  if (data == null) {
    return ''
  }

  try {
    return JSON.stringify(data)
  } catch {
    return String(data)
  }
}

export function DebugPanel() {
  const pages = useLuiStore((state) => state.pages)
  const [enabled, setEnabled] = useState(isLuiDebugEnabled)
  const [events, setEvents] = useState<LuiDebugEvent[]>(getLuiDebugEvents)

  useEffect(() => {
    return subscribeLuiDebug((nextEvents) => {
      setEnabled(isLuiDebugEnabled())
      setEvents(nextEvents)
    })
  }, [])

  if (!enabled) {
    return null
  }

  const pageEntries = Object.entries(pages)
  const visiblePages = pageEntries.filter(([, page]) => page.visible).map(([pageId]) => pageId)
  const recentEvents = events.slice(-12).reverse()

  return (
    <aside className="pointer-events-auto fixed bottom-3 right-3 z-50 max-h-[72vh] w-[26rem] max-w-[calc(100vw-1.5rem)] overflow-hidden rounded-lg border border-lui-line bg-slate-950/90 text-lui-ink shadow-lui">
      <div className="flex items-center justify-between border-b border-lui-line px-3 py-2">
        <div>
          <p className="text-sm font-semibold">sure_lui debug</p>
          <p className="text-xs text-lui-muted">{pageEntries.length} pages, {visiblePages.length} visible</p>
        </div>
        <button
          className="rounded-md border border-lui-line px-2 py-1 text-xs text-lui-muted transition-colors hover:bg-white/10"
          type="button"
          onClick={() => setLuiDebugEnabled(false)}
        >
          Hide
        </button>
      </div>

      <div className="max-h-[60vh] overflow-auto p-3 text-xs">
        <div className="mb-3 grid grid-cols-2 gap-2">
          <div className="rounded-md border border-lui-line bg-slate-950/70 p-2">
            <p className="text-lui-muted">Visible</p>
            <p className="break-words font-medium">{visiblePages.join(', ') || 'none'}</p>
          </div>
          <div className="rounded-md border border-lui-line bg-slate-950/70 p-2">
            <p className="text-lui-muted">Events</p>
            <p className="font-medium">{events.length}</p>
          </div>
        </div>

        <div className="flex flex-col gap-2">
          {recentEvents.map((event) => (
            <div key={event.id} className="rounded-md border border-lui-line bg-slate-950/70 p-2">
              <div className="flex items-center justify-between gap-2">
                <p className="font-semibold">{event.area}</p>
                <p className="text-lui-muted">{event.level}</p>
              </div>
              <p className="mt-1">{event.message}</p>
              {event.data != null && <p className="mt-1 break-words text-lui-muted">{formatData(event.data)}</p>}
            </div>
          ))}
        </div>
      </div>
    </aside>
  )
}

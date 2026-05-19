import { useEffect, useState } from 'react'
import { DebugPanel } from '../debug/DebugPanel'
import { createDevMockTree } from '../debug/devMock'
import { isLuiDebugEnabled, luiDebug, subscribeLuiDebug } from '../debug/luiDebug'
import { Renderer } from './Renderer'
import { notifyLuiReady } from '../bridge/nui'
import { nuiMessageSchema } from '../schemas/events'
import { useLuiStore } from '../store/useLuiStore'

function wait(ms: number) {
  return new Promise((resolve) => window.setTimeout(resolve, ms))
}

function formatIssues(issues: { path: PropertyKey[]; message: string }[]) {
  return issues.map((issue) => `${issue.path.join('.') || '<root>'}: ${issue.message}`).join('; ')
}

export function App() {
  const pages = useLuiStore((state) => state.pages)
  const renderPage = useLuiStore((state) => state.renderPage)
  const patchPage = useLuiStore((state) => state.patchPage)
  const setVisible = useLuiStore((state) => state.setVisible)
  const [debugEnabled, setDebugEnabled] = useState(isLuiDebugEnabled)

  useEffect(() => {
    let cancelled = false

    function onMessage(event: MessageEvent<unknown>) {
      luiDebug('info', 'message', 'received window message', event.data)
      const parsed = nuiMessageSchema.safeParse(event.data)
      if (!parsed.success) {
        const summary = formatIssues(parsed.error.issues)
        luiDebug('warn', 'message', 'ignored unknown message shape', {
          data: event.data,
          summary,
          issues: parsed.error.issues,
        })
        luiDebug('warn', 'message', `schema rejected message: ${summary}`)
        return
      }

      if (parsed.data.type === 'lui:render') {
        luiDebug('info', 'message', 'accepted render message', {
          page: parsed.data.page,
          children: parsed.data.tree.children.length,
        })
        renderPage(parsed.data.page, parsed.data.tree)
      } else if (parsed.data.type === 'lui:patch') {
        luiDebug('info', 'message', 'accepted patch message', {
          page: parsed.data.page,
          patches: parsed.data.patches.length,
        })
        patchPage(parsed.data.page, parsed.data.patches)
      } else {
        luiDebug('info', 'message', 'accepted visibility message', {
          page: parsed.data.page,
          visible: parsed.data.visible,
        })
        setVisible(parsed.data.page, parsed.data.visible)
      }
    }

    async function announceReady() {
      let attempt = 0

      while (!cancelled) {
        try {
          attempt += 1
          luiDebug('info', 'ready', 'sending lui:ready', { attempt })
          const result = await notifyLuiReady()
          luiDebug(result.ok ? 'info' : 'warn', 'ready', 'lui:ready result', { attempt, result })

          if (result.ok) {
            return
          }
        } catch (error) {
          // The Lua module may not be required yet. Keep trying until it registers the callback.
          luiDebug('warn', 'ready', 'lui:ready failed, retrying', { attempt, error: String(error) })
        }

        await wait(500)
      }
    }

    luiDebug('info', 'app', 'mounted React bridge')
    window.addEventListener('message', onMessage)
    void announceReady()

    if (import.meta.env.DEV && typeof window.GetParentResourceName !== 'function') {
      renderPage('dev', createDevMockTree())
      setVisible('dev', true)
    }

    return () => {
      cancelled = true
      luiDebug('info', 'app', 'unmounted React bridge')
      window.removeEventListener('message', onMessage)
    }
  }, [patchPage, renderPage, setVisible])

  useEffect(() => subscribeLuiDebug(() => setDebugEnabled(isLuiDebugEnabled())), [])

  const visiblePages = Object.entries(pages).filter(([, page]) => page.visible)

  if (visiblePages.length === 0 && !debugEnabled) {
    return null
  }

  return (
    <main className="min-h-screen bg-transparent text-lui-ink antialiased">
      <div className="fixed inset-0 pointer-events-none">
        {visiblePages.map(([pageId, page]) => (
          <section key={pageId} className="pointer-events-auto">
            <Renderer node={page.tree} />
          </section>
        ))}
      </div>
      <DebugPanel />
    </main>
  )
}

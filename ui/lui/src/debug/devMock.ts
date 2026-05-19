import type { LuiNode } from '../schemas/node'

let nodeId = 0

function node(type: string, props: Record<string, unknown> = {}, children: LuiNode[] = []): LuiNode {
  nodeId += 1
  return {
    children,
    id: `dev:${type}:${nodeId}`,
    props,
    type,
  }
}

export function createDevMockTree(): LuiNode {
  nodeId = 0

  return node('page', {
    font: 'Inter, ui-sans-serif, system-ui, sans-serif',
  }, [
    node('motion', {
      animate: { opacity: 1, y: 0 },
      as: 'div',
      className: 'fixed inset-0 overflow-auto p-6',
      initial: { opacity: 0, y: 10 },
      transition: { duration: 0.18, ease: 'easeOut' },
    }, [
      node('stack', { className: 'w-[980px]', gap: 'lg' }, [
        node('panel', { className: 'm-0 w-full max-w-[980px]', width: 'lg' }, [
          node('row', { className: 'justify-between' }, [
            node('stack', { gap: 'sm' }, [
              node('row', {}, [
                node('badge', { iconComponent: 'lucide:panels-top-left', label: 'LUI Showcase', variant: 'secondary' }),
                node('badge', { iconComponent: 'lucide:box', label: 'No Radix', variant: 'outline' }),
                node('badge', { icon: { name: 'lucide:sparkles', width: 12 }, label: 'warning', variant: 'default' }),
              ]),
              node('typography', { value: 'sure_lib Lua UI', variant: 'h1' }),
              node('typography', {
                value: 'A runtime test page that exercises every bundled LUI component from Lua.',
                variant: 'lead',
              }),
            ]),
            node('motion', {
              as: 'button',
              classBase: 'rounded-md bg-lui-accent px-4 py-2 text-sm font-semibold text-lui-accentForeground shadow-lui',
              endIconComponent: 'lucide:x',
              label: 'Close',
              whileTap: { scale: 0.96 },
            }),
          ]),
        ]),
        node('row', { align: 'start', className: 'items-start' }, [
          node('panel', { className: 'm-0 w-[480px] max-w-[480px]', width: 'lg' }, [
            node('stack', {}, [
              node('typography', { value: 'Controls', variant: 'h3' }),
              node('alert', {
                description: 'Change values here and the tracked state updates the preview, table and notifications.',
                iconComponent: 'lucide:info',
                title: 'Interactive State',
              }),
              node('input', { placeholder: 'Type a short message', prefixIconComponent: 'lucide:message-square-text', value: 'Lua-driven UI without writing HTML' }),
              node('textarea', {
                className: 'min-h-[96px]',
                placeholder: 'Long form text',
                value: 'Lua-driven UI without writing HTML',
              }),
              node('select', {
                closedIconComponent: 'lucide:chevron-down',
                openIconComponent: 'lucide:chevron-up',
                options: [
                  { label: 'Success', value: 'success' },
                  { label: 'Warning', value: 'warning' },
                  { label: 'Error', value: 'error' },
                ],
                value: 'warning',
              }),
              node('slider', { max: 12, min: 0, rangeIconComponent: 'lucide:minus', thumbIcon: { name: 'lucide:circle', width: 10 }, value: 4 }),
              node('row', {}, [
                node('button', { iconComponent: 'lucide:plus', label: 'Increment' }),
                node('button', { iconComponent: 'lucide:bell', label: 'Notify', variant: 'ghost' }),
                node('tooltip', { content: 'This tooltip is rendered by LUI without Radix.', trigger: 'Hover hint' }),
              ]),
            ]),
          ]),
          node('panel', { className: 'm-0 w-[480px] max-w-[480px]', width: 'lg' }, [
            node('stack', {}, [
              node('typography', { value: 'Content', variant: 'h3' }),
              node('tabs', {
                tabs: [
                  {
                    content: 'Tabs, table, carousel, accordion, typography, badges, alerts, controls, motion and tooltip all come from Lua nodes.',
                    label: 'Overview',
                    value: 'overview',
                  },
                  {
                    content: 'Runtime utility styles support fractions like w-1/2 and arbitrary values like w-[50px].',
                    label: 'Styling',
                    value: 'styling',
                  },
                ],
              }),
              node('carousel', {
                items: [
                  { description: 'Build UI by describing nodes in Lua.', title: 'Lua first' },
                  { description: 'AnimatePresence powers enter and exit transitions.', title: 'Motion ready' },
                  { description: 'Default colors follow a shadcn-like black and white palette.', title: 'Clean defaults' },
                ],
              }),
              node('accordion', {
                closedIconComponent: 'lucide:plus',
                openIconComponent: 'lucide:minus',
                items: [
                  {
                    content: 'Use sure.getModule("lui") and build pages with the ui builder.',
                    title: 'How is this page made?',
                    value: 'how',
                  },
                  {
                    content: 'The renderer is bundled in sure_lib and resources only send Lua node trees.',
                    title: 'Where is the HTML?',
                    value: 'html',
                  },
                ],
              }),
            ]),
          ]),
        ]),
        node('panel', { className: 'm-0 w-full max-w-[980px]', width: 'lg' }, [
          node('stack', {}, [
            node('row', { className: 'justify-between' }, [
              node('typography', { value: 'Live Data', variant: 'h3' }),
              node('badge', { iconComponent: 'lucide:activity', label: 'count: 4', variant: 'secondary' }),
            ]),
            node('table', {
              columns: [
                { key: 'component', label: 'Component' },
                { key: 'status', label: 'Status' },
                { key: 'note', label: 'Note' },
              ],
              rows: [
                { component: 'Controls', note: 'input, select, textarea, slider, button', status: 'interactive' },
                { component: 'Display', note: 'alert, badge, table, typography', status: 'ready' },
                { component: 'Motion', note: 'presence, motionDiv, motionButton', status: 'animated' },
              ],
            }),
          ]),
        ]),
        node('panel', { className: 'm-0 w-full max-w-[980px]', width: 'lg' }, [
          node('stack', {}, [
            node('typography', { value: 'Preview', variant: 'h3' }),
            node('motion', {
              animate: { opacity: 1, scale: 1 },
              as: 'div',
              className: 'rounded-lg border border-lui-line bg-lui-panel-soft p-5',
              initial: { opacity: 0, scale: 0.98 },
              transition: { duration: 0.2 },
            }, [
              node('stack', { gap: 'sm' }, [
                node('typography', { value: 'Lua-driven UI without writing HTML', variant: 'large' }),
                node('typography', { value: 'Tone: warning - Count: 4', variant: 'muted' }),
              ]),
            ]),
          ]),
        ]),
      ]),
    ]),
    node('motion', { as: 'div', classBase: 'fixed right-6 top-6 z-50 w-80 flex flex-col gap-3' }, [
      node('presence', { initial: false, mode: 'popLayout' }, [
        node('motion', {
          animate: { opacity: 1, scale: 1, x: 0 },
          as: 'div',
          className: 'rounded-lg border border-lui-line bg-lui-panel px-4 py-3 shadow-lui',
          initial: { opacity: 0, scale: 0.96, x: 36 },
        }, [
          node('stack', { gap: 'sm' }, [
            node('row', { className: 'justify-between' }, [
              node('badge', { iconComponent: 'lucide:bell', label: 'Notification', variant: 'secondary' }),
              node('motion', { as: 'button', classBase: 'rounded-md px-2 py-0.5 text-sm font-medium text-lui-muted', iconComponent: 'lucide:x', label: '' }),
            ]),
            node('text', { className: 'font-medium', value: 'Runtime notification 1' }),
          ]),
        ]),
      ]),
    ]),
  ])
}

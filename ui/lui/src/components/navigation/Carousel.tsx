import { useState } from 'react'
import type { LuiNode } from '../../schemas/node'
import { nodeClassName, nodePartClassName, nodePartStyle, nodeStyle } from '../shared/nodeProps'

type CarouselProps = {
  node: LuiNode
}

type CarouselItem = {
  description: string
  image?: string
  title: string
}

function normalizeItems(value: unknown): CarouselItem[] {
  if (!Array.isArray(value)) {
    return []
  }

  return value.map((item, index) => {
    if (typeof item === 'object' && item !== null) {
      const record = item as Record<string, unknown>
      return {
        description: String(record.description ?? record.content ?? ''),
        image: typeof record.image === 'string' ? record.image : undefined,
        title: String(record.title ?? record.label ?? `Slide ${index + 1}`),
      }
    }

    return {
      description: '',
      title: String(item),
    }
  })
}

export function Carousel({ node }: CarouselProps) {
  const items = normalizeItems(node.props.items)
  const [index, setIndex] = useState(0)
  const current = items[index]
  const previous = () => setIndex((value) => (value - 1 + items.length) % items.length)
  const next = () => setIndex((value) => (value + 1) % items.length)

  if (!current) {
    return null
  }

  return (
    <div className={nodeClassName(node.props, 'relative w-full overflow-hidden rounded-lg border border-lui-line bg-lui-panel')} style={nodeStyle(node.props)}>
      <div className={nodePartClassName(node.props, ['viewportClassName', 'contentClassName'], 'px-12 py-6')} style={nodePartStyle(node.props, ['viewportClassName', 'contentClassName'])}>
        {current.image && <img alt="" className="mb-4 h-40 w-full rounded-md object-cover" src={current.image} />}
        <div className={nodePartClassName(node.props, 'titleClassName', 'text-lg font-semibold text-lui-ink')} style={nodePartStyle(node.props, 'titleClassName')}>
          {current.title}
        </div>
        {current.description && (
          <div className={nodePartClassName(node.props, 'descriptionClassName', 'mt-1 text-sm text-lui-muted')} style={nodePartStyle(node.props, 'descriptionClassName')}>
            {current.description}
          </div>
        )}
      </div>
      {items.length > 1 && (
        <>
          <button className={nodePartClassName(node.props, ['controlClassName', 'previousClassName'], 'absolute left-2 top-1/2 size-8 -translate-y-1/2 rounded-full border border-lui-line bg-lui-panel text-lui-ink shadow-sm')} style={nodePartStyle(node.props, ['controlClassName', 'previousClassName'])} type="button" onClick={previous}>
            ‹
          </button>
          <button className={nodePartClassName(node.props, ['controlClassName', 'nextClassName'], 'absolute right-2 top-1/2 size-8 -translate-y-1/2 rounded-full border border-lui-line bg-lui-panel text-lui-ink shadow-sm')} style={nodePartStyle(node.props, ['controlClassName', 'nextClassName'])} type="button" onClick={next}>
            ›
          </button>
        </>
      )}
    </div>
  )
}

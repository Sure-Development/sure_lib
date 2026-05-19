import { Icon } from '@iconify/react'
import { useEffect, useState } from 'react'
import { luiDebug } from '../../debug/luiDebug'
import { nodePartClassName, nodePartStyle } from './nodeProps'

type IconSlotProps = {
  className?: string
  fallback?: string
  partClassName?: string | string[]
  props: Record<string, unknown>
  value: unknown
}

type IconSpec = {
  className?: string
  color?: string
  height?: number | string
  icon?: string
  iconComponent?: string
  name?: string
  rotate?: number
  text?: string
  value?: string
  width?: number | string
}

type IconData = {
  body: string
  height?: number
  hFlip?: boolean
  left?: number
  rotate?: number
  top?: number
  vFlip?: boolean
  width?: number
}

type IconAlias = Partial<IconData> & {
  parent: string
}

type IconCollection = {
  aliases?: Record<string, IconAlias>
  height?: number
  icons: Record<string, IconData>
  prefix: string
  width?: number
}

type LocalIconState = {
  data: IconData
  name: string
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value)
}

function textValue(value: unknown): string {
  return value === undefined || value === null ? '' : String(value)
}

function optionalTextValue(value: unknown): string | undefined {
  return value === undefined || value === null || value === '' ? undefined : String(value)
}

function numberValue(value: unknown): number | undefined {
  const numeric = Number(value)
  return Number.isFinite(numeric) ? numeric : undefined
}

function looksLikeIconifyName(value: string): boolean {
  return /^[a-z0-9-]+:[a-z0-9-]+$/i.test(value)
}

const loadedCollections = new Set<string>()
const loadingCollections = new Map<string, Promise<IconCollection>>()

function localCollectionPrefix(iconName: string): string | undefined {
  const [prefix] = iconName.split(':')
  return prefix === 'lucide' ? prefix : undefined
}

async function loadIconCollection(iconName: string): Promise<IconCollection | undefined> {
  const prefix = localCollectionPrefix(iconName)

  if (!prefix) {
    return undefined
  }

  let loadPromise = loadingCollections.get(prefix)
  if (!loadPromise) {
    loadPromise = import('@iconify-json/lucide/icons.json').then((collection) => {
      loadedCollections.add(prefix)
      return collection.default
    })
    loadingCollections.set(prefix, loadPromise)
  }

  return loadPromise
}

function iconDataFromCollection(iconName: string, collection: IconCollection): IconData | undefined {
  const [, iconKey] = iconName.split(':')
  const icon = collection.icons[iconKey]

  if (icon) {
    return {
      height: collection.height,
      width: collection.width,
      ...icon,
    }
  }

  const alias = collection.aliases?.[iconKey]
  const parent = alias ? collection.icons[alias.parent] : undefined
  if (alias && parent) {
    const { parent: _, ...aliasData } = alias

    return {
      height: collection.height,
      width: collection.width,
      ...parent,
      ...aliasData,
    }
  }

  return undefined
}

function normalizeIcon(value: unknown, fallback = ''): IconSpec {
  if (isRecord(value)) {
    const iconComponent = optionalTextValue(value.iconComponent ?? value.IconComponent ?? value.component)

    return {
      className: optionalTextValue(value.className),
      color: optionalTextValue(value.color),
      height: value.height as number | string | undefined,
      icon: optionalTextValue(value.icon),
      iconComponent,
      name: optionalTextValue(value.name) ?? iconComponent,
      rotate: numberValue(value.rotate),
      text: optionalTextValue(value.text),
      value: optionalTextValue(value.value),
      width: value.width as number | string | undefined,
    }
  }

  const iconValue = textValue(value || fallback)
  return looksLikeIconifyName(iconValue)
    ? {
        name: iconValue,
      }
    : {
        text: iconValue,
      }
}

export function IconSlot({ className = '', fallback = '', partClassName = 'iconClassName', props, value }: IconSlotProps) {
  const [localIcon, setLocalIcon] = useState<LocalIconState | null>(null)
  const icon = normalizeIcon(value, fallback)
  const iconName = icon.name || icon.icon || icon.iconComponent
  const iconText = icon.text || icon.value

  useEffect(() => {
    setLocalIcon(null)

    if (!iconName) {
      return
    }

    const collectionPrefix = localCollectionPrefix(iconName)
    if (!collectionPrefix) {
      return
    }

    let mounted = true
    void loadIconCollection(iconName)
      .then((collection) => {
        if (!mounted || !collection) {
          return
        }

        const data = iconDataFromCollection(iconName, collection)
        if (data) {
          setLocalIcon({
            data,
            name: iconName,
          })
        }
      })
      .catch((error: unknown) => {
        luiDebug('warn', 'icons', 'could not load local icon collection', {
          error,
          icon: iconName,
          prefix: collectionPrefix,
        })
      })

    return () => {
      mounted = false
    }
  }, [iconName])

  if (!iconName && !iconText) {
    return null
  }

  const mergedClassName = nodePartClassName(props, partClassName, className)
  const mergedStyle = nodePartStyle(props, partClassName)

  if (iconName) {
    const renderedIcon = localIcon?.name === iconName ? localIcon.data : iconName

    return (
      <Icon
        className={`${mergedClassName} ${icon.className ?? ''}`.trim()}
        color={icon.color || undefined}
        height={icon.height}
        icon={renderedIcon}
        rotate={icon.rotate}
        style={mergedStyle}
        width={icon.width}
      />
    )
  }

  return (
    <span className={`${mergedClassName} ${icon.className ?? ''}`.trim()} style={mergedStyle}>
      {iconText}
    </span>
  )
}

export function hasIcon(value: unknown): boolean {
  const icon = normalizeIcon(value)
  return Boolean(icon.name || icon.icon || icon.iconComponent || icon.text || icon.value)
}

export function iconProp(props: Record<string, unknown>, propNames: string | string[]): unknown {
  const names = Array.isArray(propNames) ? propNames : [propNames]

  for (const name of names) {
    if (props[name] !== undefined && props[name] !== null) {
      return props[name]
    }
  }

  return undefined
}

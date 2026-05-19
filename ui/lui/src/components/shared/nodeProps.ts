import type React from 'react'
import { runtimeUtilityStyle, type RuntimeStyle } from './runtimeUtilities'

type NodeStyle = RuntimeStyle

const themeVars: Record<string, `--${string}`> = {
  accent: '--lui-accent',
  accentSoft: '--lui-accent-soft',
  background: '--lui-background',
  font: '--lui-font',
  ink: '--lui-ink',
  line: '--lui-line',
  muted: '--lui-muted',
  panel: '--lui-panel',
  panelSoft: '--lui-panel-soft',
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value)
}

function readCssValue(value: unknown): string | number | undefined {
  if (typeof value === 'string' || typeof value === 'number') {
    return value
  }

  return undefined
}

function readCssText(value: unknown): string | undefined {
  return typeof value === 'string' ? value : undefined
}

function applyCssVar(style: NodeStyle, name: string, value: unknown) {
  const cssValue = readCssValue(value)
  if (cssValue === undefined) {
    return
  }

  const variableName = name.startsWith('--') ? name : `--${name}`
  style[variableName as `--${string}`] = cssValue
}

export function nodeClassName(props: Record<string, unknown>, baseClassName: string): string {
  const customClassName = props.className ?? props.class
  if (typeof customClassName !== 'string' || customClassName.length === 0) {
    return baseClassName
  }

  return `${baseClassName} ${customClassName}`
}

function readClassValue(props: Record<string, unknown>, propNames: string | string[]): string {
  const names = Array.isArray(propNames) ? propNames : [propNames]
  const classNames: string[] = []

  for (const propName of names) {
    const value = props[propName]
    if (typeof value === 'string' && value.length > 0) {
      classNames.push(value)
    }
  }

  return classNames.join(' ')
}

export function nodeTextProp(props: Record<string, unknown>, propNames: string | string[], fallback = ''): string {
  const names = Array.isArray(propNames) ? propNames : [propNames]

  for (const propName of names) {
    const value = props[propName]
    if (value !== undefined && value !== null) {
      return String(value)
    }
  }

  return fallback
}

export function nodePartClassName(props: Record<string, unknown>, propNames: string | string[], baseClassName: string): string {
  const className = readClassValue(props, propNames)
  return className.length > 0 ? `${baseClassName} ${className}` : baseClassName
}

export function nodePartStyle(props: Record<string, unknown>, propNames: string | string[]): RuntimeStyle | undefined {
  const className = readClassValue(props, propNames)
  if (className.length === 0) {
    return undefined
  }

  const style = runtimeUtilityStyle(className)
  return Object.keys(style).length === 0 ? undefined : style
}

export function nodeStyle(props: Record<string, unknown>): NodeStyle | undefined {
  const style: NodeStyle = runtimeUtilityStyle(props.classBase, props.className ?? props.class)

  if (isRecord(props.style)) {
    for (const [key, value] of Object.entries(props.style)) {
      const cssValue = readCssValue(value)
      if (cssValue !== undefined) {
        style[key as keyof React.CSSProperties] = cssValue as never
      }
    }
  }

  const font = readCssText(props.font ?? props.fontFamily)
  if (font !== undefined) {
    style.fontFamily = font
  }

  const color = readCssText(props.color)
  if (color !== undefined) {
    style.color = color
  }

  const background = readCssValue(props.background ?? props.backgroundColor)
  if (background !== undefined) {
    style.background = background
  }

  const borderColor = readCssText(props.borderColor)
  if (borderColor !== undefined) {
    style.borderColor = borderColor
  }

  const radius = readCssValue(props.radius ?? props.borderRadius)
  if (radius !== undefined) {
    style.borderRadius = radius
  }

  const opacity = readCssValue(props.opacity)
  if (opacity !== undefined) {
    style.opacity = opacity
  }

  if (isRecord(props.theme)) {
    for (const [key, value] of Object.entries(props.theme)) {
      const variableName = themeVars[key]
      if (variableName !== undefined) {
        applyCssVar(style, variableName, value)
      }
    }
  }

  if (isRecord(props.vars)) {
    for (const [key, value] of Object.entries(props.vars)) {
      applyCssVar(style, key, value)
    }
  }

  return Object.keys(style).length === 0 ? undefined : style
}

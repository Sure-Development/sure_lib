import type React from 'react'

export type RuntimeStyle = React.CSSProperties & Record<`--${string}`, string | number>

const spacingScale: Record<string, string> = {
  '0': '0px',
  '0.5': '0.125rem',
  '1': '0.25rem',
  '1.5': '0.375rem',
  '2': '0.5rem',
  '2.5': '0.625rem',
  '3': '0.75rem',
  '3.5': '0.875rem',
  '4': '1rem',
  '5': '1.25rem',
  '6': '1.5rem',
  '7': '1.75rem',
  '8': '2rem',
  '9': '2.25rem',
  '10': '2.5rem',
  '11': '2.75rem',
  '12': '3rem',
  '14': '3.5rem',
  '16': '4rem',
  '20': '5rem',
  '24': '6rem',
  '28': '7rem',
  '32': '8rem',
  '36': '9rem',
  '40': '10rem',
  '44': '11rem',
  '48': '12rem',
  '52': '13rem',
  '56': '14rem',
  '60': '15rem',
  '64': '16rem',
  '72': '18rem',
  '80': '20rem',
  '96': '24rem',
  auto: 'auto',
  full: '100%',
  screen: '100vh',
}

const namedColors: Record<string, string> = {
  black: '#000000',
  transparent: 'transparent',
  white: '#ffffff',
}

const luiColors: Record<string, string> = {
  'lui-accent': 'var(--lui-accent)',
  'lui-accent-foreground': 'var(--lui-accent-foreground)',
  'lui-accentForeground': 'var(--lui-accent-foreground)',
  'lui-accent-soft': 'var(--lui-accent-soft)',
  'lui-background': 'var(--lui-background)',
  'lui-ink': 'var(--lui-ink)',
  'lui-line': 'var(--lui-line)',
  'lui-muted': 'var(--lui-muted)',
  'lui-panel': 'var(--lui-panel)',
  'lui-panel-soft': 'var(--lui-panel-soft)',
  accent: 'var(--lui-accent)',
  background: 'var(--lui-background)',
  border: 'var(--lui-line)',
  card: 'var(--lui-panel)',
  destructive: '#ef4444',
  foreground: 'var(--lui-ink)',
  input: 'var(--lui-line)',
  muted: 'var(--lui-panel-soft)',
  'muted-foreground': 'var(--lui-muted)',
  popover: 'var(--lui-panel)',
  primary: 'var(--lui-accent)',
  'primary-foreground': 'var(--lui-accent-foreground)',
  secondary: 'var(--lui-panel-soft)',
  'secondary-foreground': 'var(--lui-ink)',
}

const radiusScale: Record<string, string> = {
  none: '0px',
  sm: '0.125rem',
  DEFAULT: '0.25rem',
  md: '0.375rem',
  lg: '0.5rem',
  xl: '0.75rem',
  '2xl': '1rem',
  '3xl': '1.5rem',
  full: '9999px',
}

const fontWeightScale: Record<string, number> = {
  thin: 100,
  extralight: 200,
  light: 300,
  normal: 400,
  medium: 500,
  semibold: 600,
  bold: 700,
  extrabold: 800,
  black: 900,
}

const fontSizeScale: Record<string, string> = {
  xs: '0.75rem',
  sm: '0.875rem',
  base: '1rem',
  lg: '1.125rem',
  xl: '1.25rem',
  '2xl': '1.5rem',
  '3xl': '1.875rem',
  '4xl': '2.25rem',
  '5xl': '3rem',
}

function readTokenValue(value: string): string | undefined {
  if (value.startsWith('[') && value.endsWith(']')) {
    return value.slice(1, -1).replaceAll('_', ' ')
  }

  const fraction = value.match(/^(\d+)\/(\d+)$/)
  if (fraction) {
    const numerator = Number(fraction[1])
    const denominator = Number(fraction[2])
    if (denominator > 0) {
      return `${(numerator / denominator) * 100}%`
    }
  }

  return spacingScale[value]
}

function readColor(value: string): string | undefined {
  const [colorName, opacity] = value.split('/')
  const color = colorName.startsWith('[') && colorName.endsWith(']')
    ? colorName.slice(1, -1).replaceAll('_', ' ')
    : luiColors[colorName] ?? namedColors[colorName]

  if (color !== undefined && opacity !== undefined) {
    const alpha = Number(opacity)
    if (Number.isFinite(alpha) && color.startsWith('#') && color.length === 7) {
      const red = Number.parseInt(color.slice(1, 3), 16)
      const green = Number.parseInt(color.slice(3, 5), 16)
      const blue = Number.parseInt(color.slice(5, 7), 16)
      return `rgb(${red} ${green} ${blue} / ${alpha / 100})`
    }
  }

  if (color !== undefined) {
    return color
  }

  if (value.startsWith('[') && value.endsWith(']')) {
    return value.slice(1, -1).replaceAll('_', ' ')
  }

  return undefined
}

function assignSpacing(style: RuntimeStyle, property: string, value: string) {
  switch (property) {
    case 'm':
      style.margin = value
      break
    case 'mx':
      style.marginLeft = value
      style.marginRight = value
      break
    case 'my':
      style.marginBottom = value
      style.marginTop = value
      break
    case 'mt':
      style.marginTop = value
      break
    case 'mr':
      style.marginRight = value
      break
    case 'mb':
      style.marginBottom = value
      break
    case 'ml':
      style.marginLeft = value
      break
    case 'p':
      style.padding = value
      break
    case 'px':
      style.paddingLeft = value
      style.paddingRight = value
      break
    case 'py':
      style.paddingBottom = value
      style.paddingTop = value
      break
    case 'pt':
      style.paddingTop = value
      break
    case 'pr':
      style.paddingRight = value
      break
    case 'pb':
      style.paddingBottom = value
      break
    case 'pl':
      style.paddingLeft = value
      break
  }
}

function applyUtility(style: RuntimeStyle, className: string) {
  if (className === 'absolute' || className === 'fixed' || className === 'relative' || className === 'sticky') {
    style.position = className
    return
  }

  if (className === 'block' || className === 'flex' || className === 'grid' || className === 'inline-flex') {
    style.display = className
    return
  }

  if (className === 'flex-col') {
    style.flexDirection = 'column'
    return
  }

  if (className === 'flex-row') {
    style.flexDirection = 'row'
    return
  }

  if (className === 'flex-wrap') {
    style.flexWrap = 'wrap'
    return
  }

  if (className.startsWith('items-')) {
    style.alignItems = className.slice(6)
    return
  }

  if (className.startsWith('justify-')) {
    style.justifyContent = className.slice(8).replace('between', 'space-between').replace('around', 'space-around')
    return
  }

  if (className.startsWith('z-')) {
    const value = Number(className.slice(2))
    if (Number.isFinite(value)) {
      style.zIndex = value
    }
    return
  }

  const spacing = className.match(/^(m|mx|my|mt|mr|mb|ml|p|px|py|pt|pr|pb|pl)-(.+)$/)
  if (spacing) {
    const value = readTokenValue(spacing[2])
    if (value !== undefined) {
      assignSpacing(style, spacing[1], value)
    }
    return
  }

  const positioned = className.match(/^(top|right|bottom|left|inset)-(.+)$/)
  if (positioned) {
    const value = readTokenValue(positioned[2])
    if (value !== undefined) {
      if (positioned[1] === 'inset') {
        style.inset = value
      } else {
        style[positioned[1] as 'top' | 'right' | 'bottom' | 'left'] = value
      }
    }
    return
  }

  const sized = className.match(/^(size|w|h|min-w|min-h|max-w|max-h)-(.+)$/)
  if (sized) {
    const value = readTokenValue(sized[2])
    if (value === undefined) {
      return
    }

    const property = sized[1]
    if (property === 'size') {
      style.height = value
      style.width = value
    }
    if (property === 'w') style.width = value
    if (property === 'h') style.height = value
    if (property === 'min-w') style.minWidth = value
    if (property === 'min-h') style.minHeight = value
    if (property === 'max-w') style.maxWidth = value
    if (property === 'max-h') style.maxHeight = value
    return
  }

  if (className.startsWith('gap-')) {
    const value = readTokenValue(className.slice(4))
    if (value !== undefined) {
      style.gap = value
    }
    return
  }

  if (className === 'overflow-hidden' || className === 'overflow-auto' || className === 'overflow-scroll') {
    style.overflow = className.slice(9)
    return
  }

  if (className === 'whitespace-nowrap') {
    style.whiteSpace = 'nowrap'
    return
  }

  if (className === 'truncate') {
    style.overflow = 'hidden'
    style.textOverflow = 'ellipsis'
    style.whiteSpace = 'nowrap'
    return
  }

  if (className === 'border') {
    style.borderStyle = 'solid'
    style.borderWidth = '1px'
    return
  }

  const borderWidth = className.match(/^border-(\d+)$/)
  if (borderWidth) {
    style.borderStyle = 'solid'
    style.borderWidth = `${borderWidth[1]}px`
    return
  }

  if (className.startsWith('rounded')) {
    const radius = className === 'rounded' ? radiusScale.DEFAULT : radiusScale[className.slice(8)]
    if (radius !== undefined) {
      style.borderRadius = radius
    }
    return
  }

  const color = className.match(/^(bg|text|border)-(.+)$/)
  if (color) {
    const value = readColor(color[2])
    if (value !== undefined) {
      if (color[1] === 'bg') style.background = value
      if (color[1] === 'text') style.color = value
      if (color[1] === 'border') style.borderColor = value
      return
    }
  }

  if (className.startsWith('font-')) {
    if (className === 'font-mono') {
      style.fontFamily = 'ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace'
      return
    }

    if (className === 'font-sans') {
      style.fontFamily = 'var(--lui-font), ui-sans-serif, system-ui, sans-serif'
      return
    }

    const weight = fontWeightScale[className.slice(5)]
    if (weight !== undefined) {
      style.fontWeight = weight
    }
    return
  }

  if (className === 'italic') {
    style.fontStyle = 'italic'
    return
  }

  if (className === 'not-italic') {
    style.fontStyle = 'normal'
    return
  }

  if (className === 'text-left' || className === 'text-center' || className === 'text-right') {
    style.textAlign = className.slice(5) as 'left' | 'center' | 'right'
    return
  }

  if (className.startsWith('text-')) {
    const size = fontSizeScale[className.slice(5)] ?? readTokenValue(className.slice(5))
    if (size !== undefined) {
      style.fontSize = size
    }
    return
  }

  if (className.startsWith('leading-')) {
    const value = readTokenValue(className.slice(8))
    if (value !== undefined) {
      style.lineHeight = value
    }
    return
  }

  if (className === 'shadow-lui') {
    style.boxShadow = '0 24px 80px rgba(0, 0, 0, 0.36)'
    return
  }

  if (className === 'shadow-lg') {
    style.boxShadow = '0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1)'
  }
}

export function runtimeUtilityStyle(...classNames: Array<unknown>): RuntimeStyle {
  const style: RuntimeStyle = {} as RuntimeStyle

  for (const value of classNames) {
    if (typeof value !== 'string') {
      continue
    }

    for (const className of value.split(/\s+/)) {
      if (className.length > 0 && !className.includes(':')) {
        applyUtility(style, className)
      }
    }
  }

  return style
}

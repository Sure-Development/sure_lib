import { Fragment, cloneElement, isValidElement, type ReactNode } from 'react'
import { Button } from '../components/controls/Button'
import { Input } from '../components/controls/Input'
import { Select } from '../components/controls/Select'
import { Slider } from '../components/controls/Slider'
import { Textarea } from '../components/controls/Textarea'
import { Accordion } from '../components/display/Accordion'
import { Alert } from '../components/display/Alert'
import { Badge } from '../components/display/Badge'
import { Table } from '../components/display/Table'
import { Typography } from '../components/display/Typography'
import { Panel } from '../components/layout/Panel'
import { Row } from '../components/layout/Row'
import { Stack } from '../components/layout/Stack'
import { MotionNode } from '../components/motion/MotionNode'
import { Presence } from '../components/motion/Presence'
import { Carousel } from '../components/navigation/Carousel'
import { Tabs } from '../components/navigation/Tabs'
import { Tooltip } from '../components/overlay/Tooltip'
import { Text } from '../components/primitives/Text'
import { nodeClassName, nodeStyle } from '../components/shared/nodeProps'
import type { LuiNode } from '../schemas/node'

function nodeKey(node: LuiNode): string {
  const key = node.props.key ?? node.props.id
  if (typeof key === 'string' || typeof key === 'number') {
    return String(key)
  }

  return node.id
}

function keyedElement(node: LuiNode, key: string): ReactNode {
  const element = renderElement(node)
  if (isValidElement(element)) {
    return cloneElement(element, { key })
  }

  return <Fragment key={key}>{element}</Fragment>
}

function childrenOf(node: LuiNode) {
  return node.children.map((child) => keyedElement(child, nodeKey(child)))
}

function presenceChildrenOf(node: LuiNode) {
  return node.children.flatMap((child) => {
    if (child.type !== 'foreach') {
      return keyedElement(child, nodeKey(child))
    }

    return child.children.flatMap((item) => {
      if (item.children.length === 1) {
        return keyedElement(item.children[0], nodeKey(item))
      }

      return (
        <Fragment key={nodeKey(item)}>
          {item.children.map((itemChild) => keyedElement(itemChild, nodeKey(itemChild)))}
        </Fragment>
      )
    })
  })
}

export function renderElement(node: LuiNode): ReactNode {
  switch (node.type) {
    case 'page':
      return (
        <div className={nodeClassName(node.props, 'lui-page')} style={nodeStyle(node.props)}>
          {childrenOf(node)}
        </div>
      )
    case 'presence':
      return <Presence node={node}>{presenceChildrenOf(node)}</Presence>
    case 'motion':
      return <MotionNode node={node}>{childrenOf(node)}</MotionNode>
    case 'stack':
      return <Stack node={node}>{childrenOf(node)}</Stack>
    case 'row':
      return <Row node={node}>{childrenOf(node)}</Row>
    case 'panel':
      return <Panel node={node}>{childrenOf(node)}</Panel>
    case 'text':
      return <Text node={node} />
    case 'button':
      return <Button node={node} />
    case 'input':
      return <Input node={node} />
    case 'select':
      return <Select node={node} />
    case 'textarea':
      return <Textarea node={node} />
    case 'slider':
      return <Slider node={node} />
    case 'alert':
      return <Alert node={node}>{childrenOf(node)}</Alert>
    case 'badge':
      return <Badge node={node} />
    case 'accordion':
      return <Accordion node={node} />
    case 'table':
      return <Table node={node} />
    case 'tabs':
      return <Tabs node={node} />
    case 'tooltip':
      return <Tooltip node={node}>{childrenOf(node)}</Tooltip>
    case 'carousel':
      return <Carousel node={node} />
    case 'typography':
      return <Typography node={node}>{childrenOf(node)}</Typography>
    case 'foreach':
    case 'item':
      return (
        <div className={nodeClassName(node.props, '')} style={nodeStyle(node.props)}>
          {childrenOf(node)}
        </div>
      )
    default:
      return null
  }
}

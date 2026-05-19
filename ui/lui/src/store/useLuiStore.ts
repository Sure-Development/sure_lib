import { create } from 'zustand'
import type { LuiNode } from '../schemas/node'
import { luiDebug } from '../debug/luiDebug'
import type { LuiPatch } from '../schemas/events'

type PageState = {
  tree: LuiNode
  visible: boolean
}

type LuiState = {
  pages: Record<string, PageState>
  renderPage: (page: string, tree: LuiNode) => void
  patchPage: (page: string, patches: LuiPatch[]) => void
  setVisible: (page: string, visible: boolean) => void
}

function replaceNode(node: LuiNode, id: string, replacement: LuiNode): LuiNode {
  if (node.id === id) {
    return replacement
  }

  let changed = false
  const children = node.children.map((child) => {
    const nextChild = replaceNode(child, id, replacement)
    if (nextChild !== child) {
      changed = true
    }

    return nextChild
  })

  return changed ? { ...node, children } : node
}

function updateNodeProps(node: LuiNode, id: string, props: Record<string, unknown>): LuiNode {
  if (node.id === id) {
    return {
      ...node,
      props,
    }
  }

  let changed = false
  const children = node.children.map((child) => {
    const nextChild = updateNodeProps(child, id, props)
    if (nextChild !== child) {
      changed = true
    }

    return nextChild
  })

  return changed ? { ...node, children } : node
}

function applyPatch(tree: LuiNode, patch: LuiPatch) {
  if (patch.op === 'replaceNode') {
    return replaceNode(tree, patch.id, patch.node)
  }

  return updateNodeProps(tree, patch.id, patch.props)
}

export const useLuiStore = create<LuiState>((set) => ({
  pages: {},
  renderPage: (page, tree) =>
    set((state) => {
      const visible = state.pages[page]?.visible ?? false
      luiDebug('info', 'store', 'render page', {
        page,
        visible,
        children: tree.children.length,
      })

      return {
        pages: {
          ...state.pages,
          [page]: {
            tree,
            visible,
          },
        },
      }
    }),
  patchPage: (page, patches) =>
    set((state) => {
      const current = state.pages[page]
      if (!current) {
        luiDebug('warn', 'store', 'ignored patches before render', { page, patches: patches.length })
        return state
      }

      let tree = current.tree
      for (const patch of patches) {
        tree = applyPatch(tree, patch)
      }

      luiDebug('info', 'store', 'patch page', {
        page,
        patches: patches.length,
      })

      return {
        pages: {
          ...state.pages,
          [page]: {
            ...current,
            tree,
          },
        },
      }
    }),
  setVisible: (page, visible) =>
    set((state) => {
      const current = state.pages[page]
      if (!current) {
        luiDebug('warn', 'store', 'ignored visibility before render', { page, visible })
        return state
      }

      luiDebug('info', 'store', 'set visibility', { page, visible })
      return {
        pages: {
          ...state.pages,
          [page]: {
            ...current,
            visible,
          },
        },
      }
    }),
}))

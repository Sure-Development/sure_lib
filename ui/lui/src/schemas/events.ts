import { z } from 'zod'
import { nodeSchema } from './node'

export const renderMessageSchema = z.object({
  type: z.literal('lui:render'),
  page: z.string(),
  tree: nodeSchema,
})

export const visibilityMessageSchema = z.object({
  type: z.literal('lui:visibility'),
  page: z.string(),
  visible: z.boolean(),
})

export const patchSchema = z.discriminatedUnion('op', [
  z.object({
    op: z.literal('updateProps'),
    id: z.string(),
    props: z.preprocess((value) => {
      if (value == null || Array.isArray(value)) {
        return {}
      }

      return value
    }, z.record(z.string(), z.unknown())),
  }),
  z.object({
    op: z.literal('replaceNode'),
    id: z.string(),
    node: nodeSchema,
  }),
])

export const patchMessageSchema = z.object({
  type: z.literal('lui:patch'),
  page: z.string(),
  patches: z.array(patchSchema),
})

export const nuiMessageSchema = z.discriminatedUnion('type', [
  renderMessageSchema,
  visibilityMessageSchema,
  patchMessageSchema,
])

export type NuiMessage = z.infer<typeof nuiMessageSchema>
export type LuiPatch = z.infer<typeof patchSchema>

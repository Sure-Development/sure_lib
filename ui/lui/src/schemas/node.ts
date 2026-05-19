import { z } from 'zod'

const propsSchema = z.preprocess((value) => {
  if (value == null || Array.isArray(value)) {
    return {}
  }

  return value
}, z.record(z.string(), z.unknown()))

export const nodeSchema: z.ZodType<LuiNode> = z.lazy(() =>
  z.object({
    id: z.string(),
    type: z.string(),
    props: propsSchema.default({}),
    children: z.preprocess((value) => (Array.isArray(value) ? value : []), z.array(nodeSchema)),
  }),
)

export type LuiNode = {
  id: string
  type: string
  props: Record<string, unknown>
  children: LuiNode[]
}

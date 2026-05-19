export type NuiEventPayload = {
  actionId: string
  payload?: unknown
}

export type NuiEventResult = {
  ok: boolean
  error?: string
}

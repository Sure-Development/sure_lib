local state = {
  handlers = {},
  pages = {},
}

function state.nextId(page, prefix)
  page.nodeCursor = (page.nodeCursor or 0) + 1
  return page.id .. ':' .. prefix .. ':' .. page.nodeCursor
end

function state.nextAction(page)
  page.actionCursor = (page.actionCursor or 0) + 1
  return page.id .. ':action:' .. page.actionCursor
end

function state.registerHandler(page, callback)
  if type(callback) ~= 'function' then
    return nil
  end

  local actionId = state.nextAction(page)
  state.handlers[actionId] = callback
  page.handlers[#page.handlers + 1] = actionId
  return actionId
end

return state

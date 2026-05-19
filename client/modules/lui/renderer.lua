local function create(lui, state, utils, blueprint, builderModule, track)
  local renderer = {}

  local function sendPage(page)
    SendNUIMessage({
      type = 'lui:render',
      page = page.id,
      tree = page.tree,
    })
  end

  local function sendPatches(page, patches)
    if #patches == 0 then
      return
    end

    SendNUIMessage({
      type = 'lui:patch',
      page = page.id,
      patches = patches,
    })
  end

  function renderer.sendVisibility(page)
    SendNUIMessage({
      type = 'lui:visibility',
      page = page.id,
      visible = page.visible == true,
    })
  end

  local function diffNode(previousNode, nextNode, patches)
    if previousNode == nil then
      return
    end

    if previousNode.id ~= nextNode.id or previousNode.type ~= nextNode.type then
      patches[#patches + 1] = {
        op = 'replaceNode',
        id = previousNode.id,
        node = nextNode,
      }
      return
    end

    if not utils.sameValue(previousNode.props, nextNode.props) then
      patches[#patches + 1] = {
        op = 'updateProps',
        id = nextNode.id,
        props = nextNode.props,
      }
    end

    local previousChildren = previousNode.children or {}
    local nextChildren = nextNode.children or {}
    if #previousChildren ~= #nextChildren then
      patches[#patches + 1] = {
        op = 'replaceNode',
        id = previousNode.id,
        node = nextNode,
      }
      return
    end

    for index = 1, #nextChildren do
      diffNode(previousChildren[index], nextChildren[index], patches)
    end
  end

  local function buildPageTree(page, deps)
    page.handlers = {}
    page.actionCursor = 0
    page.nodeCursor = 0

    local tree = {
      id = page.id,
      type = 'page',
      props = page.props,
      children = {},
    }

    if type(page.builder) == 'function' then
      blueprint.addDeclarativeNode(tree, page, deps, page.builder(builderModule.createBuilder(page, tree, deps)))
    else
      blueprint.addDeclarativeNode(tree, page, deps, page.builder)
    end

    return tree
  end

  local function watchDeps(page, deps)
    for _, dep in ipairs(deps) do
      local stateName = dep.stateName
      if not page.watched[stateName] then
        page.watched[stateName] = true
        track.effect(function()
          renderer.renderPage(page)
        end, { dep })
      end
    end
  end

  function renderer.renderPage(page, options)
    options = options or {}
    local deps = {}
    local previousHandlers = page.handlers or {}

    for _, actionId in ipairs(previousHandlers) do
      state.handlers[actionId] = nil
    end

    local previousTree = page.tree
    local nextTree = buildPageTree(page, deps)
    page.tree = nextTree

    if options.force == true or previousTree == nil then
      sendPage(page)
    else
      local patches = {}
      diffNode(previousTree, nextTree, patches)
      sendPatches(page, patches)
    end

    watchDeps(page, deps)
  end

  function renderer.page(pageId, pageBuilder, props)
    local page = {
      id = pageId,
      builder = pageBuilder,
      props = props or {},
      watched = {},
      visible = false,
    }

    state.pages[pageId] = page
    renderer.renderPage(page, { force = true })
    return page
  end

  function renderer.render(pageId)
    local page = state.pages[pageId]
    if page then
      renderer.renderPage(page)
    end
  end

  function renderer.open(pageId, focusOptions)
    focusOptions = focusOptions or {}
    local page = state.pages[pageId]
    if page then
      page.visible = true
      renderer.renderPage(page)
    end

    SetNuiFocus(focusOptions.focus ~= false, focusOptions.cursor ~= false)
    renderer.sendVisibility(page or { id = pageId, visible = true })
  end

  function renderer.close(pageId)
    local page = state.pages[pageId]
    if page then
      page.visible = false
    end

    SetNuiFocus(false, false)
    renderer.sendVisibility(page or { id = pageId, visible = false })
  end

  function renderer.handleReady(_, cb)
    for _, page in pairs(state.pages) do
      renderer.renderPage(page, { force = true })
      if page.visible == true then
        renderer.sendVisibility(page)
      end
    end

    cb({
      ok = true,
    })
  end

  function renderer.handleEvent(data, cb)
    local handler = data and state.handlers[data.actionId]
    if handler then
      local ok, err = pcall(handler, data.payload or {})
      if not ok then
        lib.print.error('[sure_lib][lui] event error: ' .. tostring(err))
        cb({
          ok = false,
          error = tostring(err),
        })
        return
      end
    end

    cb({
      ok = true,
    })
  end

  function renderer.attach()
    lui.page = renderer.page
    lui.render = renderer.render
    lui.open = renderer.open
    lui.close = renderer.close
  end

  return renderer
end

return {
  create = create,
}

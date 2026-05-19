local lui = {}
local track = sure.getModule('track')
local pages = {}
local handlers = {}
local type = type

local function nextId(page, prefix)
  page.nodeCursor = (page.nodeCursor or 0) + 1
  return page.id .. ':' .. prefix .. ':' .. page.nodeCursor
end

local function nextAction(page)
  page.actionCursor = (page.actionCursor or 0) + 1
  return page.id .. ':action:' .. page.actionCursor
end

local function isReactive(value)
  return type(value) == 'table' and value.isReactive == true and type(value.stateName) == 'string'
end

local function readValue(value, deps)
  if isReactive(value) then
    deps[#deps + 1] = value
    return value()
  end

  return value
end

local function normalizeProps(props)
  if type(props) == 'table' then
    return props
  end

  return {}
end

local function isNodeBlueprint(value)
  return type(value) == 'table' and value.__luiNode == true
end

local function shallowCopy(values)
  local copied = {}
  for key, value in pairs(values or {}) do
    copied[key] = value
  end

  return copied
end

local function isDeclarativeChildren(value)
  if isNodeBlueprint(value) then
    return true
  end

  if type(value) ~= 'table' then
    return false
  end

  for _, child in ipairs(value) do
    if isNodeBlueprint(child) or isDeclarativeChildren(child) then
      return true
    end
  end

  return false
end

local function readItemKey(item, index, props)
  local keyBy = props.keyBy or props.key
  if type(keyBy) == 'function' then
    local ok, value = pcall(keyBy, item, index)
    if ok and value ~= nil then
      return value
    end
  end

  if type(keyBy) == 'string' and type(item) == 'table' and item[keyBy] ~= nil then
    return item[keyBy]
  end

  if type(item) == 'table' then
    return item.id or item.key or item.name or index
  end

  return index
end

local function sameValue(left, right)
  if left == right then
    return true
  end

  if type(left) ~= 'table' or type(right) ~= 'table' then
    return false
  end

  for key, value in pairs(left) do
    if not sameValue(value, right[key]) then
      return false
    end
  end

  for key in pairs(right) do
    if left[key] == nil then
      return false
    end
  end

  return true
end

local function addNode(parent, node)
  parent.children[#parent.children + 1] = node
  return node
end

local function registerHandler(page, callback)
  if type(callback) ~= 'function' then
    return nil
  end

  local actionId = nextAction(page)
  handlers[actionId] = callback
  page.handlers[#page.handlers + 1] = actionId
  return actionId
end

local instantiateBlueprint

local function addDeclarativeNode(parent, page, deps, node)
  if isNodeBlueprint(node) then
    return addNode(parent, instantiateBlueprint(page, deps, node))
  end

  if type(node) == 'table' then
    for _, child in ipairs(node) do
      addDeclarativeNode(parent, page, deps, child)
    end
  end

  return node
end

local function createBlueprint(nodeType, props, children)
  return {
    __luiNode = true,
    type = nodeType,
    props = normalizeProps(props),
    children = children,
  }
end

local function createLeafBlueprint(nodeType, props)
  return createBlueprint(nodeType, props, nil)
end

local function normalizeContainerArgs(props, children)
  if type(props) == 'function' or isDeclarativeChildren(props) then
    children = props
    props = {}
  end

  return normalizeProps(props), children
end

local function createBuilder(page, parent, deps)
  local builder = {
    h = lui,
    node = lui,
    parent = parent,
  }

  local function addCurrentNode(node)
    return addNode(builder.parent, node)
  end

  local function withParent(node, callback)
    if isDeclarativeChildren(callback) then
      addDeclarativeNode(node, page, deps, callback)
      return node
    end

    if type(callback) ~= 'function' then
      return node
    end

    local previousParent = builder.parent
    builder.parent = node
    callback(builder)
    builder.parent = previousParent
    return node
  end

  local function addContainer(prefix, nodeType, props, callback)
    if type(props) == 'function' or isDeclarativeChildren(props) then
      callback = props
      props = {}
    end

    local node = addCurrentNode({
      id = nextId(page, prefix),
      type = nodeType,
      props = normalizeProps(props),
      children = {},
    })

    return withParent(node, callback)
  end

  local function addLeaf(prefix, nodeType, props)
    return addCurrentNode({
      id = nextId(page, prefix),
      type = nodeType,
      props = normalizeProps(props),
    })
  end

  local function addMotion(elementName, props, callback)
    if type(props) == 'function' then
      callback = props
      props = {}
    end

    props = normalizeProps(props)
    props.as = props.as or elementName

    local node = addCurrentNode({
      id = nextId(page, 'motion'),
      type = 'motion',
      props = props,
      children = {},
    })

    return withParent(node, callback)
  end

  local function renderCondition(condition, onTruthy, onFalsy)
    local value = readValue(condition, deps)
    local callback = value and onTruthy or onFalsy

    if type(callback) == 'function' then
      callback(builder, value)
    end

    return value
  end

  function builder.when(condition, onTruthy, onFalsy)
    return renderCondition(condition, onTruthy, onFalsy)
  end

  function builder.ifElse(condition, onTruthy, onFalsy)
    return renderCondition(condition, onTruthy, onFalsy)
  end

  function builder.unless(condition, onFalsy, onTruthy)
    local value = readValue(condition, deps)
    local callback = value and onTruthy or onFalsy

    if type(callback) == 'function' then
      callback(builder, value)
    end

    return not value
  end

  builder['if'] = builder.when

  function builder.text(value, props)
    props = normalizeProps(props)
    props.value = readValue(value, deps)

    return addCurrentNode({
      id = nextId(page, 'text'),
      type = 'text',
      props = props,
    })
  end

  function builder.button(label, onPress, props)
    props = normalizeProps(props)
    props.label = readValue(label, deps)
    props.actionId = registerHandler(page, onPress)

    return addCurrentNode({
      id = nextId(page, 'button'),
      type = 'button',
      props = props,
    })
  end

  function builder.motionButton(label, onPress, props)
    props = normalizeProps(props)
    props.as = 'button'
    props.label = readValue(label, deps)
    props.actionId = registerHandler(page, onPress)

    return addCurrentNode({
      id = nextId(page, 'motion'),
      type = 'motion',
      props = props,
      children = {},
    })
  end

  function builder.motionText(value, props)
    props = normalizeProps(props)
    props.as = props.as or 'p'
    props.label = readValue(value, deps)

    return addCurrentNode({
      id = nextId(page, 'motion'),
      type = 'motion',
      props = props,
      children = {},
    })
  end

  function builder.input(props)
    props = normalizeProps(props)
    props.value = readValue(props.value, deps)
    props.actionId = registerHandler(page, props.onChange)
    props.onChange = nil

    return addCurrentNode({
      id = nextId(page, 'input'),
      type = 'input',
      props = props,
    })
  end

  function builder.select(props)
    props = normalizeProps(props)
    props.value = readValue(props.value, deps)
    props.options = readValue(props.options, deps) or {}
    props.actionId = registerHandler(page, props.onChange)
    props.onChange = nil

    return addCurrentNode({
      id = nextId(page, 'select'),
      type = 'select',
      props = props,
    })
  end

  function builder.textarea(props)
    props = normalizeProps(props)
    props.value = readValue(props.value, deps)
    props.actionId = registerHandler(page, props.onChange)
    props.onChange = nil

    return addLeaf('textarea', 'textarea', props)
  end

  function builder.slider(props)
    props = normalizeProps(props)
    props.value = readValue(props.value, deps)
    props.actionId = registerHandler(page, props.onChange)
    props.onChange = nil

    return addLeaf('slider', 'slider', props)
  end

  function builder.stack(props, callback)
    return addContainer('stack', 'stack', props, callback)
  end

  function builder.row(props, callback)
    return addContainer('row', 'row', props, callback)
  end

  function builder.panel(props, callback)
    return addContainer('panel', 'panel', props, callback)
  end

  function builder.alert(props, callback)
    return addContainer('alert', 'alert', props, callback)
  end

  function builder.tooltip(props, callback)
    return addContainer('tooltip', 'tooltip', props, callback)
  end

  function builder.badge(label, props)
    props = normalizeProps(props)
    props.label = readValue(label, deps)

    return addLeaf('badge', 'badge', props)
  end

  function builder.typography(value, props, callback)
    if (type(value) == 'table' and not isReactive(value)) or (type(value) == 'function' and props == nil) then
      callback = props
      props = value
      value = nil
    end

    props = normalizeProps(props)
    if value ~= nil then
      props.value = readValue(value, deps)
    end

    if type(callback) == 'function' then
      return addContainer('typography', 'typography', props, callback)
    end

    return addLeaf('typography', 'typography', props)
  end

  function builder.accordion(items, props)
    props = normalizeProps(props)
    props.items = readValue(items, deps) or props.items or {}

    return addLeaf('accordion', 'accordion', props)
  end

  function builder.tabs(items, props)
    props = normalizeProps(props)
    props.tabs = readValue(items, deps) or props.tabs or {}

    return addLeaf('tabs', 'tabs', props)
  end

  function builder.table(columns, rows, props)
    props = normalizeProps(props)
    props.columns = readValue(columns, deps) or props.columns or {}
    props.rows = readValue(rows, deps) or props.rows or {}

    return addLeaf('table', 'table', props)
  end

  function builder.carousel(items, props)
    props = normalizeProps(props)
    props.items = readValue(items, deps) or props.items or {}

    return addLeaf('carousel', 'carousel', props)
  end

  function builder.presence(props, callback)
    return addContainer('presence', 'presence', props, callback)
  end

  builder.animatePresence = builder.presence

  function builder.motion(props, callback)
    return addMotion('div', props, callback)
  end

  function builder.motionDiv(props, callback)
    return addMotion('div', props, callback)
  end

  function builder.motionRow(props, callback)
    if type(props) == 'function' then
      callback = props
      props = {}
    end

    props = normalizeProps(props)
    props.as = props.as or 'div'
    props.classBase = props.classBase or 'flex flex-wrap gap-3 items-center'
    return addMotion('div', props, callback)
  end

  function builder.motionStack(props, callback)
    if type(props) == 'function' then
      callback = props
      props = {}
    end

    props = normalizeProps(props)
    props.as = props.as or 'div'
    props.classBase = props.classBase or 'flex flex-col gap-3'
    return addMotion('div', props, callback)
  end

  function builder.motionList(props, callback)
    return addMotion('ul', props, callback)
  end

  function builder.motionListItem(props, callback)
    return addMotion('li', props, callback)
  end

  builder.motionItem = builder.motionListItem

  function builder.motionSection(props, callback)
    return addMotion('section', props, callback)
  end

  function builder.foreach(source, callback, props)
    props = normalizeProps(props)
    local values = readValue(source, deps) or {}
    local node = addCurrentNode({
      id = nextId(page, 'foreach'),
      type = 'foreach',
      props = props,
      children = {},
    })

    for index, item in ipairs(values) do
      local itemNode = addNode(node, {
        id = nextId(page, 'item'),
        type = 'item',
        props = {
          index = index,
          key = tostring(readItemKey(item, index, props)),
        },
        children = {},
      })

      local previousParent = builder.parent
      builder.parent = itemNode
      callback(item, index, builder)
      builder.parent = previousParent
    end

    return node
  end

  return builder
end

function instantiateBlueprint(page, deps, blueprint)
  local props = shallowCopy(blueprint.props)
  local nodeType = blueprint.type
  local node = {
    id = nextId(page, nodeType == 'list' and 'foreach' or nodeType),
    type = nodeType == 'list' and 'foreach' or nodeType,
    props = props,
  }

  if nodeType == 'text' then
    props.value = readValue(props.value, deps)
  elseif nodeType == 'button' then
    props.label = readValue(props.label, deps)
    props.actionId = registerHandler(page, props.onPress)
    props.onPress = nil
  elseif nodeType == 'motion' then
    props.label = readValue(props.label, deps)
    props.actionId = registerHandler(page, props.onPress)
    props.onPress = nil
  elseif nodeType == 'input' or nodeType == 'textarea' or nodeType == 'slider' then
    props.value = readValue(props.value, deps)
    props.actionId = registerHandler(page, props.onChange)
    props.onChange = nil
  elseif nodeType == 'select' then
    props.value = readValue(props.value, deps)
    props.options = readValue(props.options, deps) or {}
    props.actionId = registerHandler(page, props.onChange)
    props.onChange = nil
  elseif nodeType == 'badge' then
    props.label = readValue(props.label, deps)
  elseif nodeType == 'typography' then
    props.value = readValue(props.value, deps)
  elseif nodeType == 'accordion' then
    props.items = readValue(props.items, deps) or {}
  elseif nodeType == 'tabs' then
    props.tabs = readValue(props.tabs, deps) or {}
  elseif nodeType == 'table' then
    props.columns = readValue(props.columns, deps) or {}
    props.rows = readValue(props.rows, deps) or {}
  elseif nodeType == 'carousel' then
    props.items = readValue(props.items, deps) or {}
  end

  if nodeType == 'list' then
    local values = readValue(blueprint.source, deps) or {}
    node.children = {}

    for index, item in ipairs(values) do
      local itemNode = addNode(node, {
        id = nextId(page, 'item'),
        type = 'item',
        props = {
          index = index,
          key = tostring(readItemKey(item, index, props)),
        },
        children = {},
      })

      addDeclarativeNode(itemNode, page, deps, blueprint.render(item, index, lui))
    end
  elseif blueprint.children ~= nil then
    node.children = {}
    addDeclarativeNode(node, page, deps, blueprint.children)
  end

  return node
end

function lui.text(value, props)
  props = shallowCopy(props)
  props.value = value

  return createLeafBlueprint('text', props)
end

function lui.button(label, onPress, props)
  props = shallowCopy(props)
  props.label = label
  props.onPress = onPress

  return createLeafBlueprint('button', props)
end

function lui.motionButton(label, onPress, props)
  props = shallowCopy(props)
  props.as = 'button'
  props.label = label
  props.onPress = onPress

  return createBlueprint('motion', props, {})
end

function lui.motionText(value, props)
  props = shallowCopy(props)
  props.as = props.as or 'p'
  props.label = value

  return createBlueprint('motion', props, {})
end

function lui.input(props)
  return createLeafBlueprint('input', shallowCopy(props))
end

function lui.select(props)
  return createLeafBlueprint('select', shallowCopy(props))
end

function lui.textarea(props)
  return createLeafBlueprint('textarea', shallowCopy(props))
end

function lui.slider(props)
  return createLeafBlueprint('slider', shallowCopy(props))
end

function lui.stack(props, children)
  props, children = normalizeContainerArgs(props, children)
  return createBlueprint('stack', props, children)
end

function lui.row(props, children)
  props, children = normalizeContainerArgs(props, children)
  return createBlueprint('row', props, children)
end

function lui.panel(props, children)
  props, children = normalizeContainerArgs(props, children)
  return createBlueprint('panel', props, children)
end

function lui.alert(props, children)
  props, children = normalizeContainerArgs(props, children)
  return createBlueprint('alert', props, children)
end

function lui.tooltip(props, children)
  props, children = normalizeContainerArgs(props, children)
  return createBlueprint('tooltip', props, children)
end

function lui.badge(label, props)
  props = shallowCopy(props)
  props.label = label

  return createLeafBlueprint('badge', props)
end

function lui.typography(value, props, children)
  if (type(value) == 'table' and not isReactive(value)) or (type(value) == 'function' and props == nil) then
    children = props
    props = value
    value = nil
  end

  props = shallowCopy(props)
  props.value = value

  if children ~= nil then
    return createBlueprint('typography', props, children)
  end

  return createLeafBlueprint('typography', props)
end

function lui.accordion(items, props)
  props = shallowCopy(props)
  props.items = items

  return createLeafBlueprint('accordion', props)
end

function lui.tabs(items, props)
  props = shallowCopy(props)
  props.tabs = items

  return createLeafBlueprint('tabs', props)
end

function lui.table(columns, rows, props)
  props = shallowCopy(props)
  props.columns = columns
  props.rows = rows

  return createLeafBlueprint('table', props)
end

function lui.carousel(items, props)
  props = shallowCopy(props)
  props.items = items

  return createLeafBlueprint('carousel', props)
end

function lui.presence(props, children)
  props, children = normalizeContainerArgs(props, children)
  return createBlueprint('presence', props, children)
end

lui.animatePresence = lui.presence

function lui.motion(props, children)
  props, children = normalizeContainerArgs(props, children)
  props.as = props.as or 'div'

  return createBlueprint('motion', props, children or {})
end

function lui.motionDiv(props, children)
  return lui.motion(props, children)
end

function lui.motionRow(props, children)
  props, children = normalizeContainerArgs(props, children)
  props.as = props.as or 'div'
  props.classBase = props.classBase or 'flex flex-wrap gap-3 items-center'

  return createBlueprint('motion', props, children or {})
end

function lui.motionStack(props, children)
  props, children = normalizeContainerArgs(props, children)
  props.as = props.as or 'div'
  props.classBase = props.classBase or 'flex flex-col gap-3'

  return createBlueprint('motion', props, children or {})
end

function lui.motionList(props, children)
  props, children = normalizeContainerArgs(props, children)
  props.as = props.as or 'ul'

  return createBlueprint('motion', props, children or {})
end

function lui.motionListItem(props, children)
  props, children = normalizeContainerArgs(props, children)
  props.as = props.as or 'li'

  return createBlueprint('motion', props, children or {})
end

lui.motionItem = lui.motionListItem

function lui.motionSection(props, children)
  props, children = normalizeContainerArgs(props, children)
  props.as = props.as or 'section'

  return createBlueprint('motion', props, children or {})
end

function lui.list(source, render, props)
  local blueprint = createBlueprint('list', shallowCopy(props), nil)
  blueprint.source = source
  blueprint.render = render

  return blueprint
end

function lui.fragment(children)
  return children or {}
end

function lui.component(component, ...)
  return component(...)
end

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

local function sendVisibility(page)
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

  if not sameValue(previousNode.props, nextNode.props) then
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
    addDeclarativeNode(tree, page, deps, page.builder(createBuilder(page, tree, deps)))
  else
    addDeclarativeNode(tree, page, deps, page.builder)
  end

  return tree
end

local renderPage

local function watchDeps(page, deps)
  for _, dep in ipairs(deps) do
    local stateName = dep.stateName
    if not page.watched[stateName] then
      page.watched[stateName] = true
      track.effect(function()
        renderPage(page)
      end, { dep })
    end
  end
end

renderPage = function(page, options)
  options = options or {}
  local deps = {}
  local previousHandlers = page.handlers or {}

  for _, actionId in ipairs(previousHandlers) do
    handlers[actionId] = nil
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

function lui.page(pageId, builder, props)
  local page = {
    id = pageId,
    builder = builder,
    props = props or {},
    watched = {},
    visible = false,
  }

  pages[pageId] = page
  renderPage(page, { force = true })
  return page
end

function lui.render(pageId)
  local page = pages[pageId]
  if page then
    renderPage(page)
  end
end

function lui.open(pageId, focusOptions)
  focusOptions = focusOptions or {}
  local page = pages[pageId]
  if page then
    page.visible = true
    renderPage(page)
  end

  SetNuiFocus(focusOptions.focus ~= false, focusOptions.cursor ~= false)
  sendVisibility(page or { id = pageId, visible = true })
end

function lui.close(pageId)
  local page = pages[pageId]
  if page then
    page.visible = false
  end

  SetNuiFocus(false, false)
  sendVisibility(page or { id = pageId, visible = false })
end

RegisterNUICallback('lui:ready', function(_, cb)
  for _, page in pairs(pages) do
    renderPage(page, { force = true })
    if page.visible == true then
      sendVisibility(page)
    end
  end

  cb({
    ok = true,
  })
end)

RegisterNUICallback('lui:event', function(data, cb)
  local handler = data and handlers[data.actionId]
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
end)

return lui

local type = type

local function create(lui, state, utils)
  local blueprint = {}

  local instantiateBlueprint

  function blueprint.addDeclarativeNode(parent, page, deps, node)
    if utils.isNodeBlueprint(node) then
      return utils.addNode(parent, instantiateBlueprint(page, deps, node))
    end

    if type(node) == 'table' then
      for _, child in ipairs(node) do
        blueprint.addDeclarativeNode(parent, page, deps, child)
      end
    end

    return node
  end

  local function createBlueprint(nodeType, props, children)
    return {
      __luiNode = true,
      type = nodeType,
      props = utils.normalizeProps(props),
      children = children,
    }
  end

  local function createLeafBlueprint(nodeType, props)
    return createBlueprint(nodeType, props, nil)
  end

  local function normalizeContainerArgs(props, children)
    if type(props) == 'function' or utils.isDeclarativeChildren(props) then
      children = props
      props = {}
    end

    return utils.normalizeProps(props), children
  end

  instantiateBlueprint = function(page, deps, nodeBlueprint)
    local props = utils.shallowCopy(nodeBlueprint.props)
    local nodeType = nodeBlueprint.type
    local node = {
      id = state.nextId(page, nodeType == 'list' and 'foreach' or nodeType),
      type = nodeType == 'list' and 'foreach' or nodeType,
      props = props,
    }

    if nodeType == 'text' then
      props.value = utils.readValue(props.value, deps)
    elseif nodeType == 'button' then
      props.label = utils.readValue(props.label, deps)
      props.actionId = state.registerHandler(page, props.onPress)
      props.onPress = nil
    elseif nodeType == 'motion' then
      props.label = utils.readValue(props.label, deps)
      props.actionId = state.registerHandler(page, props.onPress)
      props.onPress = nil
    elseif nodeType == 'input' or nodeType == 'textarea' or nodeType == 'slider' then
      props.value = utils.readValue(props.value, deps)
      props.actionId = state.registerHandler(page, props.onChange)
      props.onChange = nil
    elseif nodeType == 'select' then
      props.value = utils.readValue(props.value, deps)
      props.options = utils.readValue(props.options, deps) or {}
      props.actionId = state.registerHandler(page, props.onChange)
      props.onChange = nil
    elseif nodeType == 'badge' then
      props.label = utils.readValue(props.label, deps)
    elseif nodeType == 'typography' then
      props.value = utils.readValue(props.value, deps)
    elseif nodeType == 'accordion' then
      props.items = utils.readValue(props.items, deps) or {}
    elseif nodeType == 'tabs' then
      props.tabs = utils.readValue(props.tabs, deps) or {}
    elseif nodeType == 'table' then
      props.columns = utils.readValue(props.columns, deps) or {}
      props.rows = utils.readValue(props.rows, deps) or {}
    elseif nodeType == 'carousel' then
      props.items = utils.readValue(props.items, deps) or {}
    end

    if nodeType == 'list' then
      local values = utils.readValue(nodeBlueprint.source, deps) or {}
      node.children = {}

      for index, item in ipairs(values) do
        local itemNode = utils.addNode(node, {
          id = state.nextId(page, 'item'),
          type = 'item',
          props = {
            index = index,
            key = tostring(utils.readItemKey(item, index, props)),
          },
          children = {},
        })

        blueprint.addDeclarativeNode(itemNode, page, deps, nodeBlueprint.render(item, index, lui))
      end
    elseif nodeBlueprint.children ~= nil then
      node.children = {}
      blueprint.addDeclarativeNode(node, page, deps, nodeBlueprint.children)
    end

    return node
  end

  blueprint.instantiate = instantiateBlueprint

  function blueprint.attach()
    function lui.text(value, props)
      props = utils.shallowCopy(props)
      props.value = value

      return createLeafBlueprint('text', props)
    end

    function lui.button(label, onPress, props)
      props = utils.shallowCopy(props)
      props.label = label
      props.onPress = onPress

      return createLeafBlueprint('button', props)
    end

    function lui.motionButton(label, onPress, props)
      props = utils.shallowCopy(props)
      props.as = 'button'
      props.label = label
      props.onPress = onPress

      return createBlueprint('motion', props, {})
    end

    function lui.motionText(value, props)
      props = utils.shallowCopy(props)
      props.as = props.as or 'p'
      props.label = value

      return createBlueprint('motion', props, {})
    end

    function lui.input(props)
      return createLeafBlueprint('input', utils.shallowCopy(props))
    end

    function lui.select(props)
      return createLeafBlueprint('select', utils.shallowCopy(props))
    end

    function lui.textarea(props)
      return createLeafBlueprint('textarea', utils.shallowCopy(props))
    end

    function lui.slider(props)
      return createLeafBlueprint('slider', utils.shallowCopy(props))
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
      props = utils.shallowCopy(props)
      props.label = label

      return createLeafBlueprint('badge', props)
    end

    function lui.typography(value, props, children)
      if (type(value) == 'table' and not utils.isReactive(value)) or (type(value) == 'function' and props == nil) then
        children = props
        props = value
        value = nil
      end

      props = utils.shallowCopy(props)
      props.value = value

      if children ~= nil then
        return createBlueprint('typography', props, children)
      end

      return createLeafBlueprint('typography', props)
    end

    function lui.accordion(items, props)
      props = utils.shallowCopy(props)
      props.items = items

      return createLeafBlueprint('accordion', props)
    end

    function lui.tabs(items, props)
      props = utils.shallowCopy(props)
      props.tabs = items

      return createLeafBlueprint('tabs', props)
    end

    function lui.table(columns, rows, props)
      props = utils.shallowCopy(props)
      props.columns = columns
      props.rows = rows

      return createLeafBlueprint('table', props)
    end

    function lui.carousel(items, props)
      props = utils.shallowCopy(props)
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
      local listBlueprint = createBlueprint('list', utils.shallowCopy(props), nil)
      listBlueprint.source = source
      listBlueprint.render = render

      return listBlueprint
    end

    function lui.fragment(children)
      return children or {}
    end

    function lui.component(component, ...)
      return component(...)
    end
  end

  return blueprint
end

return {
  create = create,
}

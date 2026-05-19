local type = type

local function create(lui, state, utils, blueprint)
  local builderModule = {}

  function builderModule.createBuilder(page, parent, deps)
    local builder = {
      h = lui,
      node = lui,
      parent = parent,
    }

    local function addCurrentNode(node)
      return utils.addNode(builder.parent, node)
    end

    local function withParent(node, callback)
      if utils.isDeclarativeChildren(callback) then
        blueprint.addDeclarativeNode(node, page, deps, callback)
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
      if type(props) == 'function' or utils.isDeclarativeChildren(props) then
        callback = props
        props = {}
      end

      local node = addCurrentNode({
        id = state.nextId(page, prefix),
        type = nodeType,
        props = utils.normalizeProps(props),
        children = {},
      })

      return withParent(node, callback)
    end

    local function addLeaf(prefix, nodeType, props)
      return addCurrentNode({
        id = state.nextId(page, prefix),
        type = nodeType,
        props = utils.normalizeProps(props),
      })
    end

    local function addMotion(elementName, props, callback)
      if type(props) == 'function' then
        callback = props
        props = {}
      end

      props = utils.normalizeProps(props)
      props.as = props.as or elementName

      local node = addCurrentNode({
        id = state.nextId(page, 'motion'),
        type = 'motion',
        props = props,
        children = {},
      })

      return withParent(node, callback)
    end

    local function renderCondition(condition, onTruthy, onFalsy)
      local value = utils.readValue(condition, deps)
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
      local value = utils.readValue(condition, deps)
      local callback = value and onTruthy or onFalsy

      if type(callback) == 'function' then
        callback(builder, value)
      end

      return not value
    end

    builder['if'] = builder.when

    function builder.text(value, props)
      props = utils.normalizeProps(props)
      props.value = utils.readValue(value, deps)

      return addCurrentNode({
        id = state.nextId(page, 'text'),
        type = 'text',
        props = props,
      })
    end

    function builder.button(label, onPress, props)
      props = utils.normalizeProps(props)
      props.label = utils.readValue(label, deps)
      props.actionId = state.registerHandler(page, onPress)

      return addCurrentNode({
        id = state.nextId(page, 'button'),
        type = 'button',
        props = props,
      })
    end

    function builder.motionButton(label, onPress, props)
      props = utils.normalizeProps(props)
      props.as = 'button'
      props.label = utils.readValue(label, deps)
      props.actionId = state.registerHandler(page, onPress)

      return addCurrentNode({
        id = state.nextId(page, 'motion'),
        type = 'motion',
        props = props,
        children = {},
      })
    end

    function builder.motionText(value, props)
      props = utils.normalizeProps(props)
      props.as = props.as or 'p'
      props.label = utils.readValue(value, deps)

      return addCurrentNode({
        id = state.nextId(page, 'motion'),
        type = 'motion',
        props = props,
        children = {},
      })
    end

    function builder.input(props)
      props = utils.normalizeProps(props)
      props.value = utils.readValue(props.value, deps)
      props.actionId = state.registerHandler(page, props.onChange)
      props.onChange = nil

      return addCurrentNode({
        id = state.nextId(page, 'input'),
        type = 'input',
        props = props,
      })
    end

    function builder.select(props)
      props = utils.normalizeProps(props)
      props.value = utils.readValue(props.value, deps)
      props.options = utils.readValue(props.options, deps) or {}
      props.actionId = state.registerHandler(page, props.onChange)
      props.onChange = nil

      return addCurrentNode({
        id = state.nextId(page, 'select'),
        type = 'select',
        props = props,
      })
    end

    function builder.textarea(props)
      props = utils.normalizeProps(props)
      props.value = utils.readValue(props.value, deps)
      props.actionId = state.registerHandler(page, props.onChange)
      props.onChange = nil

      return addLeaf('textarea', 'textarea', props)
    end

    function builder.slider(props)
      props = utils.normalizeProps(props)
      props.value = utils.readValue(props.value, deps)
      props.actionId = state.registerHandler(page, props.onChange)
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
      props = utils.normalizeProps(props)
      props.label = utils.readValue(label, deps)

      return addLeaf('badge', 'badge', props)
    end

    function builder.typography(value, props, callback)
      if (type(value) == 'table' and not utils.isReactive(value)) or (type(value) == 'function' and props == nil) then
        callback = props
        props = value
        value = nil
      end

      props = utils.normalizeProps(props)
      if value ~= nil then
        props.value = utils.readValue(value, deps)
      end

      if type(callback) == 'function' then
        return addContainer('typography', 'typography', props, callback)
      end

      return addLeaf('typography', 'typography', props)
    end

    function builder.accordion(items, props)
      props = utils.normalizeProps(props)
      props.items = utils.readValue(items, deps) or props.items or {}

      return addLeaf('accordion', 'accordion', props)
    end

    function builder.tabs(items, props)
      props = utils.normalizeProps(props)
      props.tabs = utils.readValue(items, deps) or props.tabs or {}

      return addLeaf('tabs', 'tabs', props)
    end

    function builder.table(columns, rows, props)
      props = utils.normalizeProps(props)
      props.columns = utils.readValue(columns, deps) or props.columns or {}
      props.rows = utils.readValue(rows, deps) or props.rows or {}

      return addLeaf('table', 'table', props)
    end

    function builder.carousel(items, props)
      props = utils.normalizeProps(props)
      props.items = utils.readValue(items, deps) or props.items or {}

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

      props = utils.normalizeProps(props)
      props.as = props.as or 'div'
      props.classBase = props.classBase or 'flex flex-wrap gap-3 items-center'
      return addMotion('div', props, callback)
    end

    function builder.motionStack(props, callback)
      if type(props) == 'function' then
        callback = props
        props = {}
      end

      props = utils.normalizeProps(props)
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
      props = utils.normalizeProps(props)
      local values = utils.readValue(source, deps) or {}
      local node = addCurrentNode({
        id = state.nextId(page, 'foreach'),
        type = 'foreach',
        props = props,
        children = {},
      })

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

        local previousParent = builder.parent
        builder.parent = itemNode
        callback(item, index, builder)
        builder.parent = previousParent
      end

      return node
    end

    return builder
  end

  return builderModule
end

return {
  create = create,
}

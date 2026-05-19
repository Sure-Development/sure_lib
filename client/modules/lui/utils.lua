local utils = {}
local type = type

function utils.isReactive(value)
  return type(value) == 'table' and value.isReactive == true and type(value.stateName) == 'string'
end

function utils.readValue(value, deps)
  if utils.isReactive(value) then
    deps[#deps + 1] = value
    return value()
  end

  return value
end

function utils.normalizeProps(props)
  if type(props) == 'table' then
    return props
  end

  return {}
end

function utils.isNodeBlueprint(value)
  return type(value) == 'table' and value.__luiNode == true
end

function utils.shallowCopy(values)
  local copied = {}
  for key, value in pairs(values or {}) do
    copied[key] = value
  end

  return copied
end

function utils.isDeclarativeChildren(value)
  if utils.isNodeBlueprint(value) then
    return true
  end

  if type(value) ~= 'table' then
    return false
  end

  for _, child in ipairs(value) do
    if utils.isNodeBlueprint(child) or utils.isDeclarativeChildren(child) then
      return true
    end
  end

  return false
end

function utils.readItemKey(item, index, props)
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

function utils.sameValue(left, right)
  if left == right then
    return true
  end

  if type(left) ~= 'table' or type(right) ~= 'table' then
    return false
  end

  for key, value in pairs(left) do
    if not utils.sameValue(value, right[key]) then
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

function utils.addNode(parent, node)
  parent.children[#parent.children + 1] = node
  return node
end

return utils

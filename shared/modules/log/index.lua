local app = {}

local levels = {
  debug = 0,
  info = 1,
  warn = 2,
  error = 3,
}

local currentLevel = 'info'

local function levelValue(level)
  return levels[level] or 0
end

local function shouldEmit(level)
  return levelValue(level) >= levelValue(currentLevel)
end

local function tagged(tag, message)
  if tag == nil or tag == '' then
    return tostring(message)
  end

  return ('[%s] %s'):format(tag, tostring(message))
end

local function emit(tag, level, message)
  if not shouldEmit(level) then
    return
  end

  if level == 'error' or level == 'warn' then
    lib.print.error(tagged(tag, ('[%s] %s'):format(level, message)))
    return
  end

  lib.print.info(tagged(tag, message))
end

--- @param level 'debug'|'info'|'warn'|'error'
function app.setLevel(level)
  if levels[level] ~= nil then
    currentLevel = level
  end
end

--- @return string
function app.getLevel()
  return currentLevel
end

--- @param tag string
--- @return SureLogger
function app.create(tag)
  local logger = {}

  function logger:debug(message)
    emit(tag, 'debug', message)
  end

  function logger:info(message)
    emit(tag, 'info', message)
  end

  function logger:warn(message)
    emit(tag, 'warn', message)
  end

  function logger:error(message)
    emit(tag, 'error', message)
  end

  return logger
end

function app.debug(message)
  emit(nil, 'debug', message)
end

function app.info(message)
  emit(nil, 'info', message)
end

function app.warn(message)
  emit(nil, 'warn', message)
end

function app.error(message)
  emit(nil, 'error', message)
end

return app

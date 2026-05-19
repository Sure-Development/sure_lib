--- @alias SURELIB.MODULE_NAME 'esx'|'player'|'cooldown'|'validator'|'track'|'listener'|'spawn'|'config'|'db'

---@diagnostic disable-next-line: lowercase-global
sure = sure or {}

local resourceName = 'sure_lib'
local currentSide = IsDuplicityVersion() and 'server' or 'client'
local lower = string.lower

local modulePaths = {
  esx = {
    server = 'server.modules.esx.index',
  },
  player = {
    client = 'client.modules.player.index',
  },
  cooldown = {
    client = 'client.modules.cooldown.index',
    server = 'server.modules.cooldown.index',
  },
  validator = {
    shared = 'shared.modules.validator.index',
  },
  track = {
    shared = 'shared.modules.track.index',
  },
  listener = {
    shared = 'shared.modules.listener.index',
  },
  spawn = {
    client = 'client.modules.spawn.index',
  },
  config = {
    shared = 'shared.modules.config.index',
  },
  db = {
    server = 'server.modules.db.index',
  },
}

--- @param path string
--- @return string
local function buildModulePath(path)
  return ('@%s.%s'):format(resourceName, path)
end

--- @param name SURELIB.MODULE_NAME|string
--- @return any?
function sure.getModule(name)
  if type(name) ~= 'string' then
    return nil
  end

  local paths = modulePaths[lower(name)]
  if paths == nil then
    return nil
  end

  local path = paths[currentSide] or paths.shared
  if path == nil then
    return nil
  end

  return require(buildModulePath(path))
end

if currentSide == 'client' then
  sure.player = sure.getModule('player')
end
